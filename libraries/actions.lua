--we bad at this
-- Example of calling functions from the basics module
basics = require("/apis/basics.lua") -- Adjust "path.to.basics" as necessary
newPos = basics.NewPos()
currentPosition = basics.Current()
isInLocation = basics.In_location()
isInArea = basics.In_area()
inf = 1e309
distance = basics.Distance()
start = basics.Start()

bumps = {       north = { 0,  0, -1},
                south = { 0,  0,  1},
                east  = { 1,  0,  0},
                west  = {-1,  0,  0},}

left_shift = {  north = 'west',
                south = 'east',
                east  = 'north',
                west  = 'south',}

right_shift =  {north = 'east',
                south = 'west',
                east  = 'south',
                west  = 'north',}

reverse_shift = {north = 'south',
                south = 'north',
                east  = 'west',
                west  = 'east',}

move = {forward = turtle.forward,
        up      = turtle.up,
        down    = turtle.down,
        back    = turtle.back,
        left    = turtle.turnLeft,
        right   = turtle.turnRight}
                
detect = {forward = turtle.detect,
        up      = turtle.detectUp,
        down    = turtle.detectDown}
                
inspect = {forward = turtle.inspect,
            up      = turtle.inspectUp,
            down    = turtle.inspectDown}
                
dig = { forward = turtle.dig,
        up      = turtle.digUp,
        down    = turtle.digDown}
                
attack = {forward = turtle.attack,
        up      = turtle.attackUp,
        down    = turtle.attackDown}

-- Define a function to check if a block is an ore based on its tags
function detect_ore(direction)
    local block = ({inspect[direction]()})[2]
    if block == nil or block.name == nil then
        return false
    elseif checkTags(block) then
        return true
    elseif block.name:lower():find("ore") then  
        return true
    end
    return false
end
function scan(valid, ores)
    local directions = {'forward', 'up', 'down'}
    local checked_directions = {
        north = false,
        south = false,
        east = false,
        west = false,
    }
    local current_direction = state.orientation -- Make sure state.orientation is set properly

    for _, direction in ipairs(directions) do
        local success, data = inspect(direction)
        if success then
            if is_ore(data) then
                ores[data.name] = true
            else
                valid[data.name] = true
            end
        end
    end

    for i = 1, 4 do
        if not checked_directions[current_direction] then
            move(right)
            current_direction = direction_utils.right_shift[current_direction]
            checked_directions[current_direction] = true
            local success, data = inspect(forward, up, down)   
            if success then
                if is_ore(data) then
                    ores[data.name] = true
                else
                    valid[data.name] = true
                end
            end
        end
    end
end

function calibrate()
    -- GEOPOSITION BY MOVING TO ADJACENT BLOCK AND BACK
    local sx, sy, sz = gps.locate()
--    if sx == config.interface.x and sy == config.interface.y and sz == config.interface.z then
--        refuel()
--    end
    if not sx or not sy or not sz then
        return false
    end
    for i = 1, 4 do
        -- TRY TO FIND EMPTY ADJACENT BLOCK
        if not turtle.detect() then
            break
        end
        if not turtle.turnRight() then return false end
    end
    if turtle.detect() then
        -- TRY TO DIG ADJACENT BLOCK
        for i = 1, 4 do
            dig(forward)
            if not turtle.detect() then
                break
            end
            if not turtle.turnRight() then return false end
        end
        if turtle.detect() then
            return false
        end
    end
    if not turtle.forward() then return false end
    local nx, ny, nz = gps.locate()
    if nx == sx + 1 then
        state.orientation = 'east'
    elseif nx == sx - 1 then
        state.orientation = 'west'
    elseif nz == sz + 1 then
        state.orientation = 'south'
    elseif nz == sz - 1 then
        state.orientation = 'north'
    else
        return false
    end
    state.location = {x = nx, y = ny, z = nz}
end

function go(direction)
    if not face(direction) then
        return false
    end
    if detect[direction]() then
        dig[direction]()
        return move[direction]()
    end
    if not move[direction]() then
        return false
    end
    log_movement(direction)
    return true
end

function face(orientation)
    if state.orientation == orientation then
        return true
    elseif right_shift[state.orientation] == orientation then
        if not go('right') then return false end
    elseif left_shift[state.orientation] == orientation then
        if not go('left') then return false end
    elseif right_shift[right_shift[state.orientation]] == orientation then
        if not go('right') then return false end
        if not go('right') then return false end
    else
        return false
    end
    return true
end

function log_movement(direction)
    if direction == 'up' then
        state.location.y = state.location.y +1
    elseif direction == 'down' then
        state.location.y = state.location.y -1
    elseif direction == 'forward' then
        bump = bumps[state.orientation]
        state.location = {x = state.location.x + bump[1], y = state.location.y + bump[2], z = state.location.z + bump[3]}
    elseif direction == 'back' then
        bump = bumps[state.orientation]
        state.location = {x = state.location.x - bump[1], y = state.location.y - bump[2], z = state.location.z - bump[3]}
    elseif direction == 'left' then
        state.orientation = left_shift[state.orientation]
    elseif direction == 'right' then
        state.orientation = right_shift[state.orientation]
    end
    return true
end

-- Corrected and enhanced function to log the turtle's starting position with facing direction
function Wherehome() --read from start.txt file to get starting position
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
    local currentX, currentY, currentZ = basics.current()
    
    -- Assuming basics.Distance calculates straight-line distance but we need to move discretely
    -- Move along X-axis
    while currentX ~= SX do
        if currentX > SX then
            -- Assuming we have a function to face West
            faceWest()
            turtle.forward()
        else
            -- Assuming we have a function to face East
            faceEast()
            turtle.forward()
        end
        currentX, _, _ = basics.current() -- Update currentX after moving
    end

    -- Move along Z-axis
    while currentZ ~= SZ do
        if currentZ > SZ then
            -- Assuming we have a function to face North
            faceNorth()
            turtle.forward()
        else
            -- Assuming we have a function to face South
            faceSouth()
            turtle.forward()
        end
        _, _, currentZ = basics.current() -- Update currentZ after moving
    end

    -- Move along Y-axis, assuming we have a way to move vertically
    while currentY ~= SY do
        if currentY > SY then
            -- Move down
            turtle.down()
        else
            -- Move up
            turtle.up()
        end
        _, currentY, _ = basics.current() -- Update currentY after moving
    end
end

-- Function to check if the turtle is low on fuel and needs to return home or refuel
-- Call the Gohome function at the end of the script or when low on fuel
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
    local distanceToHome = Distance(Current, Start)
    local totalFuelNeeded = distanceToHome + fuelBuffer -- Add buffer for error handling
    return totalFuelNeeded
end

