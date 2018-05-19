port module Main exposing (..)

import Dom
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (..)
import Json.Encode exposing (..)
import Keyboard
import Mouse
import Task


---- MODEL ----


type alias Model =
    { showPalette : Bool
    , filterField : String
    , error : Maybe String
    , suggestions : List Suggestion
    , selectedId : Maybe Int
    }


type alias Suggestion =
    { id : Int
    , title : String
    , favIconUrl : String
    }


type ArrowKey
    = Up
    | Down


init : ( Model, Cmd Msg )
init =
    ( { showPalette = False
      , filterField = ""
      , error = Nothing
      , suggestions = []
      , selectedId = Just 0
      }
    , encodeRequest RequestSuggestions
    )



---- UPDATE ----


getPreviousItemId : List Int -> Int -> Int
getPreviousItemId ids selectedId =
    Maybe.withDefault selectedId <| List.foldr (getPrevious selectedId) Nothing ids


getPrevious : Int -> Int -> Maybe Int -> Maybe Int
getPrevious id selectedId resultId =
    if selectedId == id then
        Just id
    else if Maybe.withDefault 0 resultId == id then
        Just selectedId
    else
        resultId


getNextItemId : List Int -> Int -> Int
getNextItemId ids selectedId =
    Maybe.withDefault selectedId <| List.foldl (getPrevious selectedId) Nothing ids


navigateWithKey : ArrowKey -> List Int -> Maybe Int -> Maybe Int
navigateWithKey code ids maybeId =
    case code of
        Up ->
            Maybe.map (getPreviousItemId ids) maybeId

        Down ->
            Maybe.map (getNextItemId ids) maybeId


type Msg
    = NoOp
    | TogglePalette
    | KeyDown ArrowKey
    | ResetFilter
    | Blur
    | UpdateFilter String
    | FocusResult (Result Dom.Error ())
    | UpdateSuggestions (List Suggestion)
    | HandleResponseError (Maybe String)
    | HandleRequest OutgoingAction


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        HandleRequest action ->
            case action of
                RequestSuggestions ->
                    model ! [ encodeRequest RequestSuggestions ]

        TogglePalette ->
            { model | showPalette = not model.showPalette }
                ! [ Task.attempt FocusResult (Dom.focus "command-palette-input") ]

        Blur ->
            { model | showPalette = False }
                ! []

        KeyDown key ->
            { model
                | selectedId = navigateWithKey key (List.map (\x -> x.id) model.suggestions) model.selectedId
            }
                ! []

        UpdateFilter str ->
            { model | filterField = str }
                ! []

        ResetFilter ->
            { model | filterField = "" } ! []

        FocusResult result ->
            case result of
                Err (Dom.NotFound id) ->
                    model ! []

                Ok () ->
                    model ! []

        UpdateSuggestions suggestions ->
            { model | suggestions = suggestions } ! []

        HandleResponseError errStr ->
            { model | error = errStr } ! []



---- PORTS ----


type OutgoingAction
    = RequestSuggestions


type alias Action =
    { actionType : String, payload : Json.Encode.Value }



-- Incoming


port consumeResponse : (Json.Decode.Value -> msg) -> Sub msg



-- Outgoing


port sendRequest : Action -> Cmd msg


encodeRequest : OutgoingAction -> Cmd msg
encodeRequest action =
    case action of
        RequestSuggestions ->
            sendRequest { actionType = "REQUEST_SUGGESTIONS", payload = Json.Encode.null }


decodeResponse : Json.Decode.Value -> Msg
decodeResponse json =
    case Json.Decode.decodeValue incomingActionDecoder json of
        Err err ->
            HandleResponseError (Just err)

        Ok incomingAction ->
            case incomingAction.actionType of
                "TOGGLE_PALETTE" ->
                    TogglePalette

                "SUGGESTIONS_UPDATED" ->
                    case Json.Decode.decodeValue (Json.Decode.list suggestionDecoder) incomingAction.payload of
                        Err err ->
                            HandleResponseError (Just err)

                        Ok suggestions ->
                            UpdateSuggestions suggestions

                _ ->
                    NoOp


suggestionDecoder : Decoder Suggestion
suggestionDecoder =
    decode Suggestion
        |> Json.Decode.Pipeline.required "id" Json.Decode.int
        |> Json.Decode.Pipeline.required "title" Json.Decode.string
        |> Json.Decode.Pipeline.required "favIconUrl" Json.Decode.string


incomingActionDecoder : Decoder Action
incomingActionDecoder =
    decode Action
        |> Json.Decode.Pipeline.required "actionType" Json.Decode.string
        |> Json.Decode.Pipeline.required "payload" Json.Decode.value



---- VIEW ----


viewInput : Model -> Html Msg
viewInput { filterField } =
    input
        [ class "command-palette-input"
        , placeholder "Start typing to search..."
        , id "command-palette-input"
        , autofocus True
        , value filterField
        , name "command-palette-input"
        , onInput UpdateFilter
        ]
        []


viewSuggestions : Model -> Html Msg
viewSuggestions { suggestions, filterField, selectedId } =
    div [ class "suggestions" ]
        (suggestions
            |> List.filter (\{ title, favIconUrl } -> String.contains (String.toLower filterField) (String.toLower title))
            |> List.map (viewSuggestion selectedId)
        )


viewSuggestion : Maybe Int -> Suggestion -> Html Msg
viewSuggestion selectedId suggestion =
    div [ classList [ ( "suggestion", True ), ( "selected", suggestion.id == Maybe.withDefault 0 selectedId ) ] ]
        [ viewIcon suggestion
        , p [] [ text suggestion.title ]
        ]


viewIcon : Suggestion -> Html Msg
viewIcon { favIconUrl } =
    span [ class "icon-container" ]
        [ img [ src (getIcon favIconUrl) ] [] ]


getIcon : String -> String
getIcon iconUrl =
    if String.isEmpty iconUrl then
        ""
    else
        iconUrl


view : Model -> Html Msg
view model =
    if model.showPalette then
        div [ classList [ ( "command-palette", True ), ( "empty", List.isEmpty model.suggestions ) ] ]
            [ viewInput model
            , viewSuggestions model
            ]
    else
        Html.text ""



---- SUBSCRIPTIONS ----


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ consumeResponse decodeResponse
        , Keyboard.downs
            (\code ->
                case code of
                    27 ->
                        Blur

                    38 ->
                        KeyDown Up

                    40 ->
                        KeyDown Down

                    _ ->
                        NoOp
            )
        , if model.showPalette then
            Mouse.clicks (always Blur)
          else
            Sub.none
        ]



---- PROGRAM ----


main : Program Never Model Msg
main =
    Html.program
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        }
