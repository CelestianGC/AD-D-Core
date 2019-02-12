-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYOBLITERATE = "applyobliterate";
OOB_MSGTYPE_APPLYTURN = "applyturn";

function onInit()
  OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYOBLITERATE, handleApplyObliteration);
  OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYTURN, handleApplyTurned);
  
  ActionsManager.registerModHandler("turnundead", modRoll);
  ActionsManager.registerResultHandler("turnundead", onRoll);
end

function getRoll(rActor,nTargetDC, bSecretRoll)
  local rRoll = {};
  rRoll.sType = "turnundead";
  --rRoll.aDice = { "d20" };
  rRoll.nMod = 0;
  
  local sActorType, nodeChar = ActorManager.getTypeAndNode(rActor);
  
  local aDice = DB.getValue(nodeChar,"turn.dice");
  if aDice == nil then
    aDice = DataCommonADND.nDefaultTurnDice;
  end
  rRoll.aDice = aDice;
  -- turn.total is the total levels of cleric to turn as
  local nTargetDC = DB.getValue(nodeChar,"turn.total",1);
  rRoll.sDesc = "[TURNUNDEAD] ";
  --rRoll.bSecret = bSecretRoll;
  rRoll.nTarget = nTargetDC;
  return rRoll;
end

-- TargetDC is the level of cleric attempting turn
function performRoll(draginfo, rActor)
  local rRoll = getRoll(rActor);
  ActionsManager.performAction(draginfo, rActor, rRoll);
end


-- modRoll function
function modRoll(rSource, rTarget, rRoll)
  local aAddDesc = {};
  local aAddDice = {};
  local nAddMod = 0;
  local bEffects = false;
  if rSource then
    -- apply turn roll modifiers
    -- -- Get roll effect modifiers
    local nEffectCount;
    aAddDice, nAddMod, nEffectCount = EffectManager5E.getEffectsBonus(rSource, {"TURN"}, false);
    if (nEffectCount > 0) then
        bEffects = true;
    end
    rRoll.nMod = rRoll.nMod + nAddMod;
    
    -- apply turn level adjustment?
    aAddDice, nAddMod, nEffectCount = EffectManager5E.getEffectsBonus(rSource, {"TURNLEVEL"}, false);
    if (nEffectCount > 0) then
        bEffects = true;
    end
    rRoll.nTarget = rRoll.nTarget + nAddMod;
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

