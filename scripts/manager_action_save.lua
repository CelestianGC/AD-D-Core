-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYSAVE = "applysave";
OOB_MSGTYPE_APPLYCONC = "applyconc";

function onInit()
  OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYSAVE, handleApplySave);
  OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYCONC, handleApplyConc);

  ActionsManager.registerModHandler("save", modSave);
  ActionsManager.registerResultHandler("save", onSave);

  ActionsManager.registerResultHandler("concentration", onConcentrationRoll);
end

function handleApplySave(msgOOB)
  local rSource = ActorManager.getActor(msgOOB.sSourceType, msgOOB.sSourceNode);
  local rOrigin = ActorManager.getActor(msgOOB.sTargetType, msgOOB.sTargetNode);
  
  local rAction = {};
  rAction.bSecret = (tonumber(msgOOB.nSecret) == 1);
  rAction.sDesc = msgOOB.sDesc;
  rAction.nTotal = tonumber(msgOOB.nTotal) or 0;
  rAction.sSaveDesc = msgOOB.sSaveDesc;
  rAction.nTarget = tonumber(msgOOB.nTarget) or 0;
  rAction.sResult = msgOOB.sResult;
  rAction.bRemoveOnMiss = (tonumber(msgOOB.nRemoveOnMiss) == 1);

  applySave(rSource, rOrigin, rAction);
end

function notifyApplySave(rSource, bSecret, rRoll)
  local msgOOB = {};
  msgOOB.type = OOB_MSGTYPE_APPLYSAVE;
  
  if bSecret then
    msgOOB.nSecret = 1;
  else
    msgOOB.nSecret = 0;
  end
  msgOOB.sDesc = rRoll.sDesc;
  msgOOB.nTotal = ActionsManager.total(rRoll);
  msgOOB.sSaveDesc = rRoll.sSaveDesc;
  msgOOB.nTarget = rRoll.nTarget;
  msgOOB.sResult = rRoll.sResult;
  if rRoll.bRemoveOnMiss then msgOOB.nRemoveOnMiss = 1; end

  local sSourceType, sSourceNode = ActorManager.getTypeAndNodeName(rSource);
  msgOOB.sSourceType = sSourceType;
  msgOOB.sSourceNode = sSourceNode;

  if rRoll.sSource ~= "" then
    msgOOB.sTargetType = "ct";
    msgOOB.sTargetNode = rRoll.sSource;
  else
    msgOOB.sTargetType = "";
    msgOOB.sTargetNode = "";
  end

  Comm.deliverOOBMessage(msgOOB, "");
end

