-- Import required modules
basics = require("/apis/basics")
config = require("/apis/config")
actions = require("/apis/actions")
state = require("/apis/state")
inout = require("/apis/inout")
-- Define tasks for miner turtles
state.turtles.minerTasks = {
    go_mine = {
        prepare = function()
            print("Preparing to go to the mine...")
            local target = config.locations.mineEnter
            local Current = basics.Current(coordinates, facing)
            actions.prepare()
            actions.go_to(Current, target)
            print("Going to Entrance") -- Preparation steps here 
        end,
        mineshaft = function()
            print("Mining")
            actions.go_to(state.locations.mine)
            actions.mineshaft(config.mine_levels)
        end,
        strip = function()
            print("Cleaning up after mining...")
            actions.stripmine()

        end,
    },
    go_fish = {
        prepare = function()
            print("Preparing for fishing...")
            actions.prepare()
        end,
        execute = function()
            print("Going to fish...")
            actions.go_to(config.locations.fish)
            actions.fish()
        end,
        cleanup = function()
            print("Cleaning up after fishing...")
            actions.cleanup()
        end,
    },
}

-- Define tasks for chunk turtles
state.turtles.chunkTasks = {
    chunk_load = {
        prepare = function()
            print("Preparing for chunk loading...")
            actions.prepare()
        end,
        execute = function()
            print("Going to load chunks...")
            actions.go_to(config.locations.chunk)
            actions.load_chunks()
        end,
        cleanup = function()
            print("Cleaning up after chunk loading...")
            actions.cleanup()
        end,
    },
    chunk_unload = {
        prepare = function()
            print("Preparing for chunk unloading...")
            actions.prepare()
        end,
        execute = function()
            print("Going to unload chunks...")
            actions.go_to(config.locations.chunk)
            actions.unload_chunks()
        end,
        cleanup = function()
            print("Cleaning up after chunk unloading...")
            actions.cleanup()
        end,
    },
}

-- Execute all functions for each task in the minerTasks table
print("Executing Miner Tasks")
for taskName, task in pairs(state.turtles.minerTasks) do
    print("Starting task: " .. taskName)
    for functionName, functionCall in pairs(task) do
        print("Executing: " .. functionName)
        functionCall()
    end
end

-- Execute all functions for each task in the chunkTasks table
print("Executing Chunk Tasks")
for taskName, task in pairs(state.chunkTasks) do
    print("Starting task: " .. taskName)
    for functionName, functionCall in pairs(task) do
        print("Executing: " .. functionName)
        functionCall()
    end
end

--{we want a main loop of this script to update current location and log movement using
---functions from basics.lua, 
