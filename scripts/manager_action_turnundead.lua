-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
    ActionsManager.registerModHandler("turnundead", modRoll);
    ActionsManager.registerResultHandler("turnundead", onRoll);
    --ActionsManager.registerResultHandler("turnundead_count", onRoll_TurnCount);
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
	--if (nTargetDC == nil) then
        -- turn.total is the total levels of cleric to turn as
  local nTargetDC = DB.getValue(nodeChar,"turn.total",1);
--    end
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

-- function onRoll_TurnCount(rSource, rTarget, rRoll)
  -- ActionsManager2.decodeAdvantage(rRoll);
  -- local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
  -- local nTotal = ActionsManager.total(rRoll);
  -- local nMaxHDTurned = tonumber(rRoll.nMaxHDTurned) or 0;
  -- local nMaxHDDestroyed = tonumber(rRoll.nMaxHDDestroyed) or 0;
-- Debug.console("manager_action_turnundead.lua","onRoll_TurnCount","rRoll",rRoll);
-- Debug.console("manager_action_turnundead.lua","onRoll_TurnCount","rRoll.aHDTurn",rRoll.aHDTurn);
-- Debug.console("manager_action_turnundead.lua","onRoll_TurnCount","nTotal",nTotal);
  
  -- if (nMaxHDDestroyed > 0) then
    -- rMessage.text = rMessage.text .. " [Max HD Obliterated " .. nMaxHDDestroyed .. "]";
  -- end
  -- if (nMaxHDTurned > 0) then
    -- rMessage.text = rMessage.text .. " [Max HD Turned " .. nMaxHDTurned .. "]";
  -- end
  -- rMessage.text = rMessage.text .. " " .. nTotal;
  -- Comm.deliverChatMessage(rMessage);
-- end

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
        local bTurnedExtra = false;
        
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
                    bTurnedExtra = true;
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
                table.insert(aHDTurn,rTurn);
                -- if this HD max is larger, save it
                if nMaxHD > nMaxHDDestroyed and (nTurnValue == -2 or nTurnValue == -3) then
                  nMaxHDDestroyed = nMaxHD;
                elseif nMaxHD > nMaxHDTurned then
                  nMaxHDTurned = nMaxHD;
                end

                local sTurnedType = "\r\n[" .. sTurnString;
                sTurn = sTurn .. sTurnedType .. sTurnedResult .. "]";
                bTurnedSome = true;
            end
        end
        local sTurnAmountRoll = "";
        local sTurnHeader = "";
        if (bTurnedSome) then
       		rMessage.font = "successfont";
       		rMessage.icon = "chat_success";

            --sTurnAmountRoll = "\r\n(roll 2d6 for number affected, lowest HD first)";
            sTurnHeader = "\r\nTurn can affect:";
            table.insert(aTurnDice,'d6');
            table.insert(aTurnDice,'d6');
        else
       		rMessage.font = "failfont";
       		rMessage.icon = "chat_fail";
            sTurn = " [NOTHING TURNED!]";
        end
        if (bTurnedExtra) then
            --sTurnAmountRoll = sTurnAmountRoll .. "(add 2d4 more extra)";
            --table.insert(aTurnDice,'d4');
            --table.insert(aTurnDice,'d4');
        end
        --rMessage.text = rMessage.text .. sTurnHeader .. sTurn .. sTurnAmountRoll;
        rMessage.text = rMessage.text .. sTurnHeader .. sTurn;
	end

  -- StringManager.evalDice(dDurationDice, nModDice)
