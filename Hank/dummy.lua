-- Initialize necessary variables
local FILE_CHANNEL = 100 -- Define a specific Rednet channel for file communication
local HUB_ID = 1 -- Set your hub computer ID
local paths = {} -- Table to store paths
local fileName = "paths.txt"
local gpsLogFileName = "gps_log.txt"

-- Function to display incoming messages
local function displayMessages()
    while true do
        local event, senderID, message = os.pullEvent("rednet_message")
        print("Turtle " .. senderID .. " says: " .. message)
    end
end

-- Function to allow user input for commands
local function userInput()
    while true do
        print("Options:")
        print("1. Send command to turtle")
        print("2. Ping turtle GPS")
        local choice = tonumber(read())
        
        if choice == 1 then
            print("Enter turtle ID:")
            local turtleID = tonumber(read())
            print("Enter command:")
            local command = read()
            rednet.send(turtleID, command)
            print("Sent command '" .. command .. "' to turtle " .. turtleID)
        elseif choice == 2 then
            print("Enter turtle ID to ping GPS:")
            local turtleID = tonumber(read())
            pingTurtleGPS(turtleID)
        else
            print("Invalid choice. Please try again.")
        end
    end
end

-- Function to save paths to file
local function savePathsToFile()
    local file = fs.open(fileName, "w")
    if file then
        file.write(textutils.serialize(paths))
        file.close()
        print("Paths saved to file.")
    else
        print("Error: Could not open file for writing.")
    end
end

-- Function to load paths from file
local function loadPathsFromFile()
    if fs.exists(fileName) then
        local file = fs.open(fileName, "r")
        if file then
            paths = textutils.unserialize(file.readAll())
            file.close()
            print("Paths loaded from file.")
        else
            print("Error: Could not open file for reading.")
        end
    else
        print("No existing path file found.")
    end
end

-- Function to save GPS log to file
local function logGPSToFile(id, coordinates)
    local file = fs.open(gpsLogFileName, "a")
    if file then
        local logEntry = "Turtle " .. id .. ": X=" .. coordinates.x .. " Y=" .. coordinates.y .. " Z=" .. coordinates.z
        file.writeLine(logEntry)
        file.close()
        print("Logged GPS coordinates to file: " .. logEntry)
    else
        print("Error: Could not open GPS log file for writing.")
    end
end

-- Function to handle incoming Rednet messages
local function handleMessage(id, message)
    local command, data = message.command, message.data

    if command == "save_path" then
        table.insert(paths, data)
        savePathsToFile()
        rednet.send(id, {status = "path_saved"})
    elseif command == "recall_path" then
        local index = data
        if paths[index] then
            rednet.send(id, {status = "path_retrieved", path = paths[index]})
        else
            rednet.send(id, {status = "error", error = "Path not found"})
        end
    elseif command == "gps_update" then
        logGPSToFile(id, data)
        print("Received GPS coordinates from turtle " .. id .. ": X=" .. data.x .. " Y=" .. data.y .. " Z=" .. data.z)
    elseif command == "gps_response" then
        print("Turtle " .. id .. " GPS coordinates: X=" .. data.x .. " Y=" .. data.y .. " Z=" .. data.z)
    else
        rednet.send(id, {status = "error", error = "Unknown command"})
    end
end

-- Function to ping the GPS coordinates of a turtle
local function pingTurtleGPS(turtleID)
    rednet.send(turtleID, {command = "request_gps"})
    print("Sent GPS request to turtle " .. turtleID)
end

-- Function to send commands to turtles
local function sendCommand(turtleID, command)
    rednet.send(turtleID, command)
    print("Sent command '" .. command .. "' to turtle " .. turtleID)
end

-- Example usage of sending commands
local function sendCommandsToTurtles(commandsTable)
    for turtleID, command in pairs(commandsTable) do
        sendCommand(turtleID, command)
    end
end

-- Function to execute a task
local function executeTask(task)
    for functionName, functionCall in pairs(task) do
        print("Executing: " .. functionName)
        functionCall()
    end
end

-- Example usage of executing tasks defined in state tables
local function executeTasks(tasksTable)
    for taskName, task in pairs(tasksTable) do
        print("Starting task: " .. taskName)
        executeTask(task)
    end
end

-- Main function to coordinate actions based on state and incoming messages
local function main()
    rednet.open("back") -- Open Rednet on the appropriate side
    loadPathsFromFile()

    -- Start handling incoming Rednet messages
    parallel.waitForAny(
        function()
            while true do
                local id, message = rednet.receive(FILE_CHANNEL)
                handleMessage(id, message)
            end
        end,
        displayMessages,
        userInput
    )

    -- Example usage of sending commands to turtles
    local turtleCommands = {
        [2] = "dropItems",
        [3] = "getFuel"
    }
    sendCommandsToTurtles(turtleCommands)

    -- Example usage of executing miner tasks
    print("Executing Miner Tasks")
    executeTasks(state.turtles.minerTasks)

    -- Example usage of executing chunk tasks
    print("Executing Chunk Tasks")
    executeTasks(state.turtles.chunkTasks)
end

-- Run the main function
main()
