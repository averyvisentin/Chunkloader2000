------install.lua

local diskPath = 'disk/turtle/'
local apiPath = '/apis/'

-- Ensure /apis/ exists and copy necessary files
if fs.exists(apiPath) then
    fs.delete(apiPath)
end
fs.makeDir(apiPath)

-- Copy API files
local function copyFile(source, destination)
    if fs.exists(source) then
        fs.copy(source, destination)
        print('Copied ' .. source .. ' to ' .. destination)
    else
        print('Error: ' .. source .. ' not found.')
    end
end

copyFile(diskPath .. 'state.lua', apiPath .. 'state.lua')
copyFile(diskPath .. 'basics.lua', apiPath .. 'basics.lua')
copyFile(diskPath .. 'actions.lua', apiPath .. 'actions.lua')
copyFile(diskPath .. 'config.lua', apiPath .. 'config.lua')
copyFile(diskPath .. 'rednet.lua', apiPath .. 'inout.lua')
copyFile(diskPath .. 'startup.lua', apiPath .. 'startup.lua')
copyFile(diskPath .. 'chico.lua', apiPath .. 'chico.lua')

---------
---------startup.lua
-- Load APIs
os.loadAPI("apis/state.lua")
os.loadAPI("apis/basics.lua")
os.loadAPI("apis/actions.lua")
os.loadAPI("apis/config.lua")
os.loadAPI("apis/inout.lua")
os.loadAPI("apis/chico.lua")

-- Additional debug output
print('APIs loaded successfully.')

-- Open rednet on any available modem
for _, side in ipairs(peripheral.getNames()) do
    if peripheral.getType(side) == "modem" then
        rednet.open(side)
        break
    end
end

-- Function to announce availability
local function announceAvailability(role)
    if role == "MinerTurtle" then
        rednet.broadcast("MinerTurtleAvailable", "Pairing")
    else
        rednet.broadcast("ChunkTurtleAvailable", "Pairing")
    end
end

-- Function to wait for a pairing response
local function waitForPairing(role)
    while true do
        local senderId, message, protocol = rednet.receive("Pairing", 60)
        if protocol == "Pairing" then
            if role == "MinerTurtle" and message == "ChunkTurtleAvailable" then
                rednet.send(senderId, "PairingConfirmed", "Pairing")
                print("Paired with ChunkTurtle ID: " .. senderId)
                return senderId
            elseif role == "ChunkTurtle" and message == "MinerTurtleAvailable" then
                rednet.send(senderId, "ChunkTurtleAvailable", "Pairing")
                local confirmationId, confirmationMessage, confirmationProtocol = rednet.receive("Pairing", 60)
                if confirmationProtocol == "Pairing" and confirmationMessage == "PairingConfirmed" then
                    print("Paired with MinerTurtle ID: " .. senderId)
                    return senderId
                end
            end
        end
    end
end

-- Main pairing logic
if os.getComputerLabel():find("MinerTurtle") then
    announceAvailability("MinerTurtle")
    local chunkTurtleId = waitForPairing("MinerTurtle")
    print("MinerTurtle ID: " .. os.getComputerID() .. " paired with ChunkTurtle ID: " .. chunkTurtleId)
    logTurtleState(os.getComputerID(), chunkTurtleId)
else
    announceAvailability("ChunkTurtle")
    local minerTurtleId = waitForPairing("ChunkTurtle")
    print("ChunkTurtle ID: " .. os.getComputerID() .. " paired with MinerTurtle ID: " .. minerTurtleId)
    logTurtleState(minerTurtleId, os.getComputerID())
end

-- LAUNCH PROGRAMS AS SEPARATE THREADS
multishell.launch({}, '/inout.lua')
multishell.launch({}, '/chico.lua')
multishell.setTitle(1, 'inout')
multishell.setTitle(2, 'Chico')

--------
--------basics.lua


Bumps = {north = { 0,  0, -1}, south = { 0,  0,  1},
         east  = { 1,  0,  0}, west  = {-1,  0,  0},}
