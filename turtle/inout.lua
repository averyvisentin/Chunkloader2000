log = require("turtle.log")

-- Main loop to receive and execute commands
while true do
    local senderID, message, protocol = rednet.receive()
    print("Received command: " .. message)

    -- Check if the message matches a task in minerTasks or chunkTasks
    if log.turtles.minerTasks[message] then
        executeTask(log.turtles.minerTasks[message])
    elseif log.turtles.chunkTasks[message] then
        executeTask(log.turtles.chunkTasks[message])
    else
        print("Unknown command: " .. message)
    end

-- Function to execute a task
local function executeTask(task)
    print("Starting task: " .. taskName)
    for functionName, functionCall in pairs(task) do
        print("Executing: " .. functionName)
        functionCall()
    end
end

-- Configuration
local BROADCAST_INTERVAL = 1 -- Time in seconds between broadcasts
local HUB_ID = config.hub_ID -- The ID of the hub computer

-- Function to continuously broadcast and log GPS location
function broadcastAndLogGPS(direction)
    -- Define the log file name
    local logFileName = "gps_log.txt"
    -- Get current GPS coordinates
    local x, y, z = gps.locate()
    if x and y and z then
        -- Broadcast the coordinates
        local turtleID = os.getComputerID()
        local gpsData = {id = turtleID, x = x, y = y, z = z, direction = direction}
        rednet.broadcast(gpsData, "gps")
        -- Log the coordinates to a file
        local logFile = fs.open(logFileName, "a")
        if logFile then
            logFile.writeLine(textutils.serialize(gpsData))
            logFile.close()
        else
            print("Error: Unable to open log file.")
        end
        -- Print to terminal (for debugging purposes)
        print("Broadcasting GPS coordinates:", gpsData)
    else
        print("Error: Unable to locate GPS signal.")
    end
    -- Wait for a short duration before the next broadcast
    sleep(0.5)
end

-- Start the broadcasting and logging function
broadcastAndLogGPS()

    -- Send updated log information back to the hub computer
    rednet.send(senderID, textutils.serialize(log))  -- Serialize log and send it back
end

local HUB_ID = 1 -- Set your hub computer ID
FILE_CHANNEL = "100"

function SavePath(path)
    rednet.send(HUB_ID, {command = "save_path", data = path}, FILE_CHANNEL)
    local id, message = rednet.receive(FILE_CHANNEL)
    if message.status == "path_saved" then
        print("Path successfully saved to hub.")
    else
        print("Error saving path to hub:", message.error)
    end
end

function RecallPath(index)
    rednet.send(HUB_ID, {command = "recall_path", data = index}, FILE_CHANNEL)
    local id, message = rednet.receive(FILE_CHANNEL)
    if message.status == "path_retrieved" then
        print("Path successfully retrieved from hub.")
        return message.path
    else
        print("Error retrieving path from hub:", message.error)
        return nil
    end
end
