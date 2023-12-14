module Game exposing (..)

{-| This file handles all the game logic and provides the Gameplay interface to the Main application.alias.
-}

import Array exposing (..)
import Common exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import List exposing (..)
import Process
import Random exposing (Generator)
import Random.List
import Settings exposing (..)
import Task
import Tuple exposing (first)



--------------------------------------------------------------------------------
-- GAME MODEL
--------------------------------------------------------------------------------


{-| A record type which contains all of the game state.
-}
type alias Game =
    { settings : Settings
    , status : Status
    , turn : Player
    , tower : Array Block -- tower state
    , moveCount : Int -- overall move count
    , p1MoveCount : Int -- moves by player 1
    , p2MoveCount : Int -- moves by player 2
    , p1Score : Int -- current score of player 1
    , p2Score : Int -- current score of player 2
    , c1 : Int -- value of block c1 if chosen
    , c2 : Int -- value of block c2 if chosen
    , stage : Stage -- current stage of the game
    , winning : Player -- who is currently winning
    }

{-| A block in the tower.
-}
type alias Block =
    { front : Int -- value of the front of the block
    , touched : Bool -- has block been touched (description definition)
    , rotation : Int -- used to show forward rotation in css
    }

{-| The possible stages of the game.
-}
type Stage
    = StageSelectC1 -- no block selected
    | StageSelectC2 -- c1 selected
    | StageRotate -- c1 and c2 selected

{-| Create the initial game data given the settings.
-}
init : Settings -> ( Game, Cmd Msg )
init settings =
    let
        -- generate random tower using seed
        tower = Random.initialSeed settings.randomSeed
                |> Random.step (generateRandomFronts settings.towerSize)
                |> first
                |> List.map (\front -> {front = front, touched = False, rotation = front})
                |> Array.fromList

        initialSettings = 
            { settings = settings
            , status = Playing
            , turn = Player1
            , tower = tower
            , moveCount = 0
            , p1MoveCount = 0
            , p2MoveCount = 0
            , p1Score = settings.towerSize
            , p2Score = settings.towerSize
            , c1 = -1
            , c2 = -1
            , stage = StageSelectC1
            , winning = Player1
            }
    in
    case settings.playMode of
        PlaySolo ->
            ( initialSettings, Cmd.none )

        PlayHumanVsHuman ->
            ( initialSettings, Cmd.none )

        PlayHumanVsBot ->
            ( initialSettings, Cmd.none )

        PlayBotVsHuman ->
            ( initialSettings, Task.perform (\_ -> PauseThenMakeBotMove) (Process.sleep 1000) )

        
--------------------------------------------------------------------------------
-- GAME LOGIC
--------------------------------------------------------------------------------


{-| The possible moves that a player can make.
-}
type Move
    = Rotate Int Int Int
    | SelectC1 Int
    | SelectC2 Int
    | BackToSelectC2
    | BackToSelectC1


{-| Apply a move to a game state, returning a new game state.
-}
applyMove : Move -> Game -> Game
applyMove move game =
    case move of
        Rotate blockC1 blockC2 offset ->
            let 
                newTower =
                    rotateSegment blockC1 blockC2 offset game.tower

                newScore = 
                    getTidiness newTower
                
                newWinner = 
                    if newScore < game.p1Score && newScore < game.p2Score then
                        game.turn
                    else
                        game.winning
            in
            case game.settings.playMode of
                PlaySolo ->
                    if towerSolved newTower then
                        { game | tower = newTower, moveCount = game.moveCount + 1
                        , c1 = -1, c2 = -1, status = Complete Player1 }
                    else
                        { game | tower = newTower, moveCount = game.moveCount + 1
                        , c1 = -1, c2 = -1, stage = StageSelectC1 }
                _ ->
                     case game.turn of
                        Player1 ->
                            if towerSolved newTower then
                                { game | tower = newTower, moveCount = game.moveCount + 1, p1MoveCount = game.p1MoveCount + 1
                                , turn = Player2, c1 = -1, c2 = -1, status = Complete newWinner,  p1Score = Basics.min newScore game.p1Score,
                                winning = newWinner }
                            else
                                { game | tower = newTower, moveCount = game.moveCount + 1, p1MoveCount = game.p1MoveCount + 1
                                , turn = Player2, c1 = -1, c2 = -1, stage = StageSelectC1, p1Score = Basics.min newScore game.p1Score,
                                winning = newWinner}
                        Player2 ->
                            if towerSolved newTower || game.p1MoveCount == game.settings.moveLimit then
                                { game | tower = newTower, moveCount = game.moveCount + 1, p2MoveCount = game.p2MoveCount + 1
                                , turn = Player1, c1 = -1, c2 = -1, status = Complete newWinner, p2Score = Basics.min newScore game.p2Score,
                                winning = newWinner  }
                            else
                                { game | tower = newTower, moveCount = game.moveCount + 1, p2MoveCount = game.p2MoveCount + 1
                                , turn = Player1, c1 = -1, c2 = -1, stage = StageSelectC1, p2Score = Basics.min newScore game.p2Score
                                , winning = newWinner }
               
        SelectC1 blockC1 ->
            { game | c1 = blockC1, stage = StageSelectC2 }

        SelectC2 blockC2 ->
            { game | c2 = blockC2 + 1, stage = StageRotate }

        BackToSelectC2 ->
            { game | c2 = -1, stage = StageSelectC2 }

        BackToSelectC1 ->
            { game | c1 = -1, stage = StageSelectC1 }

