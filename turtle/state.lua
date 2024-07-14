local state = {
    start = {x = 0, y = 0, z = 0},
    location = {x = 0, y = 0, z = 0},
    locations = {
                    mine = {x = 0, y = 0, z = 0},
                    home = {x = 0, y = 0, z = 0},
                    strip = {x = 0, y = 0, z = 0},},
    orientation = {'north', 'east', 'south', 'west'},
    blocktable = {},
    turtles = {
                minerTasks = {},

                chunkTasks = {},
                fuel = {},
                -- New turtles logging structure
                log = {
                        ["turtle1"] = {
                        label = "Turtle 1",
                        id = 1,
                        xyz = {x = 0, y = 0, z = 0},
                        orientation = 'north',
                        fuel = 100,
            },
            -- Add more turtles as needed
        },
    },
}