function performRoll(draginfo, rActor, sSave, nTargetDC, bSecretRoll, rSource, bRemoveOnMiss, sSaveDesc)
  local rRoll = {};
  rRoll.sType = "save";
  rRoll.aDice = { "d20" };
  local nMod, bADV, bDIS, sAddText = ActorManager2.getSave(rActor, sSave);
  rRoll.nMod = nMod;
    local sPrettySaveText = DataCommon.saves_stol[sSave];
  rRoll.sDesc = "[SAVE] vs. " .. StringManager.capitalize(sPrettySaveText);
  if sAddText and sAddText ~= "" then
    rRoll.sDesc = rRoll.sDesc .. " " .. sAddText;
  end
  if bADV then
    rRoll.sDesc = rRoll.sDesc .. " [ADV]";
  end
  if bDIS then
    rRoll.sDesc = rRoll.sDesc .. " [DIS]";
  end
  rRoll.bSecret = bSecretRoll;
  
  rRoll.nTarget = nTargetDC;

  if bRemoveOnMiss then
    rRoll.bRemoveOnMiss = "true";
  end
  if sSaveDesc then
    rRoll.sSaveDesc = sSaveDesc;
  end
  if rSource then
    rRoll.sSource = ActorManager.getCTNodeName(rSource);
  end

  ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modSave(rSource, rTarget, rRoll)
  local bAutoFail = false;

  local sSave = nil;
  if rRoll.sDesc:match("%[DEATH%]") then
    sSave = "death";
  elseif rRoll.sDesc:match("%[CONCENTRATION%]") then
    sSave = "concentration";
  else
    sSave = rRoll.sDesc:match("%[SAVE%] (%w+)");
    if sSave then
      sSave = sSave:lower();
    end
  end

  local bADV = false;
  local bDIS = false;
  if rRoll.sDesc:match(" %[ADV%]") then
    bADV = true;
    rRoll.sDesc = rRoll.sDesc:gsub(" %[ADV%]", "");
  end
  if rRoll.sDesc:match(" %[DIS%]") then
    bDIS = true;
    rRoll.sDesc = rRoll.sDesc:gsub(" %[DIS%]", "");
  end

  local aAddDesc = {};
  local aAddDice = {};
  local nAddMod = 0;
  
  local nCover = 0;
  -- if sSave == "dexterity" then
    -- if rRoll.sSaveDesc then
      -- nCover = tonumber(rRoll.sSaveDesc:match("%[COVER %-(%d)%]")) or 0;
    -- else
      -- if ModifierStack.getModifierKey("DEF_SCOVER") then
        -- nCover = 5;
      -- elseif ModifierStack.getModifierKey("DEF_COVER") then
        -- nCover = 2;
      -- end
    -- end
  -- end
  
  if rSource then
    local bEffects = false;

    -- Build filter
    local aSaveFilter = {};
    if sSave then
      table.insert(aSaveFilter, sSave);
    end

    -- Get effect modifiers
    local rSaveSource = nil;
    if rRoll.sSource then
      rSaveSource = ActorManager.getActor("ct", rRoll.sSource);
    end
    local aAddDice, nAddMod, nEffectCount = EffectManager5E.getEffectsBonus(rSource, {"SAVE"}, false, aSaveFilter, rSaveSource);
    if nEffectCount > 0 then
      bEffects = true;
    end
    
    -- Get condition modifiers
    if EffectManager5E.hasEffect(rSource, "ADVSAV", rTarget) then
      bADV = true;
      bEffects = true;
    elseif #(EffectManager5E.getEffectsByType(rSource, "ADVSAV", aSaveFilter, rTarget)) > 0 then
      bADV = true;
      bEffects = true;
    elseif sSave == "death" and EffectManager5E.hasEffect(rSource, "ADVDEATH") then
      bADV = true;
      bEffects = true;
    end
    if EffectManager5E.hasEffect(rSource, "DISSAV", rTarget) then
      bDIS = true;
      bEffects = true;
    elseif #(EffectManager5E.getEffectsByType(rSource, "DISSAV", aSaveFilter, rTarget)) > 0 then
      bDIS = true;
      bEffects = true;
    elseif sSave == "death" and EffectManager5E.hasEffect(rSource, "DISDEATH") then
      bDIS = true;
      bEffects = true;
    end
    if sSave == "dexterity" then
      if EffectManager5E.hasEffectCondition(rSource, "Restrained") then
        bDIS = true;
        bEffects = true;
      end
      if nCover < 5 then
        if EffectManager5E.hasEffect(rSource, "SCOVER", rTarget) then
          nCover = 5;
          bEffects = true;
        elseif nCover < 2 then
          if EffectManager5E.hasEffect(rSource, "COVER", rTarget) then
            nCover = 2;
            bEffects = true;
          end
        end
      end
    end
    if StringManager.contains({ "strength", "dexterity" }, sSave) then
      if EffectManager5E.hasEffectCondition(rSource, "Paralyzed") then
        bAutoFail = true;
        bEffects = true;
      end
      if EffectManager5E.hasEffectCondition(rSource, "Stunned") then
        bAutoFail = true;
        bEffects = true;
      end
      if EffectManager5E.hasEffectCondition(rSource, "Unconscious") then
        bAutoFail = true;
        bEffects = true;
      end
    end
    if StringManager.contains({ "strength", "dexterity", "constitution", "concentration" }, sSave) then
      if EffectManager5E.hasEffectCondition(rSource, "Encumbered") then
        bEffects = true;
        bDIS = true;
      end
    end
    if sSave == "dexterity" and EffectManager5E.hasEffectCondition(rSource, "Dodge") and 
        not (EffectManager5E.hasEffectCondition(rSource, "Paralyzed") or
        EffectManager5E.hasEffectCondition(rSource, "Stunned") or
        EffectManager5E.hasEffectCondition(rSource, "Unconscious") or
        EffectManager5E.hasEffectCondition(rSource, "Incapacitated") or
        EffectManager5E.hasEffectCondition(rSource, "Grappled") or
        EffectManager5E.hasEffectCondition(rSource, "Restrained")) then
      bEffects = true;
      bADV = true;
    end
    if rRoll.sSaveDesc then
      if rRoll.sSaveDesc:match("%[MAGIC%]") then
        if EffectManager5E.hasEffectCondition(rSource, "Magic Resistance") then
          bEffects = true;
          bADV = true;
        end
      end
    end
        -- Get save modifiers
    local nBonusSave, nBonusSaveEffects = EffectManager5E.getEffectsBonus(rSource, sSave:upper(),true);
    if nBonusSaveEffects > 0 then
      bEffects = true;
      nAddMod = nAddMod + nBonusSave;
    end










        -- Get exhaustion modifiers
    local nExhaustMod, nExhaustCount = EffectManager5E.getEffectsBonus(rSource, {"EXHAUSTION"}, true);
    if nExhaustCount > 0 then
      bEffects = true;
      if nExhaustMod >= 3 then
        bDIS = true;
      end
    end
    
    -- If effects apply, then add note
    if bEffects then
      for _, vDie in ipairs(aAddDice) do
        if vDie:sub(1,1) == "-" then
          table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
        else
          table.insert(rRoll.aDice, "p" .. vDie:sub(2));
        end
      end
      rRoll.nMod = rRoll.nMod + nAddMod;
      
      local sEffects = "";
      local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
      if sMod ~= "" then
        sEffects = "[" .. Interface.getString("effects_tag") .. " " .. sMod .. "]";
      else
        sEffects = "[" .. Interface.getString("effects_tag") .. "]";
      end
      rRoll.sDesc = rRoll.sDesc .. " " .. sEffects;
    end
  end
  








  if nCover > 0 then
    rRoll.nMod = rRoll.nMod + nCover;
    rRoll.sDesc = rRoll.sDesc .. string.format(" [COVER +%d]", nCover);
  end
  ActionsManager2.encodeDesktopMods(rRoll);
    bADV = false;    -- don't use advantage/disadvantage in AD&D --celestian
    bDIS = false;
  ActionsManager2.encodeAdvantage(rRoll, bADV, bDIS);
  
  if bAutoFail then
    rRoll.sDesc = rRoll.sDesc .. " [AUTOFAIL]";
  end
