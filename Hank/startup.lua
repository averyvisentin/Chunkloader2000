-- Initialize Rednet
local modem = peripheral.find("modem") or error("No modem attached", 0)
modem.open()
rednet.open(modem)  -- Adjust the side based on your setup

-- INITIALIZE APIS
if fs.exists('/apis') then
    fs.delete('/apis')
end
fs.makeDir('/apis')
fs.copy('disk/Hank/state.lua', '/apis/state')
fs.copy('disk//Hank/rednet.lua', '/apis/rednet')
fs.copy('disk/Hank/dummy.lua', '/apis/dummy')
os.loadAPI('/apis/rednet')
os.loadAPI('/apis/state')
os.loadAPI('/apis/dummys')



-- LAUNCH PROGRAMS AS SEPARATE THREADS
multishell.launch({}, '/rednet.lua')
multishell.launch({}, '/dummy.lua')
multishell.setTitle(1, 'Rednet')
multishell.setTitle(2, 'Dummymine')