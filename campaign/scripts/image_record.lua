--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

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
  nNewEndX, nNewEndY = getClosestSnapPoint(nEndX, nEndY)
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
