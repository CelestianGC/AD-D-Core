--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

-- this causes problems when the map is marked read only so I went another route --celestian
-- function getScaleControl()
    -- return window.toolbar.subwindow.scale;
-- end
function getScaleControlValue()
    local node = getDatabaseNode().getChild("..");
    local sValue = DB.getValue(node,"scale","10ft"); -- default to 10ft here but we should never see this.
    return sValue;
end
function getScaleControlisValid()
    return getScaleControlValue():find("^%d") ~= nil
end
function getScaleControlScaleValue()
    return getScaleControlisValid() and tonumber(getScaleControlValue():match("^(%d+)")) or 0
end
function getScaleControlScaleLabel()
    return StringManager.trim(getScaleControlValue():gsub("^%d+%s*", ""))
end
--

function getClosestSnapPoint(x, y)
  if hasGrid() then
    local sGridType = getGridType()
    local nSize = getGridSize()

    if sGridType == "hexrow" or sGridType == "hexcolumn" then
      local nGridHexWidth, nGridHexHeight = getGridHexElementDimensions()
      local nGridOffsetX, nGridOffsetY = getGridOffset()

      -- The hex grid separates into a non-square grid of elements sized nGridHexWidth*nGridHexHeight, the location in which dictates corner points
      if sGridType == "hexcolumn" then
        local nCol = math.floor((x - nGridOffsetX) / nGridHexWidth)
        local nRow = math.floor((y - nGridOffsetY) * 2 / nSize)

        local bEvenCol = nCol % 2 == 0
        local bEvenRow = nRow % 2 == 0

        local nModX = (x - nGridOffsetX) % nGridHexWidth
        local nModY = (y - nGridOffsetY) % nGridHexHeight

        if (bEvenRow and bEvenCol) or (not bEvenRow and not bEvenCol) then
          -- snap to lower right and upper left
          if nModX + nModY * (nGridHexWidth/nGridHexHeight) < nGridHexWidth then
            return nGridOffsetX + nCol*nGridHexWidth, nGridOffsetY + math.floor(nRow*nSize/2)
          else
            return nGridOffsetX + (nCol+1)*nGridHexWidth, nGridOffsetY + math.floor((nRow+1)*nSize/2)
          end
        else
          -- snap to lower left and upper right
          if (nGridHexWidth-nModX) + nModY * (nGridHexWidth/nGridHexHeight) < nGridHexWidth then
            return nGridOffsetX + (nCol+1)*nGridHexWidth, nGridOffsetY + math.floor(nRow*nSize/2)
          else
            return nGridOffsetX + nCol*nGridHexWidth, nGridOffsetY + math.floor((nRow+1)*nSize/2)
          end
        end
      else -- "hexrow"
        local nCol = math.floor((x - nGridOffsetX) * 2 / nSize)
        local nRow = math.floor((y - nGridOffsetY) / nGridHexWidth)

        local bEvenCol = nCol % 2 == 0
        local bEvenRow = nRow % 2 == 0

        local nModX = (x - nGridOffsetX) % nGridHexHeight
        local nModY = (y - nGridOffsetY) % nGridHexWidth

        if (bEvenRow and bEvenCol) or (not bEvenRow and not bEvenCol) then
          -- snap to lower right and upper left
          if nModX * (nGridHexWidth/nGridHexHeight) + nModY < nGridHexWidth then
            return nGridOffsetX + math.floor(nCol*nSize/2), nGridOffsetY + nRow*nGridHexWidth
          else
            return nGridOffsetX + math.floor((nCol+1)*nSize/2), nGridOffsetY + (nRow+1)*nGridHexWidth
          end
        else
          -- snap to lower left and upper right
          if (nGridHexHeight-nModX) * (nGridHexWidth/nGridHexHeight) + nModY < nGridHexWidth then
            return nGridOffsetX + math.floor((nCol+1)*nSize/2), nGridOffsetY + nRow*nGridHexWidth
          else
            return nGridOffsetX + math.floor(nCol*nSize/2), nGridOffsetY + (nRow+1)*nGridHexWidth
          end
        end
      end
    else -- if sGridType == "square" then
      local nGridOffsetX, nGridOffsetY = getGridOffset()

      local nBaseX = math.floor((x - (nGridOffsetX + 1))/(nSize/2))*(nSize/2) + (nGridOffsetX + 1)
      local nBaseY = math.floor((y - (nGridOffsetY + 1))/(nSize/2))*(nSize/2) + (nGridOffsetY + 1)

      local nNewX = nBaseX
      local nNewY = nBaseY

      if ((x - nBaseX) > (nSize / 4)) then
        nNewX = nNewX + (nSize / 2)
      end
      if ((y - nBaseY) > (nSize / 4)) then
        nNewY = nNewY + (nSize / 2)
      end

      return nNewX, nNewY
    end
  end
  return x, y
