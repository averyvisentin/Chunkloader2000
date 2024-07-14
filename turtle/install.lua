
if fs.exists('/apis') then
    fs.delete('/apis')
end
fs.makeDir('/apis')
fs.copy('state.lua', '/apis/state')
fs.copy('basics.lua', '/apis/basics')
fs.copy('actions.lua', '/apis/actions')
fs.copy('config.lua', '/apis/config')
fs.copy('rednet.lua', '/apis/inout')
fs.copy('startup.lua', '/apis/startup')
fs.copy('chico.lua', '/apis/chico')
