--we bad at this
-- Example of calling functions from the basics module

updatePosition = basics.updatePosition(direction)
currentPosition = basics.Current()
isInLocation = basics.In_location()
isInArea = basics.In_area()
inf = 1e309
distance = basics.Distance()
start = basics.Start()

-- Load basics module
basics = require("basics.lua")

-- Define global tables
bumps = {
    north = { 0,  0, -1},
    south = { 0,  0,  1},
    east  = { 1,  0,  0},
    west  = {-1,  0,  0},
}

left_shift = {
    north = 'west', south = 'east',
    east  = 'north', west  = 'south',
}

right_shift = {
    north = 'east', south = 'west',
    east  = 'south', west  = 'north',
}

reverse_shift = {
    north = 'south', south = 'north',
    east  = 'west', west  = 'east',
}

move = {
    forward = turtle.forward, up = turtle.up,
    down = turtle.down, back = turtle.back,
    left = turtle.turnLeft, right = turtle.turnRight
}

detect = {
    forward = turtle.detect, up = turtle.detectUp,
    down = turtle.detectDown
}

inspect = {
    forward = turtle.inspect, up = turtle.inspectUp,
    down = turtle.inspectDown
}

dig = {
    forward = turtle.dig, up = turtle.digUp,
    down = turtle.digDown
}

attack = {
    forward = turtle.attack, up = turtle.attackUp,
    down = turtle.attackDown
}


-- Global configuration
local config = {
    max_attempts = 5,
    dig_enabled = true,
    attack_enabled = true
}

-- Helper functions
local function heuristic(a, b)
    return math.abs(a.x - b.x) + math.abs(a.y - b.y) + math.abs(a.z - b.z)
end

local function get_neighbors(node)
    local neighbors = {}
    for _, dir in ipairs({'up', 'down', 'north', 'south', 'east', 'west'}) do
        local neighbor = {
            x = node.x + (dir == 'east' and 1 or dir == 'west' and -1 or 0),
            y = node.y + (dir == 'up' and 1 or dir == 'down' and -1 or 0),
            z = node.z + (dir == 'south' and 1 or dir == 'north' and -1 or 0)
        }
        table.insert(neighbors, neighbor)
    end
    return neighbors
end

local function lowest_f_score(open_set, f_score)
    local lowest, best_node = math.huge, nil
    for _, node in ipairs(open_set) do
        local f = f_score[node.x .. ',' .. node.y .. ',' .. node.z] or math.huge
        if f < lowest then
            lowest, best_node = f, node
        end
    end
    return best_node
end

local function reconstruct_path(came_from, current)
    local path = {current}
    while came_from[current.x .. ',' .. current.y .. ',' .. current.z] do
        current = came_from[current.x .. ',' .. current.y .. ',' .. current.z]
        table.insert(path, 1, current)
    end
    return path
end

-- A* pathfinding algorithm
local function a_star(start, goal)
    local open_set = {start}
    local came_from = {}
    local g_score = {[start.x .. ',' .. start.y .. ',' .. start.z] = 0}
    local f_score = {[start.x .. ',' .. start.y .. ',' .. start.z] = heuristic(start, goal)}

    while #open_set > 0 do
        local current = lowest_f_score(open_set, f_score)
        if current.x == goal.x and current.y == goal.y and current.z == goal.z then
            return reconstruct_path(came_from, current)
        end

        for i, node in ipairs(open_set) do
            if node.x == current.x and node.y == current.y and node.z == current.z then
                table.remove(open_set, i)
                break
            end
        end

        for _, neighbor in ipairs(get_neighbors(current)) do
            local tentative_g_score = g_score[current.x .. ',' .. current.y .. ',' .. current.z] + 1
            if tentative_g_score < (g_score[neighbor.x .. ',' .. neighbor.y .. ',' .. neighbor.z] or math.huge) then
                came_from[neighbor.x .. ',' .. neighbor.y .. ',' .. neighbor.z] = current
                g_score[neighbor.x .. ',' .. neighbor.y .. ',' .. neighbor.z] = tentative_g_score
                f_score[neighbor.x .. ',' .. neighbor.y .. ',' .. neighbor.z] = tentative_g_score + heuristic(neighbor, goal)
                
                local is_in_open_set = false
                for _, node in ipairs(open_set) do
                    if node.x == neighbor.x and node.y == neighbor.y and node.z == neighbor.z then
                        is_in_open_set = true
                        break
                    end
                end
                if not is_in_open_set then
                    table.insert(open_set, neighbor)
                end
            end
        end
    end
    return nil -- No path found