{-| Rotate all blocks between c1 and c2 by offset
return resulting tower
-}
rotateSegment : Int -> Int -> Int -> Array Block -> Array Block
rotateSegment blockC1 blockC2 offset tower =
    let
        segment =
            Array.slice blockC1 blockC2 tower
    in
    let
        rotatedSegment =
            Array.map (\block -> { block | front = modBy 4 (block.front + offset), rotation = block.rotation + offset }) segment
    in
    Array.append (Array.slice 0 blockC1 tower) (Array.append rotatedSegment (Array.slice blockC2 (Array.length tower) tower))
        |> touchBlock blockC1

--------------------------------------------------------------------------------
-- GAME LOGIC HELPERS
--------------------------------------------------------------------------------


{-| Create the initial tower with random values
-}
generateTower : Int -> Array Block
generateTower towerSize =
    List.range 0 (towerSize - 1)
        |> List.map (\x -> {front = modBy 4 x, touched = False, rotation = modBy 4 x})
        |> Array.fromList

{-| Generate random values from 0 to 3 for each front
-}
generateRandomFronts: Int -> Generator (List Int)
generateRandomFronts numFronts =
    Random.list numFronts (Random.int 0 3)

{-| Calculate score (or tidiness) of a tower
-}
getTidiness : Array Block -> Int
getTidiness tower =
    let
        frontList =
            Array.toList tower
                |> List.map (\block -> block.front)
        
        tidiness = 
            List.maximum (List.map (\x -> List.length (List.filter (\y -> y == x) frontList)) [0, 1, 2, 3])
    in
    case tidiness of
        Just t ->
            (Array.length tower - t)
        Nothing ->
            Array.length tower


{-| Mark a block as touched
-}
touchBlock : Int -> Array Block -> Array Block
touchBlock blockIndex tower =
    let
        block =
            Array.get blockIndex tower

        front =
            case block of
                Just b ->
                    b.front
                Nothing ->
                    -1

        rotation = case block of
            Just b ->
                b.rotation
            Nothing ->
                -1
    in
    Array.set blockIndex { front = front, touched = True, rotation = rotation } tower

{-| Check if tower has 0-tidiness
-}
towerSolved : Array Block -> Bool
towerSolved tower =
    let
        firstBlock =
            Array.get 0 tower

        front =
            case firstBlock of
                Just b ->
                    b.front
                Nothing ->
                    -1
    in
    Array.foldr (\block acc -> acc && block.front == front) True tower



--------------------------------------------------------------------------------
-- INTERFACE LOGIC
--
-- This section deals with how to map the interface to the game logic.
--
-- Msg contains messages that can be sent from the game interface.
--
-- This also sets scaffolding for the computer players - when a computer player
-- makes a move, they generate a message (ReceivedComputerMove) which is then handled
-- just like a player interacting with the interface.
--------------------------------------------------------------------------------


{-| An enumeration of all messages that can be sent from the interface to the game
-}
type Msg
    = ClickedBlock Int
    | ClickedUndo
    | ClickedRotate Int Int Int
    | ReceivedBotMove Move
    | PauseThenMakeBotMove
    | NoOp


