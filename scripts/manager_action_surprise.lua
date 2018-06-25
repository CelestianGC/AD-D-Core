-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
    ActionsManager.registerModHandler("surprise", modRoll);
    ActionsManager.registerResultHandler("surprise", onRoll);
end

function getRoll(rActor,nodeChar,nTargetDC, bSecretRoll)
  local rRoll = {};
  rRoll.sType = "surprise";
  --rRoll.aDice = { "d20" };
    rRoll.nMod = 0;
    
    local aDice = DB.getValue(nodeChar,"surprise.dice");
    if aDice == nil then
        aDice = DataCommonADND.aDefaultSurpriseDice;
    end
    rRoll.aDice = aDice;
  if (nTargetDC == nil) then
        nTargetDC = DB.getValue(nodeChar,"surprise.total",3);
    end
  rRoll.sDesc = "[CHECK] ";

  rRoll.bSecret = bSecretRoll;

  rRoll.nTarget = nTargetDC;
  
  return rRoll;
end

function performRoll(draginfo, rActor, nodeChar, nTargetDC, bSecretRoll)
  local rRoll = getRoll(rActor, nodeChar, nTargetDC, bSecretRoll);
  
  ActionsManager.performAction(draginfo, rActor, rRoll);
end

function onRoll(rSource, rTarget, rRoll)
  ActionsManager2.decodeAdvantage(rRoll);
  
  local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

  if rRoll.nTarget then
    local nTotal = ActionsManager.total(rRoll);
    local nTargetDC = tonumber(rRoll.nTarget) or 0;
    local nDifference = math.abs((nTotal - nTargetDC));
    
    rMessage.text = rMessage.text .. " (vs. Target " .. nTargetDC .. ")";
    if nTotal > nTargetDC then
           rMessage.font = "successfont";
           rMessage.icon = "chat_success";
      rMessage.text = rMessage.text .. " [NOT-SURPRISED by " .. nDifference .. "]";
    else
           rMessage.font = "failfont";
           rMessage.icon = "chat_fail";
      rMessage.text = rMessage.text .. " [SURPRISED! by " .. nDifference .. "]";
    end
  end
  
  Comm.deliverChatMessage(rMessage);
end

function modRoll(rSource, rTarget, rRoll)
  local aAddDesc = {};
  local aAddDice = {};
  local nAddMod = 0;
    local bEffects = false;

    if rSource then
        -- apply turn roll modifiers
        -- -- Get roll effect modifiers
        local nEffectCount;
        aAddDice, nAddMod, nEffectCount = EffectManager5E.getEffectsBonus(rSource, {"SURPRISE"}, false);
        if (nEffectCount > 0) then
            bEffects = true;
        end
        rRoll.nMod = rRoll.nMod + nAddMod;
    end
    
    -- If effects happened, then add note
    if bEffects then
        local sEffects = "";
        local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
        if sMod ~= "" then
            sEffects = "[" .. Interface.getString("effects_tag") .. " " .. sMod .. "]";
        else
            sEffects = "[" .. Interface.getString("effects_tag") .. "]";
        end
        table.insert(aAddDesc, sEffects);
    end
  if #aAddDesc > 0 then
    rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
  end

  ActionsManager2.encodeDesktopMods(rRoll);
  for _,vDie in ipairs(aAddDice) do
    if vDie:sub(1,1) == "-" then
      table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
    else
      table.insert(rRoll.aDice, "p" .. vDie:sub(2));
    end
  end

  ActionsManager2.encodeAdvantage(rRoll, false, false);
end
