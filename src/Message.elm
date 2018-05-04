module Message exposing (..)

import Json.Decode exposing (Decoder)
import Json.Encode


decodeMessage : Decoder Message
decodeMessage =
    Json.Decode.map2 Message
        (Json.Decode.at [ "id" ] Json.Decode.string)
        (Json.Decode.at [ "content" ] Json.Decode.string)


encodeMessage : Message -> Json.Encode.Value
encodeMessage message =
    Json.Encode.object
        [ ( "id", Json.Encode.string message.id )
        , ( "content", Json.Encode.string message.content )
        ]


type alias Message =
    { id : String
    , content : String
    }
