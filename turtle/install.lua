
if fs.exists('/apis') then
    fs.delete('/apis')
end
fs.makeDir('/apis')
fs.copy('/turtle/state.lua', '/apis/state')
fs.copy('/turtle/basics.lua', '/apis/basics')
fs.copy('/turtle/actions.lua', '/apis/actions')
fs.copy('/turtle/config.lua', '/apis/config')
fs.copy('/turtle/rednet.lua', '/apis/inout')
fs.copy('/turtle/startup.lua', '/apis/startup')
fs.copy('/turtle/chico.lua', '/apis/chico')