end

-- Main go function
function go(target, options)
    options = options or {}
    local max_attempts = options.max_attempts or config.max_attempts
    local dig_enabled = options.dig_enabled or config.dig_enabled
    local attack_enabled = options.attack_enabled or config.attack_enabled

    local current = basics.Current()
    local path = a_star(current, target)

    if not path then
        BPrint("No path found to target")
        return false
    end

    for i = 2, #path do  -- Start from 2 as 1 is the current position
        local next_pos = path[i]
        local move_direction = get_direction(current, next_pos)
        local attempts = 0

        while not basics.In_location(current, next_pos) and attempts < max_attempts do
            if try_move(move_direction) then
                current = basics.updatePosition(move_direction)
                break
            else
                if handle_obstacle(move_direction) then
                    attempts = attempts + 1
                else
                    -- Try to find an alternative path
                    for _, alt_direction in ipairs({'up', 'down', 'left', 'right'}) do
                        if try_move(alt_direction) then
                            current = basics.updatePosition(alt_direction)
                            path = a_star(current, target)  -- Recalculate path
                            if path then
                                break
                            end
                        end
                    end
                    attempts = attempts + 1
                end
            end

            if attempts >= max_attempts then
                BPrint("Failed to reach next position after " .. max_attempts .. " attempts")
                return false
            end
        end
    end

    return basics.In_location(current, target)
end

-- Helper functions from the original code
local function get_direction(current, target)
    local dx = target.x - current.x
    local dy = target.y - current.y
    local dz = target.z - current.z
    
    if dy ~= 0 then
        return dy > 0 and 'up' or 'down'
    elseif dx ~= 0 then
        return dx > 0 and 'east' or 'west'
    elseif dz ~= 0 then
        return dz > 0 and 'south' or 'north'
    end
    return nil
end

local function face_direction(direction)
    while state.orientation ~= direction do
        if right_shift[state.orientation] == direction then
            move.right()
        else
            move.left()
        end
        state.orientation = right_shift[state.orientation]
    end
end

local function try_move(direction)
    if direction == 'up' or direction == 'down' then
        return move[direction]()
    else
        face_direction(direction)
        return move.forward()
    end
end

local function handle_obstacle(direction)
    if dig_enabled and detect[direction] and detect[direction]() then
        dig[direction]()
        return true
    elseif attack_enabled and attack[direction] then
        attack[direction]()
        return true
    end
    return false
end


--check tags of a block
function check_tags(data)
    if type(data.tags) ~= 'table' or not config.blocktags then
        return false
    end
    for k, _ in pairs(data.tags) do
        if config.blocktags[k] then
            return true
        end
    end
    return false
end
-- Define a function to check if a block is an ore based on its tags
function detect_ore(direction)
    local success, block = inspect[direction]()
    if not success or not block.name then
        return false
    end
    return check_tags(block) or block.name:lower():find("ore")
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

    -- Function to check and categorize a block
    local function check_block(direction)
        local success, block = turtle.inspect(direction)
        if success then
            if detect_ore(direction) then
                ores[block.name] = true
            else
                valid[block.name] = true
            end
        end
    end

    -- Check forward, up, and down
    for _, direction in ipairs(directions) do
        check_block(direction)
    end

    -- Check all horizontal directions
    for i = 1, 4 do
        if not checked_directions[current_direction] then
            turtle.turnRight()
            current_direction = bump.right_shift[current_direction]
            checked_directions[current_direction] = true
            check_block('forward')
        end
    end
