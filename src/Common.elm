module Common exposing (..)

{-| This module contains code shared in Settings, Main and Game.
-}

--------------------------------------------------------------------------------
-- TYPES
--------------------------------------------------------------------------------


{-| Basic type representation for a two player game.
-}
type Player
    = Player1
    | Player2


{-| The game either ends up with a winner or as a draw.
-}
type Outcome
    = Winner Player
    | Draw


{-| A game is either in progress of complete.
-}
type Status
    = Playing
    | Complete Player


--------------------------------------------------------------------------------
-- CONVENIENCE FUNCTIONS
--------------------------------------------------------------------------------


{-| A convenience function for the opposite player.
-}
opponent : Player -> Player
opponent player =
    case player of
        Player1 ->
            Player2

        Player2 ->
            Player1