--turn left 90 degrees
Left_shift = {north = 'west', south = 'east',
              east  = 'north', west  = 'south',}
--turn right 90 degrees
Right_shift = {north = 'east',south = 'west',
               east  = 'south', west  = 'north',}
--180 degrees
Reverse_shift = {north = 'south', south = 'north',
                 east  = 'west', west  = 'east',}

local state = {}

function Start(coordinates, facing) -- Function to set the absolute starting position
    -- Initialize the start sub-table if it doesn't exist
    state.start = state.start or {}
    gps.locate(0.1)
    if coordinates then
        -- Unpack coordinates directly into state.start
        state.start.X, state.start.Y, state.start.Z = table.unpack(coordinates)
    else
        -- Use gps.locate to get the current position if coordinates are not provided
        state.start.X, state.start.Y, state.start.Z = gps.locate(5)
    end
    -- Open the "state" file for writing
    local file = fs.open("state", "w")
    if file then
        -- Serialize the state table and write it to the file
        local serializedState = textutils.serialize(state)
        file.write(serializedState)
        file.close()
    end
    
    -- Construct the return string using state.start.X, state.start.Y, state.start.Z
    if facing then
        return state.start.X .. ',' .. state.start.Y .. ',' .. state.start.Z .. ':' .. face
    else    -- If 'facing' is not provided, return just the coordinates
        return state.start.X .. ',' .. state.start.Y .. ',' .. state.start.Z
    end
end

--quick locate with no logging
function locate(xyz)
    if not xyz then
        local x, y, z = gps.locate()
        if x and y and z then
            return x .. ',' .. y .. ',' .. z
        else
            return nil, "GPS location failed"
        end
    else
        return x.x .. ',' .. y.y .. ',' .. z.z
    end
end

-- Function to get the current position
function Current(coordinates, facing)
    if coordinates then
        -- Update state.location with new coordinates and facing direction
        local cx, cy, cz = table.unpack(coordinates)
        state.location = { X = cx, Y = cy, Z = cz, facing = facing }
        
        -- Serialize and write state to file
        local file = fs.open("state", "w")
        if file then
            local serializedState = textutils.serialize(state)
            file.write(serializedState)
            file.close()
        else
            print("Error: Could not open state file for writing")
            return nil
        end
    else
        -- Read and deserialize state from file
        local file = fs.open("state", "r")
        if file then
            local serializedState = file.readAll()
            file.close()
            
            state = textutils.unserialize(serializedState)
        else
            print("Error: Could not open state file for reading")
            return nil -- Return nil if the file doesn't exist
        end
    end
    
    -- Format the position string
    if state.location then
        local facingStr = state.location.facing and (":" .. state.location.facing) or ""
        return string.format("%d,%d,%d%s", state.location.X, state.location.Y, state.location.Z, facingStr)
    else
        return nil
    end
end



-- Function to update position based on direction
function updatePosition(direction)
    if not state.location then
        print("Error: state.location is not set")
        return nil
    end

    if Bumps[direction] then
        state.location.x = state.location.x + Bumps[direction].x
        state.location.y = state.location.y + Bumps[direction].y
        state.location.z = state.location.z + Bumps[direction].z
    else
        print("Invalid direction: " .. direction)
        return nil
    end
    
    -- Save the updated state to the file
    local file = fs.open("state", "w")
    if file then
        local serializedState = textutils.serialize(state)
        file.write(serializedState)
        file.close()
    else
        print("Error: Could not open state file for writing")
    end

    return state.location
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

function In_location(xyzo, location)            
local location = location or state.location
    for _, axis in pairs({'x', 'y', 'z'}) do    --iterates over x, y, z and checks if point coordinates match those specified
        if state.location[axis] then                  --in the state.location table
            if state.location[axis] ~= xyzo[axis] then
                return false
            end
        end
    end
    return true
end

