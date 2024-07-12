-- Initialize global variables
local currentLocation = nil
local targetLocation = {x = 0, y = 0, z = 0} -- Example target location

-- Function to update turtle's location
function updateLocation()
    local x, y, z = gps.locate(5)
    if not x then
        print("GPS location failed. Retrying...")
        return false
    else
        currentLocation = {x = x, y = y, z = z}
        return true
    end
end
if updateLocation() then
    print("Starting location: ", currentLocation.x, currentLocation.y, currentLocation.z)
-- Save the updated location to location.txt at the root of the filesystem
    saveLocationToFile("/location.txt")
else
    print("Failed to obtain starting location.")
end

-- Modified saveLocationToFile function with existence check
function saveLocationToFile(filename)
    local x, y, z = gps.locate(5)
    if not x then
        print("Failed to locate GPS signal.")
        return false
    else
        print("Current location: ", x, y, z)
        
        -- Check if the file exists, if not, it will be created in the write operation
        if not fs.exists(filename) then
            print(filename .. " does not exist, creating file.")
        end
        
        local file = fs.open(filename, "w")
        if not file then
            print("Failed to open file for writing.")
            return false
        end
        
        file.writeLine(string.format("%d,%d,%d", x, y, z))
        file.close()
        
        print("Location saved to " .. filename)
        return true
    end
end

-- Modified readLocationFromFile function with existence check
function readLocationFromFile(filename)
    -- Check if the file exists before attempting to read
    if not fs.exists(filename) then
        print(filename .. " does not exist.")
        return nil
    end
    
    local file = fs.open(filename, "r")
    if not file then
        print("Failed to open file for reading.")
        return nil
    end
    
    local line = file.readLine()
    file.close()
    
    if line then
        local x, y, z = line:match("^(%d+),(%d+),(%d+)$")
        if x and y and z then
            x, y, z = tonumber(x), tonumber(y), tonumber(z)
            print("Location read from file: ", x, y, z)
            return {x = x, y = y, z = z}
        else
            print("Failed to parse location data.")
            return nil
        end
    else
        print("Failed to read data from file.")
        return nil
    end
end

-- Example usage
local location = readLocationFromFile("location.txt")
if location then
    -- Use the location data
    print("Using location: ", location.x, location.y, location.z)
else
    print("Location data not available.")
end