end

function onTokenSnap(token, x, y)
  if hasGrid() then
    return getClosestSnapPoint(x, y)
  else
    return x, y
  end
end

function onPointerSnap(nStartX, nStartY, nEndX, nEndY, sPointerType)
  local nNewStartX = nStartX
  local nNewStartY = nStartY
  local nNewEndX = nEndX
  local nNewEndY = nEndY
  local nAngle = math.atan2(nEndX - nStartX, - nEndY + nStartY)
  local scale = hasGrid() and getGridSize() or 32

  nNewStartX, nNewStartY = getClosestSnapPoint(nStartX, nStartY)
  if sPointerType == "sw_cone" then
    nNewEndX = 9*scale * math.sin(nAngle) + nStartX
    nNewEndY = 9*scale * -math.cos(nAngle) + nStartY
  elseif sPointerType == "sw_sb" then
    nNewEndX = scale * math.sin(nAngle) + nStartX
    nNewEndY = scale * -math.cos(nAngle) + nStartY
  elseif sPointerType == "sw_mb" then
    nNewEndX = 2*scale * math.sin(nAngle) + nStartX
    nNewEndY = 2*scale * -math.cos(nAngle) + nStartY
  elseif sPointerType == "sw_lb" then
    nNewEndX = 3*scale * math.sin(nAngle) + nStartX
    nNewEndY = 3*scale * -math.cos(nAngle) + nStartY
  else
    nNewEndX, nNewEndY = getClosestSnapPoint(nEndX, nEndY)
  end

  return nNewStartX, nNewStartY, nNewEndX, nNewEndY
end

function measureVector(nVectorX, nVectorY, sGridType, nGridSize, nGridHexWidth, nGridHexHeight)
  local nDiag = 1;
    if OptionsManager.isOption("HRDD", "variant") then
    nDiag = 1.5;
  end
  local nDistance = 0

  if sGridType == "hexrow" or sGridType == "hexcolumn" then
    local nCol, nRow = 0, 0
    if sGridType == "hexcolumn" then
      nCol = nVectorX / (nGridHexWidth*3)
      nRow = (nVectorY / (nGridHexHeight*2)) - (nCol * 0.5)
    else
      nRow = nVectorY / (nGridHexWidth*3)
      nCol = (nVectorX / (nGridHexHeight*2)) - (nRow * 0.5)
    end

    if  ((nRow >= 0 and nCol >= 0) or (nRow < 0 and nCol < 0)) then
      nDistance = math.abs(nCol) + math.abs(nRow)
    else
      nDistance = math.max(math.abs(nCol), math.abs(nRow))
    end

  else -- if sGridType == "square" then
    local nDiagonals = 0
    local nStraights = 0

    local nGridX = math.abs(nVectorX / nGridSize)
    local nGridY = math.abs(nVectorY / nGridSize)

    if nGridX > nGridY then
      nDiagonals = nDiagonals + nGridY
      nStraights = nStraights + nGridX - nGridY
    else
      nDiagonals = nDiagonals + nGridX
      nStraights = nStraights + nGridY - nGridX
    end

    nDistance = nDiagonals * nDiag + nStraights
  end

  return nDistance
end