{-| A convenience function to pipe a command into a (Game, Cmd Msg) tuple.
-}
withCmd : Cmd Msg -> Game -> ( Game, Cmd Msg )
withCmd cmd game =
    ( game, cmd )


{-| The main update function for the game, which takes an interface message and returns
a new game state as well as any additional commands to be run.
-}
update : Msg -> Game -> ( Game, Cmd Msg )
update msg game =
    case msg of
        ClickedBlock block ->
            case game.stage of
                StageSelectC1 ->
                    game
                        |> applyMove (SelectC1 block)
                        |> withCmd Cmd.none
                StageSelectC2 ->
                    game
                        |> applyMove (SelectC2 block)
                        |> withCmd Cmd.none
                _ ->
                    game
                        |> withCmd Cmd.none

        ClickedUndo ->
            case game.stage of
                StageSelectC2 ->
                    game
                        |> applyMove BackToSelectC1
                        |> withCmd Cmd.none
                StageRotate ->
                    game
                        |> applyMove BackToSelectC2
                        |> withCmd Cmd.none
                _ ->    
                    game
                        |> withCmd Cmd.none

        ClickedRotate c1 c2 offset ->
            case game.settings.playMode of
                PlaySolo ->
                    game
                        |> applyMove (Rotate c1 c2 offset)
                        |> withCmd Cmd.none
                PlayHumanVsHuman ->
                    game
                        |> applyMove (Rotate c1 c2 offset)
                        |> withCmd Cmd.none
                _ ->
                    game
                        |> applyMove (Rotate c1 c2 offset)
                        |> withCmd (Task.perform (\_ -> PauseThenMakeBotMove) (Process.sleep 1000))

        -- This interface message is generated by the computer player when it's time to make a move.
        PauseThenMakeBotMove ->
            if game.status == Playing then
                case game.settings.botDifficulty of
                    Easy ->
                        game |> withCmd (makeBotMoveEasy game)

                    Hard ->
                        game |> withCmd (makeBotMoveHard game)
            else
                game |> withCmd Cmd.none

        ReceivedBotMove move ->
            applyMove move game
                |> withCmd Cmd.none

        NoOp ->
            game
                |> withCmd Cmd.none


--------------------------------------------------------------------------------
-- GAME VIEW FUNCTION
--------------------------------------------------------------------------------

-- {-| The main view function that gets called from the Main application.

-- Essentially, takes a game and projects it into a HTML interface where Messages
-- can be sent from.

-- -}
view : Game -> Html Msg
view game =
    div [ id "game-screen-container" ]
        [ div [ id "game-header" ] [ viewStatus game ]
        , div [ id "game-main" ] [ viewTower game ]
        , div [ id "game-buttons" ] [ viewButtons game ]
        ]

