-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local parsed = false;
local rPower = nil;

local hoverAbility = nil;
local clickAbility = nil;

function onValueChanged()
  parsed = false;
end

function onHover(oncontrol)
  if dragging then
    return;
  end

  -- Reset selection when the cursor leaves the control
  if not oncontrol then
    -- Clear hover tracking
    hoverAbility = nil;
    
    -- Clear any selections
    setSelectionPosition(0);
  end
end

function onHoverUpdate(x, y)
  -- If we're typing or dragging, then exit
  if dragging then
    return;
  end

  -- Compute the locations of the relevant phrases, and the mouse
  local nMouseIndex = getIndexAt(x, y);
  if not parsed then
    parsed = true;
    rPower = CombatManager2.parseAttackLine(getValue());
  end

  -- Clear any memory of the last hover update
  hoverAbility = nil;
  
  -- Capture the power that we're over, so we can name it
  if rPower then
    for k, v in pairs(rPower.aAbilities) do
      if (v.nStart <= nMouseIndex) and (v.nEnd > nMouseIndex) then
        hoverAbility = k;
        setCursorPosition(v.nStart);
        setSelectionPosition(v.nEnd);
        break;
      end
    end

    if hoverAbility then
      if rPower.aAbilities[hoverAbility].sType == "attack" or rPower.aAbilities[hoverAbility].sType == "damage" then
        setHoverCursor("hand");
      else
        setHoverCursor("arrow");
      end

      return;
    end
  end

  -- Reset the cursor
  setHoverCursor("arrow");
end

function onClickDown(button, x, y)
  -- Suppress default processing to support dragging
  clickAbility = hoverAbility;
  
  return true;
end

function onClickRelease(button, x, y)
  -- Enable edit mode on mouse release
  setFocus();
  
  local n = getIndexAt(x, y);
  
  setSelectionPosition(n);
  setCursorPosition(n);
  
  return true;
end

function getActor()
  local nodeActor = nil;
  local node = getDatabaseNode();
  if node then
    nodeActor = node.getChild(actorpath[1]);
  end
  
  return ActorManager.getActor(actortype[1], nodeActor);
end

function rechargePower(rPower)
  if rPower and rPower.sUsage == "USED" then
    local s = string.sub(getValue(), 1, rPower.nUsageStart - 2) .. string.sub(getValue(), rPower.nUsageEnd + 1);
    setValue(s);

    local nodeCT = window.windowlist.window.getDatabaseNode();
    EffectManager.removeEffect(nodeCT, "RCHG: %d " .. string.gsub(rPower.name, "%*", "%%%*"));
  end
end

function usePower(rPower)
  if rPower and rPower.sUsage and rPower.sUsage ~= "USED" then
    local s = string.sub(getValue(), 1, rPower.nUsageEnd) .. "[USED]" .. string.sub(getValue(), rPower.nUsageEnd + 1);
    setValue(s);

    local sRecharge = string.match(rPower.sUsage, 'R:(%d)');
    if sRecharge then
      local nodeCT = window.windowlist.window.getDatabaseNode();
      EffectManager.addEffect("", "", nodeCT, { sName = "RCHG: " .. sRecharge .. " " .. rPower.name, nDuration = 0, nGMOnly = 1 }, false);
    end
  end
end

function actionAbility(draginfo, rAction)
  local bResult = true;
  -- USAGE
  if rAction.sType == "usage" then
    if draginfo then
      bResult = false;
    elseif rPower.sUsage == "USED" then
      rechargePower(rPower);
    else
      usePower(rPower);
    end
  -- ATTACK
  elseif rAction.sType == "attack" then
    ActionAttack.performRoll(draginfo, getActor(), rAction);
    usePower(rPower);
  -- SAVE VS
  elseif rAction.sType == "powersave" then
    ActionPower.performSaveVsRoll(draginfo, getActor(), rAction);
    usePower(rPower);
  -- DAMAGE
  elseif rAction.sType == "damage" then
    ActionDamage.performRoll(draginfo, getActor(), rAction);
    usePower(rPower);
  -- HEAL
  elseif rAction.sType == "heal" then
    ActionHeal.performRoll(draginfo, getActor(), rAction);
    usePower(rPower);
  -- EFFECT
  elseif rAction.sType == "effect" then
    ActionEffect.performRoll(draginfo, getActor(), rAction);
    usePower(rPower);
  end
  
  return bResult;
end

function onDoubleClick(x, y)
  if hoverAbility then
    return actionAbility(nil, rPower.aAbilities[hoverAbility]);
  end
end

function onDragStart(button, x, y, draginfo)
  dragging = false;
  if clickAbility then
    dragging = actionAbility(draginfo, rPower.aAbilities[clickAbility]);
    clickAbility = nil;
  end
  return dragging;
end

function onDragEnd(dragdata)
  setCursorPosition(0);
  dragging = false;
end
