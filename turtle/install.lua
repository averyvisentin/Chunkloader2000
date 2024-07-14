local diskPath = 'disk/turtle/'
local apiPath = '/apis/'

-- Ensure /apis/ exists and copy necessary files
if fs.exists(apiPath) then
    fs.delete(apiPath)
end
fs.makeDir(apiPath)

-- Copy API files
local function copyFile(source, destination)
    if fs.exists(source) then
        fs.copy(source, destination)
        print('Copied ' .. source .. ' to ' .. destination)
    else
        print('Error: ' .. source .. ' not found.')
    end
end

copyFile(diskPath .. 'state.lua', apiPath .. 'state.lua')
copyFile(diskPath .. 'basics.lua', apiPath .. 'basics.lua')
copyFile(diskPath .. 'actions.lua', apiPath .. 'actions.lua')
copyFile(diskPath .. 'config.lua', apiPath .. 'config.lua')
copyFile(diskPath .. 'rednet.lua', apiPath .. 'inout.lua')
copyFile(diskPath .. 'startup.lua', apiPath .. 'startup.lua')
copyFile(diskPath .. 'chico.lua', apiPath .. 'chico.lua')

