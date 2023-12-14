module Settings exposing (..)

{-| This module handles everything on the Settings screen.
-}

import Common exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)



--------------------------------------------------------------------------------
-- SETTING DEFINITIONS
--------------------------------------------------------------------------------


{-| STEP 1: Define the data model for your settings and their types.
-}
type alias Settings =
    { playMode : PlayMode
    , randomSeed: Int
    , towerSize: Int
    , moveLimit : Int
    , botDifficulty : BotDifficulty
    , player1Name : String
    , player2Name : String
    }


{-| STEP 2: Define the default values for your settings.
-}
default : Settings
default =
    { playMode = PlaySolo
    , randomSeed = 0
    , towerSize = 8
    , moveLimit = 3
    , botDifficulty = Easy
    , player1Name = "Alice"
    , player2Name = "Bob"
    }


{-| STEP 3: Add a message type to update your settings.
-}
type Msg
    = SetPlayMode PlayMode
    | SetRandomSeed Int
    | SetTowerSize Int
    | SetMoveCount Int
    | SetBotDifficulty BotDifficulty
    | SetPlayerName Player String
    

{-| STEP 4: Define explicitly what happens to your settings when a message is received.
-}
update : Msg -> Settings -> Settings
update msg settings =
    case msg of
        SetPlayMode playMode ->
            { settings | playMode = playMode }

        SetRandomSeed value -> 
            { settings | randomSeed = value }

        SetTowerSize size ->
            { settings | towerSize = size }

        SetMoveCount size ->
            { settings | moveLimit = size }
        
        SetBotDifficulty difficulty ->
            { settings | botDifficulty = difficulty }

        SetPlayerName player name ->
            case player of
                Player1 ->
                    { settings | player1Name = name }

                Player2 ->
                    { settings | player2Name = name }


{-| STEP 5: Define a list of pickers for each setting you want to be able to change.
-}
pickers : Settings -> List SettingPickerItem
pickers settings =
    let 
        commonSettings = 
            [ pickChoiceDropdown
                { label = "Play Mode"
                , onSelect = SetPlayMode
                , toString = playModeToString
                , fromString = stringToPlayMode
                , current = settings.playMode
                , options = [ ("Solo", PlaySolo), ( "Human vs Human", PlayHumanVsHuman )
                    ,( "Human vs Bot", PlayHumanVsBot ), ( "Bot vs Human", PlayBotVsHuman ) 
                ]
                }
            , inputInt
                { label = "Random Seed for Tower Generation"
                , value = settings.randomSeed
                , min = 0
                , max = 9999999
                , onChange = SetRandomSeed
                }
            , inputIntRange
                { label = "Tower Size"
                , value = settings.towerSize
                , min = 4
                , max = 12
                , onChange = SetTowerSize
                }
            ]
        
        pvpSettings = 
            [ inputIntRange
                { label = "Moves Per Player"
                , value = settings.moveLimit
                , min = 2
                , max = settings.towerSize // 2
                , onChange = SetMoveCount
                }
            ]

    in
    case settings.playMode of
        PlaySolo ->
            commonSettings
        PlayHumanVsHuman ->
            commonSettings ++ pvpSettings
            ++ 
            [ inputString
                { label = "Player 1 Name"
                , value = settings.player1Name
                , onChange = SetPlayerName Player1
                }
            , inputString
                { label = "Player 2 Name"
                , value = settings.player2Name
                , onChange = SetPlayerName Player2
                }  
            ]
        _ ->
            commonSettings ++ pvpSettings
            ++
            [ pickChoiceButtons
                { label = "Bot Difficulty"
                , onSelect = SetBotDifficulty
                , current = settings.botDifficulty
                , options = [ ( "Easy", Easy ), ( "Hard", Hard ) ]
                }   
            ]

--------------------------------------------------------------------------------
-- SUPPORTING TYPES
--------------------------------------------------------------------------------

{-| Play mode (i.e. solo, human vs human, me vs AI or AI vs me) for the game.
-}
type PlayMode
    = PlaySolo
    | PlayHumanVsHuman
    | PlayHumanVsBot
    | PlayBotVsHuman

{-| Basic function to convert a PlayMode to a String (for the option selector).
-}
playModeToString : PlayMode -> String
playModeToString playMode =
    case playMode of
        PlaySolo ->
            "Solo"

        PlayHumanVsHuman ->
            "Human vs Human"

        PlayHumanVsBot ->
            "Human vs Bot"

        PlayBotVsHuman ->
            "Bot vs Human"

