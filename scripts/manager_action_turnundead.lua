-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
    ActionsManager.registerModHandler("turnundead", modRoll);
    ActionsManager.registerResultHandler("turnundead", onRoll);
end

function getRoll(rActor,nodeChar,nTargetDC, bSecretRoll)
	local rRoll = {};
	rRoll.sType = "turnundead";
	--rRoll.aDice = { "d20" };
    rRoll.nMod = 0;
    
    local aDice = DB.getValue(nodeChar,"turn.dice");
    if aDice == nil then
        aDice = DataCommonADND.nDefaultTurnDice;
    end
    rRoll.aDice = aDice;
	if (nTargetDC == nil) then
        -- turn.total is the total levels of cleric to turn as
        nTargetDC = DB.getValue(nodeChar,"turn.total",1);
    end
	rRoll.sDesc = "[TURNUNDEAD] ";

	rRoll.bSecret = bSecretRoll;

	rRoll.nTarget = nTargetDC;
	
	return rRoll;
end

-- TargetDC is the level of cleric attempting turn
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
        
        local nMaxLevel = DataCommonADND.nDefaultTurnUndeadMaxLevel;
        local nMaxTurnHD = DataCommonADND.nDefaultTurnUndeadMaxHD;
        local nClericLevel = nTargetDC or 1;
        if (nClericLevel < 1) then
            nClericLevel = 1;
        elseif (nClericLevel > DataCommonADND.nDefaultTurnUndeadMaxLevel) then
            nClericLevel = DataCommonADND.nDefaultTurnUndeadMaxLevel;
        end

        rMessage.text = rMessage.text .. " (as Level " .. nClericLevel .. ")";
        
        local sTurn = "";
        local bTurnedSome = false;
        local bTurnedExtra = false;
        for i=1, nMaxTurnHD,1 do
            local nTurnValue = DataCommonADND.aTurnUndead[nClericLevel][i];
            --  0 = Cannot turn
            -- -1 = Turn
            -- -2 = Destroy
            -- -3 = Additional 2d4 creatures effected.
            if nTurnValue ~= 0 and nTotal >= nTurnValue then
                local sTurnedResult = "(TURN)";
                if (nTurnValue == -1) then
                    sTurnedResult = "(TURN!)";
                elseif (nTurnValue == -2) then
                    sTurnedResult = "(DESTROY)";
                elseif (nTurnValue == -3) then
                    sTurnedResult = "(DESTROY!)";
                    bTurnedExtra = true;
                end
                local sTurnedType = "\r\n[" .. DataCommonADND.turn_name_index[i];
                sTurn = sTurn .. sTurnedType .. sTurnedResult .. "]";
                bTurnedSome = true;
            end
        end
        local sTurnAmountRoll = "";
        local sTurnHeader = "";
        if (bTurnedSome) then
       		rMessage.font = "successfont";
       		rMessage.icon = "chat_success";

            sTurnAmountRoll = "\r\n(roll 2d6 for number affected, lowest HD first)";
            sTurnHeader = "\r\nTurn can affect:";
        else
       		rMessage.font = "failfont";
       		rMessage.icon = "chat_fail";
            sTurn = "[NOTHING TURNED!]";
        end
        if (bTurnedExtra) then
            sTurnAmountRoll = sTurnAmountRoll .. "(add 2d4 more extra)";
        end
        rMessage.text = rMessage.text .. sTurnHeader .. sTurn .. sTurnAmountRoll;
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
