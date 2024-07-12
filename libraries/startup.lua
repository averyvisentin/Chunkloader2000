-- SET LABEL according to peripheral
for _, side in ipairs(peripheral.getNames()) do
    if peripheral.getType(side) == "chunk_vial" or "chunkloader" or "chunkvial" or "chunk" then
        os.setComputerLabel('ChunkTurtle ' .. os.getComputerID())
    else
    if peripheral.getType(side) == "pickaxe" then
        os.setComputerLabel('MinerTurtle ' .. os.getComputerID())
    end
    end
end

-- INITIALIZE APIS
if fs.exists('/apis') then
    fs.delete('/apis')
end
fs.makeDir('/apis')
fs.copy('/state.lua', '/apis/state')
fs.copy('/basics.lua', '/apis/basics')
fs.copy('/actions.lua', '/apis/actions')
os.loadAPI('/apis/actions')
os.loadAPI('/apis/state')
os.loadAPI('/apis/basics')


--Open rednet
for _, side in ipairs(peripheral.getNames()) do
    if peripheral.getType(side) == "modem" then
        rednet.open(side)
        break
    end
end

function StartPosition(coords, facing)
    local startX, startY, startZ = gps.locate(5)
    local file = fs.open("/location.txt", "w")
    if facing then
        file.writeLine("Start Position: " .. startX .. ", " .. startY .. ", " .. startZ .. ", Facing: " .. facing)
    else
        file.writeLine("Start Position: " .. startX .. ", " .. startY .. ", " .. startZ)
    end
    file.close()
    if facing then
        return startX .. ',' .. startY .. ',' .. startZ .. ':' .. facing
    else
        return startX .. ',' .. startY .. ',' .. startZ
    end
end


-- LAUNCH PROGRAMS AS SEPARATE THREADS
--multishell.launch({}, '/report.lua')
--multishell.launch({}, '/receive.lua')
---multishell.setTitle(1, 'report')
--multishell.setTitle(2, 'receive')