function onRoll(rSource, rTarget, rRoll)
  ActionsManager2.decodeAdvantage(rRoll);

  local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
  local nMaxHDTurned = 0;
  local nMaxHDDestroyed = 0;
  local aTurnDice = {};
  local aHDTurn = {};
  
  if rRoll.nTarget then
    local nTotal = ActionsManager.total(rRoll);
    local nTargetDC = tonumber(rRoll.nTarget) or 0;
    local nMaxLevel = DataCommonADND.nDefaultTurnUndeadMaxLevel;
    local nMaxTurnHD = DataCommonADND.nDefaultTurnUndeadMaxHD;
    local nClericLevel = nTargetDC or 1;
    if (nClericLevel < 1) then
        nClericLevel = 1;
    elseif (nClericLevel > DataCommonADND.nDefaultTurnUndeadMaxLevel) then
        nClericLevel = DataCommonADND.nDefaultTurnUndeadMaxLevel;
    end

    rMessage.text = rMessage.text .. "[as Level " .. nClericLevel .. "] " .. nTotal;
    local bTurnedSome = false;
    local sTurn = "";
    for i=1, nMaxTurnHD,1 do
      local rTurn = {};
      local nTurnValue = DataCommonADND.aTurnUndead[nClericLevel][i];
      --  0 = Cannot turn
      -- -1 = Turn
      -- -2 = Destroy
      -- -3 = Additional 2d4 creatures effected.
      if nTurnValue ~= 0 and nTotal >= nTurnValue then
        rTurn.nTurnValue = nTurnValue; -- save turn value for this HD.
        rTurn.bTurn = true;
        local sTurnedResult = "(TURN)";
        if (nTurnValue == -1) then
            sTurnedResult = "(TURN!)";
        elseif (nTurnValue == -2) then
            sTurnedResult = "(DESTROY)";
            rTurn.bDestroy = true
        elseif (nTurnValue == -3) then
            sTurnedResult = "(DESTROY!)";
            rTurn.bDestroyPlus = true
        end
        
        local sTurnString = DataCommonADND.turn_name_index[i];
        -- grab the number before HD, match "2" 1-2HD or "10" for 10HD or "6" for 5-6HD.
        local sMaxHD = sTurnString:match("(%d+)HD");
        local nMaxHD = 0;
        if (sMaxHD ~= nil) then
          nMaxHD = tonumber(sMaxHD) or 0;
        end
        rTurn.nHD = nMaxHD;
        -- collected all the data into rTurn, now stuff into aHDTurn
        table.insert(aHDTurn,rTurn);

        local sTurnedType = "\r\n[" .. sTurnString;
        sTurn = sTurn .. sTurnedType .. sTurnedResult .. "]";
        bTurnedSome = true;
      end
    end
    if (bTurnedSome) then
      rMessage.font = "successfont";
      rMessage.icon = "chat_success";
    end

    Debug.console("manager_action_turnundead.lua","onRoll","sTurn=",sTurn);
    ChatManager.SystemMessage("TURN VALUE: " .. sTurn);
    
    -- if we have a dice count we turned something so roll it
    if (bTurnedSome) then
      table.insert(aTurnDice,'d6');
      table.insert(aTurnDice,'d6');
      local aExtraTurn = {}
      table.insert(aExtraTurn,'d4');
      table.insert(aExtraTurn,'d4');
      
      local nodeTargets = ActorManagerADND.getTargetNodes(rSource);
      local aTargets = nil;
      local bTurnedNPC = false;
      if (nodeTargets ~= nil) then
        -- sort targets by HD, low to high
        aTargets = sortByLevel(nodeTargets);
        -- if we have targets then we proceed
        if (#aTargets > 0) then 
          local aTurnedList = {};
          local nTurnBase = StringManager.evalDice(aTurnDice, 0);
          Debug.console("manager_action_turnundead.lua","onRoll","Turned Slots, 2d6, nTurnBase=",nTurnBase);
          ChatManager.SystemMessage("TURNED SLOTS [" .. nTurnBase .. "]");
          -- flip through #aHDTurn
          for i=1, #aHDTurn do
            local nTurnExtra = 0;
            -- check if turn/destroy/destroy+
            local bDestroy = aHDTurn[i].bDestroy;
            local bDestroyPlus = aHDTurn[i].bDestroyPlus;
            if bDestroyPlus then
            -- destroy+ turn (add 2d4)
              nTurnExtra = StringManager.evalDice(aExtraTurn, 0);
              Debug.console("manager_action_turnundead.lua","onRoll","Gained extra turn, 2d4, nTurnExtra=",nTurnExtra," For HD=",aHDTurn[i].nHD);
              ChatManager.SystemMessage("TURNED EXTRA SLOTS [" .. nTurnExtra .. "] for HD [" .. aHDTurn[i].nHD .. "]");
            end
            -- flip through sorted Targets
            local aTurnIDs = {};
            for nID=1,#aTargets do
              local sNodeName = aTargets[nID];
              if (sNodeName ~= nil) then
                local node = DB.findNode(sNodeName);
                -- if target.HD <= aHDTurn.nHD
                local nLevel = DB.getValue(node,"level",9999);
                local sCreatureType = DB.getValue(node,"type",""):lower();
                -- if type undead and level lower than HD effected by turn and not already turned
                if (sCreatureType:match("undead") ~= nil and nLevel <= aHDTurn[i].nHD 
                      and not getAlreadyTurned(aTurnedList,node)) then
                  bTurnedNPC = true;
                  -- if check if nTurnExtraUsed < nTurnExtra then nTurnExtraUsed +1 and mark target turned/destroyed
                  if (nTurnExtra > 0) then
                    nTurnExtra = nTurnExtra - 1;
                    handleTurn(rSource, node,rMessage,(bDestroy or bDestroyPlus));
                    table.insert(aTurnedList,node);
                  -- check if nTurnBaseUsed < nTurnBase then nTurnBaseUsed +1 and mark target turned/destroyed
                  elseif (nTurnBase > 0) then
                    nTurnBase = nTurnBase - 1;
                    handleTurn(rSource, node,rMessage,(bDestroy or bDestroyPlus));
                    table.insert(aTurnedList,node);
                  else
                    -- nothing, we have no more turn slots left.
                  end
                end -- sNodeName == nil
              end
            end -- next sorted target
          end -- next #aHDTurn
        else
          -- no targets
          rMessage.text = rMessage.text .. " [NO TARGETS]";
        end
      end
      if (not bTurnedNPC) then
        rMessage.font = "failfont";
        rMessage.icon = "chat_fail";
        rMessage.text = rMessage.text .. " [NOTHING TURNED!]";
      end
    end
  end
  Comm.deliverChatMessage(rMessage);
end

-- pass list of nodes with a "HD" record and sort by HD
function sortByLevel(nodes)
  local aSorted = {};
  for _,node in pairs(nodes) do
    table.insert(aSorted, node);
  end        
  table.sort(aSorted, function (a, b) return DB.getValue(a,"level",1) < DB.getValue(b,"level",1) end);
  return aSorted;
end
-- flip through list of already turned nodes and 
-- return true if the node passed already exists in it
function getAlreadyTurned(aTurnedList,node)
  local bFound = false
  for i=1, #aTurnedList do
    if aTurnedList[i] == node then
      bFound = true;
      break;
    end
  end
  return bFound;
end
-- handle turning a creature
function handleTurn(rSource, nodeTurn,rMessage,bDestroy)
  local rTarget = ActorManager.getActor("ct",nodeTurn);
  local sName = DB.getValue(nodeTurn,"name","NO-NAME");

  if (bDestroy) then
    notifyApplyObliteration(rSource,rTarget);
    rMessage.text = rMessage.text .."\r\nObliterated " .. sName .. "!";
  else
    notifyApplyTurn(rSource,rTarget);
    rMessage.text = rMessage.text .."\r\nTurned " .. sName .. "!";
  end
end
-- notify OOB to take control and handle this node update
function notifyApplyObliteration(rSource, rTarget)
  local msgOOB = {};
  msgOOB.type = OOB_MSGTYPE_APPLYOBLITERATE;
  
  local sSourceType, sSourceNode = ActorManager.getTypeAndNodeName(rSource);
  msgOOB.sSourceType = sSourceType;
  msgOOB.sSourceNode = sSourceNode;

  local sTargetType, sTargetNode = ActorManager.getTypeAndNodeName(rTarget);
  msgOOB.sTargetType = sTargetType;
  msgOOB.sTargetNode = sTargetNode;
  
  Comm.deliverOOBMessage(msgOOB, "");
end
-- oob takes control and makes change (sends to apply)
function handleApplyObliteration(msgOOB)
  local rSource = ActorManager.getActor(msgOOB.sSourceType, msgOOB.sSourceNode);
  local rTarget = ActorManager.getActor(msgOOB.sTargetType, msgOOB.sTargetNode);
  if rTarget then
    rTarget.nOrder = msgOOB.nTargetOrder;
  end
  
  local nTotal = tonumber(msgOOB.nTotal) or 0;
  applyObliteration(rSource, rTarget);
end
-- Obliterate rTarget (set Wounds to max HP+1 and kill it)
function applyObliteration(rSource, rTarget)
    -- obliterate undead
    local nodeTurn = ActorManager.getCTNode(rTarget);
    local nHPMax = DB.getValue(nodeTurn,"hptotal",0);
    --DB.setValue(nodeTurn,"wounds","number",nHPMax+1);
    ActionDamage.applyDamage(rSource, rTarget, false, "[OBLITERATION]", nHPMax+1);
end

-- function applyChange(sAdjustmentType)
-- local node = window.getDatabaseNode();
-- local rActor = ActorManager.getActorFromCT(node);
-- local nAdjustment = self.getValue();
-- if (sAdjustmentType == "heal") then
    -- nAdjustment = -(nAdjustment);
-- end
-- if (nAdjustment ~= 0) then
    -- ActionDamage.applyDamage(nil, rActor, CombatManager.isCTHidden(node), "DM manually applied adjustment-NOTSHOWN.", nAdjustment);
-- end
-- setValue(0);
-- window.close();
-- end


-- notify OOB to take control and handle this node update
function notifyApplyTurn(rSource, rTarget)
  local msgOOB = {};
  msgOOB.type = OOB_MSGTYPE_APPLYTURN;
  
  local sSourceType, sSourceNode = ActorManager.getTypeAndNodeName(rSource);
  msgOOB.sSourceType = sSourceType;
  msgOOB.sSourceNode = sSourceNode;

  local sTargetType, sTargetNode = ActorManager.getTypeAndNodeName(rTarget);
  msgOOB.sTargetType = sTargetType;
  msgOOB.sTargetNode = sTargetNode;
  
  Comm.deliverOOBMessage(msgOOB, "");
end
-- oob takes control and makes change (sends to apply)
function handleApplyTurned(msgOOB)
  local rSource = ActorManager.getActor(msgOOB.sSourceType, msgOOB.sSourceNode);
  local rTarget = ActorManager.getActor(msgOOB.sTargetType, msgOOB.sTargetNode);
  
  local nTotal = tonumber(msgOOB.nTotal) or 0;
  applyTurnedState(rSource, rTarget);
end
-- TURN rTarget (apply turn effect)
function applyTurnedState(rSource, rTarget)
  -- turn undead
  if not EffectManager5E.hasEffect(rTarget, "Turned") then
    EffectManager.addEffect("", "", ActorManager.getCTNode(rTarget), { sName = "Turned", nDuration = 0, sSource = rSource.sCTNode, nGMOnly = 0 }, true);
  end
end
