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
    { showPalette : Bool, filterField : String, error : Maybe String, suggestions : List String }


init : ( Model, Cmd Msg )
init =
    ( { showPalette = False, filterField = "", error = Nothing, suggestions = [] }, encodeRequest RequestSuggestions )



---- UPDATE ----


type Msg
    = NoOp
    | TogglePalette
    | Blur
    | UpdateFilter String
    | FocusResult (Result Dom.Error ())
    | UpdateSuggestions (List String)
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

        UpdateFilter str ->
            { model | filterField = str }
                ! []

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
                    case Json.Decode.decodeValue (Json.Decode.list Json.Decode.string) incomingAction.payload of
                        Err err ->
                            HandleResponseError (Just err)

                        Ok suggestions ->
                            UpdateSuggestions suggestions

                _ ->
                    NoOp


incomingActionDecoder : Decoder Action
incomingActionDecoder =
    decode Action
        |> Json.Decode.Pipeline.required "actionType" Json.Decode.string
        |> Json.Decode.Pipeline.required "payload" Json.Decode.value



---- VIEW ----


view : Model -> Html Msg
view model =
    if model.showPalette then
        div [ classList [ ( "command-palette", True ), ( "empty", List.isEmpty model.suggestions ) ] ]
            [ input
                [ class "command-palette-input"
                , placeholder "Start typing to search..."
                , id "command-palette-input"
                , autofocus True
                , value model.filterField
                , name "newTodo"
                , onInput UpdateFilter
                ]
                []
            , div [ class "suggestions" ]
                (model.suggestions
                    |> List.filter (\suggestion -> String.contains (String.toLower model.filterField) (String.toLower suggestion))
                    |> List.map (\tab -> div [ class "suggestion" ] [ p [] [ text tab ] ])
                )
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
                if code == 27 then
                    Blur
                else
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