end
function onSave(rSource, rTarget, rRoll)
  ActionsManager2.decodeAdvantage(rRoll);

  local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
  Comm.deliverChatMessage(rMessage);

  local bAutoFail = rRoll.sDesc:match("%[AUTOFAIL%]");
  if not bAutoFail and rRoll.nTarget then
    notifyApplySave(rSource, rMessage.secret, rRoll);
  end
end

function applySave(rSource, rOrigin, rAction, sUser)
  local msgShort = {font = "msgfont"};
  local msgLong = {font = "msgfont"};
  
  msgShort.text = "Save";
  msgLong.text = "Save [" .. rAction.nTotal ..  "]";
  if rAction.nTarget > 0 then
    msgLong.text = msgLong.text .. " [Target " .. rAction.nTarget .. "]";
  end
  msgShort.text = msgShort.text .. " ->";
  msgLong.text = msgLong.text .. " ->";
  if rSource then
    msgShort.text = msgShort.text .. " [for " .. rSource.sName .. "]";
    msgLong.text = msgLong.text .. " [for " .. rSource.sName .. "]";
  end
  if rOrigin then
    msgShort.text = msgShort.text .. " [vs " .. rOrigin.sName .. "]";
    msgLong.text = msgLong.text .. " [vs " .. rOrigin.sName .. "]";
  end
  
  msgShort.icon = "roll_cast";
    
  local sAttack = "";
  local bHalfMatch = false;
  if rAction.sSaveDesc then
    sAttack = rAction.sSaveDesc:match("%[SAVE VS[^]]*%] ([^[]+)") or "";
    bHalfMatch = (rAction.sSaveDesc:match("%[HALF ON SAVE%]") ~= nil);
  end
  rAction.sResult = "";
  
  if rAction.nTarget > 0 then
        if rAction.nTotal >= rAction.nTarget then
            msgLong.text = msgLong.text .. " [SUCCESS]";
            msgLong.icon = "chat_success";msgLong.font = "successfont";
            if rSource then
                local bHalfDamage = bHalfMatch;
                local bAvoidDamage = false;
                if bHalfDamage then
                    if EffectManager5E.hasEffectCondition(rSource, "Avoidance") then
                        bAvoidDamage = true;
                        msgLong.text = msgLong.text .. " [AVOIDANCE]";
                    elseif EffectManager5E.hasEffectCondition(rSource, "Evasion") then
                        local sSave = rAction.sDesc:match("%[SAVE%] (%w+)");
                        if sSave then
                            sSave = sSave:lower();
                        end
                        if sSave == "dexterity" then
                            bAvoidDamage = true;
                            msgLong.text = msgLong.text .. " [EVASION]";
                        end
                    end
                end
                
                if bAvoidDamage then
                    rAction.sResult = "none";
                    rAction.bRemoveOnMiss = false;
                elseif bHalfDamage then
                    rAction.sResult = "half_success";
                    rAction.bRemoveOnMiss = false;
                end
                
                if rOrigin and rAction.bRemoveOnMiss then
                    TargetingManager.removeTarget(ActorManager.getCTNodeName(rOrigin), ActorManager.getCTNodeName(rSource));
                end
            end
        else
            msgLong.text = msgLong.text .. " [FAILURE]";
            msgLong.icon = "chat_fail";  msgLong.font = "failfont";
            if rSource then
                local bHalfDamage = false;
                if bHalfMatch then
                    if EffectManager5E.hasEffectCondition(rSource, "Avoidance") then
                        bHalfDamage = true;
                        msgLong.text = msgLong.text .. " [AVOIDANCE]";
                    elseif EffectManager5E.hasEffectCondition(rSource, "Evasion") then
                        local sSave = rAction.sDesc:match("%[SAVE%] (%w+)");
                        if sSave then
                            sSave = sSave:lower();
                        end
                        if sSave == "dexterity" then
                            bHalfDamage = true;
                            msgLong.text = msgLong.text .. " [EVASION]";
                        end
                    end
                end
                
                if bHalfDamage then
                    rAction.sResult = "half_failure";
                end
            end
        end
    end

  ActionsManager.messageResult(bSecret, rSource, rOrigin, msgLong, msgShort);
  
  if rSource and rOrigin then
    ActionDamage.setDamageState(rOrigin, rSource, StringManager.trim(sAttack), rAction.sResult);
  end
