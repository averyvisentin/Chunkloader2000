--we bad at this

-- Function to move the turtle forward a specified number of steps
local function moveForward(steps)
    for i = 1, steps do
        while not turtle.forward() do
            turtle.dig()
            turtle.attack()
        end
    end
end

-- Function to move the turtle to a specified Y coordinate
local function moveToY(targetY)
    local currentY = select(2, gps.locate(5))

    if currentY < targetY then
        while currentY < targetY do
            if not turtle.up() then
                turtle.digUp()
            else
                currentY = currentY + 1
            end
        end
    elseif currentY > targetY then
        while currentY > targetY do
            if not turtle.down() then
                turtle.digDown()
            else
                currentY = currentY - 1
            end
        end
    end
end

local function main()
    print("Enter the target Y coordinate:")
    local targetY = tonumber(read())
    moveToY(targetY)

    local sideLength = 2000
    local areaSideLength = 16
    local areasPerSide = sideLength / areaSideLength

    for row = 1, areasPerSide do
        for column = 1, areasPerSide do
            -- Move the turtle in a 16x16 square
            for i = 1, 4 do
                moveForward(areaSideLength - 1) -- Adjust for the initial position in each side
                turtle.turnRight()
            end
            -- Move to the start of the next 16x16 area, if not at the end of a row
            if column < areasPerSide then
                moveForward(areaSideLength)
            end
        end
        -- Change direction at the end of each row and move to the start of the next row
        if row % 2 == 0 then
            turtle.turnLeft()
            moveForward(areaSideLength)
            turtle.turnLeft()
        else
            turtle.turnRight()
            if row < areasPerSide then -- Avoid moving beyond the last row
                moveForward(areaSideLength)
            end
            turtle.turnRight()
        end
    end
end

-- Start the main function
main()
-- Function to log the turtle's starting position
function startPosition()
    local startX, startY, startZ = gps.locate(5)
    local file = fs.open("start_position.txt", "w")
    file.writeLine("Start Position: " .. startX .. ", " .. startY .. ", " .. startZ)
    file.close()
    return startX, startY, startZ
end

-- Function to return the turtle to its starting position
function returnTostartPosition(startX, startY, startZ)
    local currentX, currentY, currentZ = gps.locate(5)
    local distanceX = currentX - startX
    local distanceY = currentY - startY
    local distanceZ = currentZ - startZ

    -- Move the turtle back to the starting position
    if distanceX > 0 then
        turtle.turnLeft()
        moveForward(distanceX)
        turtle.turnRight()
    elseif distanceX < 0 then
        turtle.turnRight()
        moveForward(math.abs(distanceX))
        turtle.turnLeft()
    end

    if distanceY > 0 then
        moveToY(startY)
    elseif distanceY < 0 then
        moveToY(startY)
    end

    if distanceZ > 0 then
        turtle.turnRight()
        moveForward(distanceZ)
        turtle.turnLeft()
    elseif distanceZ < 0 then
        turtle.turnLeft()
        moveForward(math.abs(distanceZ))
        turtle.turnRight()
    end
end

-- Call the logStartPosition function at the beginning of the script
local startX, startY, startZ = StartPosition()

-- Call the returnToStartPosition function at the end of the script or when low on fuel
if isLowOnFuel() then
    returnToStartPosition(startX, startY, startZ)
end

-- Function to check if the turtle is low on fuel
function isLowOnFuel()
    local fuelLevel = turtle.getFuelLevel()
    local minimumFuelLevel = 100 -- Adjust this value as needed
    local fuelConsumptionRate = 80 -- Adjust this value based on the fuel efficiency

    return fuelLevel < minimumFuelLevel + fuelConsumptionRate
end

