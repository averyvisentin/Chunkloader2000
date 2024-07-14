
if fs.exists('/apis') then
    fs.delete('/apis')
end
fs.makeDir('/apis')
fs.copy('/disk/turtle/state.lua', '/apis/state')
fs.copy('/disk/turtle/basics.lua', '/apis/basics')
fs.copy('/disk/turtle/actions.lua', '/apis/actions')
fs.copy('/disk/turtle/config.lua', '/apis/config')
fs.copy('/disk/turtle/rednet.lua', '/apis/inout')
fs.copy('/disk/turtle/startup.lua', '/apis/startup')
fs.copy('/disk/turtle/chico.lua', '/apis/chico')