end

function calibrate()
    -- GEOPOSITION BY MOVING TO ADJACENT BLOCK AND BACK
    local sx, sy, sz = gps.locate()
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
    if state.orientation == orientation then -- Check if the current orientation matches the desired orientation
        return true
    elseif right_shift[state.orientation] == orientation then -- Check if turning right once matches the desired orientation
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

function log_movement(direction) --adjust location and orientation based on movement
    if direction == 'up' then --so y plus is upvalue
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

-- Import any required libraries or functions for A* pathfinding and navigation
currentPosition = basics.Current()
isInLocation = basics.In_location()
isInArea = basics.In_area()
inf = 1e309
distance = basics.Distance()

function go_to(start, goal, path)
    local start = { X = state.location.X, Y = state.location.Y, Z = state.location.Z, orientation = nil}
    local goal = { X = goal.X, Y = goal.Y, Z = goal.Z, orientation = nil}
    local path = find_path(start, goal)
    if path then
        for axis in path:gmatch'.' do
            if not go_to_XYZ(axis, goal[axis]) then
                return false
            end end else return false end
    if goal then
        if not face(goal) then
            return false
        end
    elseif goal.orientation then
        if not face(goal.orientation) then
            return false
        end
    end
    
    return true
end

function go_to_XYZ(axis, coordinate)
    local delta = coordinate - state.location[axis]
    if delta == 0 then
        return true
    end
    
    if axis == 'x' then
        if delta > 0 then
            if not face('east') then return false end
        else
            if not face('west') then return false end
        end
    elseif axis == 'z' then
        if delta > 0 then
            if not face('south') then return false end
        else
            if not face('north') then return false end
        end
    end
    
    for i = 1, math.abs(delta) do
        if axis == 'y' then
            if delta > 0 then
                if not go('up') then return false end
            else
                if not go('down') then return false end
            end
        else
            if not go('forward') then return false end
        end
    end
    return true
end

-- Improved Gohome function
function Gohome()
    local SX, SY, SZ = Wherehome()
    local currentX, currentY, currentZ = basics.Current()
    
    -- Use go_to function for more efficient pathfinding
    local success = go_to({X = currentX, Y = currentY, Z = currentZ}, {X = SX, Y = SY, Z = SZ})
    
    if not success then
        Print("Failed to return home")
        return false
    end
    
    Print("Successfully returned home")
    return true
end

-- Improved IsLowOnFuel function
function IsLowOnFuel()
    local currentFuel = turtle.getFuelLevel()
    local SX, SY, SZ = Wherehome()
    local currentX, currentY, currentZ = basics.Current()
    -- Calculate the Manhattan distance to home
    local distanceToHome = math.abs(currentX - SX) + math.abs(currentY - SY) + math.abs(currentZ - SZ)
    -- Add a buffer for safety (e.g., 20% more than the calculated distance)
    local requiredFuel = math.ceil(distanceToHome * 1.2)
    -- Check if current fuel is less than required fuel
    if currentFuel < requiredFuel then
        Print(string.format("Low on fuel. Current: %d, Required: %d", currentFuel, requiredFuel))
        return true
    end
    return false
end

-- Function to refuel if necessary
function RefuelIfNeeded()
    if IsLowOnFuel() then
        BPrint("Attempting to refuel")
        -- Implement refueling logic here
        -- For example:
        for i = 1, 16 do
            turtle.select(i)
            if turtle.refuel(0) then
                turtle.refuel()
                BPrint("Refueled successfully")
                return true
            end
        end
        BPrint("Failed to refuel")
        return false
    end
    return true
end

-- Main execution
while true do
    if IsLowOnFuel() then
        if not RefuelIfNeeded() then
            Gohome()
            break
        end
    end
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

