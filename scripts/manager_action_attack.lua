-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYATK = "applyatk";
OOB_MSGTYPE_APPLYHRFC = "applyhrfc";

function onInit()
  -- replace default roll with adnd_roll to allow
  -- control-dice click to prompt for manual roll
  ActionsManager.roll = adnd_roll;
  --

  OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYATK, handleApplyAttack);
  OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYHRFC, handleApplyHRFC);

  ActionsManager.registerTargetingHandler("attack", onTargeting);
  ActionsManager.registerModHandler("attack", modAttack);
  ActionsManager.registerResultHandler("attack", onAttack);
    -- callback for mirror/stoneskins
  ActionsManager.registerResultHandler("roll_against_mirrorimages", againstMirrors);
end

function handleApplyAttack(msgOOB)
  local rSource = ActorManager.getActor(msgOOB.sSourceType, msgOOB.sSourceNode);
  local rTarget = ActorManager.getActor(msgOOB.sTargetType, msgOOB.sTargetNode);
  
  local nTotal = tonumber(msgOOB.nTotal) or 0;
  
  applyAttack(rSource, rTarget, (tonumber(msgOOB.nSecret) == 1), msgOOB.sAttackType, msgOOB.sDesc, nTotal, msgOOB.sResults,msgOOB.sAttackLable);
end

function notifyApplyAttack(rSource, rTarget, bSecret, sAttackType, sDesc, nTotal, sResults,sAttackLable)
  if not rTarget then
    return;
  end

  local msgOOB = {};
  msgOOB.type = OOB_MSGTYPE_APPLYATK;
  
  if bSecret then
    msgOOB.nSecret = 1;
  else
    msgOOB.nSecret = 0;
  end
  msgOOB.sAttackType = sAttackType;
  msgOOB.nTotal = nTotal;
  msgOOB.sDesc = sDesc;
  msgOOB.sResults = sResults;
  msgOOB.sAttackLable = sAttackLable

  local sSourceType, sSourceNode = ActorManager.getTypeAndNodeName(rSource);
  msgOOB.sSourceType = sSourceType;
  msgOOB.sSourceNode = sSourceNode;

  local sTargetType, sTargetNode = ActorManager.getTypeAndNodeName(rTarget);
  msgOOB.sTargetType = sTargetType;
  msgOOB.sTargetNode = sTargetNode;

  Comm.deliverOOBMessage(msgOOB, "");
end

function handleApplyHRFC(msgOOB)
  TableManager.processTableRoll("", msgOOB.sTable);
end

function notifyApplyHRFC(sTable)
  local msgOOB = {};
  msgOOB.type = OOB_MSGTYPE_APPLYHRFC;
  
  msgOOB.sTable = sTable;

  Comm.deliverOOBMessage(msgOOB, "");
end

