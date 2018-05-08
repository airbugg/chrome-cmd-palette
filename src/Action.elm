module Action exposing (..)

import Json.Decode exposing (..)


type alias Action =
    { actionType : String
    , payload : List String
    }


actionDecoder : Decoder Action
actionDecoder =
    map2 Action
        (field "actionType" string)
        (field "payload" (list string))
