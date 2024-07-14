--we bad at this
basics = require("basics.lua")
config = require("config.lua")
state = require("state.lua")
actions = {}


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

function actions.Get_direction(current, target) -- get the direction
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

function actions.Get_neighbors(node) --a* function
    local neighbors = {}
    for _, dir in ipairs({'up', 'down', 'north', 'south', 'east', 'west'}) do
        -- Assume check_block has been modified to return isOre directly
        local isOre, blockLocation = actions.Check_block(dir)
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

function actions.Lowest_f_score(open_set, f_score)   --a* function
    local lowest, best_node = math.huge, nil
    for _, node in ipairs(open_set) do
        local f = f_score[node.x .. ',' .. node.y .. ',' .. node.z] or math.huge
        if f < lowest then
            lowest, best_node = f, node
        end    end    return best_node
end

function actions.Reconstruct_path(came_from, current)   --a* function
    local path = {current}
    while came_from[current.x .. ',' .. current.y .. ',' .. current.z] do
        current = came_from[current.x .. ',' .. current.y .. ',' .. current.z]
        table.insert(path, 1, current)
    end    return path
end



function actions.A_star(start, goal)    -- A* pathfinding algorithm
    local heuristic = Distance(start, goal)
    local open_set = {start}
    local came_from = {}
    local g_score = {[start.x .. ',' .. start.y .. ',' .. start.z] = 0}
    local f_score = {[start.x .. ',' .. start.y .. ',' .. start.z] = heuristic(start, goal)}

    while #open_set > 0 do
        local current = actions.Lowest_f_score(open_set, f_score)
        if current.x == goal.x and current.y == goal.y and current.z == goal.z then
            return actions.Reconstruct_path(came_from, current)
        end

        for i, node in ipairs(open_set) do
            if node.x == current.x and node.y == current.y and node.z == current.z then
                table.remove(open_set, i)
                break
            end
        end

        for _, neighbor in ipairs(actions.Get_neighbors(current)) do
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

function actions.Go_to(target)  -- Go to a target location using A* pathfinding
    local current = basics.Current()
    local path = actions.A_star(current, target)
    local max_attempts = 5 -- Assuming max_attempts is defined here

    if not path then
        print("No path found to target")
        return false
    end
    inout.SavePath(path) -- Save the path to a file
    local i = 2 -- Start from 2 as 1 is the current position
    while i <= #path do
        local target = path[i]
        local direction = actions.Get_direction(current, target)
        local attempts = 0
        while not basics.In_location(current, target) and attempts < max_attempts do
            if actions.Try_move(direction) then
                current = basics.UpdatePosition(direction)
                i = i + 1 -- Move to the next position in the path
                break -- Exit the while loop since the move was successful
            else
                attempts = attempts + 1
                if not actions.Handle_obstacle(direction) or attempts >= max_attempts then
                    -- Recalculate path from the current position if obstacle handling fails or max attempts reached
                    path = actions.A_star(current, target)
                    if not path then
                        print("Failed to find a new path to target")
                        return false
                    end
                    i = 2 -- Reset path index to start from the new current position
                end            end        end
        if attempts >= max_attempts then
            Print("Failed to reach next position after " .. max_attempts .. " attempts")
            return false
        end    end    return basics.In_location(current, target)
end


function actions.Try_move(direction)    -- try to move in a direction
    if direction == 'up' or direction == 'down' then
        return move[direction]()    else
        actions.Face(direction)
        return move.forward()    end
end

function actions.Handle_obstacle(direction)   -- handle an obstacle
    if dig_enabled and Detect[direction] and Detect[direction]() then
        Dig[direction]()
        return true
    elseif attack_enabled and Attack[direction] then
        Attack[direction]()
        return true
    end
    return false
end

-- Unified function to handle block checking, ore detection, tags checking, and updating blocktable
function actions.Check_block(direction)
    local actions.Detect_ore(direction)   -- Detect ore in a specific direction
        local success, block = turtle.inspect(direction)
        if success then
            return config.oretags[block.name] 
            return local actions.Detect_ore(direction) or false
        end
        return nil
    end
    local location = basics.Locate()
    if not location then
        print("Error: Unable to locate GPS signal.")
        return false
    end

    local success, block = turtle.inspect(direction)
    if success then
        local isOre = local actions.Detect_ore(direction)
        local hasValidTag = actions.Check_tags(block)
        
        -- Update blocktable
        table.insert(blocktable, {
            name = block.name,
            isOre = isOre,
            location = location,
            turtleID = os.getComputerID()
        })

        -- Update state with relevant information (example with block name)
        state.updateState("lastInspectedBlock", block.name)

        -- Send block data (example)
        sendBlockData({
            name = block.name,
            isOre = isOre,
            location = location,
            turtleID = os.getComputerID()
        })

        return isOre, location -- Return isOre and location
    end
    return false
