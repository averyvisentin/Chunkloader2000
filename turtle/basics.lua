
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
    while true do
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
end
