-- Get arguments.
modemSide = "back"
sendProtocol = "follow_master"
locationInfoPerSecond = 50

-- Open modem
rednet.open(modemSide)

if rednet.isOpen(modemSide) then
  print("[*] Modem is ready, broadcasting location...")

  while true do
    -- Broadcast own location.
    x,y,z = gps.locate()
    message = table.concat({tostring(x), tostring(y), tostring(z)}, " ")

    print(message)
    rednet.broadcast(message, sendProtocol)

    sleep(1 / locationInfoPerSecond)
  end
end

rednet.close(modemSide)