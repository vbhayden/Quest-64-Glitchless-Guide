
-- Maps for each boss
--
-- Beigis and Mammon share a map (Brannoch Castle),
-- so they will be differentiated by submap
--
MAP_SOLVARING = 31
MAP_ZELSE = 33
MAP_NEPTY = 35
MAP_SHILF = 28
MAP_FARGO = 29
MAP_GUILTY = 30
MAP_BEIGIS = 30
MAP_MAMMON = 34

HITS_GUILTY = 74
HITS_BEIGIS = 60

MAP_BRANNOCH_CASTLE = 30

SUBMAP_GUILTY = 10
SUBMAP_BEIGIS = 14

MapIDToBossHits = {
    [MAP_SOLVARING] = 67,
    [MAP_ZELSE] = 60,
    [MAP_NEPTY] = 56,
    [MAP_SHILF] = 56,
    [MAP_FARGO] = 62,
    [MAP_GUILTY] = 74,
    [MAP_BEIGIS] = 60,
    [MAP_MAMMON] = 160
}

LastMapID = -1
LastSubMapID = -1
BestExpected = 0
BestIntersections = 0

ShowAbout = true
ShowExplanation = true

GUI_CHAR_WIDTH = 10
GUI_PADDING_RIGHT = 240 + 80

-- Memory Locations
MEM_TIME_UNTIL_ACTION_16BE = 0x07C99A
MEM_BYTE_BATTLE_STATE = 0x8c593

MESSAGE_SHOW_DURATION_MS = 3500
MESSAGE_SUCCESS_COLOR_A = "cyan"
MESSAGE_SUCCESS_COLOR_B = "white"

-- UI Values
PreviousKeys = {}
KEY_TOGGLE_ABOUT = "A"
KEY_TOGGLE_DD_STEPS = "S"
KEY_TOGGLE_CONSTANT_FEEDBACK = "T"
KEY_TOGGLE_FEEDBACK = "D"
KEY_TOGGLE_EXTRA_DATA = "X"

-- Feedback Values
CurrentStreak = 0
MessageShownAt = 0
MostRecentEncounterFeedback = "Unknown"
MessageColor = "white"
MessageSuccessAlternate = false

LastCombatState = nil
RecentAccuracyTable = {}

local function PrintAvalanchePracticeHeader(index)

    GuiText(index + 1, "Avalanche Practice")
    GuiText(index + 2, "+-------------------------")
    GuiTextWithColor(index + 3, "| " .. KEY_TOGGLE_ABOUT .. " - " .. Ternary(ShowAbout, "Hide", "Show") .. " About", Ternary(ShowAbout, "white", "cyan"))
    GuiTextWithColor(index + 4, "| " .. KEY_TOGGLE_CONSTANT_FEEDBACK .. " - " .. Ternary(ShowConstantFeedback, "Hide", "Show") .. " Enc. Tracker", Ternary(ShowConstantFeedback, "white", "cyan"))
    GuiTextWithColor(index + 5, "| " .. KEY_TOGGLE_FEEDBACK .. " - " .. Ternary(ShowFeedback, "Hide", "Show") .. " Feedback", Ternary(ShowFeedback, "white", "cyan"))
    GuiTextWithColor(index + 6, "| " .. KEY_TOGGLE_EXTRA_DATA .. " - " .. Ternary(ShowExtraData, "Hide", "Show") .. " Extra Data", Ternary(ShowExtraData, "white", "cyan"))
    GuiText(index + 7, "+-------------------------")

    local lineIndex = 8

     return lineIndex;
end