end


function actions.Scan(valid, ores)
    local directions = {'forward', 'up', 'down'}
    -- Use the state's current orientation to determine the initial direction
    local current_direction = state.orientation
    -- Check vertical directions first
    for _, direction in ipairs(directions) do
        local isOre, location = actions.Check_block(direction)
        -- Update valid and ores tables based on the result
        if isOre ~= nil then -- Only update if check_block returned a result
            if isOre then
                ores[location] = true
            else
                valid[location] = true
            end   end    end
    -- Initialize checked_directions table
    local checked_directions = {}
    checked_directions[current_direction] = true
    -- Check horizontal directions by turning the turtle
    for _ = 1, 4 do
        turtle.turnRight()
        current_direction = right_shift[current_direction] -- Update current direction based on right shift
        if not checked_directions[current_direction] then
            checked_directions[current_direction] = true
            actions.Check_block('forward')
            actions.Check_block('up')
            actions.Check_block('down')
            local isOre, location = actions.Check_block(direction)
            -- Update valid and ores tables based on the result
            if isOre ~= nil then -- Only update if check_block returned a result
                if isOre then
                    ores[location] = true
                else
                    valid[location] = true
                end            end        end    end
end

function actions.Go(direction)  
    if not face(direction) then
        return false end
    if detect[direction]() then
        Dig[direction]()
    return Move[direction]() end
    if not Move[direction]() then
    return false end
    Log_movement(direction)
    return true
end
-- Unified function to face a specific orientation or compass direction
function actions.Face(target_orientation)
    while state.orientation ~= target_orientation do
        if right_shift[state.orientation] == target_orientation then
            go('right')
        elseif left_shift[state.orientation] == target_orientation then
            go('left')
        elseif right_shift[right_shift[state.orientation]] == target_orientation then
            go('right')
            go('right')
        elseif left_shift[left_shift[state.orientation]] == target_orientation then
            go('left')
            go('left')
        else
            return false -- If the target orientation is invalid
        end
        state.orientation = right_shift[state.orientation] -- Update the state after each turn
    end
    basics.Log_movement(target_orientation)
    return true
end

function actions.Go_to_XYZ(axis, coordinate)
    local delta = coordinate - state.location[axis]
    if delta == 0 then
        return true end
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
        end end
    for i = 1, math.abs(delta) do
        if axis == 'y' then
            if delta > 0 then
                if not go('up') then return false end
            else
                if not go('down') then return false end
            end
        else
            if not go('forward') then return false end
        end end return true
end

