local ITER = 10
local TORCH_DIST = 13

local MINE_BLOCKS = {
  ["minecraft:gold_ore"]=true,
  ["minecraft:iron_ore"]=true,
  ["minecraft:coal_ore"]=true,
  ["minecraft:redstone_ore"]=true,
  ["minecraft:emerald_ore"]=true
}

local REPORT_BLOCKS = {
  ["minecraft:diamond_ore"]=true,
  ["minecraft:lapis_ore"]=true
}

local FILL_BLOCK = "minecraft:cobblestone"

local Dir = {
  Front = 0,
  Back = 1,
  Left = 2,
  Right = 3,
  Up = 4,
  Down = 5
}

local logFile = fs.open("mine.log", "w")

local function log(content)
  logFile.writeLine(content)
  logFile.flush()
end

local function myVec(depth, dir)
  return {depth=depth, dir=dir}
end

local function alignDir(dir, depth, track)
  if (dir == Dir.Left) then
    turtle.turnLeft()
    table.insert(track, myVec(depth, Dir.Left))
  elseif (dir == Dir.Right) then
    turtle.turnRight()
    table.insert(track, myVec(depth, Dir.Right))
  elseif (dir == Dir.Back) then
    turtle.turnRight()
    turtle.turnRight()
    table.insert(track, myVec(depth, Dir.Right))
    table.insert(track, myVec(depth, Dir.Right))
  end
end

local function undoAlignDir(depth, track)
  while (#track > 0 and track[#track].depth == depth) do
    local vec = table.remove(track)
    if (vec.dir == Dir.Left) then
      turtle.turnRight()
    elseif (vec.dir == Dir.Right) then
      turtle.turnLeft()
    end
  end
end

local function isMine(hasBlock, blockInfo)
  if (hasBlock and REPORT_BLOCKS[blockInfo.name]) then
    log("found " .. blockInfo.name)
  end
  return hasBlock and MINE_BLOCKS[blockInfo.name]
end

local function inspectDirIsMine(dir)
  local hasBlock, blockInfo
  if (dir == Dir.Up) then
    hasBlock, blockInfo = turtle.inspectUp()
  elseif (dir == Dir.Down) then
    hasBlock, blockInfo = turtle.inspectDown()
  else
    hasBlock, blockInfo = turtle.inspect()
  end

  return isMine(hasBlock, blockInfo)
end

local function excavateDir(dir, depth, track)
  if (dir == Dir.Up) then
    turtle.digUp()
    turtle.up()
    table.insert(track, myVec(depth, Dir.Up))
  elseif (dir == Dir.Down) then
    turtle.digDown()
    turtle.down()
    table.insert(track, myVec(depth, Dir.Down))
  else
    local counter = 0
    repeat
      turtle.dig()
      counter = counter + 1
    until turtle.forward()
    table.insert(track, myVec(depth, Dir.Front))
    if counter > 1 then
      log("WARNING: encountered gravity block during DFS")
    end
  end
end

local function selectFillBlock()
  for i = 1, 16 do
    local info = turtle.getItemDetail(i)
    if info and info.name == FILL_BLOCK then
      turtle.select(i)
      return
    end
  end
  log("WARNING: not enough blocks to fill in")
end

local function backtrack(currentDepth, targetDepth, moveTrack, turnTrack)
  while (currentDepth ~= targetDepth) do
    while (#moveTrack > 0 and moveTrack[#moveTrack].depth == currentDepth - 1) do
      local vec = table.remove(moveTrack)
      if (vec.dir == Dir.Front) then
        turtle.back()
        selectFillBlock()
        turtle.place()
      elseif (vec.dir == Dir.Up) then
        turtle.down()
        selectFillBlock()
        turtle.placeUp()
      elseif (vec.dir == Dir.Down) then
        turtle.up()
        selectFillBlock()
        turtle.placeDown()
      end
    end
    undoAlignDir(currentDepth - 1, turnTrack)
    currentDepth = currentDepth - 1
  end
end

local function dfs(initDir)
  local stack = {}
  local turnTrack = {}
  local moveTrack = {}
  local depth = 0
  table.insert(stack, myVec(depth, initDir))

  while (#stack > 0) do
    local vec = table.remove(stack)
    backtrack(depth, vec.depth, moveTrack, turnTrack)
    depth = vec.depth

    alignDir(vec.dir, depth, turnTrack)

    if (inspectDirIsMine(vec.dir)) then
      excavateDir(vec.dir, depth, moveTrack)
      depth = depth + 1

      if isMine(turtle.inspect()) then
        table.insert(stack, myVec(depth, Dir.Front))
      end

      if isMine(turtle.inspectUp()) then
        table.insert(stack, myVec(depth, Dir.Up))
      end
      if isMine(turtle.inspectDown()) then
        table.insert(stack, myVec(depth, Dir.Down))
      end
      turtle.turnRight()
      if isMine(turtle.inspect()) then
        table.insert(stack, myVec(depth, Dir.Right))
      end
      turtle.turnRight()
      if isMine(turtle.inspect()) then
        table.insert(stack, myVec(depth, Dir.Back))
      end
      turtle.turnRight()
      if isMine(turtle.inspect()) then
        table.insert(stack, myVec(depth, Dir.Left))
      end
      turtle.turnRight()
    else
      undoAlignDir(depth, turnTrack)
    end
  end

  backtrack(depth, 0, moveTrack, turnTrack)
end

local function triggerDfs(dir)
  if inspectDirIsMine(dir) then
    dfs(dir)
  end
end

local function inspectAround()
  turtle.turnRight()
  triggerDfs(Dir.Front)

  turtle.turnLeft()
  triggerDfs(Dir.Up)

  turtle.turnLeft()
  triggerDfs(Dir.Front)

  turtle.down()
  triggerDfs(Dir.Front)

  turtle.turnRight()
  triggerDfs(Dir.Down)

  turtle.turnRight()
  triggerDfs(Dir.Front)

  turtle.turnLeft()
  turtle.up()
end

local function advance()
  repeat
    turtle.dig()
  until turtle.forward()
  turtle.digDown()
end

log("I'm minning!")

advance()
inspectAround()
turtle.select(1)
turtle.placeDown()

for i = 1, ITER do
  for j = 1, TORCH_DIST do
    advance()
    inspectAround()
  end
  turtle.select(1)
  turtle.placeDown()
end

logFile.close()

turtle.turnRight()
turtle.turnRight()
for i = 1, ITER * TORCH_DIST do
  turtle.forward()
end