local function ProcessControls()
    
    local keys = input.get()

    if keys[KEY_TOGGLE_ABOUT] == true and PreviousKeys[KEY_TOGGLE_ABOUT] ~= true then
        ShowAbout = not ShowAbout
    end

    if keys[KEY_TOGGLE_DD_STEPS] == true and PreviousKeys[KEY_TOGGLE_DD_STEPS] ~= true then
        ShowExplanation = not ShowExplanation
    end

    if keys[KEY_TOGGLE_FEEDBACK] == true and PreviousKeys[KEY_TOGGLE_FEEDBACK] ~= true then
        ShowFeedback = not ShowFeedback
    end

    if keys[KEY_TOGGLE_EXTRA_DATA] == true and PreviousKeys[KEY_TOGGLE_EXTRA_DATA] ~= true then
        ShowExtraData = not ShowExtraData
    end

    if keys[KEY_TOGGLE_CONSTANT_FEEDBACK] == true and PreviousKeys[KEY_TOGGLE_CONSTANT_FEEDBACK] ~= true then
        ShowConstantFeedback = not ShowConstantFeedback
    end
    
    PreviousKeys = input.get()
end

local function GetBattleState()
    local state = memory.readbyte(MEM_BYTE_BATTLE_STATE, "RDRAM")
    return {
        brianCanAct = state == 1,
        enemyCanAct = state == 3,
        betweenTurns = state == 7,
        battleActive = state > 0
    }
end

local function CanBrianAct()
    local state = GetBattleState()
    return state.brianCanAct
end

local function GetBossHits(mapID, subMapID)
    if mapID == MAP_BRANNOCH_CASTLE then
        if subMapID == SUBMAP_GUILTY then
            return HITS_GUILTY
        else
            return HITS_BEIGIS
        end
    else
        return MapIDToBossHits[mapID]
    end
end

local function Factorial(k)
	local result = 1;
    
    for i = 1, k do
	    result = result * i;
    end

	return result;
end

local function NChooseK(n, k)
    local numerator = Factorial(n)
    local demoninator = Factorial(n - k) * Factorial(k)

    return numerator / demoninator
end

local function Binomial(chance, successes, trials)
    
    local coefficient = NChooseK(trials, successes)
    return coefficient * (chance ^ successes) * (1 - chance) ^ (trials - successes)
end

local function Round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function Ternary ( cond , T , F )
    if cond then return T else return F end
end

local function GuiTextWithColor(row_index, text, color)
    
    local borderWidth = client.borderwidth();
    gui.text(borderWidth + 40, 200 + row_index * 15, text, color)
end

local function GuiText(row_index, text)
    GuiTextWithColor(row_index, text, "white")
end

local function GuiTextRightWithColor(row_index, text, color)
    
    local borderWidth = client.borderwidth();
    local screenWidth = client.screenwidth();
    local resolvedOffset = screenWidth - borderWidth - GUI_PADDING_RIGHT

    gui.text(resolvedOffset, 20 + row_index * 15, text, color)
end

local function GuiTextRight(row_index, text)
    GuiTextRightWithColor(row_index, text, "white")
end

local function GuiTextCenterWithColor(row_index, text, color)
    local length = string.len(text)
    local halfWidth = GUI_CHAR_WIDTH * length / 2

    local screenWidth = client.screenwidth();
    local resolvedCenter = screenWidth / 2 - halfWidth

    gui.text(resolvedCenter, 100 + row_index * 15, text, color)
end

local function GuiTextCenter(row_index, text, color)
    return GuiTextCenterWithColor(row_index, text, "white")
end

local function GetExpectedRockHits(overlaps)
    local TOTAL_POSSIBLE = 320
    local ROCK_COUNT = 10

    local percent = (1.0 * overlaps) / TOTAL_POSSIBLE
    local expected = ROCK_COUNT * percent

    return expected
end

local function RocksBrianToEnemy(BrianX1, BrianY1, EnemyX1, EnemyY1, Size1)

    local validRocks = 0
    local totalPossible = 0

    for i = 0, 15 do -- Angles
        for j = 20, 39 do -- Distances
            local x = BrianX1 + j * math.cos(i * 22.5 * math.pi / 180)
            local y = BrianY1 + j * math.sin(i * 22.5 * math.pi / 180)

            XDiff1 = x - EnemyX1
            YDiff1 = y - EnemyY1
            D1 = math.sqrt(XDiff1 * XDiff1 + YDiff1 * YDiff1)
            if D1 <= Size1 + 10 then
                validRocks = validRocks + 1
            end

            totalPossible = totalPossible + 1
        end
    end

    local hitChance = (1.0 * validRocks) / totalPossible

    return validRocks, hitChance, totalPossible
