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
        nTargetDC = DB.getValue(nodeChar,"turn.level.total",1);
    end
	rRoll.sDesc = "[TURN] ";

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
            sTurnAmountRoll = "\r\n(roll 2d6 for number affected, lowest HD first)";
            sTurnHeader = " ->Turn can affect:";
        else
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

	ActionsManager2.encodeDesktopMods(rRoll);
	for _,vDie in ipairs(aAddDice) do
		if vDie:sub(1,1) == "-" then
			table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
		else
			table.insert(rRoll.aDice, "p" .. vDie:sub(2));
		end
	end
	rRoll.nMod = rRoll.nMod + nAddMod;
	
	ActionsManager2.encodeAdvantage(rRoll, false, false);
end
