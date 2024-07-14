-- Dummy.lua
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
        print("Enter turtle ID:")
        local turtleID = tonumber(read())
        print("Enter command:")
        local command = read()
        rednet.send(turtleID, command)
        print("Sent command '" .. command .. "' to turtle " .. turtleID)
    end
end

-- Run both functions in parallel
parallel.waitForAny(displayMessages, userInput)