end













































































































--
--  Concentration saving throw
--

function hasConcentrationEffects(rSource)
  return #(getConcentrationEffects(rSource)) > 0;
end

function getConcentrationEffects(rSource)
  local aEffects = {};
  
  local nodeCTSource = ActorManager.getCTNode(rSource);
  if nodeCTSource then
    local sCTNodeSource = nodeCTSource.getPath();
    for _,nodeCT in pairs(CombatManager.getCombatantNodes()) do
      local sCTNode = nodeCT.getPath();
      for _,nodeEffect in pairs(DB.getChildren(nodeCT, "effects")) do
        local bSourceMatch = false;
        local sEffectCTSource = DB.getValue(nodeEffect, "source_name", "");
        if sEffectCTSource == sCTNodeSource then
          bSourceMatch = true;
        elseif (sCTNode == sCTNodeSource) and (sEffectCTSource == "") then
          bSourceMatch = true;
        end
        if bSourceMatch then
          if DB.getValue(nodeEffect, "label", ""):match("%([cC]%)") then
            table.insert(aEffects, { nodeCT = nodeCT, nodeEffect = nodeEffect });
          end
        end
      end
    end
  end
  
  return aEffects;
end

function handleApplyConc(msgOOB)
  local rSource = ActorManager.getActor(msgOOB.sSourceType, msgOOB.sSourceNode);
  
  local rAction = {};
  rAction.bSecret = (tonumber(msgOOB.nSecret) == 1);
  rAction.sDesc = msgOOB.sDesc;
  rAction.nTotal = tonumber(msgOOB.nTotal) or 0;
  rAction.nTarget = tonumber(msgOOB.nTarget) or 0;
  
  applyConcentrationRoll(rSource, rAction);
end

function notifyApplyConc(rSource, bSecret, rRoll)
  local msgOOB = {};
  msgOOB.type = OOB_MSGTYPE_APPLYCONC;
  
  if bSecret then
    msgOOB.nSecret = 1;
  else
    msgOOB.nSecret = 0;
  end
  msgOOB.sDesc = rRoll.sDesc;
  msgOOB.nTotal = ActionsManager.total(rRoll);
  msgOOB.nTarget = rRoll.nTarget;

  local sSourceType, sSourceNode = ActorManager.getTypeAndNodeName(rSource);
  msgOOB.sSourceType = sSourceType;
  msgOOB.sSourceNode = sSourceNode;

  Comm.deliverOOBMessage(msgOOB, "");
end

function performConcentrationRoll(draginfo, rActor, nTargetDC)
  local rRoll = { };
  rRoll.sType = "concentration";
  rRoll.aDice = { "d20" };
  local nMod, bADV, bDIS, sAddText = ActorManager2.getSave(rActor, "constitution");
  rRoll.nMod = nMod;
  
  rRoll.sDesc = "[CONCENTRATION]";
  if sAddText and sAddText ~= "" then
    rRoll.sDesc = rRoll.sDesc .. " " .. sAddText;
  end
  if bADV then
    rRoll.sDesc = rRoll.sDesc .. " [ADV]";
  end
  if bDIS then
    rRoll.sDesc = rRoll.sDesc .. " [DIS]";
  end

  rRoll.nTarget = nTargetDC;
  
  ActionsManager.performAction(draginfo, rActor, rRoll);