function onMeasureVector(token, aVector)
  if hasGrid() then
    local sGridType = getGridType()
    local nGridSize = getGridSize()

    local nDistance = 0
    if sGridType == "hexrow" or sGridType == "hexcolumn" then
      local nGridHexWidth, nGridHexHeight = getGridHexElementDimensions()
      for i = 1, #aVector do
        local nVector = measureVector(aVector[i].x, aVector[i].y, sGridType, nGridSize, nGridHexWidth, nGridHexHeight)
        nDistance = nDistance + nVector
      end
    else -- if sGridType == "square" then
      for i = 1, #aVector do
        local nVector = measureVector(aVector[i].x, aVector[i].y, sGridType, nGridSize)
        nDistance = nDistance + nVector
      end
    end

    if getScaleControlisValid() then
      return math.floor(nDistance * getScaleControlScaleValue()) .. getScaleControlScaleLabel()
    else
      return ""
    end
  else
    return ""
  end
end

function onMeasurePointer(nLength, sPointerType, nStartX, nStartY, nEndX, nEndY)
  if sPointerType == "sw_cone" or sPointerType == "sw_sb" or sPointerType == "sw_mb" or sPointerType == "sw_lb" then
    return ""
  end

  if hasGrid() then
    local sGridType = getGridType()
    local nGridSize = getGridSize()

    if sGridType == "hexrow" or sGridType == "hexcolumn" then
      local nGridHexWidth, nGridHexHeight = getGridHexElementDimensions()
      nDistance = measureVector(nEndX - nStartX, nEndY - nStartY, sGridType, nGridSize, nGridHexWidth, nGridHexHeight)
    else -- if sGridType == "square" then
      nDistance = measureVector(nEndX - nStartX, nEndY - nStartY, sGridType, nGridSize)
    end

    if getScaleControlisValid() then
      return math.floor(nDistance * getScaleControlScaleValue()) .. getScaleControlScaleLabel()
    else
      return ""
    end
  else
    return ""
  end
end

function transformSpline(rSpline, nAngle, nCenterX, nCenterY)
  for _,rSegment in ipairs(rSpline) do
    for nControlPointIndex, aControlPoint in ipairs(rSegment) do
      local x = aControlPoint[1]
      local y = aControlPoint[2]

      local nSegmentX = (x-nCenterX) * math.cos(nAngle) - (y-nCenterY) * math.sin(nAngle) + nCenterX
      local nSegmentY = (x-nCenterX) * math.sin(nAngle) + (y-nCenterY) * math.cos(nAngle) + nCenterY

      rSegment[nControlPointIndex] = { nSegmentX, nSegmentY }
    end
  end
end

