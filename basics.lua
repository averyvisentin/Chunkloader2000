
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

function NewPos(facing)--update location file with new position
    local cx, cy, cz = gps.locate(1) -- 1 second1 timeout
    local posStr = facing and string.format("%d,%d,%d:%s", cx, cy, cz, facing) or string.format("%d,%d,%d", cx, cy, cz)
    local file = fs.open("location.txt", "a")
    if file then
        file.writeLine("Pos: " .. posStr)
        file.close()
    end
        return posStr
end

function Current() --read location file and return current position
    local file = io.open("location.txt", "r")
    local content = file:read("*all")
    file:close()
    local x, y, z, facing = content:match("(%d+),(%d+),(%d+):?(%w*)$")
    local position = {x = tonumber(x), y = tonumber(y), z = tonumber(z)}
    if facing and facing ~= "" then
        position.facing = facing
    end
    return position -- Corrected to return the actual position
end

function In_location(xyzo, Pos)            --checks if xyzo matches a specific location (from a config file)
    for _, axis in pairs({'x', 'y', 'z'}) do    --iterates over x, y, z and checks if point coordinates match those specified
        if Pos[axis] then                  --in the location table
            if Pos[axis] ~= xyzo[axis] then
                return false
            end
        end
    end
    return true
end


function In_area(xyz, area) --checks if xyz is in an area, defined by a table with min and max xyz
    return xyz.x <= area.max_x and xyz.x >= area.min_x and xyz.y <= area.max_y and xyz.y >= area.min_y and xyz.z <= area.max_z and xyz.z >= area.min_z
end

function D3(point1, point2)
    local dx = point2.x - point1.x
    local dy = point2.y - point1.y
    local dz = point2.z - point1.z
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

function D2(point1, point2)
    local dx = point2.x - point1.x
    local dy = point2.y - point1.y
    return math.sqrt(dx*dx + dy*dy)
end
-- Module export
local basics = {
    NewPos = NewPos
    , D3 = D3
    , Bumps = Bumps
    , D2 = D2
    , Current = Current
    , In_location = In_location
    , In_area = In_area
}

return basics