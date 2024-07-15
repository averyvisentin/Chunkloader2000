require("state")

local config = {
    locations = {
        vault = { x = 0, y = 0, z = 0 },    --chest for item grabbing
        refuel = { x = 10, y = 0, z = 0 },  --chest for refueling
        home = { x = 0, y = 0, z = 10 }},   --chest for dumping
        fuelnames = {
            -- ITEMS THE TURTLE CONSIDERS FUEL
            ['minecraft:coal'] = 80,
            ['minecraft:coal_block'] = 720,
            ['minecraft:charcoal'] = 80,
            ['minecraft:charcoal_block'] = 720,
            ['minecraft:lava_bucket'] = 1000,
            ['minecraft:blaze_rod'] = 120},
        
        fuel_per_unit = fuelnames[item]
        }
        -- Initialize rednet and start listening for commands
rednet.open() -- Adjust based on your setup
-- Define global tables
Bumps = {
    north = { 0,  0, -1},
    south = { 0,  0,  1},
    east  = { 1,  0,  0},
    west  = {-1,  0,  0},
}

Left_shift = {
    north = 'west', south = 'east',
    east  = 'north', west  = 'south',
}

Right_shift = {
    north = 'east', south = 'west',
    east  = 'south', west  = 'north',
}

Reverse_shift = {
    north = 'south', south = 'north',
    east  = 'west', west  = 'east',
}

Move = {
    forward = turtle.forward, up = turtle.up,
    down = turtle.down, back = turtle.back,
    left = turtle.turnLeft, right = turtle.turnRight
}

Detect = {
    forward = turtle.detect, up = turtle.detectUp,
    down = turtle.detectDown
}

Inspect = {
    forward = turtle.inspect, up = turtle.inspectUp,
    down = turtle.inspectDown
}

Dig = {
    forward = turtle.dig, up = turtle.digUp,
    down = turtle.digDown
}

Attack = {
    forward = turtle.attack, up = turtle.attackUp,
    down = turtle.attackDown
}


        function Check_fuel(state)
            local fuel_level = turtle.getFuelLevel()
            local fuel_buffer = config.fuelBuffer
            local fuel_per_unit = config.fuel_per_unit
        
            if not state.turtles.log.fuel[turtleID] then
                state.turtles.log.fuel[turtleID] = {}
            end
        
            table.insert(state.turtles.log.fuel[turtleID], fuel_level)
        
            if fuel_level == "unlimited" or fuel_level >= fuel_buffer then
                return true
            end
        
            for i = 1, 16 do
                local item = turtle.getItemDetail(i)
                if item and config.fuelnames[item.name] then
                    local fuel_amount = config.fuelnames[item.name] * item.count
                    turtle.select(i)
                    turtle.refuel(item.count)
                    if turtle.getFuelLevel() >= fuel_buffer then
                        return true
                    end
                    local consumed_fuel = fuel_amount - (config.fuelnames[item.name] * turtle.getItemCount(i))
                    local required_fuel = fuel_buffer - turtle.getFuelLevel()
                    local additional_fuel = math.ceil(required_fuel / fuel_per_unit) - consumed_fuel
                    if additional_fuel > 0 then
                        turtle.select(i)
                        turtle.refuel(additional_fuel)
                        return true
                    end
                end
            end
            return false
        end



function Prepare(min_fuel_amount, state)
    if not state.turtles.log.fuel then
        state.turtles.log.fuel = {}
    end
    
    -- Check if turtle has any items to deposit
    if state.item_count > 0 then
        if not Go_to(config.locations.vault) then
            return false
        end
    end
    
    -- Calculate minimum fuel amount required
    local min_fuel_amount = min_fuel_amount + config.fuelBuffer
    
    -- Go to refuel location
    if not Go_to(config.locations.refuel) then
        return false
    end
    
    -- Go to home location
    if not Go_to(config.locations.home) then
        return false
    end
    
    -- Refuel until minimum fuel amount is reached
    turtle.select(1)
    if turtle.getFuelLevel() ~= 'unlimited' then
        while turtle.getFuelLevel() < min_fuel_amount do
            local fuel_to_suck = math.min(64, math.ceil(min_fuel_amount / config.fuel_per_unit))
            if not turtle.suck(fuel_to_suck) then
                return false
            end
            turtle.refuel()
        end
    end
    
    -- Check fuel level again before proceeding with actions
    if not Check_fuel() then
        local home = config.locations.home
        if not Go_to(home) then
            print("Failed to return home")
        end
        return false -- Stop executing actions
    end
    
    return true
