--Open rednet
for _, side in ipairs(peripheral.getNames()) do
    if peripheral.getType(side) == "modem" then
        rednet.open(side)
        break
    end
end


-- SET LABEL according to peripheral
for _, side in ipairs(peripheral.getNames()) do
    if peripheral.getType(side) == "chunk_vial" or "chunkloader" or "chunkvial" or "chunk" then
        os.setComputerLabel('ChunkTurtle ' .. os.getComputerID())
    else
    if peripheral.getType(side) == "modem" then
        os.setComputerLabel('MinerTurtle ' .. os.getComputerID())
    end
    end
end

-- INITIALIZE APIS
if fs.exists('/apis') then
    fs.delete('/apis')
end
fs.makeDir('/apis')
fs.copy('disk/state.lua', '/apis/state')
fs.copy('disk/basics.lua', '/apis/basics')
fs.copy('disk/actions.lua', '/apis/actions')
os.loadAPI('/apis/basics')
os.loadAPI('/apis/state')
os.loadAPI('/apis/actions')



-- LAUNCH PROGRAMS AS SEPARATE THREADS
--multishell.launch({}, '/report.lua')
--multishell.launch({}, '/receive.lua')
---multishell.setTitle(1, 'report')
--multishell.setTitle(2, 'receive')