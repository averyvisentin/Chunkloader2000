
-- Load other scripts and modules
local config = require("config")
local actions = require("actions")
local basics = require("basics")
local state = require("state")

-- Function to execute a task
local function executeTask(task)
    print("Starting task: " .. taskName)
    for functionName, functionCall in pairs(task) do
        print("Executing: " .. functionName)
        functionCall()
    end
end

-- Function to handle incoming Rednet messages
local function handleRednetMessages()
    while true do
        local senderID, message, protocol = rednet.receive()

        -- Process the received message
        print("Received from turtle " .. senderID .. ": " .. message)
        
        -- Example: Check if message is a command to execute a task
        if state.turtles.minerTasks[message] then
            executeTask(state.turtles.minerTasks[message])
        elseif state.turtles.chunkTasks[message] then
            executeTask(state.turtles.chunkTasks[message])
        else
            print("Unknown command: " .. message)
        end

        -- Optionally, you can broadcast this message to other parts of your hub system
        os.queueEvent("rednet_message", senderID, message)
    end
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

-- Example usage of executing tasks defined in state tables
local function executeTasks(tasksTable)
    for taskName, task in pairs(tasksTable) do
        print("Starting task: " .. taskName)
        executeTask(task)
    end
end

-- Main function to coordinate actions based on state and incoming messages
local function main()
    -- Start handling incoming Rednet messages
    handleRednetMessages()

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