{-| View game status at the top
-}
viewStatus : Game -> Html Msg
viewStatus game =
    let
        ( statusClass, statusText, playerClass ) =
            case game.status of
                Playing ->
                    case game.settings.playMode of 
                        PlaySolo ->
                            ( "status-playing", "", "")
                        PlayHumanVsHuman ->
                            case game.turn of
                                Player1 ->
                                    ( "status-playing", currentName game ++ "'s turn.", "player1" )

                                Player2 ->
                                    ( "status-playing", currentName game ++ "'s turn.", "player2" )
                            
                        PlayBotVsHuman ->
                            case game.turn of
                                Player1 ->
                                    ( "status-thinking", "Bot is thinking...", "player1" )

                                Player2 ->
                                    ( "status-playing", "Your turn.", "player2" )

                        PlayHumanVsBot ->
                            case game.turn of
                                Player1 ->
                                    ( "status-playing", "Your turn.", "player1" )

                                Player2 ->
                                    ( "status-thinking", "Bot is thinking...", "player2" )
                
                Complete Player1 ->
                    case game.settings.playMode of
                        PlaySolo ->
                            ( "status-won", "You solved the tower in " ++ String.fromInt game.moveCount ++ " moves!", "" )

                        PlayHumanVsHuman ->
                            ( "status-won", game.settings.player1Name ++ " Wins!", "player1" )
                        
                        PlayBotVsHuman ->
                            ( "status-lost", "You lost...", "player1" )

                        PlayHumanVsBot ->
                            ( "status-won", "You win!", "player1" )
                        
                Complete Player2 ->
                    case game.settings.playMode of
                        PlaySolo ->
                            ( "status-won", "You solved the tower in " ++ String.fromInt game.moveCount ++ " moves!", "" )
                        PlayHumanVsHuman ->
                            ( "status-won", game.settings.player2Name ++ " Wins!", "player2" )
                        PlayBotVsHuman ->
                            ( "status-won", "You win!", "player2" )
                        PlayHumanVsBot ->
                            ( "status-lost", "You lost...", "player2" )

        moveText = 
            case game.settings.playMode of
                PlaySolo ->
                    case game.status of
                        Playing ->
                            "Move #" ++ String.fromInt (game.moveCount + 1)
                        Complete _ ->
                            ""
                _ ->
                    case game.status of
                        Playing ->
                            case game.turn of
                                Player1 ->
                                    "Move " ++ String.fromInt (game.p1MoveCount + 1) ++ " of " ++ String.fromInt game.settings.moveLimit
                                Player2 ->
                                    "Move " ++ String.fromInt (game.p2MoveCount + 1) ++ " of " ++ String.fromInt game.settings.moveLimit
                        Complete _ ->
                             ""
    
        showStatContainer = 
            if game.settings.playMode == PlaySolo then
                "hide"
            else
                "show"

        player1Name = 
            case game.settings.playMode of
                PlaySolo ->
                    "You"
                PlayHumanVsHuman ->
                    game.settings.player1Name
                PlayBotVsHuman ->
                    "Bot"
                PlayHumanVsBot ->
                    "You"

        player2Name = 
            case game.settings.playMode of
                PlaySolo ->
                    "You"
                PlayHumanVsHuman ->
                    game.settings.player2Name
                PlayBotVsHuman ->
                    "You"
                PlayHumanVsBot ->
                    "Bot"
        
        player1Score =
            if game.p1Score == game.settings.towerSize then
                "∞"
            else
                String.fromInt game.p1Score

        player2Score =
            if game.p2Score == game.settings.towerSize then
                "∞"
            else
                String.fromInt game.p2Score
                        
    in
    div [ id "game-status", class statusClass ]
        [ div [ class ("game-status-text " ++ playerClass) ] [ text statusText ]
        , div [class ("game-move-counter")] [ text moveText]
        , div [ class ("game-stat-container " ++ showStatContainer)] [
            div [class "game-stat-block player1"]
            [ div [ class "game-stat-title" ] [ text player1Name ]
            , div [ class "game-stat-value" ] [ text player1Score ]
            ]
        , div [class "game-stat-block player2"]
            [ div [ class "game-stat-title" ] [ text player2Name ]
            , div [ class "game-stat-value" ] [ text player2Score ]
            ]
        ]
        , div [ class "firework-container", classList [ ( "show", statusClass == "status-won" ) ] ]
            [ div [ class "firework" ] []
            , div [ class "firework" ] []
            , div [ class "firework" ] []
            ]
        , div
            [ class "flash"
            , class statusClass
            , classList [ ( "show", statusClass == "status-won" || statusClass == "status-lost" || statusClass == "status-draw" ) ]
            ]
            []
        ]

