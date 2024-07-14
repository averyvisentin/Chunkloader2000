


-- Open rednet on any available modem
for _, side in ipairs(peripheral.getNames()) do
    if peripheral.getType(side) == "modem" then
        rednet.open(side)
        break
    end
end

-- Set label according to the peripheral
local isChunkTurtle = false
for _, side in ipairs(peripheral.getNames()) do
    local peripheralType = peripheral.getType(side)
    if peripheralType == "chunk_vial" or peripheralType == "chunkloader" or peripheralType == "chunkvial" or peripheralType == "chunk" then
        os.setComputerLabel('ChunkTurtle ' .. os.getComputerID())
        isChunkTurtle = true
        break
    end
end

if not isChunkTurtle then
    os.setComputerLabel('MinerTurtle ' .. os.getComputerID())
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


-- Function to log turtle locations and states
function logTurtleState(minerId, chunkTurtleId)
    if not state.turtles then
        state.turtles = {}
    end
    state.turtles[minerTurtleId] = { type = "MinerTurtle", pair = chunkTurtleId, location = { x = 0, y = 0, z = 0 } }
    state.turtles[chunkTurtleId] = { type = "ChunkTurtle", pair = minerTurtleId, location = { x = 0, y = 0, z = 0 } }
    state.save()  -- Ensure to save the state to persist the data
end

-- Enhanced function to log turtle pairs with additional context
function logTurtlePair(minerId, chunkId)
    if not state.turtles then
        state.turtles = {pairs = {}}
    end
    -- Create a unique pair identifier, combining both turtle IDs
    pairId = "Pair_" .. minerId .. "_" .. chunkId
    -- Log the pair with additional details
    state.turtles.pairs[pairId] = {
        minerId = minerId,
        chunkId = chunkId,
        pairedOn = os.date("%Y-%m-%d %H:%M:%S"), -- Log the current date and time
        minerLocation = {x = 0, y = 0, z = 0}, -- Initial location, assuming starting at origin
        chunkLocation = {x = 0, y = 0, z = 0}  -- Same for chunk turtle
    }
    state.save() -- Assuming a function to save the state persistently
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

-- INITIALIZE APIS
if fs.exists('/apis') then
    fs.delete('/apis')
end
fs.makeDir('/apis')
fs.copy('disk/turtle/state.lua', '/apis/state')
fs.copy('disk/turtle/basics.lua', '/apis/basics')
fs.copy('disk/turtle/actions.lua', '/apis/actions')
fs.copy('disk/turtle/config.lua', '/apis/config')
fs.copy('disk/turtle/rednet.lua', '/apis/inout')
os.loadAPI('/apis/basics')
os.loadAPI('/apis/state')
os.loadAPI('/apis/actions')
os.loadAPI('/apis/config')
os.loadAPI('/apis/inout')



-- LAUNCH PROGRAMS AS SEPARATE THREADS
multishell.launch({}, '/inout.lua')
multishell.launch({}, '/chico.lua')
multishell.setTitle(1, 'inout')
multishell.setTitle(2, 'Chico')