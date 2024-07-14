-- Initialize APIs

os.loadAPI('/apis/basics')
os.loadAPI('/apis/actions')
os.loadAPI('/apis/inout')
os.loadAPI('/apis/state')
os.loadAPI('/apis/config')
os.loadAPI('/apis/chico')

-- Open rednet on any available modem
for _, side in ipairs(peripheral.getNames()) do
    if peripheral.getType(side) == "modem" then
        rednet.open(side)
        break
    end
end

-- Function to announce availability
local function announceAvailability(role)
    if role == "MinerTurtle" then
        rednet.broadcast("MinerTurtleAvailable", "Pairing")
    else
        rednet.broadcast("ChunkTurtleAvailable", "Pairing")
    end
end

-- Function to wait for a pairing response
local function waitForPairing(role)
    while true do
        local senderId, message, protocol = rednet.receive("Pairing", 60)
        if protocol == "Pairing" then
            if role == "MinerTurtle" and message == "ChunkTurtleAvailable" then
                rednet.send(senderId, "PairingConfirmed", "Pairing")
                print("Paired with ChunkTurtle ID: " .. senderId)
                return senderId
            elseif role == "ChunkTurtle" and message == "MinerTurtleAvailable" then
                rednet.send(senderId, "ChunkTurtleAvailable", "Pairing")
                local confirmationId, confirmationMessage, confirmationProtocol = rednet.receive("Pairing", 60)
                if confirmationProtocol == "Pairing" and confirmationMessage == "PairingConfirmed" then
                    print("Paired with MinerTurtle ID: " .. senderId)
                    return senderId
                end
            end
        end
    end
end

-- Main pairing logic
if os.getComputerLabel():find("MinerTurtle") then
    announceAvailability("MinerTurtle")
    local chunkTurtleId = waitForPairing("MinerTurtle")
    print("MinerTurtle ID: " .. os.getComputerID() .. " paired with ChunkTurtle ID: " .. chunkTurtleId)
    logTurtleState(os.getComputerID(), chunkTurtleId)
else
    announceAvailability("ChunkTurtle")
    local minerTurtleId = waitForPairing("ChunkTurtle")
    print("ChunkTurtle ID: " .. os.getComputerID() .. " paired with MinerTurtle ID: " .. minerTurtleId)
    logTurtleState(minerTurtleId, os.getComputerID())
end

-- LAUNCH PROGRAMS AS SEPARATE THREADS
multishell.launch({}, '/inout.lua')
multishell.launch({}, '/chico.lua')
multishell.setTitle(1, 'inout')
multishell.setTitle(2, 'Chico')