end

local function GetMapIDs()
    local mapID = memory.readbyte(0x8536B, "RDRAM")
    local subMapID = memory.readbyte(0x8536F, "RDRAM")

    return mapID, subMapID
end

local function CalculateBossSize()
    local sizeModifier = memory.readfloat(0x7C9E0, true, "RDRAM")
    local trueSize = memory.readfloat(0x7C9E4, true, "RDRAM")
    local size = sizeModifier * trueSize

    return Round(size, 3)
end

local function AddToRecentTable(accuracy)
    if #RecentAccuracyTable > 10 then
        table.remove(RecentAccuracyTable, 1)
    end

    table.insert(RecentAccuracyTable, #RecentAccuracyTable + 1, accuracy)
end

local function GetRecentAccuracyPercent()
    local recentAccuracy = 0
    local tableElements = #RecentAccuracyTable
    for _, accuracy in pairs(RecentAccuracyTable) do
        recentAccuracy = recentAccuracy + accuracy
    end

    if tableElements == 0 then
        return 0
    else
        return Round(recentAccuracy / tableElements, 0)
    end
end

local function GetRecentAccuracyColor(percent)
    if percent >= 90 then
        return "cyan"
    elseif percent >= 70 then
        return "white"
    elseif percent >= 50 then
        return "yellow"
    elseif percent >= 30 then
        return "orange"
    end
    
    return "red"
end

local function CalculateCurrentRocks()

    local brianX = memory.readfloat(0x7BACC, true, "RDRAM")
    local brianY = memory.readfloat(0x7BAD4, true, "RDRAM")

    local i = 1 -- Enemy number 1 (starting at 1)

    local EnemyX = memory.readfloat(0x7C9BC + 296 * (i - 1), true, "RDRAM")
    local EnemyY = memory.readfloat(0x7C9C4 + 296 * (i - 1), true, "RDRAM")
    
    local XDiff = brianX - EnemyX
    local YDiff = brianY - EnemyY
    
    local size = CalculateBossSize()
    local distance = math.sqrt(XDiff * XDiff + YDiff * YDiff)

    local validRocks, hitChance, total = RocksBrianToEnemy(brianX, brianY, EnemyX, EnemyY, size)
    local expected = GetExpectedRockHits(validRocks)
    
    local accuracy = 0
    if BestExpected > 0 then
        local comparedToBest = expected / BestExpected
        accuracy = Round(100 * comparedToBest, 0)
    end

    local rockData = {
        validRocks = validRocks,
        expected = expected,
        distance = distance,
        accuracy = accuracy,
        size = size,
        total = total
    }

    return rockData

    -- local accuracy = Ternary(comparedToBest ~= -1, Round(100 * comparedToBest, 0), 0)
    -- if (comparedToBest ~= -1) then
    --     comparedString = accuracy .. "% optimal"
    -- end

    -- local comparedToBest = -1
    -- if BestExpected > 0 then
    --     comparedToBest = expected / BestExpected
    -- end

    -- local color = "red"
    -- if (comparedToBest > 0.9) then
    --     color = "cyan"
    -- elseif (comparedToBest > 0.75) then
    --     color = "yellow"
    -- elseif (comparedToBest > 0.5) then
    --     color = "orange"
    -- elseif (comparedToBest == -1) then
    --     color = "gray"
    -- end

    -- local comparedString = "Unknown"
    -- local accuracy = Ternary(comparedToBest ~= -1, Round(100 * comparedToBest, 0), 0)
    -- if (comparedToBest ~= -1) then
    --     comparedString = accuracy .. "% optimal"
    -- end

    -- GuiText(row_index + 1, "Boss Size:  " .. size)
    -- GuiText(row_index + 2, "Boss Distance: " .. Round(distance, 3))

    -- -- GuiText(index + 4, "Live")
    -- GuiTextWithColor(row_index + 4, "Positioning: " .. comparedString, color)
    -- GuiText(row_index + 5, "Intersections:  " .. validRocks .. " of " .. total)
    -- GuiText(row_index + 6, "Expected Rocks: " .. expected)

    -- GuiText(index + 9, "Best")
    -- GuiText(index + 10, "Best Intersections:  " .. BestIntersections)
    -- GuiText(index + 11, "Best Expected Rocks: " .. BestExpected)
    
    -- local expectedHitsRounded = Round(expected, 0)
    -- local atLeastOne = 1 - (1 - hitChance) ^ 10

    -- if ShowExtraData then
    --     for hits = 0, 10 do
    --         local number = Ternary(hits < 10, " " .. hits, hits)
    --         local chance = Binomial(hitChance, hits, 10)
    --         local blocks = Round(chance * 100) / 4
    
    --         local line = string.rep(" ", 25 - blocks) .. string.rep("=", blocks) .. "|" .. number .. "  "
    
    --         GuiTextRight(row_index + 7 + hits, line)
    --     end
    -- end

    -- return expected
end

local function DrawFeedbackUI(rockData, row_index)
    local accuracy = rockData.accuracy
    local color = "red"
    if (accuracy > 0.9) then
        color = "cyan"
    elseif (accuracy > 0.75) then
        color = "yellow"
    elseif (accuracy > 0.5) then
        color = "orange"
    elseif (accuracy == -1) then
        color = "gray"
    end

    local comparedString = Ternary(accuracy == -1, "Unknown", accuracy .. "% optimal")
    
    -- if ShowConstantFeedback then
        GuiText(row_index + 0, "Live Feedback")
        GuiText(row_index + 1, "-----------------------")
        GuiText(row_index + 2, "Boss Size:  " .. rockData.size)
        GuiText(row_index + 3, "Boss Distance: " .. Round(rockData.distance, 3))

        GuiTextWithColor(row_index + 4, "Positioning: " .. comparedString, color)
        GuiText(row_index + 5, "Intersections:  " .. rockData.validRocks .. " of " .. rockData.total)
        GuiText(row_index + 6, "Expected Rocks: " .. rockData.expected)
    -- end

    -- local currentTime = os.time()
    -- local messageDelta = os.difftime(currentTime, MessageShownAt)
    -- if messageDelta * 1000 < MESSAGE_SHOW_DURATION_MS then

    --     local messageColor = MessageColor
    --     if CurrentStreak > 0 then
    --         messageColor = Ternary(MessageSuccessAlternate, MESSAGE_SUCCESS_COLOR_A, MESSAGE_SUCCESS_COLOR_B)
    --         MessageSuccessAlternate = not MessageSuccessAlternate
    --     end

    --     GuiTextCenterWithColor(index + 0, "Timing Feedback:", "white")
    --     GuiTextCenterWithColor(index + 1, "-----------------------", "white")
    --     GuiTextCenterWithColor(index + 2, MostRecentEncounterFeedback, messageColor)
    -- end

    -- local state = GetBattleState()
    -- if LastCombatState ~= nil then
    --     local turnEnded = state.betweenTurns and LastCombatState.brianCanAct
    --     if turnEnded then

    --     end
    -- end

    -- LastCombatState = state
end

while true do

    local mapID, subMapID = GetMapIDs()
    if (mapID ~= LastMapID or subMapID ~= LastSubMapID) then

        local idealHits = GetBossHits(mapID, subMapID)
        if (idealHits ~= nil) then
            local expected = GetExpectedRockHits(idealHits)
    
            LastMapID = mapID
            LastSubMapID = subMapID
            BestIntersections = idealHits
            BestExpected = expected
        end
    end 

    local rockData = CalculateCurrentRocks()
    local headerLines = DrawFeedbackUI(rockData, 20)
    
    local canAct = CanBrianAct()
    -- gui.text(100, 300, Ternary(canAct, "Yes", "No"), "white")

    emu.frameadvance()
end