function onBuildCustomPointer(nStartX, nStartY, nEndX, nEndY, sType)
  local aSegments = {}
  local aDistancePosition
  local bDrawArrow

  local u = 32 / getScaleControlScaleValue()
  if hasGrid() then
    u = getGridSize() / getScaleControlScaleValue()
  end
  local nAngle = math.atan2(nEndX - nStartX, - nEndY + nStartY)

  if sType == "sw_cone" then
    -- Build a cone facing in the negative y direction
    local segment = { { nStartX, nStartY }, { nStartX, nStartY }, { nStartX - 1.5*u, nStartY - 6.5*u }, { nStartX - 1.5*u, nStartY - 7.5*u } }
    table.insert(aSegments, segment)
    local segment = { { nStartX - 1.5*u, nStartY - 7.5*u }, { nStartX - 1.5*u, nStartY - 8.25*u }, { nStartX - 0.75*u, nStartY - 9*u }, { nStartX, nStartY - 9*u } }
    table.insert(aSegments, segment)
    local segment = { { nStartX, nStartY }, { nStartX, nStartY }, { nStartX + 1.5*u, nStartY - 6.5*u }, { nStartX + 1.5*u, nStartY - 7.5*u } }
    table.insert(aSegments, segment)
    local segment = { { nStartX + 1.5*u, nStartY - 7.5*u }, { nStartX + 1.5*u, nStartY - 8.25*u }, { nStartX + 0.75*u, nStartY - 9*u }, { nStartX, nStartY - 9*u } }
    table.insert(aSegments, segment)

    -- Set the distance indicator position (in pixels)
    aDistancePosition = { 30, 30 }
  elseif sType == "sw_sb" then
    local segment = { { nStartX - u, nStartY }, { nStartX - u, nStartY - 0.56*u }, { nStartX - 0.56*u, nStartY - u }, { nStartX, nStartY - u } }
    table.insert(aSegments, segment)
    local segment = { { nStartX, nStartY - u }, { nStartX + 0.56*u, nStartY - u }, { nStartX + u, nStartY - 0.56*u }, { nStartX + u, nStartY } }
    table.insert(aSegments, segment)
    local segment = { { nStartX - u, nStartY }, { nStartX - u, nStartY + 0.56*u }, { nStartX - 0.56*u, nStartY + u }, { nStartX, nStartY + u } }
    table.insert(aSegments, segment)
    local segment = { { nStartX, nStartY + u }, { nStartX + 0.56*u, nStartY + u }, { nStartX + u, nStartY + 0.56*u }, { nStartX + u, nStartY } }
    table.insert(aSegments, segment)
  elseif sType == "sw_mb" then
    u = u * 2

    local segment = { { nStartX - u, nStartY }, { nStartX - u, nStartY - 0.56*u }, { nStartX - 0.56*u, nStartY - u }, { nStartX, nStartY - u } }
    table.insert(aSegments, segment)
    local segment = { { nStartX, nStartY - u }, { nStartX + 0.56*u, nStartY - u }, { nStartX + u, nStartY - 0.56*u }, { nStartX + u, nStartY } }
    table.insert(aSegments, segment)
    local segment = { { nStartX - u, nStartY }, { nStartX - u, nStartY + 0.56*u }, { nStartX - 0.56*u, nStartY + u }, { nStartX, nStartY + u } }
    table.insert(aSegments, segment)
    local segment = { { nStartX, nStartY + u }, { nStartX + 0.56*u, nStartY + u }, { nStartX + u, nStartY + 0.56*u }, { nStartX + u, nStartY } }
    table.insert(aSegments, segment)
  elseif sType == "sw_lb" then
    u = u * 3

    local segment = { { nStartX - u, nStartY }, { nStartX - u, nStartY - 0.56*u }, { nStartX - 0.56*u, nStartY - u }, { nStartX, nStartY - u } }
    table.insert(aSegments, segment)
    local segment = { { nStartX, nStartY - u }, { nStartX + 0.56*u, nStartY - u }, { nStartX + u, nStartY - 0.56*u }, { nStartX + u, nStartY } }
    table.insert(aSegments, segment)
    local segment = { { nStartX - u, nStartY }, { nStartX - u, nStartY + 0.56*u }, { nStartX - 0.56*u, nStartY + u }, { nStartX, nStartY + u } }
    table.insert(aSegments, segment)
    local segment = { { nStartX, nStartY + u }, { nStartX + 0.56*u, nStartY + u }, { nStartX + u, nStartY + 0.56*u }, { nStartX + u, nStartY } }
    table.insert(aSegments, segment)
  end

  -- Transform it to match angle
  transformSpline(aSegments, nAngle, nStartX, nStartY)

  return aSegments, aDistancePosition, bDrawArrow
end

--
-- Event functions to update imagewindow toolbar elements
--

function onGridStateChanged(sGridType)
  super.onGridStateChanged(sGridType)
  if User.isHost() then
    if sGridType == "hex" then
      setTokenOrientationCount(12)
    else
      setTokenOrientationCount(8)
    end
  end
end

function onTokenClickRelease(token, button)
  if User.isHost() and Input.isControlPressed() then
    if button == 2 then
      token.setScale(1)
    end
  end
end

function onTokenContainerChanging(token)
  token.onMenuSelection = function () end
  token.onClickRelease = function () end
  token.onWheel = function ()
      if User.isHost() and Input.isControlPressed() then
        return true
      end
    end
  token.onContainerChanging = function () end
end

function onTokenWheel(token, nNotches)
  if User.isHost() and Input.isControlPressed() then
    if Input.isAltPressed() then
      ntoken.setScale(math.max(math.floor(token.getScale() + nNotches), 1))
    else
      token.setScale(math.max(token.getScale() + (nNotches * 0.1), 0.1))
    end
    return true
  end
end

function onTokenMenuSelection(token, nOption)
  if nOption == 2 then
    token.setScale(1)
  end
end

function onTokenAdded(token)
  token.registerMenuItem("Reset individual token scaling", "minimize", 2)
  token.onMenuSelection = onTokenMenuSelection

  token.onClickRelease = onTokenClickRelease
  token.onWheel = onTokenWheel
  token.onContainerChanging = onTokenContainerChanging
end