end

function FuelRequirement(current, target, fuelBuffer)
    -- Assuming current is a table with x, y, z keys or nil. If nil, use gps.locate()
    local currentX, currentY, currentZ = Locate()
    if current then
        currentX, currentY, currentZ = current.x, current.y, current.z
    end

    -- Validate GPS location retrieval
    if not currentX or not currentY or not currentZ then
        error("GPS location could not be determined.")
    end

    -- Assuming target is a table with x, y, z keys
    local distanceToTarget = Distance({x=currentX, y=currentY, z=currentZ}, {x=target.x, y=target.y, z=target.z})

    local totalFuelNeeded = distanceToTarget + fuelBuffer
    return totalFuelNeeded
end

function Get_direction(current, target) -- get the direction
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

function Get_neighbors(node) --a* function
    local neighbors = {}
    for _, dir in ipairs({'up', 'down', 'north', 'south', 'east', 'west'}) do
        -- Assume check_block has been modified to return isOre directly
        local isOre, blockLocation = Check_block(dir)
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

function Lowest_f_score(open_set, f_score)   --a* function
    local lowest, best_node = math.huge, nil
    for _, node in ipairs(open_set) do
        local f = f_score[node.x .. ',' .. node.y .. ',' .. node.z] or math.huge
        if f < lowest then
            lowest, best_node = f, node
        end    end    return best_node
end

function Reconstruct_path(came_from, current)   --a* function
    local path = {current}
    while came_from[current.x .. ',' .. current.y .. ',' .. current.z] do
        current = came_from[current.x .. ',' .. current.y .. ',' .. current.z]
        table.insert(path, 1, current)
    end    return path
end


-- Cache for storing calculated paths
local pathCache = {}

function A_star(start, goal)
    -- Check if path is already calculated and cached
    local startKey = start.x .. ',' .. start.y .. ',' .. start.z
    local goalKey = goal.x .. ',' .. goal.y .. ',' .. goal.z
    if pathCache[startKey] and pathCache[startKey][goalKey] then
        return pathCache[startKey][goalKey]
    end

    local heuristic = Distance(start, goal)
    local open_set = {start}
    local came_from = {}
    local g_score = {[startKey] = 0}
    local f_score = {[startKey] = heuristic(start, goal)}

    while #open_set > 0 do
        local current = Lowest_f_score(open_set, f_score)
        if current.x == goal.x and current.y == goal.y and current.z == goal.z then
            local path = Reconstruct_path(came_from, current)

            -- Cache the path
            pathCache[startKey] = pathCache[startKey] or {}
            pathCache[startKey][goalKey] = path

            return path
        end

        for i, node in ipairs(open_set) do
            if node.x == current.x and node.y == current.y and node.z == current.z then
                table.remove(open_set, i)
                break
            end
        end

        for _, neighbor in ipairs(Get_neighbors(current)) do
            local neighborKey = neighbor.x .. ',' .. neighbor.y .. ',' .. neighbor.z
            local tentative_g_score = g_score[startKey] + 1
            if tentative_g_score < (g_score[neighborKey] or math.huge) then
                came_from[neighborKey] = current
                g_score[neighborKey] = tentative_g_score
                f_score[neighborKey] = tentative_g_score + heuristic(neighbor, goal)
                
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

    print("No path found from " .. start.x .. "," .. start.y .. "," .. start.z .. " to " .. goal.x .. "," .. goal.y .. "," .. goal.z)
    return nil -- No path found
end


function Try_move(direction)
    if direction == 'up' or direction == 'down' then
        return Move[direction]()
    else
        Face(direction)
        return Move.forward()
    end
end

function Handle_obstacle(direction)
    if Detect[direction] and Detect[direction]() then
        Dig[direction]()
        return true
    elseif Attack[direction] then
        Attack[direction]()
        return true
    end
    return false
end

-- Add logging for key events and errors
function logError(message)
    local file = fs.open("error_log", "a")
    if file then
        file.writeLine(os.date("[%Y-%m-%d %H:%M:%S] ") .. message)
        file.close()
    end
end