{-| View the actual tower
-}
viewTower: Game -> Html Msg
viewTower game =
    let
        towerSize = 
            game.settings.towerSize

        playMode =
            case game.settings.playMode of
                PlaySolo ->
                    "solo"
                _ ->
                    "multi"

         -- Convert a single block/cube to HTML
        blockView index block =
            let
                onClickEvent =
                    if game.status == Playing then
                        case game.settings.playMode of
                            PlaySolo ->
                                case game.stage of
                                    StageSelectC1 ->
                                        ClickedBlock index
                                    StageSelectC2 ->
                                        if index > game.c1 then
                                            ClickedBlock index
                                        else
                                            NoOp
                                    StageRotate ->
                                        NoOp
                            
                            PlayHumanVsHuman ->
                                case game.stage of
                                    StageSelectC1 ->
                                        if block.touched == False then
                                            ClickedBlock index
                                        else
                                            NoOp
                                    StageSelectC2 ->
                                        if index > game.c1 then
                                            ClickedBlock index
                                        else
                                            NoOp
                                    StageRotate ->
                                        NoOp
                            
                            PlayBotVsHuman ->
                                case game.stage of
                                    StageSelectC1 ->
                                        if block.touched == False && game.turn == Player2 then
                                            ClickedBlock index
                                        else
                                            NoOp
                                    StageSelectC2 ->
                                        if index > game.c1 then
                                            ClickedBlock index
                                        else
                                            NoOp
                                    StageRotate ->
                                        NoOp

                            PlayHumanVsBot ->
                                case game.stage of
                                    StageSelectC1 ->
                                        if block.touched == False && game.turn == Player1 then
                                            ClickedBlock index
                                        else
                                            NoOp
                                    StageSelectC2 ->
                                        if index > game.c1 then
                                            ClickedBlock index
                                        else
                                            NoOp
                                    StageRotate ->
                                        NoOp
                    else
                        NoOp
                
                blockSelect =
                    case game.stage of
                        StageSelectC2 ->
                            if index == game.c1 then
                                "selected"
                            else
                                "not-selected"
                        StageRotate ->
                            if index >= game.c1 && index < game.c2 then
                                "selected"
                            else
                                "not-selected"
                        _ ->
                            "not-selected"

                blockTouched =
                    case game.settings.playMode of
                        PlaySolo ->
                            ""
                        _ ->
                            if block.touched == True then
                                "touched"
                            else
                                "not-touched"

                rotateDegrees = 
                    320 - block.rotation * 90
            in
            div
            [ class "block-container"] [
                div [ class ("cube-indicator " ++ playMode)] 
                [ img [ class ("cube-indicator-image " ++ blockTouched)] []
                ],
                div [ class "cube-container"
                , onClick onClickEvent
                , style "z-index" (String.fromInt index)
                ]
                [ div [ class ("cube"), 
                        style "transform" ("rotateX(-15deg) rotateY(" ++ String.fromInt rotateDegrees ++ "deg)"), 
                        class blockSelect ]
                    [
                        div [ class ("cube-side " ++ blockSelect)] [ div [class "cube-side-text"] [text "0"] ],
                        div [ class ("cube-side " ++ blockSelect)] [ div [class "cube-side-text"] [text "1"] ],
                        div [ class ("cube-side " ++ blockSelect)] [ div [class "cube-side-text"] [text "2"] ],
                        div [ class ("cube-side " ++ blockSelect)] [ div [class "cube-side-text"] [text "3"] ],
                        div [ class ("cube-side " ++ blockSelect)] [ ],
                        div [ class ("cube-side " ++ blockSelect)] [ ]
                    ]
                ]
            ]
                
    in
    div
        [ id "game-tower-container"
        ]
        [ div
            [ id "game-tower"
            , Html.Attributes.style "grid-template-column" ("repeat(" ++ String.fromInt towerSize ++ ", 1fr)")
            ]
            (List.indexedMap blockView (Array.toList game.tower)
                |> List.reverse)
        ]

{-| View rotate and undo buttons
-}
viewButtons: Game -> Html Msg
viewButtons game =
    let rotateView index =
            let
                onClickEvent =
                    if game.status == Playing then
                        case game.stage of
                            StageRotate ->
                                ClickedRotate game.c1 game.c2 index
                            StageSelectC2 ->
                                ClickedRotate game.c1 (game.c1 + 1) index
                            _ ->
                                NoOp
                    else
                        NoOp
            in
            button
                [ class ("game-button " ++ complete)
                , class "game-button-rotate"
                , onClick onClickEvent
                ]
                [ text ("↻ " ++ String.fromInt index) ]

        undoEvent = 
            if game.status == Playing then
                case game.stage of
                    StageSelectC2 ->
                        ClickedUndo
                    StageRotate ->
                        ClickedUndo
                    _ ->
                        NoOp
            else
                NoOp

        complete =
            case game.status of
                Complete _ ->
                    "complete"
                _ ->
                    "incomplete"

        rotateValues = 
            case game.settings.playMode of
                PlaySolo ->
                    [1, 2, 3]
                _ ->
                    [1, 2, 3, 0]
    in
    div
        [ id "game-rotate-container"
        ]
        ((List.map rotateView rotateValues) ++ [button
            [ class "game-button", class complete
            , id "game-button-undo"
            , onClick undoEvent
            ]
            [ text "Undo" ]])
        

