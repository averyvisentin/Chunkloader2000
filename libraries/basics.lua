
Bumps = {               
    north = { 0,  0, -1},
    south = { 0,  0,  1},
    east  = { 1,  0,  0},
    west  = {-1,  0,  0},
}

Left_shift = {--turn left 90 degrees
    north = 'west',
    south = 'east',
    east  = 'north',
    west  = 'south',
}

Right_shift = {--turn right 90 degrees
    north = 'east',
    south = 'west',
    east  = 'south',
    west  = 'north',
}

Reverse_shift = {--180 degrees
    north = 'south',
    south = 'north',
    east  = 'west',
    west  = 'east',
}

local state = {}
local x, y, z = Current()

-- Function to set the starting position
function Start(coordinates, face)
    -- Initialize the start sub-table if it doesn't exist
    state.start = state.start or {}
    gps.locate(1)
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
        -- Serialize the entire state table and write it to the file
        local serializedState = textutils.serialize(state)
        file.write(serializedState)
        file.close()
    end
    
    -- Construct the return string using state.start.X, state.start.Y, state.start.Z
    if facing then
        return state.start.X .. ',' .. state.start.Y .. ',' .. state.start.Z .. ':' .. face
    else
        return state.start.X .. ',' .. state.start.Y .. ',' .. state.start.Z
    end
end

--function to get the current position
function Current(coordinates, face)
    if coordinates then
        -- Update state.location with new coordinates and facing direction
        local cx, cy, cz = table.unpack(coordinates)
        state.location = { X = cx, Y = cy, Z = cz, facing = face }
        -- Serialize and write state to file
        local file = fs.open("state", "w")
        if file then
            local serializedState = textutils.serialize(state)
            file.write(serializedState)
            file.close()
        end
    else
        -- Read and deserialize state from file
        local file = fs.open("state", "r")
        if file then
            local serializedState = file.readAll()
            file.close()
            state = textutils.unserialize(serializedState)
        else
            return nil -- Return nil if the file doesn't exist
        end
    end
    -- Format the position string
    if state.location then
        if state.location.facing then
            return string.format("%d,%d,%d:%s", state.location.X, state.location.Y, state.location.Z, state.location.facing)
        else
            return string.format("%d,%d,%d", state.location.X, state.location.Y, state.location.Z)
        end
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
        state.location.X = state.location.X + Bumps[direction].x
        state.location.Y = state.location.Y + Bumps[direction].y
        state.location.Z = state.location.Z + Bumps[direction].z
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


function In_location(xyzo)            --checks if xyzo matches the specific location stored in state.location
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
    return xyz.x <= area.max_x and xyz.x >= area.min_x and xyz.y <= area.max_y and xyz.y >= area.min_y and xyz.z <= area.max_z and xyz.z >= area.min_z
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

function Dprint(thing) --debug print
    -- PRINT; IF TABLE PRINT EACH ITEM
    if type(thing) == 'table' then 
        for k, v in pairs(thing) do
            print(tostring(k) .. ': ' .. tostring(v))
        end
    else      --otherwise it just prints
        print(thing)
    end
    return true
end


-- Module export
local basics = {
      Bumps = Bumps
    , distance = Distance
    , Current = Current
    , In_location = In_location
    , In_area = In_area
}

return basics
