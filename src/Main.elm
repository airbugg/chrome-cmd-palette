port module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import Keyboard exposing (..)


-- type alias GenericOutsideData =
--     { tag : String, data : Json.Encode.Value }
-- port sendEvent : GenericOutsideData -> Cmd msg


port consumeEvent : (() -> msg) -> Sub msg



---- MODEL ----


type alias Model =
    { showPalette : Bool, searchField : String }


init : ( Model, Cmd Msg )
init =
    ( { showPalette = False, searchField = "" }, Cmd.none )



---- UPDATE ----


type Msg
    = NoOp
    | TogglePalette
    | ClosePalette
    | UpdateField String


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
            ]
    else
        Html.text ""


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ consumeEvent (\_ -> TogglePalette)
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
