module Calendar exposing (..)

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Date exposing (Date)
import Date.Extra
import DefaultStyles exposing (..)


type alias State =
    { timespan : String
    , viewing : Date
    }


init : String -> Date -> State
init timespan viewing =
    { timespan = timespan
    , viewing = viewing
    }


type TimeSpan
    = Month
    | Week
    | Day
    | Agenda


toTimeSpan : String -> TimeSpan
toTimeSpan timespan =
    case timespan of
        "Month" ->
            Month

        "Week" ->
            Week

        "Day" ->
            Day

        "Agenda" ->
            Agenda

        _ ->
            Month


fromTimeSpan : TimeSpan -> String
fromTimeSpan timespan =
    case timespan of
        Month ->
            "Month"

        Week ->
            "Week"

        Day ->
            "Day"

        Agenda ->
            "Agenda"


type Msg
    = PageBack
    | PageForward
    | ChangeTimeSpan TimeSpan


update msg state =
    case msg of
        PageBack ->
            state
                |> page -1

        PageForward ->
            state
                |> page 1

        ChangeTimeSpan timespan ->
            state
                |> changeTimespan timespan


page : Int -> State -> State
page step state =
    let
        { timespan, viewing } =
            state

        timespanType =
            toTimeSpan timespan
    in
        case timespanType of
            Month ->
                { state | viewing = Date.Extra.add Date.Extra.Month step viewing }

            _ ->
                state


changeTimespan timespan state =
    { state | timespan = fromTimeSpan timespan }


view : State -> Html Msg
view state =
    let
        calendarView =
            case toTimeSpan state.timespan of
                Month ->
                    viewMonth state

                Week ->
                    viewWeek state (dayRangeOfWeek state.viewing)

                _ ->
                    viewMonth state
    in
        div [ styleCalendar ]
            [ viewToolbar state
            , calendarView
            ]


dayRangeOfWeek date =
    let
        weekdayNumber =
            Date.Extra.weekdayNumber date

        begOfWeek =
            Date.Extra.add Date.Extra.Day (-1 * weekdayNumber) date

        endOfWeek =
            Date.Extra.add Date.Extra.Day (7 - weekdayNumber) date
    in
        Date.Extra.range Date.Extra.Day 1 begOfWeek endOfWeek


viewToolbar state =
    div [ styleToolbar ]
        [ viewPagination state
        , viewTitle state
        , viewTimespanSelection state
        ]


viewTitle { viewing } =
    let
        month =
            toString <| Date.month viewing

        year =
            toString <| Date.year viewing

        title =
            month ++ " " ++ year
    in
        div []
            [ h2 [] [ text title ] ]


viewPagination state =
    div []
        [ button [ styleButton, onClick PageBack ] [ text "back" ]
        , button [ styleButton, onClick PageForward ] [ text "next" ]
        ]


viewTimespanSelection state =
    div []
        [ button [ styleButton, onClick (ChangeTimeSpan Month) ] [ text "Month" ]
        , button [ styleButton, onClick (ChangeTimeSpan Week) ] [ text "Week" ]
        , button [ styleButton, onClick (ChangeTimeSpan Day) ] [ text "Day" ]
        , button [ styleButton, onClick (ChangeTimeSpan Agenda) ] [ text "Agenda" ]
        ]