{-| Basic function to convert a String to a PlayMode, with a default.
-}
stringToPlayMode : String -> PlayMode
stringToPlayMode string =
    case string of
        "Solo" ->
            PlaySolo

        "Human vs Human" ->
            PlayHumanVsHuman

        "Human vs Bot" ->
            PlayHumanVsBot

        "Bot vs Human" ->
            PlayBotVsHuman

        _ ->
            PlaySolo

{-| Difficulty of the computer (if playing against a computer).
-}
type BotDifficulty
    = Easy
    | Hard


--------------------------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------------------------
-- Helper functions to create Setting picker item types.

-- INPUT STRING


type alias InputStringConfig =
    { label : String
    , value : String
    , onChange : String -> Msg
    }


{-| A basic text box that allows the user to input a string.
-}
inputString : InputStringConfig -> SettingPickerItem
inputString data =
    InputString data



-- INPUT FLOAT


type alias InputFloatConfig =
    { label : String
    , value : Float
    , min : Float
    , max : Float
    , onChange : Float -> Msg
    }


{-| A basic box that allows the user to input a float.
-}
inputFloat : InputFloatConfig -> SettingPickerItem
inputFloat data =
    InputFloat data



-- INPUT INT


type alias InputIntConfig =
    { label : String
    , value : Int
    , min : Int
    , max : Int
    , onChange : Int -> Msg
    }


{-| A basic box that allows the user to input an int.
-}
inputInt : InputIntConfig -> SettingPickerItem
inputInt data =
    InputInt data



-- INPUT FLOAT RANGE


type alias InputFloatRangeConfig =
    { label : String
    , value : Float
    , step : Float
    , min : Float
    , max : Float
    , onChange : Float -> Msg
    }


{-| A range slider that allows the user to input a float.
-}
inputFloatRange : InputFloatRangeConfig -> SettingPickerItem
inputFloatRange data =
    InputFloatRange data



-- INPUT INT RANGE


type alias InputIntRangeConfig =
    { label : String
    , value : Int
    , min : Int
    , max : Int
    , onChange : Int -> Msg
    }


{-| A range slider that allows the user to input an int.
-}
inputIntRange : InputIntRangeConfig -> SettingPickerItem
inputIntRange data =
    InputIntRange data



-- PICK CHOICE BUTTONS


type alias PickChoiceButtonsGenericConfig enum =
    { label : String
    , onSelect : enum -> Msg
    , current : enum
    , options : List ( String, enum )
    }


{-| A set of buttons that allows the user to pick from a list of options.
-}
pickChoiceButtons : PickChoiceButtonsGenericConfig enum -> SettingPickerItem
pickChoiceButtons { label, onSelect, current, options } =
    PickChoiceButtons
        { label = label
        , options = List.map (\( optionLabel, value ) -> { label = optionLabel, onSelect = onSelect value, isSelected = value == current }) options
        }



-- PICK CHOICE DROPDOWN


type alias PickChoiceDropdownGenericConfig enum =
    { label : String
    , onSelect : enum -> Msg
    , toString : enum -> String
    , fromString : String -> enum
    , current : enum
    , options : List ( String, enum )
    }


{-| A dropdown that allows the user to pick from a list of options.
-}
pickChoiceDropdown : PickChoiceDropdownGenericConfig enum -> SettingPickerItem
pickChoiceDropdown { label, onSelect, toString, fromString, current, options } =
    PickChoiceDropdown
        { label = label
        , onSelect = fromString >> onSelect
        , options = List.map (\( optionLabel, value ) -> { label = optionLabel, value = toString value, isSelected = value == current }) options
        }



--------------------------------------------------------------------------------
-- PICKER TYPES
--------------------------------------------------------------------------------


{-| A type of a single item in a setting picker

Note: these are NOT constructed directly. Instead, there are specific helper
functions to construct each of these. The reason is because Elm's type
system is a bit limited, and we want to be able to have different types of Enums
stored as items - so my compromise is to use more generic helper functions to convert it
into these types instead.

-}
type SettingPickerItem
    = InputString InputStringConfig
    | InputFloat InputFloatConfig
    | InputInt InputIntConfig
    | InputFloatRange InputFloatRangeConfig
    | InputIntRange InputIntRangeConfig
    | PickChoiceButtons PickChoiceButtonsConfig
    | PickChoiceDropdown PickChoiceDropdownConfig


type alias PickChoiceOptionButton =
    { label : String
    , onSelect : Msg
    , isSelected : Bool
    }


type alias PickChoiceButtonsConfig =
    { label : String
    , options : List PickChoiceOptionButton
    }


type alias PickChoiceDropdownOption =
    { label : String
    , value : String
    , isSelected : Bool
    }


type alias PickChoiceDropdownConfig =
    { label : String
    , onSelect : String -> Msg
    , options : List PickChoiceDropdownOption
    }



