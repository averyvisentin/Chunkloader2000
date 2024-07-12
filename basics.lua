inf = 1e309

bumps = {               
    north = { 0,  0, -1},
    south = { 0,  0,  1},
    east  = { 1,  0,  0},
    west  = {-1,  0,  0},
}

left_shift = {
    north = 'west',
    south = 'east',
    east  = 'north',
    west  = 'south',
}

right_shift = {
    north = 'east',
    south = 'west',
    east  = 'south',
    west  = 'north',
}

reverse_shift = {
    north = 'south',
    south = 'north',
    east  = 'west',
    west  = 'east',
}

function dprint(thing) --debug print
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

function str_xyz(coords, facing) --converts coordinates to string, with facing if wanted or needed
    if facing then                                  --good for logging
        return coords.x .. ',' .. coords.y .. ',' .. coords.z .. ':' .. facing
    else
        return coords.x .. ',' .. coords.y .. ',' .. coords.z
    end
end

function distance(point_1, point_2)             --manahttan distance, pathfinding
    return math.abs(point_1.x - point_2.x)
         + math.abs(point_1.y - point_2.y)
         + math.abs(point_1.z - point_2.z)
end

function in_area(xyz, area) --checks if xyz is in an area, defined by a table with min and max xyz
    return xyz.x <= area.max_x and xyz.x >= area.min_x and xyz.y <= area.max_y and xyz.y >= area.min_y and xyz.z <= area.max_z and xyz.z >= area.min_z
end

function in_location(xyzo, location)            --checks if xyzo matches a specific location (from a config file or something)
    for _, axis in pairs({'x', 'y', 'z'}) do    --iterates over x, y, z and checks if point coordinates match those specified
        if location[axis] then                  --in the location table
            if location[axis] ~= xyzo[axis] then
                return false
            end
        end
    end
    return true
end

