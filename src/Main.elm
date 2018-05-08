port module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (..)
import Json.Encode exposing (..)
import Keyboard exposing (..)


---- MODEL ----


type alias Model =
    { showPalette : Bool, searchField : String, error : Maybe String, tabs : List String }


init : ( Model, Cmd Msg )
init =
    ( { showPalette = False, searchField = "", error = Nothing, tabs = [] }, Cmd.none )



---- UPDATE ----


type Msg
    = NoOp
    | TogglePalette
    | ClosePalette
    | UpdateField String
    | GetTabs (List String)
    | HandleResponseError (Maybe String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        TogglePalette ->
            { model | showPalette = not model.showPalette }
                ! []

        ClosePalette ->
            { model | showPalette = False }
                ! []

        UpdateField str ->
            { model | searchField = str }
                ! []

        GetTabs tabs ->
            { model | tabs = tabs } ! []

        HandleResponseError errStr ->
            { model | error = errStr } ! []



---- PORTS ----


type alias IncomingAction =
    { actionType : String, payload : Json.Encode.Value }


port consumeResponse : (Json.Decode.Value -> msg) -> Sub msg


decodeResponse : Json.Decode.Value -> Msg
decodeResponse json =
    case Json.Decode.decodeValue incomingActionDecoder json of
        Err err ->
            HandleResponseError (Just err)

        Ok incomingAction ->
            case incomingAction.actionType of
                "TOGGLE_PALETTE" ->
                    TogglePalette

                "GET_TABS" ->
                    case Json.Decode.decodeValue (Json.Decode.list Json.Decode.string) incomingAction.payload of
                        Err err ->
                            HandleResponseError (Just err)

                        Ok tabs ->
                            GetTabs tabs

                _ ->
                    NoOp


incomingActionDecoder : Decoder IncomingAction
incomingActionDecoder =
    decode IncomingAction
        |> Json.Decode.Pipeline.required "actionType" Json.Decode.string
        |> Json.Decode.Pipeline.required "payload" Json.Decode.value



---- VIEW ----


view : Model -> Html Msg
view model =
    if model.showPalette then
        div [ class "command-palette" ]
            [ input
                [ class "command-palette-input"
                , placeholder "Start typing to search..."
                , autofocus True
                , value model.searchField
                , name "newTodo"
                , onInput UpdateField
                ]
                []
            , div [ class "command-palette" ] (List.map Html.text model.tabs)
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
                    ClosePalette
                else
                    NoOp
            )
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
