-- Function to send a command to a turtle
function sendCommand(turtleId, command)
    rednet.send(turtleId, command, "command_protocol")
    print("Sent command to Turtle #" .. turtleId .. ": " .. command)
end

-- Example usage: Sending a command to move a turtle
local turtleId = 1  -- Replace with the actual ID of the turtle you want to command
local command = "moveTo:10,20,30"  -- Example command to move to coordinates (10, 20, 30)
sendCommand(turtleId, command)
