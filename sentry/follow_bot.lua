receiveProtocol = "follow_master"
fuelSlot = 16
fuelThreshold = 10

-- Util functions
function isEmpty(s)
  return (s == null or s == "")
end
function split(str)
  local chunks = {}
  for substring in str:gmatch("%S+") do
    table.insert(chunks, substring)
  end
  return chunks
end

-- Get arguments.
modemSide = ...
-- Default arguments, if not specified.
if isEmpty(modemSide) then
  modemSide = "right"
end

-- General turtle functions
function checkFuel()
  if turtle.getFuelLevel() <= fuelThreshold then
    turtle.select(fuelSlot)
    turtle.refuel(10)
  end
end

-- Open modem
rednet.open(modemSide)

if rednet.isOpen(modemSide) then
  print("[*] Modem is ready, waiting for master.")
  print("[*] My computer ID: " .. tostring(os.getComputerID()))
  
  while true do
    -- Refuel first if needed
    checkFuel()

    -- Get master's location
    senderId, message, protocol = rednet.receive(receiveProtocol)
    masterLocation = split(message)
    masterPos = vector.new(masterLocation[1], masterLocation[2], masterLocation[3])

    -- Get own location
    mePos = vector.new(gps.locate())

    -- Calculate the vector the path to master
    toMaster = masterPos - mePos

    -- Calculate coordinates, move accordingly
    toForward = (toMaster.x - (toMaster.x % 1))
    toUp = (toMaster.y - (toMaster.y % 1))
    toRight = (toMaster.z - (toMaster.z % 1))

    -- Move forward/backward (X axis)
    if (toForward > 1) or (toForward < -1) then
      if toForward >= 0 then
        turtle.forward()
      else
        turtle.back()
      end
    end

    -- Move up/down (Y axis)
    if (toUp > 1) or (toUp < -1) then
      if toUp >= 0 then
        turtle.up()
      else
        turtle.down()
      end
    end

    -- Move right/left (Z axis)
    -- Turns it's face always to East (Forward: +X, Up: +Y, Right: +Z)
    if (toRight > 1) or (toRight < -1) then
      if toRight >= 0 then
        turtle.turnRight()
        for i=1,toRight do
          turtle.forward()
        end
        turtle.turnLeft()
      else
        turtle.turnLeft()
        for i=toRight,0 do
          turtle.forward()
        end
        turtle.turnRight()
      end
    end

    -- break
  end
end