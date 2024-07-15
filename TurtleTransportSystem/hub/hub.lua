-- Initialize Rednet
local modem = peripheral.find("modem") or error("No modem attached", 0)
modem.open()
rednet.open(modem)  -- Adjust the side based on your setup

-- Display received messages
while true do
    local senderID, message, protocol = rednet.receive("turtle_hub")
    
    -- Example: Display received data
    print("Received from Turtle ID:", senderID)
    print("Message:", message)
    print("Protocol:", protocol)
    
    -- Handle different types of messages if needed
    -- Example: Display coordinates
    if protocol == "coords" then
        print("Coordinates:", message.x, message.y, message.z)
    end
    
    -- Add more handling for other message types (state, fuel, inventory, etc.)
    
    -- Add user interaction or additional functionality as required
end