--------------------------------------------------------------------------------
-- VIEW FUNCTIONS
--------------------------------------------------------------------------------


{-| The view function for a single setting picker item.

Renders each item based on its type. You also have access to the
current settings in this function (as Settings) so can use that
information to make decisions on what to render as well.

-}
viewPickerItem : Settings -> SettingPickerItem -> Html Msg
viewPickerItem settings item =
    case item of
        InputString data ->
            div [ class "setting-picker-item" ]
                [ label [ class "setting-picker-item-label" ] [ text data.label ]
                , input [ class "setting-picker-item-input setting-picker-item-input-string", type_ "text", value data.value, onInput data.onChange ] []
                ]

        InputFloat data ->
            div [ class "setting-picker-item" ]
                [ label [ class "setting-picker-item-label" ] [ text data.label ]
                , input
                    [ class "setting-picker-item-input setting-picker-item-input-float"
                    , type_ "number"
                    , value (String.fromFloat data.value)
                    , Html.Attributes.min (String.fromFloat data.min)
                    , Html.Attributes.max (String.fromFloat data.max)
                    , onInput (String.toFloat >> Maybe.withDefault 0.0 >> data.onChange)
                    ]
                    []
                ]

        InputInt data ->
            div [ class "setting-picker-item" ]
                [ label [ class "setting-picker-item-label" ] [ text data.label ]
                , input
                    [ class "setting-picker-item-input setting-picker-item-input-int"
                    , type_ "number"
                    , value (String.fromInt data.value)
                    , Html.Attributes.min (String.fromInt data.min)
                    , Html.Attributes.max (String.fromInt data.max)
                    , onInput (String.toInt >> Maybe.withDefault 0 >> data.onChange)
                    ]
                    []
                ]

        InputFloatRange data ->
            div [ class "setting-picker-item" ]
                [ label [ class "setting-picker-item-label" ] [ text data.label ]
                , div [ class "setting-picker-item-input-container" ]
                    [ input
                        [ class "setting-picker-item-input setting-picker-item-input-float-range"
                        , type_ "range"
                        , value (String.fromFloat data.value)
                        , Html.Attributes.min (String.fromFloat data.min)
                        , Html.Attributes.max (String.fromFloat data.max)
                        , step (String.fromFloat data.step)
                        , onInput (String.toFloat >> Maybe.withDefault 0.0 >> data.onChange)
                        ]
                        []
                    , div [ class "setting-picker-item-input-value" ] [ text (String.fromFloat data.value) ]
                    ]
                ]

        InputIntRange data ->
            div [ class "setting-picker-item" ]
                [ label [ class "setting-picker-item-label" ] [ text data.label ]
                , div [ class "setting-picker-item-input-container" ]
                    [ input
                        [ class "setting-picker-item-input setting-picker-item-input-int-range"
                        , type_ "range"
                        , value (String.fromInt data.value)
                        , Html.Attributes.min (String.fromInt data.min)
                        , Html.Attributes.max (String.fromInt data.max)
                        , onInput (String.toInt >> Maybe.withDefault 0 >> data.onChange)
                        ]
                        []
                    , div [ class "setting-picker-item-input-value" ] [ text (String.fromInt data.value) ]
                    ]
                ]

        PickChoiceButtons data ->
            div [ class "setting-picker-item" ]
                [ label [ class "setting-picker-item-label" ] [ text data.label ]
                , div [ class "setting-picker-item-input setting-picker-item-input-buttons" ]
                    (List.map
                        (\{ label, onSelect, isSelected } ->
                            button
                                [ class ("setting-picker-item-button setting-picker-item-button-" ++ String.replace " " "-" label)
                                , classList [ ( "selected", isSelected ) ]
                                , onClick onSelect
                                ]
                                [ text label ]
                        )
                        data.options
                    )
                ]

        PickChoiceDropdown data ->
            div [ class "setting-picker-item" ]
                [ label [ class "setting-picker-item-label" ] [ text data.label ]
                , select [ class "setting-picker-item-input setting-picker-item-input-select", onInput data.onSelect ]
                    (List.map
                        (\optionData ->
                            option [ value optionData.value, selected optionData.isSelected ] [ text optionData.label ]
                        )
                        data.options
                    )
                ]


{-| View just the picker part of the settings
-}
viewPicker : Settings -> List SettingPickerItem -> Html Msg
viewPicker settings items =
    div [ id "settings-picker" ]
        (List.map (viewPickerItem settings) items)


{-| The function that views all settings which gets called from the Main application.
-}
view : Settings -> Html Msg
view settings =
    div [ id "settings" ]
        [ viewPicker settings (pickers settings)
        ]