function In_area(xyz, area) --checks if xyz is in an area, defined by a table with min and max xyz
    local locations = config.locations
    if locations then
        for _, location in ipairs(locations) do
            if xyz.x <= location.max_x and xyz.x >= location.min_x and xyz.y <= location.max_y and xyz.y >= location.min_y and xyz.z <= location.max_z and xyz.z >= location.min_z then
                return true
            end
        end
    end
    return false
end



function Distance(point1, point2)
    local dx = point2.x - point1.x
    local dy = point2.y - point1.y
    -- Check if z coordinates are present for both points
    if point1.z ~= nil and point2.z ~= nil then
        local dz = point2.z - point1.z
        return math.sqrt(dx*dx + dy*dy + dz*dz) -- 3D distance
    else
        return math.sqrt(dx*dx + dy*dy) -- 2D distance
    end
end


state.blocktable = state.blocktable or {} -- Initialize blocktable if it doesn't exist

-- Example function to gather mine data with actual location
function mineData()
    -- Get the current location using GPS or another method
    local location = gps.locate() -- Get actual coordinates
    if not location then
        print("Error: Unable to locate GPS signal.")
        return
    end
 local blockTable ={}
    -- Store gathered data in state.blocktable
    for _, block in ipairs(blockTable) do
        table.insert(state.blocktable, block)
    end

    return location, blockTable
end

-- Example of how to use the gatherMineData function and print the state.blocktable
function printBlockTable()
    for _, block in ipairs(state.blocktable) do
        print(string.format("Block: %s, Metadata: %d, Location: (%d, %d, %d)",
            block.name, block.metadata, block.location.x, block.location.y, block.location.z))
    end
end


-- Main loop to receive and execute commands
 ---   while true do
    local senderID, message, protocol = rednet.receive()
    state.logState("Received command: " .. message)
    if actions[message] then
        actions[message]()
        -- Log mine data after executing an action
        local location, blockTable = gatherMineData()
        basics.logMineData(location, blockTable)
    else
        print("Unknown command: " .. message)
    end


-------
-------actions.lua

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

function get_neighbors(node)
    local neighbors = {}
    for _, dir in ipairs({'up', 'down', 'north', 'south', 'east', 'west'}) do
        -- Assume check_block has been modified to return isOre directly
        local isOre, blockLocation = check_block(dir)
        if not isOre then
            local neighbor = {
                x = node.x + (dir == 'east' and 1 or dir == 'west' and -1 or 0),
                y = node.y + (dir == 'up' and 1 or dir == 'down' and -1 or 0),
                z = node.z + (dir == 'south' and 1 or dir == 'north' and -1 or 0),
                location = blockLocation
            }
            table.insert(neighbors, neighbor)
        end
    end
    return neighbors
end

function lowest_f_score(open_set, f_score)
    local lowest, best_node = math.huge, nil
    for _, node in ipairs(open_set) do
        local f = f_score[node.x .. ',' .. node.y .. ',' .. node.z] or math.huge
        if f < lowest then
            lowest, best_node = f, node
        end
    end
    return best_node
end

function reconstruct_path(came_from, current)
    local path = {current}
    while came_from[current.x .. ',' .. current.y .. ',' .. current.z] do
        current = came_from[current.x .. ',' .. current.y .. ',' .. current.z]
        table.insert(path, 1, current)
    end
    return path
end


-- A* pathfinding algorithm
function a_star(start, goal)
    local heuristic = Distance(start, goal)
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

