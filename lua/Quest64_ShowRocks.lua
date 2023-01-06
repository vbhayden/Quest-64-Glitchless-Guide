function RocksBrianToEnemy(BrianX1, BrianY1, EnemyX1, EnemyY1, Size1)

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

    local ROCK_COUNT = 10
    local percent = (1.0 * validRocks) / totalPossible
    local expected = ROCK_COUNT * percent

    return validRocks, 100.0 * percent, expected, totalPossible
end

function HeatMapGenerator()
    MapSize = 120
    brianX = math.floor(MapSize / 2)
    brianY = math.floor(MapSize / 2)
    Size = 6.3
    -- Solvaring 10 + 8.4  Note: Solvaring is moving about half a pixel during standing.
    -- Zelse 10 + 5.6  (Investigate Zelse Mid-Range)  Zelse moves about 0.4 pixels during standing.  He recoils a couple pixels when hit.
    -- Nepty 10 + 4.9  Nepty moves about 0.4 px during standing.
    -- Shilf 10 + 4.9  Shilf moves about 0.05
    -- Fargo 10 + 7 moves about 0.05
    -- Guilty 10 + 9.52 No movement
    -- Beigis 10 + 6.3 No movement
    -- Mammon 10 + 94.5 Moves around 0.6 px.
    heatTextfile = "HeatMap"
    heatDumpfile = heatTextfile .. ".txt"
    io.output(heatDumpfile)

    Max = 0

    for EnemyX = 0, MapSize do
        for EnemyY = MapSize, 0, -1 do
            R = RocksBrianToEnemy(brianX, brianY, EnemyX, EnemyY, Size)
            if R > Max then
                Max = R
            end
            io.write(string.format("%02X ", R))
        end
        io.write("\n")
    end

    io.write("\n")
    io.write("EnemySize: " .. Size)
    io.write("\n")
    io.write("Max: ", string.format("%02X", Max))
    io.write("\n")
    io.write("MapSize: " .. MapSize + 1)

    io.output():close()

end

BestExpected = 0
BestIntersections = 0

function HowManyRocksCurrently(x, y)

    local brianX = memory.readfloat(0x7BACC, true, "RDRAM")
    local brianY = memory.readfloat(0x7BAD4, true, "RDRAM")

    local i = 1 -- Enemy number 1 (starting at 1)

    local EnemyX = memory.readfloat(0x7C9BC + 296 * (i - 1), true, "RDRAM")
    local EnemyY = memory.readfloat(0x7C9C4 + 296 * (i - 1), true, "RDRAM")
    local SizeModifier = memory.readfloat(0x7C9E0 + 296 * (i - 1), true, "RDRAM")
    local TrueSize = memory.readfloat(0x7C9E4 + 296 * (i - 1), true, "RDRAM")
    local Size = SizeModifier * TrueSize
    local XDiff = brianX - EnemyX
    local YDiff = brianY - EnemyY

    local D = math.sqrt(XDiff * XDiff + YDiff * YDiff)
    local A = math.atan2(XDiff, YDiff) * (180 / (math.pi))

    local validRocks, percent, expected, total = RocksBrianToEnemy(brianX, brianY, EnemyX, EnemyY, Size)

    if (BestExpected < expected) then
        BestExpected = expected
    end
    if (BestIntersections < validRocks) then
        BestIntersections = validRocks
    end

    local comparedToBest = 1
    if BestExpected > 0 then
        comparedToBest = expected / BestExpected
    end

    local color = "red"
    if (comparedToBest > 0.9) then
        color = "cyan"
    elseif (comparedToBest > 0.75) then
        color = "yellow"
    elseif (comparedToBest > 0.5) then
        color = "orange"
    end

    gui.text(x, y + 15 * 1, "Boss Size:  " .. round(Size, 3))
    gui.text(x, y + 15 * 2, "Boss Distance: " .. round(D, 3))

    gui.text(x, y + 15 * 4, "Live")
    gui.text(x, y + 15 * 5, "Positioning: " .. round(100 * comparedToBest, 0) .. "% optimal", color)
    gui.text(x, y + 15 * 6, "Intersections:  " .. validRocks .. " of " .. total)
    gui.text(x, y + 15 * 7, "Expected Rocks: " .. expected)

    gui.text(x, y + 15 * 9, "Best")
    gui.text(x, y + 15 * 10, "Best Intersections:  " .. BestIntersections)
    gui.text(x, y + 15 * 11, "Best Expected Rocks: " .. BestExpected)

end

while true do

    HowManyRocksCurrently(50, 225)

    emu.frameadvance()
end
