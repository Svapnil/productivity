-- Copyright (c) 2016 Miro Mannino
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this
-- software and associated documentation files (the "Software"), to deal in the Software
-- without restriction, including without limitation the rights to use, copy, modify, merge,
-- publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
-- to whom the Software is furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all copies
-- or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
-- INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
-- PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
-- FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.

hs.window.animationDuration = 0

-- Use if using a normal aspect ratio
-- local sizes = {3, 2, 3/2}
-- Use if using an ultrawide aspect ratio
local sizes = {3, 2, 3/2}
local fullScreenSizes = {1, 4/3, 2}

local GRID = {w = 24, h = 24}
hs.grid.setGrid(GRID.w .. 'x' .. GRID.h)
hs.grid.MARGINX = 0
hs.grid.MARGINY = 0

local pressed = {
  up = false,
  down = false,
  left = false,
  right = false
}

local goDown = function ()
  pressed.down = true
  if pressed.up then 
    fullDimension('h')
  else
    nextStep('h', true, function (cell, nextSize)
      cell.y = GRID.h - GRID.h / nextSize
      cell.h = GRID.h / nextSize
    end)
  end
end

local finishDown = function () 
  pressed.down = false
end

local goUp = function ()
  pressed.up = true
  if pressed.down then 
      fullDimension('h')
  else
    nextStep('h', false, function (cell, nextSize)
      cell.y = 0
      cell.h = GRID.h / nextSize
    end)
  end
end

local finishUp = function () 
  pressed.up = false
end

local goRight = function ()
  pressed.right = true
  if pressed.left then 
    fullDimension('w')
  else
    nextStep('w', true, function (cell, nextSize)
      cell.x = GRID.w - GRID.w / nextSize
      cell.w = GRID.w / nextSize
    end)
  end
end

local finishRight = function () 
  pressed.right = false
end

local goLeft = function ()
  pressed.left = true
  if pressed.right then 
    fullDimension('w')
  else
    nextStep('w', false, function (cell, nextSize)
      cell.x = 0
      cell.w = GRID.w / nextSize
    end)
  end
end

local finishLeft = function () 
  pressed.left = false
end

function nextStep(dim, offs, cb)
  if hs.window.focusedWindow() then
    local axis = dim == 'w' and 'x' or 'y'
    local oppDim = dim == 'w' and 'h' or 'w'
    local oppAxis = dim == 'w' and 'y' or 'x'
    local win = hs.window.frontmostWindow()
    local id = win:id()
    local screen = win:screen()

    cell = hs.grid.get(win, screen)

    local nextSize = sizes[1]
    for i=1,#sizes do
      if cell[dim] == GRID[dim] / sizes[i] and
        (cell[axis] + (offs and cell[dim] or 0)) == (offs and GRID[dim] or 0)
        then
          nextSize = sizes[(i % #sizes) + 1]
        break
      end
    end

    cb(cell, nextSize)
    if cell[oppAxis] ~= 0 and cell[oppAxis] + cell[oppDim] ~= GRID[oppDim] then
      cell[oppDim] = GRID[oppDim]
      cell[oppAxis] = 0
    end

    hs.grid.set(win, cell, screen)
  end
end

function nextFullScreenStep()
  if hs.window.focusedWindow() then
    local win = hs.window.frontmostWindow()
    local id = win:id()
    local screen = win:screen()

    cell = hs.grid.get(win, screen)

    -- Go to the next smallest size
    -- BUG: Doesn't ever hit the last size of "2"
    local nextSize = fullScreenSizes[1]
    for i=1,#fullScreenSizes do
      if cell.w == GRID.w / fullScreenSizes[i] and 
         cell.h == GRID.h / fullScreenSizes[i] and
         cell.x == (GRID.w - GRID.w / fullScreenSizes[i]) / 2 and
         cell.y == (GRID.h - GRID.h / fullScreenSizes[i]) / 2 then
        nextSize = fullScreenSizes[(i % #fullScreenSizes) + 1]
        break
      end
    end

    -- Poor implementation. This logic overrides 4/3 to make it 
    -- cover the middle of the screen for ultrawide
    if (nextSize == 4/3) then
      cell.w = GRID.w / 3
      cell.h = GRID.h 
      cell.x = (GRID.w - GRID.w / 3) / 2
      cell.y = 0
    else
      cell.w = GRID.w / nextSize
      cell.h = GRID.h / nextSize
      cell.x = (GRID.w - GRID.w / nextSize) / 2
      cell.y = (GRID.h - GRID.h / nextSize) / 2
    end

    hs.grid.set(win, cell, screen)
  end
end

function fullDimension(dim)
  if hs.window.focusedWindow() then
    local win = hs.window.frontmostWindow()
    local id = win:id()
    local screen = win:screen()
    cell = hs.grid.get(win, screen)

    if (dim == 'x') then
      cell = '0,0 ' .. GRID.w .. 'x' .. GRID.h
    else  
      cell[dim] = GRID[dim]
      cell[dim == 'w' and 'x' or 'y'] = 0
    end
    hs.grid.set(win, cell, screen)
  end
end

hs.hotkey.bind(hyper, "down", goDown, finishDown)
hs.hotkey.bind(hyper, "/", goDown, finishDown)

hs.hotkey.bind(hyper, "right", goRight, finishRight)
hs.hotkey.bind(hyper, "'", goRight, finishRight)

hs.hotkey.bind(hyper, "left", goLeft, finishLeft)
hs.hotkey.bind(hyper, ";", goLeft, finishLeft)

hs.hotkey.bind(hyper, "up", goUp, finishUp)
hs.hotkey.bind(hyper, "[", goUp, finishUp)

hs.hotkey.bind(hyper, "return", function ()
  nextFullScreenStep()
end)