end

function onConcentrationRoll(rSource, rTarget, rRoll)
  ActionsManager2.decodeAdvantage(rRoll);

  local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
  Comm.deliverChatMessage(rMessage);

  local bAutoFail = rRoll.sDesc:match("%[AUTOFAIL%]");
  if not bAutoFail and rRoll.nTarget then
    notifyApplyConc(rSource, rMessage.secret, rRoll);
  end
end

function applyConcentrationRoll(rSource, rAction)
  local msgShort = {font = "msgfont"};
  local msgLong = {font = "msgfont"};
  
  msgShort.text = "Concentration";
  msgLong.text = "Concentration [" .. rAction.nTotal ..  "]";
  if rAction.nTarget > 0 then
    msgLong.text = msgLong.text .. "[vs. DC " .. rAction.nTarget .. "]";
  end
  msgShort.text = msgShort.text .. " ->";
  msgLong.text = msgLong.text .. " ->";
  if rSource then
    msgShort.text = msgShort.text .. " [for " .. rSource.sName .. "]";
    msgLong.text = msgLong.text .. " [for " .. rSource.sName .. "]";
  end
  
  msgShort.icon = "roll_cast";
    
  if rAction.nTotal >= rAction.nTarget then
    msgLong.text = msgLong.text .. " [SUCCESS]";
  else
    msgLong.text = msgLong.text .. " [FAILURE]";
  end
  
  ActionsManager.outputResult(rAction.bSecret, rSource, nil, msgLong, msgShort);
  
  -- On failed concentration check, remove all effects with the same source creature
  if rAction.nTotal < rAction.nTarget then
    expireConcentrationEffects(rSource);
  end
end

function expireConcentrationEffects(rSource)
  local aSourceConcentrationEffects = getConcentrationEffects(rSource);
  for _,v in ipairs(aSourceConcentrationEffects) do
    EffectManager.expireEffect(v.nodeCT, v.nodeEffect, 0);
  end
end

function setNPCSave(nodeEntry, sSave, nodeNPC)
--Debug.console("manager_action_save.lua", "setNPCSave", "DataCommonADND.aWarriorSaves[nLevel][nSaveIndex]", DataCommonADND.aWarriorSaves[0][1]);    
    --Debug.console("manager_action_save.lua", "setNPCSave", sSave);

    local nSaveIndex = DataCommonADND.saves_table_index[sSave];

    --Debug.console("manager_action_save.lua", "setNPCSave", "DataCommonADND.saves_table_index[sSave]", DataCommonADND.saves_table_index[sSave]);
    
    --Debug.console("manager_action_save.lua", "setNPCSave", "nSaveIndex", nSaveIndex);
    
    local nSaveScore = 20;
    
    local sHitDice = DB.getValue(nodeNPC, "hitDice", "1");
    DB.setValue(nodeEntry,"hitDice","string", sHitDice);
    
    local nLevel = CombatManager2.getNPCLevelFromHitDice(nodeNPC);

    -- store it incase we wanna look at it later
    DB.setValue(nodeEntry, "level", "number", nLevel);
    
    --Debug.console("manager_action_save.lua", "setNPCSave", "nLevel", nLevel);
    
    if (nLevel > 17) then
        nSaveScore = DataCommonADND.aWarriorSaves[17][nSaveIndex];
    elseif (nLevel < 1) then
        nSaveScore = DataCommonADND.aWarriorSaves[0][nSaveIndex];
    else
        nSaveScore = DataCommonADND.aWarriorSaves[nLevel][nSaveIndex];
    --Debug.console("manager_action_save.lua", "setNPCSave", "DataCommonADND.aWarriorSaves[nLevel][nSaveIndex]", DataCommonADND.aWarriorSaves[nLevel][nSaveIndex]);
    end

    --Debug.console("manager_action_save.lua", "setNPCSave", "nSaveScore", nSaveScore);
    
    DB.setValue(nodeEntry, "saves." .. sSave .. ".score", "number", nSaveScore);
    DB.setValue(nodeEntry, "saves." .. sSave .. ".base", "number", nSaveScore);

    --Debug.console("manager_action_save.lua", "setNPCSave", "setValue Done");

    return nSaveScore;
end