--Debug.console("manager_action_turnundead.lua","onRoll","aHDTurn",aHDTurn);
--Debug.console("manager_action_turnundead.lua","onRoll","rTarget",rTarget);
  
  -- if we have a dice count we turned something so roll it
  if (#aTurnDice > 0) then
    local aExtraTurn = {}
    table.insert(aExtraTurn,'d4');
    table.insert(aExtraTurn,'d4');
    
    local nodeTargets = ActorManagerADND.getTargets(rSource);
    local aTargets = nil;
    if (nodeTargets ~= nil) then
--Debug.console("manager_action_turnundead.lua","onRoll","nodeTargets",nodeTargets);
      -- sort targets by HD, low to high
      aTargets = sortByLevel(nodeTargets);
--Debug.console("manager_action_turnundead.lua","onRoll","aTargets",aTargets);      
    end -- nodeCT != nil
    -- if we have targets then we proceed
    if (aTargets ~= nil) then 
      local aTurnedList = {};
--Debug.console("manager_action_turnundead.lua","onRoll","aTargets",aTargets);    
      local nTurnBase = StringManager.evalDice(aTurnDice, 0);
      -- flip through #aHDTurn
      for i=1, #aHDTurn do
        local nTurnExtra = 0;
        -- check if turn/destroy/destroy+
        local bDestroy = aHDTurn[i].bDestroy;
        local bDestroyPlus = aHDTurn[i].bDestroyPlus;
        if bDestroyPlus then
        -- destroy+ turn (add 2d4)
          nTurnExtra = StringManager.evalDice(aExtraTurn, 0);
        --elseif bDestroy then
        -- destroy turn
        --else
        -- plain turn
        end
        -- flip through sorted Targets
        --for ii=1, #aTargets  do
        local aTurnIDs = {};
        for nID=1,#aTargets do
          local sNodeName = aTargets[nID];
          if (sNodeName ~= nil) then
            local node = DB.findNode(aTargets[nID]);
            --local node = DB.findNode(aTargets[i]);
            -- if target.HD <= aHDTurn.nHD
            local nLevel = DB.getValue(node,"level",9999);
            if (nLevel <= aHDTurn[i].nHD and not getAlreadyTurned(aTurnedList,node)) then
            -- check if nTurnBaseUsed < nTurnBase then nTurnBaseUsed +1 and mark target turned/destroyed
              if (nTurnBase > 0) then
                nTurnBase = nTurnBase - 1;
                  handleTurn(node,(bDestroy or bDestroyPlus));
                  table.insert(aTurnedList,node);
            -- elseif check if nTurnExtraUsed < nTurnExtra then nTurnExtraUsed +1 and mark target turned/destroyed
              elseif (nTurnExtra > 0) then
                nTurnExtra = nTurnExtra - 1;
                handleTurn(node,(bDestroy or bDestroyPlus));
                table.insert(aTurnedList,node);
              else
                -- nothing, we have no more turn slots left.
              end
            end -- sNodeName == nil
          end
        -- next sorted target
        end
      -- next #aHDTurn
      end
    end


    --local rTurnHDRoll = { sType = "turnundead_count", sDesc = "[TURNED COUNT]", aDice = aTurnDice, nMod = 0, bSecret = rRoll.bSecret, nMaxHDTurned = nMaxHDTurned, nMaxHDDestroyed = nMaxHDDestroyed, aHDTurn = aHDTurn  };
    --ActionsManager.performAction(nil, rSource, rTurnHDRoll);
  end
-- Debug.console("manager_action_turnundead.lua","onRoll","rTurnHDRoll",rTurnHDRoll);
-- Debug.console("manager_action_turnundead.lua","onRoll","nTurnedTotal",nTurnedTotal);
	
	Comm.deliverChatMessage(rMessage);
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
function handleTurn(nodeTurn,bDestroy)
local sName = DB.getValue(nodeTurn,"name","NO-NAME");
  if (bDestroy) then
    -- obliterate undead
--Debug.console("manager_action_turnundead.lua","handleTurn","-----------------------obliterate",nodeTurn);  
    local nHPMax = DB.getValue(nodeTurn,"hptotal",0);
    DB.setValue(nodeTurn,"wounds","number",nHPMax+1);
  else
    -- turn undead
--Debug.console("manager_action_turnundead.lua","handleTurn","========================turn",nodeTurn);
    EffectManager.addEffect("", "", nodeTurn, { sName = "Turned", nDuration = 0 }, true);
  end
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

function modRoll(rSource, rTarget, rRoll)
	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;
  local bEffects = false;

  Debug.console("manager_action_turnundead.lua","modRoll","rSource",rSource);
  Debug.console("manager_action_turnundead.lua","modRoll","rTarget",rTarget);
  
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