function Go_to(target)  -- Go to a target location using A* pathfinding
    local current = Current()
    local path = A_star(current, target)
    local max_attempts = 5 -- Assuming max_attempts is defined here

    if not path then
        print("No path found to target")
        return false
    end
    inout.SavePath(path) -- Save the path to a file
    local i = 2 -- Start from 2 as 1 is the current position
    while i <= #path do
        local target = path[i]
        local direction = Get_direction(current, target)
        local attempts = 0
        while not In_location(current, target) and attempts < max_attempts do
            if Try_move(direction) then
                current = UpdatePosition(direction)
                i = i + 1 -- Move to the next position in the path
                break -- Exit the while loop since the move was successful
            else
                attempts = attempts + 1
                if not Handle_obstacle(direction) or attempts >= max_attempts then
                    -- Recalculate path from the current position if obstacle handling fails or max attempts reached
                    path = A_star(current, target)
                    if not path then
                        print("Failed to find a new path to target")
                        return false
                    end
                    i = 2 -- Reset path index to start from the new current position
                end            end        end
        if attempts >= max_attempts then
            Print("Failed to reach next position after " .. max_attempts .. " attempts")
            return false
        end    end    return In_location(current, target)
end


function Try_move(direction)    -- try to move in a direction
    if direction == 'up' or direction == 'down' then
        return move[direction]()    else
        Face(direction)
        return move.forward()    end
end

function Handle_obstacle(direction)   -- handle an obstacle
    if dig_enabled and Detect[direction] and Detect[direction]() then
        Dig[direction]()
        return true
    elseif attack_enabled and Attack[direction] then
        Attack[direction]()
        return true
    end
    return false
end


function Start(coordinates, facing, state) -- Function to set the absolute starting position
    -- Initialize the start sub-table if it doesn't exist
    state.start = state.start or {}
    gps.locate(0.1)
    if coordinates then
        -- Unpack coordinates directly into state.start
        state.start.X, state.start.Y, state.start.Z = table.unpack(coordinates)
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
function Locate(xyz)
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

function Current(coordinates, facing, state)
    if coordinates then
        state.location = {
            X = coordinates.x,
            Y = coordinates.y,
            Z = coordinates.z,
            facing = facing
        }
        saveState()
    else
        local file = fs.open("state", "r")
        if file then
            local serializedState = file.readAll()
            file.close()
            state = textutils.unserialize(serializedState)
        else
            print("Error: Could not open state file for reading")
            return nil
        end
    end

    if state.location then
        local facingStr = state.location.facing and (":" .. state.location.facing) or ""
        return string.format("%d,%d,%d%s", state.location.X, state.location.Y, state.location.Z, facingStr)
    else
        return nil
    end
end

function UpdatePosition(direction, state)
    if state.location then
        if direction == 'up' then
            state.location.Y = state.location.Y + 1
        elseif direction == 'down' then
            state.location.Y = state.location.Y - 1
        elseif direction == 'forward' then
            local bump = Bumps[state.orientation]
            state.location.X = state.location.X + bump[1]
            state.location.Y = state.location.Y + bump[2]
            state.location.Z = state.location.Z + bump[3]
        elseif direction == 'back' then
            local bump = Bumps[state.orientation]
            state.location.X = state.location.X - bump[1]
            state.location.Y = state.location.Y - bump[2]
            state.location.Z = state.location.Z - bump[3]
        elseif direction == 'left' then
            state.orientation = Left_shift[state.orientation]
        elseif direction == 'right' then
            state.orientation = Right_shift[state.orientation]
        else
            print("Invalid direction: " .. direction)
            return nil
        end
        saveState()
        return state.location
    else
        print("Error: state.location is not set")
        return nil
    end
end

function saveState(state) --save the state to a file
    local file = fs.open("state", "w")
    if file then
        file.write(textutils.serialize(state))
        file.close()
    else
        print("Error: Could not open state file for writing")
    end
end


function Log_movement(direction, state) --adjust location and orientation based on movement
    if direction == 'up' then --so y plus is upvalue
        state.location.y = state.location.y + 1
    elseif direction == 'down' then
        state.location.y = state.location.y - 1
    elseif direction == 'forward' then
        bump = Bumps[state.orientation]
        state.location = {x = state.location.x + bump[1], y = state.location.y + bump[2], z = state.location.z + bump[3]}
    elseif direction == 'back' then
        bump = Bumps[state.orientation]
        state.location = {x = state.location.x - bump[1], y = state.location.y - bump[2], z = state.location.z - bump[3]}
    elseif direction == 'left' then
        state.orientation = left_shift[state.orientation]
    elseif direction == 'right' then
        state.orientation = right_shift[state.orientation]
    end
    broadcastAndLogGPS(direction)
    return true
