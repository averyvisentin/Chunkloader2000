-- Main loop to listen for commands
while true do
    local senderId, message, protocol = rednet.receive("command_protocol")

    if message then
        local action, params = string.match(message, "^(%a+):(.+)$")
        
        if action == "moveTo" then
            local x, y, z = params:match("(%d+),(%d+),(%d+)")
            local destination = { x = tonumber(x), y = tonumber(y), z = tonumber(z) }

            if Go_to(destination) then
                print("Turtle #" .. os.getComputerID() .. " arrived at destination: " .. textutils.serialize(destination))
            else
                logError("Turtle #" .. os.getComputerID() .. " failed to move to destination: " .. textutils.serialize(destination))
            end
        elseif action == "collectItems" then
            local location = { x = tonumber(x), y = tonumber(y), z = tonumber(z) }  -- Example: Parse location from params
            if Go_to(location) then
                turtle.suckUp()
                print("Turtle #" .. os.getComputerID() .. " collected items from location: " .. textutils.serialize(location))
            else
                logError("Turtle #" .. os.getComputerID() .. " failed to collect items from location: " .. textutils.serialize(location))
            end
        elseif action == "returnHome" then
            if Go_to(home) then
                print("Turtle #" .. os.getComputerID() .. " returned to home.")
            else
                logError("Turtle #" .. os.getComputerID() .. " failed to return to home.")
            end
        elseif action == "transferItems" then
            if TransferItems() then
                print("Turtle #" .. os.getComputerID() .. " transferred items successfully.")
            else
                logError("Turtle #" .. os.getComputerID() .. " failed to transfer items.")
            end
        elseif action == "refuel" then
            if turtle.getFuelLevel() < config.refuelLevel then
                turtle.select(1) -- Assume fuel is in slot 1
                turtle.refuel(1)
                print("Turtle #" .. os.getComputerID() .. " refueled.")
            else
                print("Turtle #" .. os.getComputerID() .. " fuel level is sufficient.")
            end
        else
            logError("Turtle #" .. os.getComputerID() .. " received unknown action: " .. tostring(action))
        end
    end
end