getMonthRange : Date -> List (List Date)
getMonthRange date =
    let
        curMonth =
            Date.month date

        begMonth =
            Date.Extra.floor Date.Extra.Month date

        endMonth =
            Date.Extra.ceiling Date.Extra.Month date

        begOfMonthWeekdayNum =
            Date.Extra.weekdayNumber begMonth

        monthRange =
            Date.Extra.range Date.Extra.Day 1 begMonth endMonth

        previousMonthFirstDate =
            Date.Extra.add Date.Extra.Day (-1 * begOfMonthWeekdayNum) begMonth

        previousMonthRange =
            Date.Extra.range Date.Extra.Day 1 previousMonthFirstDate begMonth

        endOfMonthWeekdayNum =
            Date.Extra.weekdayNumber endMonth

        nextMonthLastDate =
            Date.Extra.add Date.Extra.Day (7 - endOfMonthWeekdayNum) endMonth

        nextMonthRange =
            Date.Extra.range Date.Extra.Day 1 endMonth nextMonthLastDate

        fullRange =
            List.concat [ previousMonthRange, monthRange, nextMonthRange ]
    in
        [ List.take 7 fullRange
        , List.drop 7 <| List.take 14 fullRange
        , List.drop 14 <| List.take 21 fullRange
        , List.drop 21 <| List.take 28 fullRange
        , List.drop 28 <| List.take 35 fullRange
        ]
            ++ if List.length fullRange > 35 then
                [ List.drop 35 <| List.take 42 fullRange ]
               else
                []


viewMonth : State -> Html Msg
viewMonth state =
    let
        weeks =
            getMonthRange state.viewing

        styleWeek =
            style
                [ ( "display", "flex" )
                ]

        viewWeek week =
            div [ styleWeek ]
                (List.map (viewCell state) week)
    in
        div [ styleMonth ]
            (List.map viewWeek weeks)


viewCell : State -> Date -> Html Msg
viewCell state date =
    div [ styleCell ]
        [ text <| toString <| Date.day date ]


intToHourString : Int -> String
intToHourString int =
    let
        ending =
            if int < 12 then
                ":00 AM"
            else
                ":00 PM"

        hour =
            if int == 0 || int == 12 then
                "12"
            else if int < 12 then
                toString int
            else
                toString <| int - 12
    in
        hour ++ ending


viewWeek state days =
    div [ styleWeek ]
        [ viewWeekHeader days
        , viewWeekContent days
        ]


viewWeekHeader days =
    div [ styleWeekHeader ]
        [ viewDates days
        , viewAllDayCell days
        ]


viewDates days =
    let
        viewTimeGutterHeader =
            div [ style [ ( "width", "70px" ) ] ] []

        title day =
            (toString <| Date.dayOfWeek day) ++ (toString <| Date.day day) ++ "/" ++ (toString <| Date.Extra.monthNumber day)

        viewDate day =
            div [ styleDateHeader ]
                [ a [ styleDate, href "#" ] [ text <| title day ] ]
    in
        div [ styleDates ]
            (viewTimeGutterHeader :: List.map viewDate days)


viewAllDayCell days =
    let
        viewAllDayText =
            div [ style [ ( "width", "70px" ) ] ] [ text "All day" ]

        viewAllDay day =
            div [ styleAllDay ]
                []
    in
        div [ styleAllDayCell ]
            (viewAllDayText :: List.map viewAllDay days)


viewWeekContent days =
    let
        styleDay =
            style
                [ ( "display", "flex" )
                , ( "flex-direction", "column" )
                ]

        viewDay day =
            div [ styleDay ]
                [ viewDaySlot day
                ]

        hours =
            List.repeat 24 0
                |> List.indexedMap (\index _ -> intToHourString index)

        viewTimeGutter =
            hours
                |> List.map viewTimeSlotGroup
                |> div [ styleTimeGutter ]

        viewTimeSlotGroup hourString =
            div [ styleTimeSlotGroup ]
                [ viewTimeSlot <| hourString
                , div [ style [ ( "flex", "1 0 0" ) ] ] []
                ]

        viewTimeSlot hourString =
            div [ style [ ( "padding", "0 5px" ), ( "flex", "1 0 0" ) ] ]
                [ span [ style [ ( "font-size", "14px" ) ] ] [ text hourString ] ]

        viewDaySlot day =
            hours
                |> List.map viewDaySlotGroup
                |> div [ styleDaySlot ]

        viewDaySlotGroup hourString =
            div [ styleTimeSlotGroup ]
                [ div [ style [ ( "flex", "1 0 0" ) ] ] []
                , div [ style [ ( "flex", "1 0 0" ) ] ] []
                ]
    in
        div [ styleWeekContent ]
            ([ viewTimeGutter ] ++ (List.map viewDay days))