--------------------------------------------------------------------------------
-- COMPUTER: EASY PLAYER
--------------------------------------------------------------------------------


{-| Logic for an "easy" computer player.

Chooses two random blocks c1, c2 and finds the rotation that minimizes the bot's score
-}
makeBotMoveEasy : Game -> Cmd Msg
makeBotMoveEasy game =
    let
        -- all blocks that haven't been touched
        validBlocks =
            game.tower
                |> Array.indexedMap (\index block -> ( index, block ))
                |> Array.filter (\( _, block) -> block.touched == False)

        -- for some block c1, generate all (c1, c2) combinations, include offset that minimizes score
        c1Options (index, block) =
            let
                -- all possible c2 values for c1
                c2Values = range (index + 1) (game.settings.towerSize)

                -- find tidiness if (c1, c2) was rotated by offset
                getScore c2 offset =
                    rotateSegment index c2 offset game.tower
                        |> getTidiness

                -- from a list of (c2, offset) pairs, choose the one that minimizes tidiness
                -- maps it to an object with c1, c2, offset, score
                bestChoice list = 
                    List.map (\(c2, offset) -> {c1 = index, c2 = c2, offset = offset, score = getScore c2 offset}) list
                        |> List.sortBy (\{ score, offset } -> score * 1000 - offset) -- higher offset is better
                        |> List.take 1
                
            in
            List.map (\c2 -> [(c2, 0), (c2, 1), (c2, 2), (c2, 3)]) c2Values
                |> List.map bestChoice
                |> List.concat
            
    in
    List.map c1Options (Array.toList validBlocks)
        |> List.concat
        |> List.map (\{ c1, c2, offset } -> (c1, c2, offset))
        |> Random.List.choose
        |> Random.map 
            (\tuple -> 
                tuple
                    |> first
                    |> Maybe.withDefault ( 0, 0, 0 ) 
                    |> (\(c1, c2, offset) -> Rotate c1 c2 offset)
            )
        |> Random.generate ReceivedBotMove

--------------------------------------------------------------------------------
-- COMPUTER: HARD PLAYER
--------------------------------------------------------------------------------


{-| Logic for a "hard" computer player.

Try every possible c1, c2, offset combination and choose the one that minimizes score.
-}
makeBotMoveHard : Game -> Cmd Msg
makeBotMoveHard game =
    let

        -- all blocks that haven't been touched
        validBlocks =
            game.tower
                |> Array.indexedMap (\index block -> ( index, block ))
                |> Array.filter (\( _, block) -> block.touched == False)

        -- for some block c1, generate all (c1, c2, offset) combinations
        c1Options (index, block) =
            let
                
                -- all possible c2 values for c1
                c2s = range (index + 1) (game.settings.towerSize)

                -- find tidiness if (c1, c2) was rotated by offset
                getScore c2 offset =
                    rotateSegment index c2 offset game.tower
                        |> getTidiness

                -- all offset combinations for some c2
                c2sOffsets = List.map (\c2 -> (c2, 0)) c2s ++ List.map (\c2 -> (c2, 1)) c2s ++ List.map (\c2 -> (c2, 2)) c2s ++ List.map (\c2 -> (c2, 3)) c2s
            in
            List.map (\(c2, offset) -> {c1 = index, c2 = c2, offset = offset, score = getScore c2 offset}) c2sOffsets
            

    in
    List.map c1Options (Array.toList validBlocks)
        |> List.concat
        |> List.sortBy (\{ score } -> score)
        |> List.take 1
        |> List.map (\{ c1, c2, offset } -> (c1, c2, offset))
        |> Random.List.choose
        |> Random.map 
            (\tuple -> 
                tuple
                    |> first
                    |> Maybe.withDefault ( 0, 0, 0 ) 
                    |> (\(c1, c2, offset) -> Rotate c1 c2 offset)
            )
        |> Random.generate ReceivedBotMove

--------------------------------------------------------------------------------
-- GAME HELPER FUNCTIONS
-- Helper functions to implement the game logic.
--------------------------------------------------------------------------------


{-| Returns the name of the current player
-}
currentName : Game -> String
currentName game =
    case game.turn of
        Player1 ->
            game.settings.player1Name

        Player2 ->
            game.settings.player2Name
