-- Import the necessary APIs
os.loadAPI("actions")
os.loadAPI("basics")

-- Variables
local scanner = peripheral.find("scanner")
local radius = 10
local patrolCenter = {x = 0, y = 0, z = 0}
local stepSize = 1

-- Function to get user input for patrol center and radius
local function getUserInput()
    print("Enter the patrol center coordinates (x y z):")
    patrolCenter.x = tonumber(read())
    patrolCenter.y = tonumber(read())
    patrolCenter.z = tonumber(read())
    
    print("Enter the patrol radius:")
    radius = tonumber(read())
end

-- Function to scan for entities and attack until dead
local function scanAndAttack()
    local entities = scanner.scan()
    for _, entity in ipairs(entities) do
        if entity.type == "Player" or entity.type == "Hostile" then
            print("Entity detected: " .. entity.name)
            while true do
                local entitiesCheck = scanner.scan()
                local entityFound = false
                for _, e in ipairs(entitiesCheck) do
                    if e.name == entity.name then
                        entityFound = true
                        break
                    end
                end
                if not entityFound then
                    break
                end
                Attack()
            end
            print("Entity " .. entity.name .. " defeated")
        end
    end
end

-- Function to patrol in a square around the center point
local function patrol()
    for x = patrolCenter.x - radius, patrolCenter.x + radius, stepSize do
        for z = patrolCenter.z - radius, patrolCenter.z + radius, stepSize do
            Go_to(x, patrolCenter.y, z)
            scanAndAttack()
            
        end
    end
end


-- Main function
local function main()
    getUserInput()
    while true do
        patrol()
    end
end

-- Run the main function
main()
