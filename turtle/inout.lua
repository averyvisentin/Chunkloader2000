-- Load other scripts
local config = require("config")
local actions = require("actions")
local basics = require("basics")
local state = require("state")

-- Main loop to receive and execute commands
while true do
    local senderID, message, protocol = rednet.receive()
    print("Received command: " .. message)

    -- Check if the message matches a task in minerTasks or chunkTasks
    if state.turtles.minerTasks[message] then
        executeTask(state.turtles.minerTasks[message])
    elseif state.turtles.chunkTasks[message] then
        executeTask(state.turtles.chunkTasks[message])
    else
        print("Unknown command: " .. message)
    end

    -- Send updated state information back to the hub computer
    rednet.send(senderID, textutils.serialize(state))  -- Serialize state and send it back
end

-- Function to execute a task
function executeTask(task)
    print("Starting task: " .. taskName)
    for functionName, functionCall in pairs(task) do
        print("Executing: " .. functionName)
        functionCall()
    end
end
