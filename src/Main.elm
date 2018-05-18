port module Main exposing (..)

import Dom
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (..)
import Json.Encode exposing (..)
import Keyboard exposing (..)
import Mouse
import Task


---- MODEL ----


type alias Model =
    { showPalette : Bool
    , filterField : String
    , error : Maybe String
    , suggestions : List Suggestion
    , selectedId : Int
    }


type alias Suggestion =
    { title : String
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
      , selectedId = 0
      }
    , encodeRequest RequestSuggestions
    )



---- UPDATE ----


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
            case key of
                Up ->
                    { model | selectedId = model.selectedId + 1 } ! []

                Down ->
                    { model | selectedId = model.selectedId - 1 } ! []

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
        |> Json.Decode.Pipeline.required "title" Json.Decode.string
        |> Json.Decode.Pipeline.required "favIconUrl" Json.Decode.string


incomingActionDecoder : Decoder Action
incomingActionDecoder =
    decode Action
        |> Json.Decode.Pipeline.required "actionType" Json.Decode.string
        |> Json.Decode.Pipeline.required "payload" Json.Decode.value



---- VIEW ----


viewInput : Model -> Html Msg
viewInput model =
    input
        [ class "command-palette-input"
        , placeholder "Start typing to search..."
        , id "command-palette-input"
        , autofocus True
        , value model.filterField
        , name "command-palette-input"
        , onInput UpdateFilter
        ]
        []


viewSuggestions : Model -> Html Msg
viewSuggestions model =
    div [ class "suggestions" ]
        (model.suggestions
            |> List.filter (\{ title, favIconUrl } -> String.contains (String.toLower model.filterField) (String.toLower title))
            |> List.map viewSuggestion
        )


viewSuggestion : Suggestion -> Html Msg
viewSuggestion suggestion =
    div [ class "suggestion" ]
        [ viewIcon suggestion
        , p [] [ text suggestion.title ]
        ]


viewIcon : Suggestion -> Html Msg
viewIcon suggestion =
    span [ class "icon-container" ]
        [ img [ src (getIcon suggestion.favIconUrl) ] [] ]


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
        , downs
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
             -- if code == 27 then
             --     Blur
             -- else
             --     NoOp
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