function onTargeting(rSource, aTargeting, rRolls)
  local bRemoveOnMiss = false;
  local sOptRMMT = OptionsManager.getOption("RMMT");
  if sOptRMMT == "on" then
    bRemoveOnMiss = true;
  elseif sOptRMMT == "multi" then
    local aTargets = {};
    for _,vTargetGroup in ipairs(aTargeting) do
      for _,vTarget in ipairs(vTargetGroup) do
        table.insert(aTargets, vTarget);
      end
    end
    bRemoveOnMiss = (#aTargets > 1);
  end
  
  if bRemoveOnMiss then
    for _,vRoll in ipairs(rRolls) do
      vRoll.bRemoveOnMiss = "true";
    end
  end

  return aTargeting;
end

function getRoll(rActor, rAction)
  -- Build basic roll
  local rRoll = {};
  rRoll.sType = "attack";
  rRoll.aDice = { "d20" };
  rRoll.nMod = 0;
  rRoll.bWeapon = false;

  -- psionics, we need to hand these off since modRoll doesn't keep rAction
--Debug.console("manger_action_attack.lua","modAttack","rAction.Psionic_DisciplineType",rAction.Psionic_DisciplineType);                      
  
  if (rAction) then 
    if (rAction.Psionic_DisciplineType ~= nil and rAction.Psionic_DisciplineType ~= "") then
      rRoll.bPsionic             = 'true';
    end
  --Debug.console("manger_action_attack.lua","modAttack","rRoll.bPsionic",rRoll.bPsionic);   
    rRoll.sSpellSource           = rAction.sSpellSource or "";
    rRoll.Psionic_Source         = rAction.Psionic_Source or "";
    rRoll.Psionic_DisciplineType = rAction.Psionic_DisciplineType or "";
    rRoll.Psionic_MAC            = rAction.Psionic_MAC or 10;
    rRoll.Psionic_PSP            = rAction.Psionic_PSP or 0;
    rRoll.Psionic_PSPOnFail      = rAction.Psionic_PSPOnFail or 0;
    -----
    rRoll.nMod = rAction.modifier or 0;
    rRoll.bWeapon = rAction.bWeapon;
    if (rActor.itemPath and rActor.itemPath ~= "") then
      rRoll.itemPath = rActor.itemPath;
    end
    local bADV = rAction.bADV or false;
    local bDIS = rAction.bDIS or false;
    
    
    -- Build the description label
    rRoll.sDesc = "[ATTACK";
    if rAction.order and rAction.order > 1 then
        rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
    end
    if rAction.range then
        rRoll.sDesc = rRoll.sDesc .. " (" .. rAction.range .. ")";
        rRoll.range = rAction.range;
    end
--Debug.console("manager_action_attack.lua","getRoll","rAction.label",rAction.label);
    rRoll.sAttackLable = rAction.label;
    rRoll.sDesc = rRoll.sDesc .. "] " .. rAction.label;

    -- Add crit range
    if rAction.nCritRange then
        rRoll.sDesc = rRoll.sDesc .. " [CRIT " .. rAction.nCritRange .. "]";
    end
    
    -- Add ability modifiers
    if rAction.stat then
      local sAbilityEffect = DataCommon.ability_ltos[rAction.stat];
      if sAbilityEffect then
          rRoll.sDesc = rRoll.sDesc .. " [MOD:" .. sAbilityEffect .. "]";
      end

      -- not in AD&D --celestian
      -- Check for armor non-proficiency
      -- local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);
      -- if sActorType == "pc" then
        -- if StringManager.contains({"strength", "dexterity"}, rAction.stat) then
          -- if DB.getValue(nodeActor, "defenses.ac.prof", 1) == 0 then
              -- rRoll.sDesc = rRoll.sDesc .. " " .. Interface.getString("roll_msg_armor_nonprof");
              -- bDIS = true;
          -- end
        -- end
      -- end
      
    end
    
    -- Add advantage/disadvantage tags
    if bADV then
        rRoll.sDesc = rRoll.sDesc .. " [ADV]";
    end
    if bDIS then
        rRoll.sDesc = rRoll.sDesc .. " [DIS]";
    end
  else
    rRoll.sDesc = "[ATTACK][BASIC]";
  end
  return rRoll;
end

function performRoll(draginfo, rActor, rAction)
--Debug.console("manager_action_attack.lua","performRoll","draginfo",draginfo);
  local rRoll = getRoll(rActor, rAction);

    if (draginfo and rActor.itemPath and rActor.itemPath ~= "") then
        draginfo.setMetaData("itemPath",rActor.itemPath);
    end
    
  ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modAttack(rSource, rTarget, rRoll)
  clearCritState(rSource);
  local bOptAscendingAC = (OptionsManager.getOption("HouseRule_ASCENDING_AC"):match("on") ~= nil);
  
  local aAddDesc = {};
  local aAddDice = {};
  local nAddMod = 0;
  local bPsionicPower =  rRoll.bPsionic == "true";
  -- Check for opportunity attack
  local bOpportunity = ModifierStack.getModifierKey("ATT_OPP") or Input.isShiftPressed();

  if bOpportunity then
    table.insert(aAddDesc, "[OPPORTUNITY]");
  end

  -- Check defense modifiers
  local bCover = ModifierStack.getModifierKey("DEF_COVER");
  local bSuperiorCover = ModifierStack.getModifierKey("DEF_SCOVER");
  local bHidden = ModifierStack.getModifierKey("DEF_HIDDEN");
  
  if bSuperiorCover then
    table.insert(aAddDesc, "[COVER -5]");
  elseif bCover then
    table.insert(aAddDesc, "[COVER -2]");
  end
  if bHidden then
    table.insert(aAddDesc, "[HIDDEN]");
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

  local aAttackFilter = {};