function go(target)
    local current = basics.Current()
    local path = a_star(current, target)
    local max_attempts = 5 -- Assuming max_attempts is defined here

    if not path then
        BPrint("No path found to target")
        return false
    end

    local i = 2 -- Start from 2 as 1 is the current position
    while i <= #path do
        local next_pos = path[i]
        local move_direction = get_direction(current, next_pos)
        local attempts = 0

        while not basics.In_location(current, next_pos) and attempts < max_attempts do
            if try_move(move_direction) then
                current = basics.updatePosition(move_direction)
                i = i + 1 -- Move to the next position in the path
                break -- Exit the while loop since the move was successful
            else
                attempts = attempts + 1
                if not handle_obstacle(move_direction) or attempts >= max_attempts then
                    -- Recalculate path from the current position if obstacle handling fails or max attempts reached
                    path = a_star(current, target)
                    if not path then
                        Print("Failed to find a new path to target")
                        return false
                    end
                    i = 2 -- Reset path index to start from the new current position
                end
            end
        end

        if attempts >= max_attempts then
            Print("Failed to reach next position after " .. max_attempts .. " attempts")
            return false
        end
    end

    return basics.In_location(current, target)
end

-- Helper functions from the original code
function get_direction(current, target)
    local distance = Distance(current, target) --calling distance function from basics.lua
return get_direction
end

function face_direction(direction)
    while state.orientation ~= direction do
        if right_shift[state.orientation] == direction then
            move.right()
        else
            move.left()
        end
        state.orientation = right_shift[state.orientation]
    end
end

function try_move(direction)
    if direction == 'up' or direction == 'down' then
        return move[direction]()
    else
        face_direction(direction)
        return move.forward()
    end
end

function handle_obstacle(direction)
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
    -- Use the state's current orientation to determine the initial direction
    local current_direction = state.orientation

    -- Check vertical directions first
    for _, direction in ipairs(directions) do
        local isOre, location = check_block(direction)
        -- Update valid and ores tables based on the result
        if isOre ~= nil then -- Only update if check_block returned a result
            if isOre then
                ores[location] = true
            else
                valid[location] = true
            end
        end
    end

    -- Initialize checked_directions table
    local checked_directions = {}
    checked_directions[current_direction] = true

    -- Check horizontal directions by turning the turtle
    for _ = 1, 4 do
        turtle.turnRight()
        current_direction = right_shift[current_direction] -- Update current direction based on right shift
        if not checked_directions[current_direction] then
            checked_directions[current_direction] = true
            check_block('forward')
            check_block('up')
            check_block('down')
            local isOre, location = check_block('forward')
            -- Update valid and ores tables based on the result
            if isOre ~= nil then -- Only update if check_block returned a result
                if isOre then
                    ores[location] = true
                else
                    valid[location] = true
                end
            end
        end
    end
end



-- Corrected version of check_block to include sending data and proper location handling
function check_block(direction)
    local location = {x = gps.locate()}
    if not location then
        print("Error: Unable to locate GPS signal.")
        return nil, nil
    end

    local success, block = turtle.inspect(direction)
    if success then
        local isOre = detect_ore(direction)
        local valid = check_tags(config.blocktags or {block.tags})
        table.insert(state.blocktable, {
            name = block.name,
            isOre = isOre,
            location = location,
            turtleID = os.getComputerID()
        })
        
        sendBlockData({
            name = block.name, 
            isOre = isOre, 
            location = location, 
            turtleID = os.getComputerID()
        })
        return isOre, location -- Return isOre and location
    else
        return nil, location -- Return nil and location if inspect fails
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
    log_movement(direction)
end

function go(direction)
    if direction == 'up' then
        return turtle.up()
    elseif direction == 'down' then
        return turtle.down()
    elseif direction == 'forward' then
        return turtle.forward()
    elseif direction == 'back' then
        return turtle.back()
    elseif direction == 'left' then
        if not turtle.turnLeft() then return false end
        if not turtle.forward() then return false end
    elseif direction == 'right' then
        if not turtle.turnRight() then return false end
        if not turtle.forward() then return false end
    else
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
    log_movement(direction)
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

function go_to(start, goal)
    local path = a_star(start, goal)
    if path then
        for _, pos in ipairs(path) do
            local direction = get_direction(state.location, pos)
            if not go(direction) then
                return false
            end
        end
    else
        return false
    end
    if goal.orientation then
        if not face(goal.orientation) then
            return false
        end
    end
    return true
