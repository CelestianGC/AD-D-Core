-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

slots = {};
local nMaxSlotRow = 10;
local nDefaultSpacing = 10;
local nSpacing = nDefaultSpacing;

local sSheetMode = "standard";
local bSpontaneous = false;
local nAvailable = 0;
local nTotalCast = 0;
local nTotalPrepared = 0;

function onInit()
  if spacing then
    nSpacing = tonumber(spacing[1]) or nDefaultSpacing;
  end
  
  setAnchoredHeight(nSpacing*2);
  setAnchoredWidth(nSpacing);
end

function onWheel(notches)
  if not Input.isControlPressed() then
    return false;
  end

  adjustCounter(notches);
  return true;
end

function onClickDown(button, x, y)
  return true;
end

function onClickRelease(button, x, y)
  local nPrepared = getPreparedValue();
  local bPrepMode = (sSheetMode == "preparation");
  local nMax = nPrepared;
  if bSpontaneous or bPrepMode then
    nMax = nAvailable;
  end

  local nClickH = math.floor(x / nSpacing) + 1;
  local nClickV;
  if nMax > nMaxSlotRow then
    nClickV  = math.floor(y / nSpacing);
  else
    nClickV = 0;
  end
  local nClick = (nClickV * nMaxSlotRow) + nClickH;

  if bPrepMode then
    local nCurrent = getPreparedValue();
    
    if nClick > nCurrent then
      adjustCounter(1);
    else
      adjustCounter(-1);
    end
  else
    local nCurrent = getCastValue();
    
    if bSpontaneous then
      if nClick > nTotalCast then
        adjustCounter(1);
      elseif nCurrent > 0 then
        adjustCounter(-1);
      end
    else
      if nClick > nCurrent then
        adjustCounter(1);
      else
        adjustCounter(-1);
      end
    end

    if getCastValue() > nCurrent then
      window.parentcontrol.window.usePower(false);
    end
  end
  
  return true;
end

function update(sNewSheetMode, bNewSpontaneous, nNewAvailable, nNewTotalCast, nNewTotalPrepared)
  sSheetMode = sNewSheetMode;
  bSpontaneous = bNewSpontaneous;
  nAvailable = nNewAvailable;
  nTotalCast = nNewTotalCast;
  nTotalPrepared = nNewTotalPrepared;
  
  updateSlots();
end

function updateSlots()
  -- Construct based on values
  local nPrepared = getPreparedValue();
  local nCast = getCastValue();
  local bPrepMode = (sSheetMode == "preparation");

  local nMax = nPrepared;
  if bSpontaneous or bPrepMode then
    nMax = nAvailable;
  end
  
  if #slots ~= nMax then
    -- Clear
    for k, v in ipairs(slots) do
      v.destroy();
    end
    slots = {};
    
    -- Build the slots, based on the all the spell cast statistics
    for i = 1, nMax do
      local widget = nil;

      if bSpontaneous then
        if i > nTotalCast then
          widget = addBitmapWidget(stateicons[1].off[1]);
        else
          widget = addBitmapWidget(stateicons[1].on[1]);
        end
        
        if i <= nTotalCast - nCast or bPrepMode then
          widget.setColor("4FFFFFFF");
        else
          widget.setColor("FFFFFFFF");
        end
      else
        if i > nCast then
          widget = addBitmapWidget(stateicons[1].off[1]);
        else
          widget = addBitmapWidget(stateicons[1].on[1]);
        end
        
        if i > nPrepared then
          widget.setColor("4FFFFFFF");
        else
          widget.setColor("FFFFFFFF");
        end
      end
      
      local nW = (i - 1) % nMaxSlotRow;
      local nH = math.floor((i - 1) / nMaxSlotRow);
      
      local nX = (nSpacing * nW) + math.floor(nSpacing / 2);
      local nY;
      if nMax > nMaxSlotRow then
        nY = (nSpacing * nH) + math.floor(nSpacing / 2);
      else
        nY = (nSpacing * nH) + nSpacing;
      end
      
      widget.setPosition("topleft", nX, nY);
      
      slots[i] = widget;
    end

    -- Determine final width of control based on slots
    if nMax > nMaxSlotRow then
      setAnchoredWidth(nMaxSlotRow * nSpacing);
      setAnchoredHeight((math.floor((nMax - 1) / nMaxSlotRow) + 1) * nSpacing);
    else
      setAnchoredWidth(nMax * nSpacing);
      setAnchoredHeight(nSpacing * 2);
    end
  else
    for i = 1, nMax do
      if bSpontaneous then
        if i > nTotalCast then
          slots[i].setBitmap(stateicons[1].off[1]);
        else
          slots[i].setBitmap(stateicons[1].on[1]);
        end
        
        if i <= nTotalCast - nCast or bPrepMode then
          slots[i].setColor("4FFFFFFF");
        else
          slots[i].setColor("FFFFFFFF");
        end
      else
        if i > nCast then
          slots[i].setBitmap(stateicons[1].off[1]);
        else
          slots[i].setBitmap(stateicons[1].on[1]);
        end
        
        if i > nPrepared then
          slots[i].setColor("4FFFFFFF");
        else
          slots[i].setColor("FFFFFFFF");
        end
      end
    end
  end
end

function adjustCounter(val_adj)
  if sSheetMode == "preparation" then
    if bSpontaneous then
      return true;
    end
  
    local val = getPreparedValue() + val_adj;
    
    if val > nAvailable then
      setPreparedValue(nAvailable);
    elseif val < 0 then
      setPreparedValue(0);
    else
      setPreparedValue(val);
    end
  else
    local val = getCastValue() + val_adj;
    local nTempTotal = nTotalCast + val_adj;

    if bSpontaneous then
      if nTempTotal > nAvailable then
        if val - (nTempTotal - nAvailable) > 0 then
          setCastValue(val - (nTempTotal - nAvailable));
        else
          setCastValue(0);
        end
      elseif val < 0 then
        setCastValue(0);
      else
        setCastValue(val);
      end
    else
      local nPrepared = getPreparedValue();

      if val > nPrepared then
        setCastValue(nPrepared);
      elseif val < 0 then
        setCastValue(0);
      else
        setCastValue(val);
      end
    end
  end
  
  if self.onValueChanged then
    self.onValueChanged();
  end
end

function canCast()
  if bSpontaneous then
    return (nTotalCast < nAvailable);
  else
    local nCast = getCastValue();
    local nPrepared = getPreparedValue();
    
    return (nCast < nPrepared);
  end
end

function getPreparedValue()
  return DB.getValue(window.getDatabaseNode(), "prepared", 0);
end

function setPreparedValue(nNewValue)
  return DB.setValue(window.getDatabaseNode(), "prepared", "number", nNewValue);
end

function getCastValue()
  return DB.getValue(window.getDatabaseNode(), "cast", 0);
end

function setCastValue(nNewValue)
  return DB.setValue(window.getDatabaseNode(), "cast", "number", nNewValue);
end
