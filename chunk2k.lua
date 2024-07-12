-- Function to move the turtle forward a specified number of steps
local function moveForward(steps)
    for i = 1, steps do
        while not turtle.forward() do
            turtle.dig()
            turtle.attack()
        end
    end
end

-- Function to move the turtle to a specified Y coordinate
local function moveToY(targetY)
    local currentY = select(2, gps.locate(5))

    if currentY < targetY then
        while currentY < targetY do
            if not turtle.up() then
                turtle.digUp()
            else
                currentY = currentY + 1
            end
        end
    elseif currentY > targetY then
        while currentY > targetY do
            if not turtle.down() then
                turtle.digDown()
            else
                currentY = currentY - 1
            end
        end
    end
end

-- Main function
local function main()
    -- Get user input for target Y coordinate
    print("Enter the target Y coordinate:")
    local targetY = tonumber(read())

    -- Move to the specified Y coordinate
    moveToY(targetY)

    -- Define the side length of the square
    local sideLength = 2000

    -- Loop indefinitely
    while true do
        -- Move the turtle in a square
        for i = 1, 4 do
            moveForward(sideLength)
            turtle.turnRight()
        end
    end
end

-- Start the main function
main()