end

function get_direction(current, target)
    local dx = target.x - current.x
    local dy = target.y - current.y
    local dz = target.z - current.z
    if dx > 0 then
        return 'east'
    elseif dx < 0 then
        return 'west'
    elseif dz > 0 then
        return 'south'
    elseif dz < 0 then
        return 'north'
    elseif dy > 0 then
        return 'up'
    elseif dy < 0 then
        return 'down'
    end
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

function go_home()
    local home = config.locations.home
    if not go_to(state.location, home) then
        print("Failed to return home")
        return false
    end
    print("Successfully returned home")
    return true
end

-- Corrected function definition
function home_exit()
    -- Clone the home location to avoid modifying the original
    local exit_location = {
        x = config.locations.home.x,
        y = config.locations.home.y,
        z = config.locations.home.z - 1 -- One block north (assuming north is negative z) and one block below
    }
    
    -- Assuming there's logic here to use exit_location
    print("Exit location:", exit_location.x, exit_location.y, exit_location.z)
    
    return true
end

function go_vault()
    local vault = config.locations.vault
    if not go_to(state.location, vault) then
        print("Failed to go to vault")
        return false
    end
    print("Successfully reached vault")
    return true
end

function go_to_refuel()
    local refuel = config.locations.refuel
    if not go_to(state.location, refuel) then
        print("Failed to go to refuel")
        return false
    end
    print("Successfully reached refuel")
    return true
end

