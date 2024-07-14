-- Initialize Rednet
local modem = peripheral.find("modem") or error("No modem attached", 0)
modem.open()
rednet.open(modem)  -- Adjust the side based on your setup

-- INITIALIZE APIS
fs.copy('disk/Hank/state.lua', 'state.lua')
fs.copy('disk//Hank/rednet.lua', 'rednet.lua')
fs.copy('disk/Hank/dummy.lua', 'dummy.lua')
os.loadAPI('rednet.lua')
os.loadAPI('state.lua')
os.loadAPI('dummys.lua')



-- LAUNCH PROGRAMS AS SEPARATE THREADS
multishell.launch({}, '/rednet.lua')
multishell.launch({}, '/dummy.lua')
multishell.setTitle(1, 'Rednet')
multishell.setTitle(2, 'Dummymine')