end

function In_location(xyzo, location, state) --checks if xyzo is in a location     
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

function Calibrate(state)
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
    local nx, ny, nz = Locate()
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
    Log_movement(direction)
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

function TransferItems()
    local maxItems = 16 -- Assuming inventory slots from 1 to 16
    local freeSlots = 0
    
    -- Count free inventory slots
    for slot = 1, 16 do
        if turtle.getItemCount(slot) == 0 then
            freeSlots = freeSlots + 1
        end
    end
    
    -- If there are free slots, transfer items from vault to fill them
    if freeSlots > 0 then
        -- Go to the vault location
        if not Go_to(config.locations.vault) then
            logError("Failed to go to vault location for item transfer")
            return false
        end
        
        -- Transfer items from vault to turtle
        for slot = 1, 16 do
            turtle.select(slot)
            local itemDetail = turtle.getItemDetail(slot)
            if itemDetail and itemDetail.name ~= "minecraft:air" then
                local itemCount = turtle.getItemCount(slot)
                local spaceLeft = maxItems - freeSlots
                
                if spaceLeft > 0 then
                    turtle.suck(math.min(itemCount, spaceLeft))
                end
            end
        end
        
        -- Return to home location after transferring items
        if not Go_to(config.locations.home) then
            logError("Failed to return to home location after item transfer")
            return false
        end
    end
    
    -- Drop excess items back into the vault if there are still items left in the turtle
    if turtle.getItemCount(16) > 0 then
        turtle.drop(16)
    end
    
    -- Select the first slot after item transfer
    turtle.select(1)
    return true
end


function listenForCommands()
    while true do
        local senderId, message, protocol = rednet.receive("command_protocol")
        if senderId and message then
            local command, args = string.match(message, "(%w+):?(.*)")
            if command == "go_to" then
                local x, y, z = string.match(args, "(%-?%d+),(%-?%d+),(%-?%d+)")
                if x and y and z then
                    Go_to({x = tonumber(x), y = tonumber(y), z = tonumber(z)})
                else
                    logError("Invalid coordinates received: " .. args)
                end
            elseif command == "transfer_items" then
                TransferItems()
            else
                logError("Unknown command received: " .. message)
            end
        else
            logError("Error receiving command")
        end
    end
end


-- Main loop
while true do
    -- Check for incoming Rednet messages
    local senderID, message, protocol = rednet.receive()

    if message then
        -- Parse the message and determine the action
        if message.action == "moveTo" then
            local destination = message.destination
            if Go_to(destination) then
                print("Arrived at destination: " .. textutils.serialize(destination))
            else
                logError("Failed to move to destination: " .. textutils.serialize(destination))
            end
        elseif message.action == "collectItems" then
            if Go_to(message.location) then
                turtle.suckUp()
                print("Collected items from location: " .. textutils.serialize(message.location))
            else
                logError("Failed to collect items from location: " .. textutils.serialize(message.location))
            end
        elseif message.action == "returnHome" then
            if Go_to(home) then
                print("Returned to home.")
            else
                logError("Failed to return to home.")
            end
        elseif message.action == "transferItems" then
            if TransferItems() then
                print("Transferred items successfully.")
            else
                logError("Failed to transfer items.")
            end
        elseif message.action == "refuel" then
            if turtle.getFuelLevel() < config.refuelLevel then
                turtle.select(1) -- Assume fuel is in slot 1
                turtle.refuel(1)
                print("Turtle refueled.")
            else
                print("Fuel level is sufficient.")
            end
        else
            logError("Unknown action: " .. tostring(message.action))
        end
    end

    -- Optional: Perform regular maintenance tasks, like refueling or dumping items
    if turtle.getFuelLevel() < config.lowFuelThreshold then
        if Go_to(vault) then
            turtle.select(1) -- Assume fuel is in slot 1
            turtle.refuel(1)
            print("Turtle refueled.")
        else
            logError("Failed to go to vault for refueling.")
        end
    end

    -- Optional: Add a delay to avoid high CPU usage
    sleep(1)
end