-- Debug.console("manager_action_attack.lua","modAttack","rSource",rSource);
--Debug.console("manager_action_attack.lua","modAttack","rTarget",rTarget);
-- Debug.console("manager_action_attack.lua","modAttack","rRoll",rRoll);
  local nBaseAttack = 0;
  rRoll.nBaseAttack = nBaseAttack;

  if rSource then
    -- Determine attack type
    local sAttackType = string.match(rRoll.sDesc, "%[ATTACK.*%((%w+)%)%]");
    if not sAttackType then
      sAttackType = "M";
    end

    -- Determine ability used
    local sActionStat = nil;
    local sModStat = string.match(rRoll.sDesc, "%[MOD:(%w+)%]");
    if sModStat then
      sActionStat = DataCommon.ability_stol[sModStat];
    end
    
    -- Build attack filter
    if sAttackType == "M" then
      table.insert(aAttackFilter, "melee");
    elseif sAttackType == "R" then
      table.insert(aAttackFilter, "ranged");
    elseif sAttackType == "P" then
      table.insert(aAttackFilter, "psionic");
      bPsionicPower = true;
    end
    if bOpportunity then
      table.insert(aAttackFilter, "opportunity");
    end

    -- Get attack effect modifiers
    local bEffects = false;
    local nEffectCount;
    
    -- add check for psionic and then look for "PSIATK" modifier
    if bPsionicPower then
      aAddDice, nAddMod, nEffectCount = EffectManager5E.getEffectsBonus(rSource, {"PSIATK"}, false, aAttackFilter);
      if (nEffectCount > 0) then
        bEffects = true;
      end
    else -- otherwise get normal ATK mods
      aAddDice, nAddMod, nEffectCount = EffectManager5E.getEffectsBonus(rSource, {"ATK"}, false, aAttackFilter);
      if (nEffectCount > 0) then
        bEffects = true;
      end
    end

    -- Get condition modifiers
    -- if (EffectManager5E.hasEffect(rSource, "ADVATK", rTarget)) then
      -- bADV = true;
      -- bEffects = true;
    -- elseif (#(EffectManager5E.getEffectsByType(rSource, "ADVATK", aAttackFilter, rTarget)) > 0) then
      -- bADV = true;
      -- bEffects = true;
    -- end
    -- if EffectManager5E.hasEffect(rSource, "DISATK", rTarget) then
      -- bDIS = true;
      -- bEffects = true;
    -- elseif (#(EffectManager5E.getEffectsByType(rSource, "DISATK", aAttackFilter, rTarget)) > 0)  then
      -- bDIS = true;
      -- bEffects = true;
    -- end
    if EffectManager5E.hasEffectCondition(rSource, "Blinded") then
      nAddMod = nAddMod - 4;
    end
    if EffectManager5E.hasEffectCondition(rSource, "Incorporeal") then
      bEffects = true;
      table.insert(aAddDesc, "[INCORPOREAL]");
    end
    -- if EffectManager5E.hasEffectCondition(rSource, "Encumbered") then
      -- bEffects = true;
      -- bDIS = true;
    -- end
    -- if EffectManager5E.hasEffectCondition(rSource, "Frightened") then
      -- bEffects = true;
      -- bDIS = true;
    -- end
    if EffectManager5E.hasEffectCondition(rSource, "Intoxicated") then
      bEffects = true;
      nAddMod = nAddMod - 1;
    end
    if EffectManager5E.hasEffectCondition(rSource, "Invisible") then
      bEffects = true;
      nAddMod = nAddMod + 2;
    end
    -- if EffectManager5E.hasEffectCondition(rSource, "Poisoned") then
      -- bEffects = true;
      -- bDIS = true;
    -- end
    if EffectManager5E.hasEffectCondition(rSource, "Prone") then
      bEffects = true;
      nAddMod = nAddMod - 2;
    end
    if EffectManager5E.hasEffectCondition(rSource, "Restrained") then
      bEffects = true;
      nAddMod = nAddMod - 2;
    end
    -- if EffectManager5E.hasEffectCondition(rSource, "Unconscious") then
      -- bEffects = true;
      -- bDIS = true; -- (from assumed prone state)
    -- end

    -- Get Base Attack modifier
    if (bPsionicPower) then
      nBaseAttack = getBaseAttackPsionic(rSource);
      rRoll.nBaseAttack = nBaseAttack;
    else 
      nBaseAttack = getBaseAttack(rSource);
      rRoll.nBaseAttack = nBaseAttack;
    end
    
    -- Get ability modifiers
    local nBonusStat, nBonusEffects = ActorManager2.getAbilityEffectsBonus(rSource, sActionStat,"hitadj");
    if nBonusEffects > 0 then
      bEffects = true;
      nAddMod = nAddMod + nBonusStat;
    end
    -- local nBonusStatItem, nBonusEffectsItem = ActorManager2.getAbilityEffectsBonus(rItemSource, sActionStat,"hitadj");
    -- if nBonusEffectsItem > 0 then
            -- bEffects = true;
            -- nAddMod = nAddMod + nBonusStatItem;
        -- end
    
    -- Get exhaustion modifiers
    -- local nExhaustMod, nExhaustCount = EffectManager5E.getEffectsBonus(rSource, {"EXHAUSTION"}, true);
    -- if nExhaustCount > 0 then
      -- bEffects = true;
      -- if nExhaustMod >= 3 then
        -- bDIS = true;
      -- end
    -- end
    
    -- Determine crit range
    local aCritRange = EffectManager5E.getEffectsByType(rSource, "CRIT");
       --local aCritRangeItem = EffectManager5E.getEffectsByType(rItemSource, "CRIT");
        --aCritRange = EffectManagerADND.TableConcat(aCritRange,aCritRangeItem);

    if #aCritRange > 0 then
      local nCritThreshold = 20;
      for _,v in ipairs(aCritRange) do
        if v.mod > 1 and v.mod < nCritThreshold then
          bEffects = true;
          nCritThreshold = v.mod;
        end
      end
      if nCritThreshold < 20 then
        local sRollCritThreshold = string.match(rRoll.sDesc, "%[CRIT (%d+)%]");
        local nRollCritThreshold = tonumber(sRollCritThreshold) or 20;
        if nCritThreshold < nRollCritThreshold then
          if string.match(rRoll.sDesc, " %[CRIT %d+%]") then
            rRoll.sDesc = string.gsub(rRoll.sDesc, " %[CRIT %d+%]", " [CRIT " .. nCritThreshold .. "]");
          else
            rRoll.sDesc = rRoll.sDesc ..  " [CRIT " .. nCritThreshold .. "]";
          end
        end
      end
    end

    -- If effects, then add them
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

    -- add THACO for this attack so drag/drop will be able to get it --celestian
    local nTHACO = 20 - rRoll.nBaseAttack;  
    if (bPsionicPower) then
      rRoll.sDesc = rRoll.sDesc .. " [MTHACO(" ..nTHACO.. ")] ";
    elseif bOptAscendingAC then
      rRoll.sDesc = rRoll.sDesc .. " [BAB(" .. rRoll.nBaseAttack .. ")] ";
    else
      rRoll.sDesc = rRoll.sDesc .. " [THACO(" ..nTHACO.. ")] ";
    end

  else    -- no rSource, they are drag/dropping the roll
  
    -- this will grab the THACO from the roll and use it at least --celestian
    local sTHACO = string.match(rRoll.sDesc, "%[THACO.*%((%d+)%)%]") or "20";
    local sBAB = string.match(rRoll.sDesc, "%[BAB.*%((%d+)%)%]");
    if not sTHACO then -- try for MTHACO then...
      sTHACO = string.match(rRoll.sDesc, "%[MTHACO.*%((%d+)%)%]") or "20";
    end
    if not sTHACO then -- if still nothing, just set to 20
        sTHACO = "20";
    end
    local nTHACO = tonumber(sTHACO) or 20;
    if nTHACO < 1 then
        nTHACO = 20;
    end
    if (sBAB and sBAB ~= "") then
      local nBAB = tonumber(sBAB) or 0;
      rRoll.nBaseAttack = nBAB;
    else
      rRoll.nBaseAttack = 20 - nTHACO;
    end
  end
  
  if bSuperiorCover then
    nAddMod = nAddMod - 5;
  elseif bCover then
    nAddMod = nAddMod - 2;
  end
  
  local bDefADV, bDefDIS = ActorManager2.getDefenseAdvantage(rSource, rTarget, aAttackFilter);
  if bDefADV then
    bADV = true;
  end
  if bDefDIS then
    bDIS = true;
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
  rRoll.nMod = rRoll.nMod + nAddMod;
  
    -- to disable advantage/disadvantage ... not AD&D -celestian
    bADV = false;
    bDIS = false;
  ActionsManager2.encodeAdvantage(rRoll, bADV, bDIS);
end

function onAttack(rSource, rTarget, rRoll)
  local bOptAscendingAC = (OptionsManager.getOption("HouseRule_ASCENDING_AC"):match("on") ~= nil);
  local bOptSHRR = (OptionsManager.getOption("SHRR") ~= "off");
  local bOptREVL = (OptionsManager.getOption("REVL") == "on");
  local is2e = (DataCommonADND.coreVersion == "2e");
  local bHitTarget = false;
  
  ActionsManager2.decodeAdvantage(rRoll);
  local nAttackMatrixRoll = ActionsManager.total(rRoll);
  

  local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
  rMessage.text = string.gsub(rMessage.text, " %[MOD:[^]]*%]", "");

  local bIsSourcePC = (rSource and rSource.sType == "pc");
  local bPsionic = rRoll.bPsionic == "true";
  local rAction = {};
  rAction.nTotal = ActionsManager.total(rRoll);

    -- add base attack bonus here(converted THACO to BaB remember?) so it doesn't confuse players and show up as a +tohit --celestian]
  -- if is2e then
    -- rAction.nTotal = rAction.nTotal + rRoll.nBaseAttack;
  -- end
    
  rAction.aMessages = {};
  
  local nDefenseVal, nAtkEffectsBonus, nDefEffectsBonus = ActorManager2.getDefenseValue(rSource, rTarget, rRoll);
  if nAtkEffectsBonus ~= 0 then
    rAction.nTotal = rAction.nTotal + nAtkEffectsBonus;
    nAttackMatrixRoll = nAttackMatrixRoll + nAtkEffectsBonus;
    local sFormat = "[" .. Interface.getString("effects_tag") .. " %+d]"
    table.insert(rAction.aMessages, string.format(sFormat, nAtkEffectsBonus));
  end

  if nDefEffectsBonus ~= 0 then
    nDefenseVal = nDefenseVal + nDefEffectsBonus;
    local sFormat = "[" .. Interface.getString("effects_def_tag") .. " %+d]"
    table.insert(rAction.aMessages, string.format(sFormat, nDefEffectsBonus));
  end
    local bCanCrit = true;
  -- insert AC hit
--Debug.console("manager_action_attack.lua","onAttack","nDefenseVal",nDefenseVal);
  local nACHit = (20 - (rAction.nTotal + rRoll.nBaseAttack));
  if not is2e then
    nACHit = CombatManagerADND.getACHitFromMatrix(ActorManager.getCTNode(rSource),nAttackMatrixRoll);
Debug.console("manager_action_attack.lua","onAttack","Matrix ACHit--------->",nACHit);  
  elseif bOptAscendingAC then   -- you can't have AscendingAC and 1e Matrix (right now)
    nACHit = (rAction.nTotal + rRoll.nBaseAttack);
  end
  
  if rTarget ~= nil then
    if (nDefenseVal and nDefenseVal ~= 0) then
      -- adjust bCanCrit based on target AC, if they need roll+bab 20 to hit target ac then they cant crit
      bCanCrit = (not bPsionic and canCrit(rRoll.nBaseAttack,nDefenseVal));
      local nTargetAC = (20 - nDefenseVal);
      if bOptAscendingAC then
        nTargetAC = nDefenseVal;
      end
      if (bPsionic) then
        --rMessage.text = rMessage.text .. "[Hit-MAC: " .. nACHit .. " vs. ".. nTargetAC .." ]" .. table.concat(rAction.aMessages, " ");
        rMessage.text = rMessage.text .. table.concat(rAction.aMessages, " ");
        table.insert(rAction.aMessages, "[Hit-MAC: " .. nACHit .. " vs. ".. nTargetAC .." ]" );
      else
        --rMessage.text = rMessage.text .. "[Hit-AC: " .. nACHit .. " vs. ".. nTargetAC .." ]" .. table.concat(rAction.aMessages, " ");
        rMessage.text = rMessage.text .. table.concat(rAction.aMessages, " ");
        table.insert(rAction.aMessages, "[Hit-AC: " .. nACHit .. " vs. ".. nTargetAC .." ]" );
      end
    end
  elseif nDefenseVal and bPsionic and not rRoll.Psionic_DisciplineType:match("attack") then -- no source but nDefenseVal and not a psionic attack (it's a power)
    bCanCrit = false;
    local nTargetAC = (20 - nDefenseVal);
      if bOptAscendingAC then
        nTargetAC = nDefenseVal;
      end
    --rMessage.text = rMessage.text .. "[Hit-MAC: " .. nACHit .. " vs. ".. nTargetAC .." ]" .. table.concat(rAction.aMessages, " ");
    rMessage.text = rMessage.text .. table.concat(rAction.aMessages, " ");
  end
  
  if (bPsionic) then
    bCanCrit = false;
    table.insert(rAction.aMessages, string.format("[MAC: %d ]" , nACHit) );
  else
    --"[Hit-AC: " .. nACHit .. " vs. ".. nTargetAC .." ]"
    --table.insert(rAction.aMessages, "[Hit-AC: " .. nACHit .. " vs. ".. nTargetAC .." ]" );
    table.insert(rAction.aMessages, string.format("[AC: %d ]" , nACHit) );
  end
    
  
  local sCritThreshold = string.match(rRoll.sDesc, "%[CRIT (%d+)%]");
  local nCritThreshold = tonumber(sCritThreshold) or 20;
  if nCritThreshold < 2 or nCritThreshold > 20 then
    nCritThreshold = 20;
  end
  
  rAction.nFirstDie = 0;
  if #(rRoll.aDice) > 0 then
    rAction.nFirstDie = rRoll.aDice[1].result or 0;
  end
  
  if rAction.nFirstDie >= nCritThreshold and bCanCrit then
    rAction.bSpecial = true;
    bHitTarget = true;
    rAction.sResult = "crit";
    table.insert(rAction.aMessages, "[CRITICAL HIT]");
  elseif rAction.nFirstDie == 1 then
    rAction.sResult = "fumble";
    if bPsionic then
      local sAdjustPSPText = adjustPSPs(rSource,tonumber(rRoll.Psionic_PSPOnFail));
      rMessage.icon = "roll_psionic_hit";
      rMessage.text = rMessage.text .. sAdjustPSPText;
    end
    table.insert(rAction.aMessages, "[MISS-AUTOMATIC]");
  elseif nDefenseVal and nDefenseVal ~= 0 then 
    local nTargetDecendingAC = (20 - nDefenseVal);
    local bMatrixHit = ( nTargetDecendingAC >= nACHit );
    local bHit = ((rAction.nTotal + rRoll.nBaseAttack) >= nDefenseVal or rAction.nFirstDie == 20);
    if (rTarget == nil and rRoll.Psionic_DisciplineType:match("attack")) then
      -- psionic attacks only work with a target, powers however have target MACs so... this lovely confusing mess.
    else if (is2e and bHit) or (not is2e and not bOptAscendingAC and bMatrixHit) then
    --Debug.console("manager_action_attack.lua","onAttack","nDefenseVal",nDefenseVal);
    -- nFirstDie = natural roll, nat 20 == auto-hit, if you can't crit you can still hit on a 20
    -- if rAction.nTotal >= nDefenseVal or rAction.nFirstDie == 20 then
-------------------------------------
      bHitTarget = true;
      rMessage.font = "hitfont";
      rMessage.icon = "chat_hit";
      rAction.sResult = "hit";
      local sHitText = "[HIT]";
      if (rAction.nFirstDie == 20) then
        sHitText = "[HIT-AUTOMATIC]";
      end
      if bPsionic then
        rMessage.icon = "roll_psionic_hit";
      end
      -- if bPsionic then 
        -- table.insert(rAction.aMessages,adjustPSPs(rSource,tonumber(rRoll.Psionic_PSP)));
      -- end
      table.insert(rAction.aMessages, sHitText);
-------------------------------------
    else
      rMessage.font = "missfont";
      rMessage.icon = "chat_miss";
      rAction.sResult = "miss";
      if bPsionic then
        local sAdjustPSPText = adjustPSPs(rSource,tonumber(rRoll.Psionic_PSPOnFail));
        rMessage.icon = "roll_psionic_miss";
        rMessage.text = rMessage.text .. sAdjustPSPText;
      end
      table.insert(rAction.aMessages, "[MISS]");
    end
    
    end
  end

  if not rTarget then
    rMessage.text = rMessage.text .. " " .. table.concat(rAction.aMessages, " ");
  end
  
  Comm.deliverChatMessage(rMessage);
  
  if rTarget then
    notifyApplyAttack(rSource, rTarget, rMessage.secret, rRoll.sType, rRoll.sDesc, rAction.nTotal, table.concat(rAction.aMessages, " "),rRoll.sAttackLable);
  end
  
  -- TRACK CRITICAL STATE
  if rAction.sResult == "crit" then
    setCritState(rSource, rTarget);
  end
  
  -- REMOVE TARGET ON MISS OPTION
  if rTarget then
    if (rAction.sResult == "miss" or rAction.sResult == "fumble") then
      if rRoll.bRemoveOnMiss then
        TargetingManager.removeTarget(ActorManager.getCTNodeName(rSource), ActorManager.getCTNodeName(rTarget));
      end
    end
  end
  
  -- HANDLE FUMBLE/CRIT HOUSE RULES
  local sOptionHRFC = OptionsManager.getOption("HRFC");
  if rAction.sResult == "fumble" and ((sOptionHRFC == "both") or (sOptionHRFC == "fumble")) then
    notifyApplyHRFC("Fumble");
  end
  if rAction.sResult == "crit" and ((sOptionHRFC == "both") or (sOptionHRFC == "criticalhit")) then
    notifyApplyHRFC("Critical Hit");
  end
  
  -- check for MIRRORIMAGE and STONESKIN /etc...
  if rTarget and bHitTarget and not bPsionic then
    local _, nStoneSkinCount, _ = EffectManager5E.getEffectsBonus(rTarget, {"STONESKIN"}, false, nil);
    local _, nMirrorCount, nEffectCount = EffectManager5E.getEffectsBonus(rTarget, {"MIRRORIMAGE"}, false, nil);
    if (nStoneSkinCount > 0) then
      -- remove a stoneskin from count
      local nodeCT = ActorManager.getCTNode(rTarget);
      EffectManagerADND.removeEffectCount(nodeCT, "STONESKIN", 1);
      local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
      rMessage.text = "[STONESKIN HIT] " .. Interface.getString("chat_combat_hit_stoneskin");
      Comm.deliverChatMessage(rMessage);
    elseif nMirrorCount > 0 then
      local rMirrorRoll = { sType = "roll_against_mirrorimages", sDesc = "[MIRROR-IMAGE]", aDice = { "d100","d10" }, nMod = 0 ,bSecret = false, sUser = User.getUsername()};
      ActionsManager.roll(rSource, rTarget, rMirrorRoll,false);
    end
  end
end

--- see if the attack hit mirror/stoneskin instead
function againstMirrors(rSource, rTarget, rRoll)
  local nodeCT = ActorManager.getCTNode(rTarget);
  local nCheckTotal = ActionsManager.total(rRoll);
  local _, nMirrorCount, _ = EffectManager5E.getEffectsBonus(rTarget, {"MIRRORIMAGE"}, false, nil);
  
  if (nMirrorCount > 0) then
    local fHitMirror = ((nMirrorCount / (1 + nMirrorCount)) * 100)
    local nHitMirror =  math.floor(fHitMirror-0.5); 

    if (nCheckTotal <= nHitMirror) then
      -- remove a mirror from count
      EffectManagerADND.removeEffectCount(nodeCT, "MIRRORIMAGE", 1);
      local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
      rMessage.text = "[MIRROR-IMAGE HIT] " .. Interface.getString("chat_combat_hit_mirrorimage");
      Comm.deliverChatMessage(rMessage);
    end
  end
  -- remove a mirror
end
--- applyAttack
function applyAttack(rSource, rTarget, bSecret, sAttackType, sDesc, nTotal, sResults, sAttackLable)
  local msgShort = {font = "msgfont"};
  local msgLong = {font = "msgfont"};

  local sAttackTypeFull = string.match(sDesc, "(%[ATTACK %(%a%)%])");
  if not sAttackTypeFull or sAttackTypeFull == "" then
    sAttackTypeFull = "[ATTACK (?)]";
  end

-- Debug.console("manager_action_attack.lua","applyAttack","sAttackTypeFull",sAttackTypeFull);  
-- Debug.console("manager_action_attack.lua","applyAttack","sDesc",sDesc);  

  msgShort.text = "Attack ->";
  msgLong.text = "Attack [" .. nTotal .. "] ->";

  -- add in [ATTACK (X)] so DOE can see type and miss/hit on same line for sound trigger
  msgShort.text = msgShort.text .. sAttackTypeFull;
  msgLong.text = msgLong.text .. sAttackTypeFull;
  -- add in weapon used for attack for sound trigger search
  if (sAttackLable and sAttackLable ~= "") then
    if (bOptSHRR) then
      msgShort.text = msgShort.text .. " " .. sAttackLable .. " ";
    end
    msgLong.text = msgLong.text .. " " .. sAttackLable .. " ";
  end

  if rTarget then
    msgShort.text = msgShort.text .. " [at " .. ActorManager.getDisplayName(rTarget) .. "]";
    msgLong.text = msgLong.text .. " [at " .. ActorManager.getDisplayName(rTarget) .. "]";
  end
  
  if sResults ~= "" then
    msgLong.text = msgLong.text .. " " .. sResults;
    if (bOptSHRR or bOptREVL) then
      msgShort.text = msgShort.text .. " " .. sResults;
    end
  end
  
  local bPsionicPower = false;
  local sType = string.match(sDesc, "%[ATTACK %((%w+)%)%]");
  if sType and sType == "P" then
    bPsionicPower = true;
  end
  
  msgShort.icon = "roll_attack";
  if string.match(sResults, "%[CRITICAL HIT%]") then
        msgLong.font = "hitfont";
    msgLong.icon = "roll_attack_crit";
  elseif string.match(sResults, "HIT%]") then
    msgLong.font = "hitfont";
    if bPsionicPower then
      msgLong.icon = "roll_psionic_hit";
    else
      msgLong.icon = "roll_attack_hit";
    end
  elseif string.match(sResults, "MISS%]") then
    msgLong.font = "missfont";
    if bPsionicPower then
      msgLong.icon = "roll_psionic_miss";
    else
      msgLong.icon = "roll_attack_miss";
    end
  else
    msgLong.icon = "roll_attack";
  end
  
  ActionsManager.outputResult(bSecret, rSource, rTarget, msgLong, msgShort);
end

aCritState = {};

function setCritState(rSource, rTarget)
  local sSourceCT = ActorManager.getCreatureNodeName(rSource);
  if sSourceCT == "" then
    return;
  end
  local sTargetCT = "";
  if rTarget then
    sTargetCT = ActorManager.getCTNodeName(rTarget);
  end
  
  if not aCritState[sSourceCT] then
    aCritState[sSourceCT] = {};
  end
  table.insert(aCritState[sSourceCT], sTargetCT);
end

function clearCritState(rSource)
  local sSourceCT = ActorManager.getCreatureNodeName(rSource);
  if sSourceCT ~= "" then
    aCritState[sSourceCT] = nil;
  end
end

function isCrit(rSource, rTarget)
  local sSourceCT = ActorManager.getCreatureNodeName(rSource);
  if sSourceCT == "" then
    return;
  end
  local sTargetCT = "";
  if rTarget then
    sTargetCT = ActorManager.getCTNodeName(rTarget);
  end

  if not aCritState[sSourceCT] then
    return false;
  end
  
  for k,v in ipairs(aCritState[sSourceCT]) do
    if v == sTargetCT then
      table.remove(aCritState[sSourceCT], k);
      return true;
    end
  end
  
  return false;
end

-- get the base attach bonus using THACO value
function getBaseAttack(rActor)
  local nBaseAttack = 20 - getTHACO(rActor);
  return nBaseAttack;
end
function getTHACO(rActor)
  local bOptAscendingAC = (OptionsManager.getOption("HouseRule_ASCENDING_AC"):match("on") ~= nil);
  
  local nTHACO = 20;
  local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);
  if not nodeActor then
    return 0;
  end
  -- get pc thaco value
  if ActorManager.isPC(nodeActor) then
    nTHACO = DB.getValue(nodeActor, "combat.thaco.score", 20);
  else
  -- npc thaco calcs
    nTHACO = DB.getValue(nodeActor, "thaco", 20);
  end
  return nTHACO
end
-- get the base attach bonus using MTHACO value
function getBaseAttackPsionic(rActor)
  local nBaseAttack = 20 - getMTHACO(rActor);
  return nBaseAttack;
end
function getMTHACO(rActor)
  local nTHACO = 20;
  local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);
  if not nodeActor then
    return 0;
  end
  nTHACO = DB.getValue(nodeActor, "combat.mthaco.score", 20);
  return nTHACO
end


-- return true if the creature doesn't need a natural 20 to hit the target AC -- celestian
-- this assumes nBaB is base attack bonus and ascending AC values, not THACO and decending AC
function canCrit(nBaB,nAscendingAC,nRange)
    local bCanCrit = true;
    local nValidRange = 0;
    -- if nRange exists then we use it to adjust the crit window acceptance.
    -- nRange = 5, if need a 20 to hit nAscendingAC+5 then they would not be able to crit
    -- here just incase I decide to use it. Default is, if they need a 20 to hit the target
    -- AC then we don't let them crit because it seems stupid they can crit only.
    if (nRange) then
        nValidRange = nRange;
    end
    local nAC = nAscendingAC + nValidRange;
    local nAttackRoll = 20 + nBaB;
--Debug.console("manager_action_attack.lua","canCrit","nAC",nAC);    
--Debug.console("manager_action_attack.lua","canCrit","nAttackRoll",nAttackRoll);    
    if (nAttackRoll <= nAC) then
        bCanCrit = false;
    end
--Debug.console("manager_action_attack.lua","canCrit","bCanCrit",bCanCrit);    
    return bCanCrit;
end

-- replace default roll with adnd_roll to allow
-- control-dice click to prompt for manual roll
function adnd_roll(rSource, vTargets, rRoll, bMultiTarget)
  if #(rRoll.aDice) > 0 then
    if not rRoll.bTower and (OptionsManager.isOption("MANUALROLL", "on") or (User.isHost() and Input.isControlPressed())) then
      local wManualRoll = Interface.openWindow("manualrolls", "");
      wManualRoll.addRoll(rRoll, rSource, vTargets);
    else
      local rThrow = ActionsManager.buildThrow(rSource, vTargets, rRoll, bMultiTarget);
      Comm.throwDice(rThrow);
    end
  else
    if bMultiTarget then
      ActionsManager.handleResolution(rRoll, rSource, vTargets);
    else
      ActionsManager.handleResolution(rRoll, rSource, { vTargets });
    end
  end
end 

-- return PSP cost string
function adjustPSPs(rSource,nPSPCost,bAdditive)
  local sText = ""
  if not updatePsionicPoints(rSource,nPSPCost,bAdditive) then
    sText = "[**INSUFFICIENT-PSP**]";
  else
    sText = "[PSPCOST:" .. nPSPCost .. "]";
  end
  return sText;
end

-- actually adjust the psp cost here
function updatePsionicPoints(rSource,nAdjustment,bAdditive)
  local sSourceCT = ActorManager.getCreatureNodeName(rSource);
  local node = DB.findNode(sSourceCT);
  if (node) then
    if (bAdditive) then
      ManagerPsionics.addPSP(node,nAdjustment);
      return true;
    else
      return ManagerPsionics.removePSP(node,nAdjustment);
    end
  end
  return false;
end