-- Main function to create a mineshaft and handle mining
function mineshaft()
    local yLevel = config.mine_levels[math.random(#config.mine_levels)]
    local target = {x = 0, y = yLevel, z = 0} -- Adjust target coordinates as necessary

    -- Initialize state.locations.mine if it's not already initialized
    state.locations.mine = state.locations.mine or {}

    -- Set target to the last known block of the mine if available
    if state.locations.mine.lastBlock then
        target = state.locations.mine.lastBlock
    end

    if go(target) then
        local isOre, location = check_block()  -- Check the block at the current location
        if isOre ~= nil then
            if isOre then
                ores[location] = true
                dig()  -- Example: dig the ore block
            else
                valid[location] = true
                dig()
            end

            -- Update state.locations.mine with the last block broken coordinates
            state.locations.mine.lastBlock = {x = state.location.x, y = state.location.y, z = state.location.z}
            
            -- Optionally, save the updated state to a file
            local file = fs.open("state", "w")
            if file then
                local serializedState = textutils.serialize(state)
                file.write(serializedState)
                file.close()
            else
                print("Error: Could not open state file for writing")
            end

            return true
        end
    end
end



-- Function to perform strip mining
function stripmine(yLevel)
    local width, length = config.mission_length, config.mission_length
    local ores = {}
    local valid = {}

    -- Initialize state.locations.strip if it's not already initialized
    state.locations.strip = state.locations.strip or {}

    -- Set target to the last known block of the strip if available
    if state.locations.strip.lastBlock then
        target = state.locations.strip.lastBlock
    end
    
    for x = 0, width - 1 do
        for z = 0, length - 1 do
            local target = {x = x, y = yLevel, z = z}
            if go(target) then
                local isOre, location = check_block()  -- Check the block at the current location
                if isOre ~= nil then
                    if isOre then
                        ores[location] = true
                        dig()  -- Example: dig the ore block
                    else
                        valid[location] = true
                        dig()
                    end

                    -- Update state.locations.strip with the last block broken coordinates
                    state.locations.strip.lastBlock = {x = state.location.x, y = state.location.y, z = state.location.z}
                    
                    -- Optionally, save the updated state to a file
                    local file = fs.open("state", "w")
                    if file then
                        local serializedState = textutils.serialize(state)
                        file.write(serializedState)
                        file.close()
                    else
                        print("Error: Could not open state file for writing")
                    end
                end
            end
        end
    end

    return true
end





function follow() --chunk follow mine
    local chunkTurtleID = os.getComputerID()
    local minerTurtleID = state.turtles[chunkTurtleID].pair
    local minerLocation = state.turtles[minerTurtleID].location
    local chunkLocation = state.turtles[chunkTurtleID].location
    local distance = basics.Distance(minerLocation, chunkLocation)
    local maxDistance = 10 -- Maximum distance to maintain between turtles
    local maxAttempts = 5 -- Maximum attempts to reach the miner turtle
    local attempts = 0

    while distance > maxDistance and attempts < maxAttempts do
        local path = a_star(chunkLocation, minerLocation)
        if path then
            for _, pos in ipairs(path) do
                local direction = get_direction(chunkLocation, pos)
                if not go(direction) then
                    break -- Unable to move in the desired direction
                end
                chunkLocation = pos
                distance = basics.Distance(minerLocation, chunkLocation)
            end
        end
        attempts = attempts + 1
    end

    -- After all attempts, if still stuck, send messages to miner turtle and hub
    if distance > maxDistance then
        rednet.send(minerTurtleID, "Free me, I'm stuck.")
        rednet.send(HUB_ID, "Chunk turtle " .. chunkTurtleID .. " is stuck.") -- Assuming HUB_ID is defined
    end
end

function prepare(min_fuel_amount)
    if state.item_count > 0 then
        if not go_vault() then return false end
    end
    local min_fuel_amount = min_fuel_amount + config.fuelBuffer
    if not go_to_refuel() then return false end
    if not go_vault() then return false end
    turtle.select(1)
    if turtle.getFuelLevel() ~= 'unlimited' then
        while turtle.getFuelLevel() < min_fuel_amount do
            if not turtle.suck(math.min(64, math.ceil(min_fuel_amount / config.fuel_per_unit))) then return false end
            turtle.refuel()
        end
    end
    return true
end

if not state.turtles.fuel then
    state.turtles.fuel = {}
end

function check_fuel()
    local fuel_level = turtle.getFuelLevel()
    local fuel_buffer = config.fuelbuffer
    local fuel_per_unit = config.fuel_per_unit
    local turtleID = os.getComputerID()

    -- Log the fuel level for this turtle
    if not state.turtles.fuel[turtleID] then
        state.turtles.fuel[turtleID] = {}
    end
    table.insert(state.turtles.fuel[turtleID], fuel_level)

    if fuel_level == "unlimited" or fuel_level >= fuel_buffer then
        return true -- Enough fuel, continue
    end

    -- Check if there is fuel in the inventory
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        if item and config.fuelnames[item.name] then
            local fuel_amount = config.fuelnames[item.name] * item.count
            turtle.select(i)
            turtle.refuel(item.count) -- Consume all fuel in the stack
            if turtle.getFuelLevel() >= fuel_buffer then
                return true -- Enough fuel, continue
            end
            -- Calculate how much fuel was consumed
            local consumed_fuel = fuel_amount - (config.fuelnames[item.name] * turtle.getItemCount(i))
            local required_fuel = fuel_buffer - turtle.getFuelLevel()
            local additional_fuel = math.ceil(required_fuel / fuel_per_unit) - consumed_fuel
            if additional_fuel > 0 then
                turtle.select(i)
                turtle.refuel(additional_fuel) -- Consume additional fuel to reach the buffer level
                return true -- Enough fuel, continue
            end
        end
    end

    -- No fuel found, return false to indicate that the turtle should head home
    return false
end
-- Call check_fuel before executing any actions
    if not check_fuel() then
    local home = config.home
    if not go(home) then
        print("Failed to return home")
    end
    return -- Stop executing actions
end

--current location of the turtle, target location, and a buffer for fuelbuffer
function FuelRequirement(current, target, fuelBuffer)
    -- Assuming current is a table with x, y, z keys or nil. If nil, use gps.locate()
    local currentX, currentY, currentZ
    if current then
        currentX, currentY, currentZ = current.x, current.y, current.z
    else
        currentX, currentY, currentZ = gps.locate()
    end

    -- Validate GPS location retrieval
    if not currentX or not currentY or not currentZ then
        error("GPS location could not be determined.")
    end

    -- Assuming target is a table with x, y, z keys
    local distanceToTarget = basics.Distance({x=currentX, y=currentY, z=currentZ}, {x=target.x, y=target.y, z=target.z})

    local totalFuelNeeded = distanceToTarget + fuelBuffer
    return totalFuelNeeded
end

--------
--------inout.lua

-- Main loop to receive and execute commands
while true do
    local senderID, message, protocol = rednet.receive()
    print("Received command: " .. message)

    -- Check if the message matches a task in minerTasks or chunkTasks
    if state.turtles.minerTasks[message] then
        executeTask(state.turtles.minerTasks[message])
    elseif state.turtles.chunkTasks[message] then
        executeTask(state.turtles.chunkTasks[message])
    else
        print("Unknown command: " .. message)
    end

    -- Send updated state information back to the hub computer
    rednet.send(senderID, textutils.serialize(state))  -- Serialize state and send it back


-- Function to execute a task
function executeTask(task)
    print("Starting task: " .. taskName)
    for functionName, functionCall in pairs(task) do
        print("Executing: " .. functionName)
        functionCall()
    end
end


------
------chico.lua
-- Define tasks for miner turtles
state.turtles.minerTasks = {
    go_mine = {
        prepare = function()
            print("Preparing to go to the mine...")
            local target = config.locations.mineEnter
            local Current = basics.Current(coordinates, facing)
            actions.prepare()
            actions.go_to(Current, target)
            print("Going to Entrance") -- Preparation steps here 
        end,
        mineshaft = function()
            print("Mining")
            actions.go_to(state.locations.mine)
            actions.mineshaft(config.mine_levels)
        end,
        strip = function()
            print("Cleaning up after mining...")
            actions.stripmine()

        end,
    },
    go_fish = {
        prepare = function()
            print("Preparing for fishing...")
            actions.prepare()
        end,
        execute = function()
            print("Going to fish...")
            actions.go_to(config.locations.fish)
            actions.fish()
        end,
        cleanup = function()
            print("Cleaning up after fishing...")
            actions.cleanup()
        end,
    },
}

-- Define tasks for chunk turtles
state.turtles.chunkTasks = {
    chunk_load = {
        prepare = function()
            print("Preparing for chunk loading...")
            actions.prepare()
        end,
        execute = function()
            print("Going to load chunks...")
            actions.go_to(config.locations.chunk)
            actions.load_chunks()
        end,
        cleanup = function()
            print("Cleaning up after chunk loading...")
            actions.cleanup()
        end,
    },
    chunk_unload = {
        prepare = function()
            print("Preparing for chunk unloading...")
            actions.prepare()
        end,
        execute = function()
            print("Going to unload chunks...")
            actions.go_to(config.locations.chunk)
            actions.unload_chunks()
        end,
        cleanup = function()
            print("Cleaning up after chunk unloading...")
            actions.cleanup()
        end,
    },
}

-- Execute all functions for each task in the minerTasks table
print("Executing Miner Tasks")
for taskName, task in pairs(state.turtles.minerTasks) do
    print("Starting task: " .. taskName)
    for functionName, functionCall in pairs(task) do
        print("Executing: " .. functionName)
        functionCall()
    end
end

-- Execute all functions for each task in the chunkTasks table
print("Executing Chunk Tasks")
for taskName, task in pairs(state.chunkTasks) do
    print("Starting task: " .. taskName)
    for functionName, functionCall in pairs(task) do
        print("Executing: " .. functionName)
        functionCall()
    end
end

-----
------
------config.lua
inf = 1e309
config = {}
-- LOCATION OF THE CENTER OF THE MINE
--     the y value should be set to the height
--     1 above the surface:
--
--            Y
--     ####### #######
--     ####### #######


max_attempts = 5

dig_enabled = true

attack_enabled = true

locations = {
    home = {x = 104, y = 76, z = 215}, --set where you want to dig 
    refuel = {x = 104, y = 76, z = 215}, --set to fuel chest
    vault = {x = 104, y = 76, z = 215}, --set to item drop
    mineEnter = {x = 104, y = 75, z = 215}, --one block below home
    mineExit = {x = 104, y = 76, z = 214}, 
    homeArea = {min_x = state.start.X - 10,  max_x = state.start.X + 10, --location where turtle sleeps,
                min_y = state.start.Y, min_z = state.start.Z - 10,      --gets fuel and dumps items
                max_y = state.start.Y + 10, max_z = state.start.Z + 10} --near the mine entrance and hub computer
    
}
mission_length = 200 --max amount of blocks to move in a mission
fuelbuffer = 10 --extra fuel to keep in the tank


mine_levels = {
    -- LEVELS INCLUDED IN THE MINE
    --     turtles will pick randomly with weight
    --     between each listed level.
    -- Level chances should sum to 1.0
    -- e.g.
    {level = 63, chance = 1.0},}

    dig_disallow = {
    'computer',
    'chest',
    'chair',}

blocktags = {
    -- ALL BLOCKS WITH ONE OF THESE TAGS A TURTLE CONSIDERS ORE
    ['forge:ores'] = true,
    ['forge:ores/certus_quartz'] = true,
    ['c:ores'] = true,
    ['techreborn:ores'] = true,
    ['c:raw_ores'] = true,
    ['c:gems'] = true,}

orenames = {
    -- ALL THE BLOCKS A TURTLE CONSIDERS ORE
    ['BigReactors:YelloriteOre'] = true,
    ['bigreactors:oreyellorite'] = true,
    ['DraconicEvolution:draconiumDust'] = true,
    ['DraconicEvolution:draconiumOre'] = true,
    ['Forestry:apatite'] = true,
    ['Forestry:resources'] = true,
    ['IC2:blockOreCopper'] = true,
    ['IC2:blockOreLead'] = true,
    ['IC2:blockOreTin'] = true,
    ['IC2:blockOreUran'] = true,
    ['ic2:resource'] = true,
    ['ProjRed|Core:projectred.core.part'] = true,
    ['ProjRed|Exploration:projectred.exploration.ore'] = true,
    ['TConstruct:SearedBrick'] = true,
    ['ThermalFoundation:Ore'] = true,
    ['thermalfoundation:ore'] = true,
    ['thermalfoundation:ore_fluid'] = true,
    ['thaumcraft:ore_amber'] = true,
    ['minecraft:coal'] = true,
    ['minecraft:coal_ore'] = true,
    ['minecraft:diamond'] = true,
    ['minecraft:diamond_ore'] = true,
    ['minecraft:dye'] = true,
    ['minecraft:emerald'] = true,
    ['minecraft:emerald_ore'] = true,
    ['minecraft:gold_ore'] = true,
    ['minecraft:iron_ore'] = true,
    ['minecraft:lapis_ore'] = true,
    ['minecraft:redstone'] = true,
    ['minecraft:redstone_ore'] = true,
    ['galacticraftcore:basic_block_core'] = true,
    ['mekanism:oreblock'] = true,
    ['appliedenergistics2:quartz_ore'] = true}

gravitynames = {
    -- ALL BLOCKS AFFECTED BY GRAVITY
    ['minecraft:gravel'] = true,
    ['minecraft:sand'] = true,}

fuelnames = {
    -- ITEMS THE TURTLE CONSIDERS FUEL
    ['minecraft:coal'] = (80),
    ['minecraft:coal_block'] = (720),
    ['minecraft:charcoal'] = (80),
    ['minecraft:charcoal_block'] = (720),
    ['minecraft:lava_bucket'] = (1000),
    ['minecraft:blaze_rod'] = (120),}

fuel_per_unit = fuelnames[item]
