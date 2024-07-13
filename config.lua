inf = 1e309
local config = {}
-- LOCATION OF THE CENTER OF THE MINE
--     the y value should be set to the height
--     1 above the surface:
--
--            Y
--     ####### #######
--     ####### #######
config.mine_entrance = {x = 104, y = 76, z = 215}
me = mine_entrance
config.homeArea = {
    min_x = state.start.X - 5,
    max_x = state.start.X + 5,
    min_y = state.start.Y,
    max_y = state.start.Y + 5,
    min_z = state.start.Z - 5,
    max_z = state.start.Z + 5
}

config.locations = {
    refuel = {x = 104, y = 76, z = 215},
    dropoff = {x = 104, y = 76, z = 215},
    mineEnter = {x = 104, y = 76, z = 215},
    mineExit = {x = 104, y = 76, z = 215},
    homeArea = {min_x = state.start.X - 10,  max_x = state.start.X + 10,
                min_y = state.start.Y, min_z = state.start.Z - 10,
                max_y = state.start.Y + 10, max_z = state.start.Z + 10}
    
}

config.use_pairs = true
config.mission_length = 200 --max amount of blocks to move in a mission
config.fuelbuffer = 10 --extra fuel to keep in the tank


config.mine_levels = {
    -- LEVELS INCLUDED IN THE MINE
    --     turtles will pick randomly with weight
    --     between each listed level.
    -- Level chances should sum to 1.0
    -- e.g.
    {level = 63, chance = 1.0},}

config.dig_disallow = {
    'computer',
    'chest',
    'chair',}

config.blocktags = {
    -- ALL BLOCKS WITH ONE OF THESE TAGS A TURTLE CONSIDERS ORE
    ['forge:ores'] = true,
    ['forge:ores/certus_quartz'] = true,
    ['c:ores'] = true,
    ['techreborn:ores'] = true,
    ['c:raw_ores'] = true,
    ['c:gems'] = true,}

config.orenames = {
    -- ALL THE BLOCKS A TURTLE CONSIDERS ORE
    ['BigReactors:YelloriteOre'] = true,
    ['bigreactors:oreyellorite'] = true,
    ['DraconicEvolution:draconiumDust'] = true,
    ['DraconicEvolution:draconiumOre'] = true,
    ['Forestry:apatite'] = true,
    ['Forestry:resources'] = true,
    ['IC2:blockOreCopper'] = true,
    ['IC2:blockOreLead'] = true,
    ['IC2:blockOreTin'] = true,
    ['IC2:blockOreUran'] = true,
    ['ic2:resource'] = true,
    ['ProjRed|Core:projectred.core.part'] = true,
    ['ProjRed|Exploration:projectred.exploration.ore'] = true,
    ['TConstruct:SearedBrick'] = true,
    ['ThermalFoundation:Ore'] = true,
    ['thermalfoundation:ore'] = true,
    ['thermalfoundation:ore_fluid'] = true,
    ['thaumcraft:ore_amber'] = true,
    ['minecraft:coal'] = true,
    ['minecraft:coal_ore'] = true,
    ['minecraft:diamond'] = true,
    ['minecraft:diamond_ore'] = true,
    ['minecraft:dye'] = true,
    ['minecraft:emerald'] = true,
    ['minecraft:emerald_ore'] = true,
    ['minecraft:gold_ore'] = true,
    ['minecraft:iron_ore'] = true,
    ['minecraft:lapis_ore'] = true,
    ['minecraft:redstone'] = true,
    ['minecraft:redstone_ore'] = true,
    ['galacticraftcore:basic_block_core'] = true,
    ['mekanism:oreblock'] = true,
    ['appliedenergistics2:quartz_ore'] = true}

config.gravitynames = {
    -- ALL BLOCKS AFFECTED BY GRAVITY
    ['minecraft:gravel'] = true,
    ['minecraft:sand'] = true,}

config.fuelnames = {
    -- ITEMS THE TURTLE CONSIDERS FUEL
    ['minecraft:coal'] = (80),
    ['minecraft:coal_block'] = (720),
    ['minecraft:charcoal'] = (80),
    ['minecraft:charcoal_block'] = (720),
    ['minecraft:lava_bucket'] = (1000),
    ['minecraft:blaze_rod'] = (120),}

config.fuel_per_unit = config.fuelnames[item]()