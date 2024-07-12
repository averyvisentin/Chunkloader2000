--we bad at this

-- Example of calling functions from the basics module
local basics = require("/apis/basics.lua") -- Adjust "path.to.basics" as necessary
local newPos = basics.NewPos("north")
local currentPosition = basics.Current()
local isInLocation = basics.In_location({x=10, y=5, z=2}, {x=10, y=5, z=2})
local isInArea = basics.In_area({x=5, y=5, z=5}, {min_x=1, max_x=10, min_y=1, max_y=10, min_z=1, max_z=10})

main()
-- Corrected and enhanced function to log the turtle's starting position with facing direction


function Home(facing)
    local SX, SY, SZ = gps.locate(5)
    local file = fs.open("start.txt", "w")
    if facing then
        file.writeLine("Start Position: " .. SX .. ", " .. SY .. ", " .. SZ .. ", Facing: " .. facing)
    else
        file.writeLine("Start Position: " .. SX .. ", " .. SY .. ", " .. SZ)
    end
    file.close()
    if facing then
        return SX .. ',' .. SY .. ',' .. SZ .. ':' .. facing
    else
        return SX .. ',' .. SY .. ',' .. SZ
    end
end

function Wherehome()
    local file = fs.open("start.txt", "r") -- Correct the filename typo
    local line = file.readLine()
    file.close()
    -- Assuming the line format is "Start Position: X, Y, Z, Facing: F" or "Start Position: X, Y, Z"
    local _, _, SX, SY, SZ, facing = string.find(line, "Start Position: (%d+), (%d+), (%d+),? Facing:?(.*)")
    SX, SY, SZ = tonumber(SX), tonumber(SY), tonumber(SZ)
    if facing ~= "" then
        facing = facing:trim() -- Remove any leading/trailing spaces
    else
        facing = nil
    end
    return SX, SY, SZ, facing
end

-- Function to move the turtle back to the starting position
function Gohome(SX, SY, SZ)
    -- Obtain current position from basics.current()
    local currentX, currentY, currentZ = basics.current()

    local distanceX = currentX - SX
    local distanceY = currentY - SY
    local distanceZ = currentZ - SZ

    -- Move the turtle back to the starting position along the X-axis
    if distanceX > 0 then
        turtle.turnLeft()
        turtle.moveForward(distanceX)
        turtle.turnRight()
    elseif distanceX < 0 then
        turtle.turnRight()
        turtle.moveForward(math.abs(distanceX))
        turtle.turnLeft()
    end

    -- Move the turtle back to the starting position along the Y-axis
    -- Assuming moveToY handles direction internally
    moveToY(SY)

    -- Move the turtle back to the starting position along the Z-axis
    if distanceZ > 0 then
        turtle.turnRight()
        turtle.moveForward(distanceZ)
        turtle.turnLeft()
    elseif distanceZ < 0 then
        turtle.turnLeft()
        turtle.moveForward(math.abs(distanceZ))
        turtle.turnRight()
    end
end

-- Function to check if the turtle is low on fuel
function IsLowOnFuel()
    local startPos = {x = SX, y = SY, z = SZ} -- Assuming SX, SY, SZ are global variables holding the start position
    local currentPos = --should be read from start.txt
    local distanceToHome = D2(startPos, currentPos)
    local fuelConsumptionRate = 1 -- Assuming 1 unit of fuel is consumed per block moved
    local fuelNeededToReturnHome = distanceToHome * fuelConsumptionRate
    local fuelBuffer = 20 -- Additional fuel buffer for safety
    local minimumFuelLevel = fuelNeededToReturnHome + fuelBuffer
    local currentFuelLevel = turtle.getFuelLevel()
    return currentFuelLevel < minimumFuelLevel
end
-- Call the returnToStartPosition function at the end of the script or when low on fuel
if IsLowOnFuel() then
    Gohome(SX, SY, SZ)
end

--print debug messages
function BPrint(huh)
    print("[DEBUG] " .. huh)
end


-- Function to calculate the total fuel needed to return to the starting position with a buffer
function FuelRequirement(SX, SY, SZ, fuelBuffer)
    local currentX, currentY, currentZ = gps.locate(5)
    local distanceToHome = Distance(Pos, StartPosition)
    local totalFuelNeeded = distanceToHome + fuelBuffer -- Add buffer for error handling
    return totalFuelNeeded
end

-- Example usage
local startX, startY, startZ = 0, 0, 0 -- Assuming starting position is (0, 0, 0) for demonstration
local fuelBuffer = 20 -- Adjust based on expected obstacles or errors
local fuelNeeded = FuelRequirement(startX, startY, startZ, fuelBuffer)
print("Fuel needed to return home with buffer: " .. fuelNeeded)