function actions.Mineshaft()
    local yLevel = config.mine_levels[math.random(#config.mine_levels)]
    local target = {x = 0, y = yLevel, z = 0}
    local ores = {config.blocktags}
    state.locations.mine = state.locations.mine or {}

    -- Check if the mineshaft has been completed by verifying the end point
    if state.locations.mine.endPoint then
        print("Mineshaft already completed. Proceeding to grid mining.")
        return actions.Gridmine()
    end

    -- Set target to the last known block of the mine if available
    if state.locations.mine.lastBlock then
        target = state.locations.mine.lastBlock
    end

    if actions.Go(target) then
        local isOre, location = actions.Check_block()
        if isOre ~= nil then
            if isOre then
                ores[location] = true
                dig()
            else
                valid[location] = true
                dig()
            end

            -- Update state.locations.mine with the last block broken coordinates
            state.locations.mine.lastBlock = {x = state.location.x, y = state.location.y, z = state.location.z}
            
            -- Log the end point once the mineshaft is complete
            if target == {x = 0, y = yLevel, z = 0} then
                state.locations.mine.endPoint = target
            end

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


function actions.Stripmine(yLevel)
    local width, length = config.mission_length, config.mission_length
    local ores = {config.blocktags}
    local valid = {}
    state.locations.strip = state.locations.strip or {}

    -- Check if the stripmine has been completed by verifying the end point
    if state.locations.strip.endPoint then
        print("Stripmine already completed. Proceeding to grid mining.")
        return actions.Gridmine()
    end

    -- Set target to the last known block of the strip if available
    if state.locations.strip.lastBlock then
        target = state.locations.strip.lastBlock
    end
    
    for x = 0, width - 1 do
        for z = 0, length - 1 do
            local target = {x = x, y = yLevel, z = z}
            if actions.Go(target) then
                local isOre, location = actions.Check_block()
                if isOre ~= nil then
                    if isOre then
                        ores[location] = true
                        dig()
                    else
                        valid[location] = true
                        dig()
                    end
                    state.locations.strip.lastBlock = {x = state.location.x, y = state.location.y, z = state.location.z}
                    -- Log the end point once the stripmine is complete
                    if x == width - 1 and z == length - 1 then
                        state.locations.strip.endPoint = target
                    end

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




-- Function to perform grid mining
function actions.Gridmine()
    local radius = config.mission_length
    local startY = config.mine_levels[math.random(#config.mine_levels)]
    local startX, startZ = 0, 0 -- Starting from the mineshaft center
    local ores = {}
    local valid = {}

    -- Move to the starting Y level
    actions.Go({x = startX, y = startY, z = startZ})

    for x = -radius, radius do
        if x % 2 == 0 then
            for z = -radius, radius do
                local target = {x = x, y = startY, z = z}
                if actions.Go(target) then
                    local isOre, location = actions.Check_block()  -- Check the block at the current location
                    if isOre ~= nil then
                        if isOre then
                            ores[location] = true
                            dig()  -- Example: dig the ore block
                        else
                            valid[location] = true
                            dig()
                        end
                        log_and_save("grid", ores, valid)
                    end
                end
            end
        else
            for z = radius, -radius, -1 do
                local target = {x = x, y = startY, z = z}
                if actions.Go(target) then
                    local isOre, location = actions.Check_block()  -- Check the block at the current location
                    if isOre ~= nil then
                        if isOre then
                            ores[location] = true
                            dig()  -- Example: dig the ore block
                        else
                            valid[location] = true
                            dig()
                        end
                        log_and_save("grid", ores, valid)
                    end
                end
            end
        end
        -- Move to the next row
        if x < radius then
            turtle.turnRight()
            turtle.forward()
            turtle.turnRight()
        end
    end
end


function actions.Follow() --chunk follow mine
    local chunkTurtleID = os.getComputerID()
    local minerTurtleID = state.turtles[chunkTurtleID].pair 
    local minerLocation = state.turtles[minerTurtleID].location
    local chunkLocation = state.turtles[chunkTurtleID].location
    local distance = basics.Distance(minerLocation, chunkLocation)
    local maxDistance = 10 -- Maximum distance to maintain between turtles
    local maxAttempts = 5 -- Maximum attempts to reach the miner turtle
    local attempts = 0 -- Initialize attempts counter
    while distance > maxDistance and attempts < maxAttempts do
        local path = Actions.A_star(chunkLocation, minerLocation)
        if path then
            for _, pos in ipairs(path) do
                local direction = actions.Get_direction(chunkLocation, pos)
                if not actions.Go(direction) then
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

function actions.Prepare(min_fuel_amount)
    if not state.turtles.log.fuel then
        state.turtles.log.fuel = {}
    end
    if state.item_count > 0 then
        if not go_to(config.locations.vault) then return false end
    end
    local min_fuel_amount = min_fuel_amount + config.fuelBuffer
    if not Go_to(config.locations.refuel) then return false end
    if not Go_to(config.locations.home) then return false end
    turtle.select(1)
    if turtle.getFuelLevel() ~= 'unlimited' then
        while turtle.getFuelLevel() < min_fuel_amount do
            if not turtle.suck(math.min(64, math.ceil(min_fuel_amount / config.fuel_per_unit))) then return false end
            turtle.refuel()
        end
    end
    -- Call check_fuel before executing any actions
    if not actions.Check_fuel() then
        local home = config.locations.home
        if not Go_to(home) then
            print("Failed to return home")
        end
        return -- Stop executing actions
    end
    return true
end


function actions.Check_fuel()
    local fuel_level = turtle.getFuelLevel()
    local fuel_buffer = config.fuelbuffer
    local fuel_per_unit = config.fuel_per_unit
    local turtleID = os.getComputerID()
    -- Log the fuel level for this turtle
    if not state.turtles.log.fuel[turtleID] then
        state.turtles.log.fuel[turtleID] = {}
    end
    table.insert(state.turtles.log.fuel[turtleID], fuel_level)
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
            end        end    end
end

--current location of the turtle, target location, and a buffer for fuelbuffer
function actions.FuelRequirement(current, target, fuelBuffer)
    -- Assuming current is a table with x, y, z keys or nil. If nil, use gps.locate()
    local currentX, currentY, currentZ = basics.Locate()
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

return actions