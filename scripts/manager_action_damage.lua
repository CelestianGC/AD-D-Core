-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYDMG = "applydmg";
OOB_MSGTYPE_APPLYDMGSTATE = "applydmgstate";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYDMG, handleApplyDamage);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYDMGSTATE, handleApplyDamageState);

	ActionsManager.registerModHandler("death", modDeathRoll);
	ActionsManager.registerResultHandler("death", onDeathRoll);

	ActionsManager.registerModHandler("damage", modDamage);
	ActionsManager.registerPostRollHandler("damage", onDamageRoll);
	ActionsManager.registerResultHandler("damage", onDamage);
end

function handleApplyDamage(msgOOB)
	local rSource = ActorManager.getActor(msgOOB.sSourceType, msgOOB.sSourceNode);
	local rTarget = ActorManager.getActor(msgOOB.sTargetType, msgOOB.sTargetNode);
	if rTarget then
		rTarget.nOrder = msgOOB.nTargetOrder;
	end
	
	local nTotal = tonumber(msgOOB.nTotal) or 0;
	applyDamage(rSource, rTarget, (tonumber(msgOOB.nSecret) == 1), msgOOB.sDamage, nTotal);
end

function notifyApplyDamage(rSource, rTarget, bSecret, sDesc, nTotal)
	if not rTarget then
		return;
	end
	local sTargetType, sTargetNode = ActorManager.getTypeAndNodeName(rTarget);
	if sTargetType ~= "pc" and sTargetType ~= "ct" then
		return;
	end

	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYDMG;
	
	if bSecret then
		msgOOB.nSecret = 1;
	else
		msgOOB.nSecret = 0;
	end
	msgOOB.nTotal = nTotal;
	msgOOB.sDamage = sDesc;
	msgOOB.sTargetType = sTargetType;
	msgOOB.sTargetNode = sTargetNode;
	msgOOB.nTargetOrder = rTarget.nOrder;

	local sSourceType, sSourceNode = ActorManager.getTypeAndNodeName(rSource);
	msgOOB.sSourceType = sSourceType;
	msgOOB.sSourceNode = sSourceNode;

	Comm.deliverOOBMessage(msgOOB, "");
end

function performDeathRoll(draginfo, rActor)
	local rRoll = { };
	rRoll.sType = "death";
	rRoll.aDice = { "d20" };
	rRoll.nMod = 0;
	
	rRoll.sDesc = "[DEATH]";
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "damage";
	rRoll.aDice = {};
	rRoll.nMod = 0;
	rRoll.bWeapon = rAction.bWeapon;
	
	rRoll.sDesc = "[DAMAGE";
	if rAction.order and rAction.order > 1 then
		rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
	end
	if rAction.range then
		rRoll.sDesc = rRoll.sDesc .. " (" .. rAction.range ..")";
		rRoll.range = rAction.range;
	end
	rRoll.sDesc = rRoll.sDesc .. "] " .. rAction.label;
	
	-- Save the damage clauses in the roll structure
	rRoll.clauses = rAction.clauses;
	
	-- Add the dice and modifiers
	for _,vClause in pairs(rRoll.clauses) do
		for _,vDie in ipairs(vClause.dice) do
			table.insert(rRoll.aDice, vDie);
		end
		rRoll.nMod = rRoll.nMod + vClause.modifier;
	end
	
	-- Encode the damage types
	encodeDamageTypes(rRoll);
	
	return rRoll;
end

function performRoll(draginfo, rActor, rAction)
	local rRoll = getRoll(rActor, rAction);
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modDeathRoll(rSource, rTarget, rRoll)
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

	if rSource then
		local bEffects = false;

		-- Build filter
		local aSaveFilter = {"death"};

		-- Get effect modifiers
		local aAddDice, nAddMod, nEffectCount = EffectManager.getEffectsBonus(rSource, {"SAVE"}, false, {"death"});
		if nEffectCount > 0 then
			bEffects = true;
		end
		
		-- Get condition modifiers
		if EffectManager.hasEffectCondition(rSource, "ADVDEATH") then
			bADV = true;
			bEffects = true;
		end
		if EffectManager.hasEffectCondition(rSource, "DISDEATH") then
			bDIS = true;
			bEffects = true;
		end

		-- If effects happened, then add note
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
	
	ActionsManager2.encodeAdvantage(rRoll, bADV, bDIS);
end

function modDamage(rSource, rTarget, rRoll)
	-- Extract damage type information from roll
	decodeDamageTypes(rRoll);

	-- Set up
	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;
	
	-- Build attack type filter
	local aAttackFilter = {};
	if rRoll.range == "R" then
		table.insert(aAttackFilter, "ranged");
	elseif rRoll.range == "M" then
		table.insert(aAttackFilter, "melee");
	end
	
	-- Track how many damage clauses before effects applied
	local nPreEffectClauses = #(rRoll.clauses);
	
	-- Determine critical
	local bCritical = ModifierStack.getModifierKey("DMG_CRIT") or Input.isShiftPressed();
	if ActionAttack.isCrit(rSource, rTarget) then
		bCritical = true;
	end

	-- If source actor, then get modifiers
	if rSource then
		local bEffects = false;
		local aEffectDice = {};
		local nEffectMod = 0;

		-- Apply ability modifiers
		for _,vClause in ipairs(rRoll.clauses) do
			local nBonusStat, nBonusEffects = ActorManager2.getAbilityEffectsBonus(rSource, vClause.stat);
			if nBonusEffects > 0 then
				bEffects = true;
				nEffectMod = nEffectMod + nBonusStat;
				vClause.modifier = vClause.modifier + nBonusStat;
				rRoll.nMod = rRoll.nMod + nBonusStat;
			end
		end
		
		-- Apply general damage modifiers
		local aEffects, nEffectCount = EffectManager.getEffectsBonusByType(rSource, "DMG", true, aAttackFilter, rTarget);
		if nEffectCount > 0 then
			local sEffectBaseType = "";
			if #(rRoll.clauses) > 0 then
				sEffectBaseType = rRoll.clauses[1].dmgtype or "";
			end
			
			for _,v in pairs(aEffects) do
				local bCritEffect = false;
				local aEffectDmgType = {};
				local aEffectSpecialDmgType = {};
				for _,sType in ipairs(v.remainder) do
					if StringManager.contains(DataCommon.specialdmgtypes, sType) then
						table.insert(aEffectSpecialDmgType, sType);
						if sType == "critical" then
							bCritEffect = true;
						end
					elseif StringManager.contains(DataCommon.dmgtypes, sType) then
						table.insert(aEffectDmgType, sType);
					end
				end
				
				if not bCritEffect or bCritical then
					bEffects = true;
			
					local rClause = {};
					
					rClause.dice = {};
					for _,vDie in ipairs(v.dice) do
						table.insert(aEffectDice, vDie);
						table.insert(rClause.dice, vDie);
						if vDie:sub(1,1) == "-" then
							table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
						else
							table.insert(rRoll.aDice, "p" .. vDie:sub(2));
						end
					end

					nEffectMod = nEffectMod + v.mod;
					rClause.modifier = v.mod;
					rRoll.nMod = rRoll.nMod + v.mod;
					
					rClause.stat = "";

					if #aEffectDmgType == 0 then
						table.insert(aEffectDmgType, sEffectBaseType);
					end
					for _,vSpecialDmgType in ipairs(aEffectSpecialDmgType) do
						table.insert(aEffectDmgType, vSpecialDmgType);
					end
					rClause.dmgtype = table.concat(aEffectDmgType, ",");

					table.insert(rRoll.clauses, rClause);
				end
			end
		end
		
		-- Apply damage type modifiers
		local aEffects = EffectManager.getEffectsByType(rSource, "DMGTYPE", {});
		local aAddTypes = {};
		for _,v in ipairs(aEffects) do
			for _,v2 in ipairs(v.remainder) do
				local aSplitTypes = StringManager.split(v2, ",", true);
				for _,v3 in ipairs(aSplitTypes) do
					table.insert(aAddTypes, v3);
				end
			end
		end
		if #aAddTypes > 0 then
			for _,vClause in ipairs(rRoll.clauses) do
				local aSplitTypes = StringManager.split(vClause.dmgtype, ",", true);
				for _,v2 in ipairs(aAddTypes) do
					if not StringManager.contains(aSplitTypes, v2) then
						if vClause.dmgtype ~= "" then
							vClause.dmgtype = vClause.dmgtype .. "," .. v2;
						else
							vClause.dmgtype = v2;
						end
					end
				end
			end
		end
		
		-- Apply condition modifiers
		if EffectManager.hasEffect(rSource, "Incorporeal") then
			bEffects = true;
			table.insert(aAddDesc, "[INCORPOREAL]");
		end

		-- Add note about effects
		if bEffects then
			local sEffects = "";
			local sMod = StringManager.convertDiceToString(aEffectDice, nEffectMod, true);
			if sMod ~= "" then
				sEffects = "[" .. Interface.getString("effects_tag") .. " " .. sMod .. "]";
			else
				sEffects = "[" .. Interface.getString("effects_tag") .. "]";
			end
			table.insert(aAddDesc, sEffects);
		end
	end
	
	-- Handle critical
	if bCritical then
		rRoll.bCritical = true;
		table.insert(aAddDesc, "[CRITICAL]");
		
		-- Double the dice, and add extra critical dice
		local nOldDieIndex = 1;
		local aNewClauses = {};
		local aNewDice = {};
		local nMaxSides = 0;
		local nMaxClause = 0;
		local nMaxDieIndex = 0;
		for kClause,vClause in ipairs(rRoll.clauses) do
			table.insert(aNewClauses, vClause);
			
			local bApplyCritToClause = true;
			local aSplitByDmgType = StringManager.split(vClause.dmgtype, ",", true);
			for _,vDmgType in ipairs(aSplitByDmgType) do
				if vDmgType == "critical" then
					bApplyCritToClause = false;
					break;
				end
			end
			
			for _,vDie in ipairs(vClause.dice) do
				table.insert(aNewDice, rRoll.aDice[nOldDieIndex]);
				nOldDieIndex = nOldDieIndex + 1;
			end
			
			if bApplyCritToClause then
				local bNewMax = false;
				local aCritClauseDice = {};
				for kDie,vDie in ipairs(vClause.dice) do
					if vDie:sub(1,1) == "-" then
						table.insert(aNewDice, "-g" .. vDie:sub(3));
					else
						table.insert(aNewDice, "g" .. vDie:sub(2));
					end
					table.insert(aCritClauseDice, vDie);
					
					if kClause <= nPreEffectClauses and vDie:sub(1,1) ~= "-" then
						local nDieSides = tonumber(vDie:sub(2)) or 0;
						if nDieSides > nMaxSides then
							bNewMax = true;
							nMaxSides = nDieSides;
						end
					end
				end

				if #aCritClauseDice > 0 then
					local rNewClause = { dice = {}, modifier = 0, stat = "" };
					if vClause.dmgtype == "" then
						rNewClause.dmgtype = "critical";
					else
						rNewClause.dmgtype = vClause.dmgtype .. ",critical";
					end
					for kDie, vDie in ipairs(aCritClauseDice) do
						table.insert(rNewClause.dice, vDie);
					end
					table.insert(aNewClauses, rNewClause);
					
					if bNewMax then
						nMaxClause = #aNewClauses;
						nMaxDieIndex = #aNewDice + 1;
					end
				end
			end
		end
		if nMaxSides > 0 then
			local nCritDice = 0;
			if rRoll.bWeapon and ActorManager.getType(rSource) == "pc" then
				local nodePC = ActorManager.getCreatureNode(rSource);
				if rRoll.range == "R" then
					nCritDice = DB.getValue(nodePC, "weapon.critdicebonus.ranged", 0);
				else
					nCritDice = DB.getValue(nodePC, "weapon.critdicebonus.melee", 0);
				end
			end
			
			if nCritDice > 0 then
				for i = 1, nCritDice do
					table.insert(aNewDice, nMaxDieIndex, "g" .. nMaxSides);
					table.insert(aNewClauses[nMaxClause].dice, "d" .. nMaxSides);
				end
			end
		end
		rRoll.clauses = aNewClauses;
		rRoll.aDice = aNewDice;
	end
	
	-- Handle fixed damage option
	if not ActorManager.isPC(rSource) and OptionsManager.isOption("NPCD", "fixed") then
		local aFixedClauses = {};
		local aFixedDice = {};
		local nFixedPositiveCount = 0;
		local nFixedNegativeCount = 0;
		local nFixedMod = 0;

		for kClause,vClause in ipairs(rRoll.clauses) do
			if kClause <= nPreEffectClauses then
				local nClauseFixedMod = 0;
				for kDie,vDie in ipairs(vClause.dice) do
					if vDie:sub(1,1) == "-" then
						nFixedNegativeCount = nFixedNegativeCount + 1;
						nClauseFixedMod = nClauseFixedMod - math.floor(math.ceil(tonumber(vDie:sub(3)) or 0) / 2);
						if nFixedNegativeCount % 2 == 0 then
							nClauseFixedMod = nClauseFixedMod - 1;
						end
					else
						nFixedPositiveCount = nFixedPositiveCount + 1;
						nClauseFixedMod = nClauseFixedMod + math.floor(math.ceil(tonumber(vDie:sub(2)) or 0) / 2);
						if nFixedPositiveCount % 2 == 0 then
							nClauseFixedMod = nClauseFixedMod + 1;
						end
					end
					vClause.dice = {};
					vClause.modifier = vClause.modifier + nClauseFixedMod;
				end
				nFixedMod = nFixedMod + nClauseFixedMod;
			else
				for kDie,vDie in ipairs(vClause.dice) do
					table.insert(aFixedDice, vDie);
				end
			end
			
			table.insert(aFixedClauses, vClause);
		end
		
		rRoll.clauses = aFixedClauses;
		rRoll.aDice = aFixedDice;
		rRoll.nMod = rRoll.nMod + nFixedMod;
	end

	-- Handle half damage
	local bHalf = ModifierStack.getModifierKey("DMG_HALF");
	if bHalf then
		table.insert(aAddDesc, "[HALF]");
	end
	
	-- Add notes to roll description
	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
	end
	
	-- Add damage type info to roll description
	encodeDamageTypes(rRoll);

	-- Apply desktop modifiers
	ActionsManager2.encodeDesktopMods(rRoll);
end

function onDeathRoll(rSource, rTarget, rRoll)
	ActionsManager2.decodeAdvantage(rRoll);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	if ActorManager2.getPercentWounded(rSource) >= 1 then
		local nTotal = ActionsManager.total(rRoll);
		
		local bStatusCheck = true;
		local _,sOriginalStatus = ActorManager2.getPercentWounded(rSource);
		
		local nFirstDie = 0;
		if #(rRoll.aDice) > 0 then
			nFirstDie = rRoll.aDice[1].result or 0;
		end
		if nTotal <= 1 then
			rMessage.text = rMessage.text .. " [CRITICAL FAILURE]";
			
			local sSourceType, sSourceNode = ActorManager.getTypeAndNodeName(rSource);
			local nodeSource = nil;
			if sSourceType == "pc" or sSourceType == "ct" then
				nodeSource = DB.findNode(sSourceNode);
			end
			if nodeSource then
				local nValue = DB.getValue(nodeSource, "hp.deathsavefail", 0);
				if nValue < 3 then
					nValue = math.min(nValue + 2, 3);
					DB.setValue(nodeSource, "hp.deathsavefail", "number", nValue);
				end
			end
		elseif nFirstDie == 20 then
			rMessage.text = rMessage.text .. " [CRITICAL SUCCESS]";
			
			ActionDamage.applyDamage(nil, rSource, rRoll.bSecret, "[HEAL]", 1);
			bStatusCheck = false;
		elseif nTotal >= 10 then
			rMessage.text = rMessage.text .. " [SUCCESS]";

			local sSourceType, sSourceNode = ActorManager.getTypeAndNodeName(rSource);
			local nodeSource = nil;
			if sSourceType == "pc" or sSourceType == "ct" then
				nodeSource = DB.findNode(sSourceNode);
			end
			if nodeSource then
				local nValue = DB.getValue(nodeSource, "hp.deathsavesuccess", 0);
				if nValue < 3 then
					nValue = nValue + 1;
					DB.setValue(nodeSource, "hp.deathsavesuccess", "number", nValue);
				end
				if nValue >= 3 then
					EffectManager.addEffect("", "", ActorManager.getCTNode(rSource), { sName = "Stable", nDuration = 0 }, true);
				end
			end
		else
			rMessage.text = rMessage.text .. " [FAILURE]";

			local sSourceType, sSourceNode = ActorManager.getTypeAndNodeName(rSource);
			local nodeSource = nil;
			if sSourceType == "pc" or sSourceType == "ct" then
				nodeSource = DB.findNode(sSourceNode);
			end
			if nodeSource then
				local nValue = DB.getValue(nodeSource, "hp.deathsavefail", 0);
				if nValue < 3 then
					DB.setValue(nodeSource, "hp.deathsavefail", "number", nValue + 1);
				end
			end
		end
		
		if bStatusCheck then
			local bShowStatus = false;
			if ActorManager.getFaction(rTarget) == "friend" then
				bShowStatus = not OptionsManager.isOption("SHPC", "off");
			else
				bShowStatus = not OptionsManager.isOption("SHNPC", "off");
			end
			if bShowStatus then
				local _,sNewStatus = ActorManager2.getPercentWounded(rSource);
				if sOriginalStatus ~= sNewStatus then
					rMessage.text = rMessage.text .. " [" .. Interface.getString("combat_tag_status") .. ": " .. sNewStatus .. "]";
				end
			end
		end
	end
	
	Comm.deliverChatMessage(rMessage);
end

function onDamageRoll(rSource, rRoll)
	-- Handle rerolls
	local nReroll = tonumber(rRoll.sDesc:match("%[REROLL (%d+)%]")) or 0;
	if nReroll > 0 then
		local aReroll = {};
		
		for k, vDie in ipairs(rRoll.aDice) do
			if math.abs(vDie.result) <= nReroll then
				local nDieSides = tonumber(string.match(vDie.type, "[%-%+]?[a-z](%d+)")) or 0;
				if nDieSides > 0 then
					local nSubtotal = math.random(nDieSides);
					if vDie.result < 0 then
						vDie.result = -nSubtotal;
					else
						vDie.result = nSubtotal;
					end
				end
				
				table.insert(aReroll, "D" .. k .. "=" .. vDie.result);
			end
		end
		
		if #aReroll > 0 then
			rRoll.sDesc = rRoll.sDesc .. " [RESULT MOD " .. table.concat(aReroll, ",") .. "]";
		end
	end
	
	-- Decode damage types
	decodeDamageTypes(rRoll, true);
end

function onDamage(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.text = string.gsub(rMessage.text, " %[MOD:[^]]*%]", "");

	-- Send the chat message
	local bShowMsg = true;
	if rTarget and rTarget.nOrder and rTarget.nOrder ~= 1 then
		bShowMsg = false;
	end
	if bShowMsg then
		Comm.deliverChatMessage(rMessage);
	end

	-- Apply damage to the PC or CT entry referenced
	local nTotal = ActionsManager.total(rRoll);
	notifyApplyDamage(rSource, rTarget, rMessage.secret, rMessage.text, nTotal);
end

--
-- UTILITY FUNCTIONS
--

function encodeDamageTypes(rRoll)
	for _,vClause in ipairs(rRoll.clauses) do
		if vClause.dmgtype and vClause.dmgtype ~= "" then
			local sDice = StringManager.convertDiceToString(vClause.dice, vClause.modifier);
			rRoll.sDesc = rRoll.sDesc .. string.format(" [TYPE: %s (%s)(%s)]", vClause.dmgtype, sDice, vClause.stat or "");
		end
	end
end

function decodeDamageTypes(rRoll, bFinal)
	-- Process each type clause in the damage description (INITIAL ROLL)
	local nMainDieIndex = 0;
	rRoll.clauses = {};
	for sDamageType, sDamageDice, sDamageAbility in string.gmatch(rRoll.sDesc, "%[TYPE: ([^(]*) %(([^)]*)%)%((%w*)%)%]") do
		local rClause = {};
		rClause.dmgtype = StringManager.trim(sDamageType);
		rClause.stat = sDamageAbility;
		rClause.dice, rClause.modifier = StringManager.convertStringToDice(sDamageDice);
		rClause.nTotal = rClause.modifier;
		for _,vDie in ipairs(rClause.dice) do
			nMainDieIndex = nMainDieIndex + 1;
			if rRoll.aDice[nMainDieIndex] then
				rClause.nTotal = rClause.nTotal + (rRoll.aDice[nMainDieIndex].result or 0);
			end
		end
		
		table.insert(rRoll.clauses, rClause);
	end

	-- Process each type clause in the damage description (DRAG ROLL RESULT)
	local nClauses = #(rRoll.clauses);
	for sDamageType, sDamageDice in string.gmatch(rRoll.sDesc, "%[TYPE: ([^(]*) %(([^)]*)%)]") do
		local sTotal = string.match(sDamageDice, "=(%d+)");
		if sTotal then
			local nTotal = tonumber(sTotal) or 0;
			
			local rClause = {};
			rClause.dmgtype = StringManager.trim(sDamageType);
			rClause.stat = "";
			rClause.dice = {};
			rClause.modifier = nTotal;
			rClause.nTotal = nTotal;

			table.insert(rRoll.clauses, rClause);
		end
	end
	
	-- Add untyped clause if no TYPE tag found
	if #(rRoll.clauses) == 0 then
		local rClause = {};
		rClause.dmgtype = "";
		rClause.stat = "";
		rClause.dice = {};
		rClause.modifier = rRoll.nMod;
		rClause.nTotal = rRoll.nMod;
		for _,vDie in ipairs(rRoll.aDice) do
			if type(vDie) == "table" then
				table.insert(rClause.dice, vDie.type);
				rClause.nTotal = rClause.nTotal + (vDie.result or 0); 
			else
				table.insert(rClause.dice, vDie);
			end
		end

		table.insert(rRoll.clauses, rClause);
	end
	
	-- Handle drag results that are halved or doubled
	if #(rRoll.aDice) == 0 then
		local nResultTotal = 0;
		for i = nClauses + 1, #(rRoll.clauses) do
			nResultTotal = rRoll.clauses[i].nTotal;
		end
		if nResultTotal > 0 and nResultTotal ~= rRoll.nMod then
			if math.floor(nResultTotal / 2) == rRoll.nMod then
				for _,vClause in ipairs(rRoll.clauses) do
					vClause.modifier = math.floor(vClause.modifier / 2);
					vClause.nTotal = math.floor(vClause.nTotal / 2);
				end
			elseif nResultTotal * 2 == rRoll.nMod then
				for _,vClause in ipairs(rRoll.clauses) do
					vClause.modifier = 2 * vClause.modifier;
					vClause.nTotal = 2 * vClause.nTotal;
				end
			end
		end
	end
	
	-- Remove damage type information from roll description
	rRoll.sDesc = string.gsub(rRoll.sDesc, " %[TYPE:[^]]*%]", "");
	
	if bFinal then
		local nFinalTotal = ActionsManager.total(rRoll);

		-- Handle minimum damage
		if nFinalTotal < 0 and rRoll.aDice and #rRoll.aDice > 0 then
			rRoll.sDesc = rRoll.sDesc .. " [MIN DAMAGE]";
			rRoll.nMod = rRoll.nMod - nFinalTotal;
			nFinalTotal = 0;
		end

		-- Capture any manual modifiers and adjust damage types accordingly
		-- NOTE: Positive values are added to first damage clause, Negative values reduce damage clauses until none remain
		local nClausesTotal = 0;
		for _,vClause in ipairs(rRoll.clauses) do
			nClausesTotal = nClausesTotal + vClause.nTotal;
		end
		if nFinalTotal ~= nClausesTotal then
			local nRemainder = nFinalTotal - nClausesTotal;
			if nRemainder > 0 then
				if #(rRoll.clauses) == 0 then
					table.insert(rRoll.clauses, { dmgtype = "", stat = "", dice = {}, modifier = nRemainder, nTotal = nRemainder})
				else
					rRoll.clauses[1].modifier = rRoll.clauses[1].modifier + nRemainder;
					rRoll.clauses[1].nTotal = rRoll.clauses[1].nTotal + nRemainder;
				end
			else
				for _,vClause in ipairs(rRoll.clauses) do
					if vClause.nTotal >= -nRemainder then
						vClause.modifier = vClause.modifier + nRemainder;
						vClause.nTotal = vClause.nTotal + nRemainder;
						break;
					else
						vClause.modifier = vClause.modifier - vClause.nTotal;
						nRemainder = nRemainder + vClause.nTotal;
						vClause.nTotal = 0;
					end
				end
			end
		end
		
		-- Collapse damage clauses into smallest set, then add to roll description as text
		local aDamage = getDamageStrings(rRoll.clauses);
		for _, rDamage in ipairs(aDamage) do
			local sDice = StringManager.convertDiceToString(rDamage.aDice, rDamage.nMod);
			local sDmgTypeOutput = rDamage.sType;
			if sDmgTypeOutput == "" then
				sDmgTypeOutput = "untyped";
			end
			rRoll.sDesc = rRoll.sDesc .. string.format(" [TYPE: %s (%s=%d)]", sDmgTypeOutput, sDice, rDamage.nTotal);
		end
	end
end

-- Collapse damage clauses by damage type (in the original order, if possible)
function getDamageStrings(clauses)
	local aOrderedTypes = {};
	local aDmgTypes = {};
	for _,vClause in ipairs(clauses) do
		local rDmgType = aDmgTypes[vClause.dmgtype];
		if not rDmgType then
			rDmgType = {};
			rDmgType.aDice = {};
			rDmgType.nMod = 0;
			rDmgType.nTotal = 0;
			rDmgType.sType = vClause.dmgtype;
			aDmgTypes[vClause.dmgtype] = rDmgType;
			table.insert(aOrderedTypes, rDmgType);
		end

		for _,vDie in ipairs(vClause.dice) do
			table.insert(rDmgType.aDice, vDie);
		end
		rDmgType.nMod = rDmgType.nMod + vClause.modifier;
		rDmgType.nTotal = rDmgType.nTotal + (vClause.nTotal or 0);
	end
	
	return aOrderedTypes;
end

-- check this for split command/damage types on comma and ;
function getDamageTypesFromString(sDamageTypes)
	local sLower = string.lower(sDamageTypes);
	local aSplit = StringManager.split(sLower, ",", true);
	
	local aDamageTypes = {};
	for _,v in ipairs(aSplit) do
		if StringManager.contains(DataCommon.dmgtypes, v) then
			table.insert(aDamageTypes, v);
		end
	end
	
	return aDamageTypes;
end

--
-- DAMAGE APPLICATION
--

function getReductionType(rSource, rTarget, sEffectType)
	local aEffects = EffectManager.getEffectsByType(rTarget, sEffectType, {}, rSource);
	
	local aFinal = {};
	for _,v in pairs(aEffects) do
		local rReduction = {};
		
		rReduction.mod = v.mod;
		rReduction.aNegatives = {};
		for _,vType in pairs(v.remainder) do
			if #vType > 1 and ((vType:sub(1,1) == "!") or (vType:sub(1,1) == "~")) then
				if StringManager.contains(DataCommon.dmgtypes, vType:sub(2)) then
					table.insert(rReduction.aNegatives, vType:sub(2));
				end
			end
		end

		for _,vType in pairs(v.remainder) do
			if vType ~= "untyped" and vType ~= "" and vType:sub(1,1) ~= "!" and vType:sub(1,1) ~= "~" then
				if StringManager.contains(DataCommon.dmgtypes, vType) or vType == "all" then
					aFinal[vType] = rReduction;
				end
			end
		end
	end
	
	return aFinal;
end

function checkReductionTypeHelper(rMatch, aDmgType)
	if not rMatch or (rMatch.mod ~= 0) then
		return false;
	end
	if #(rMatch.aNegatives) > 0 then
		local bMatchNegative = false;
		for _,vNeg in pairs(rMatch.aNegatives) do
			if StringManager.contains(aDmgType, vNeg) then
				bMatchNegative = true;
				break;
			end
		end
		return not bMatchNegative;
	end
	return true;
end

function checkReductionType(aReduction, aDmgType)
	for _,sDmgType in pairs(aDmgType) do
		if checkReductionTypeHelper(aReduction[sDmgType], aDmgType) or checkReductionTypeHelper(aReduction["all"], aDmgType) then
			return true;
		end
	end
	
	return false;
end

function checkNumericalReductionTypeHelper(rMatch, aDmgType, nLimit)
	if not rMatch or (rMatch.mod == 0) then
		return 0;
	end

	local bMatch = false;
	if #rMatch.aNegatives > 0 then
		local bMatchNegative = false;
		for _,vNeg in pairs(rMatch.aNegatives) do
			if StringManager.contains(aDmgType, vNeg) then
				bMatchNegative = true;
				break;
			end
		end
		if not bMatchNegative then
			bMatch = true;
		end
	else
		bMatch = true;
	end
	
	local nAdjust = 0;
	if bMatch then
		nAdjust = rMatch.mod - (rMatch.nApplied or 0);
		if nLimit then
			nAdjust = math.min(nAdjust, nLimit);
		end
		rMatch.nApplied = (rMatch.nApplied or 0) + nAdjust;
	end
	
	return nAdjust;
end

function checkNumericalReductionType(aReduction, aDmgType, nLimit)
	local nAdjust = 0;
	
	for _,sDmgType in pairs(aDmgType) do
		if nLimit then
			local nSpecificAdjust = checkNumericalReductionTypeHelper(aReduction[sDmgType], aDmgType, nLimit);
			nAdjust = nAdjust + nSpecificAdjust;
			local nGlobalAdjust = checkNumericalReductionTypeHelper(aReduction["all"], aDmgType, nLimit - nSpecificAdjust);
			nAdjust = nAdjust + nGlobalAdjust;
		else
			nAdjust = nAdjust + checkNumericalReductionTypeHelper(aReduction[sDmgType], aDmgType);
			nAdjust = nAdjust + checkNumericalReductionTypeHelper(aReduction["all"], aDmgType);
		end
	end
	
	return nAdjust;
end

function getDamageAdjust(rSource, rTarget, nDamage, rDamageOutput)
	local nDamageAdjust = 0;
	local bVulnerable = false;
	local bResist = false;
	
	-- Get damage adjustment effects
	local aImmune = getReductionType(rSource, rTarget, "IMMUNE");
	local aVuln = getReductionType(rSource, rTarget, "VULN");
	local aResist = getReductionType(rSource, rTarget, "RESIST");
	
	local bIncorporealSource = EffectManager.hasEffect(rSource, "Incorporeal", rTarget);
	local bIncorporealTarget = EffectManager.hasEffect(rTarget, "Incorporeal", rSource);
	local bApplyIncorporeal = (bIncorporealSource ~= bIncorporealTarget);
	
	-- Handle immune all
	if aImmune["all"] then
		nDamageAdjust = 0 - nDamage;
		bResist = true;
		return nDamageAdjust, bVulnerable, bResist;
	end
	
	-- Iterate through damage type entries for vulnerability, resistance and immunity
	local nVulnApplied = 0;
	for k, v in pairs(rDamageOutput.aDamageTypes) do
		-- Get individual damage types for each damage clause
		local aSrcDmgClauseTypes = {};
		local aTemp = StringManager.split(k, ",", true);
		for _,vType in ipairs(aTemp) do
			if vType ~= "untyped" and vType ~= "" then
				table.insert(aSrcDmgClauseTypes, vType);
			end
		end
		
		-- Handle standard immunity, vulnerability and resistance
		local bLocalVulnerable = checkReductionType(aVuln, aSrcDmgClauseTypes);
		local bLocalResist = checkReductionType(aResist, aSrcDmgClauseTypes);
		local bLocalImmune = checkReductionType(aImmune, aSrcDmgClauseTypes);
		
		-- Handle incorporeal
		if bApplyIncorporeal then
			bLocalResist = true;
		end
		
		-- Calculate adjustment
		-- Vulnerability = double
		-- Resistance = half
		-- Immunity = none
		local nLocalDamageAdjust = 0;
		if bLocalImmune then
			nLocalDamageAdjust = -v;
			bResist = true;
		else
			-- Handle standard vulnerability
			if bLocalVulnerable then
				nLocalDamageAdjust = v;
				bVulnerable = true;
			end
			-- Handle numerical vulnerability
			local nLocalVulnerable = checkNumericalReductionType(aVuln, aSrcDmgClauseTypes);
			if nLocalVulnerable ~= 0 then
				nLocalDamageAdjust = nLocalDamageAdjust + nLocalVulnerable;
				bVulnerable = true;
			end
			-- Handle standard resistance
			if bLocalResist then
				local nAdj = math.ceil((nLocalDamageAdjust + v) / 2);
				nLocalDamageAdjust = nLocalDamageAdjust - nAdj;
				bResist = true;
			end
			-- Handle numerical resistance
			local nLocalResist = checkNumericalReductionType(aResist, aSrcDmgClauseTypes, nLocalDamageAdjust + v);
			if nLocalResist ~= 0 then
				nLocalDamageAdjust = nLocalDamageAdjust - nLocalResist;
				bResist = true;
			end
		end
		
		-- Apply adjustment to this damage type clause
		nDamageAdjust = nDamageAdjust + nLocalDamageAdjust;
	end

	-- Results
	return nDamageAdjust, bVulnerable, bResist;
end

function decodeDamageText(nDamage, sDamageDesc)
	local rDamageOutput = {};
	
	if string.match(sDamageDesc, "%[RECOVERY") then
		rDamageOutput.sType = "recovery";
		rDamageOutput.sTypeOutput = "Recovery";
		rDamageOutput.sVal = string.format("%01d", nDamage);
		rDamageOutput.nVal = nDamage;

	elseif string.match(sDamageDesc, "%[HEAL") then
		if string.match(sDamageDesc, "%[TEMP%]") then
			rDamageOutput.sType = "temphp";
			rDamageOutput.sTypeOutput = "Temporary hit points";
		else
			rDamageOutput.sType = "heal";
			rDamageOutput.sTypeOutput = "Heal";
		end
		rDamageOutput.sVal = string.format("%01d", nDamage);
		rDamageOutput.nVal = nDamage;

	elseif nDamage < 0 then
		rDamageOutput.sType = "heal";
		rDamageOutput.sTypeOutput = "Heal";
		rDamageOutput.sVal = string.format("%01d", (0 - nDamage));
		rDamageOutput.nVal = 0 - nDamage;

	else
		rDamageOutput.sType = "damage";
		rDamageOutput.sTypeOutput = "Damage";
		rDamageOutput.sVal = string.format("%01d", nDamage);
		rDamageOutput.nVal = nDamage;

		-- Determine critical
		rDamageOutput.bCritical = string.match(sDamageDesc, "%[CRITICAL%]");

		-- Determine range
		rDamageOutput.sRange = string.match(sDamageDesc, "%[DAMAGE %((%w)%)%]") or "";
		rDamageOutput.aDamageFilter = {};
		if rDamageOutput.sRange == "M" then
			table.insert(rDamageOutput.aDamageFilter, "melee");
		elseif rDamageOutput.sRange == "R" then
			table.insert(rDamageOutput.aDamageFilter, "ranged");
		end

		-- Determine damage energy types
		local nDamageRemaining = nDamage;
		rDamageOutput.aDamageTypes = {};
		for sDamageType, sDamageDice, sDamageSubTotal in string.gmatch(sDamageDesc, "%[TYPE: ([^(]*) %(([%d%+%-dD]+)%=(%d+)%)%]") do
			local nDamageSubTotal = (tonumber(sDamageSubTotal) or 0);
			rDamageOutput.aDamageTypes[sDamageType] = nDamageSubTotal + (rDamageOutput.aDamageTypes[sDamageType] or 0);
			if not rDamageOutput.sFirstDamageType then
				rDamageOutput.sFirstDamageType = sDamageType;
			end
			
			nDamageRemaining = nDamageRemaining - nDamageSubTotal;
		end
		if nDamageRemaining > 0 then
			rDamageOutput.aDamageTypes[""] = nDamageRemaining;
		elseif nDamageRemaining < 0 then
			ChatManager.SystemMessage("Total mismatch in damage type totals");
		end
	end
	
	return rDamageOutput;
end

function applyDamage(rSource, rTarget, bSecret, sDamage, nTotal)
	-- Get health fields
	local sTargetType, nodeTarget = ActorManager.getTypeAndNode(rTarget);
	if sTargetType ~= "pc" and sTargetType ~= "ct" then
		return;
	end

	local nRemainder = 0;

	local nTotalHP, nTempHP, nWounds, nDeathSaveSuccess, nDeathSaveFail;
	if sTargetType == "pc" then
		nTotalHP = DB.getValue(nodeTarget, "hp.total", 0);
		nTempHP = DB.getValue(nodeTarget, "hp.temporary", 0);
		nWounds = DB.getValue(nodeTarget, "hp.wounds", 0);
		nDeathSaveSuccess = DB.getValue(nodeTarget, "hp.deathsavesuccess", 0);
		nDeathSaveFail = DB.getValue(nodeTarget, "hp.deathsavefail", 0);
	else
		nTotalHP = DB.getValue(nodeTarget, "hptotal", 0);
		nTempHP = DB.getValue(nodeTarget, "hptemp", 0);
		nWounds = DB.getValue(nodeTarget, "wounds", 0);
		nDeathSaveSuccess = DB.getValue(nodeTarget, "deathsavesuccess", 0);
		nDeathSaveFail = DB.getValue(nodeTarget, "deathsavefail", 0);
	end

	-- Prepare for notifications
	local aNotifications = {};

	-- Remember current health status
	local _,sOriginalStatus = ActorManager2.getPercentWounded(rTarget);

	-- Decode damage/heal description
	local rDamageOutput = decodeDamageText(nTotal, sDamage);
	
	-- Healing
	if rDamageOutput.sType == "recovery" then
		local sClassNode = string.match(sDamage, "%[NODE:([^]]+)%]");
		
		if nWounds <= 0 then
			table.insert(aNotifications, "[NOT WOUNDED]");
		else
			-- Determine whether HD available
			local nClassHD = 0;
			local nClassHDMult = 0;
			local nClassHDUsed = 0;
			if sTargetType == "pc" and sClassNode then
				local nodeClass = DB.findNode(sClassNode);
				nClassHD = DB.getValue(nodeClass, "level", 0);
				nClassHDMult = #(DB.getValue(nodeClass, "hddie", {}));
				nClassHDUsed = DB.getValue(nodeClass, "hdused", 0);
			end
			
			if (nClassHD * nClassHDMult) <= nClassHDUsed then
				table.insert(aNotifications, "[INSUFFICIENT HIT DICE FOR THIS CLASS]");
			else
				-- Calculate heal amounts
				local nHealAmount = rDamageOutput.nVal;
				
				-- If healing from zero (or negative), then remove Stable effect and reset wounds to match HP
				if (nHealAmount > 0) and (nWounds >= nTotalHP) then
					EffectManager.removeEffect(ActorManager.getCTNode(rTarget), "Stable");
					nWounds = nTotalHP;
				end
				
				local nWoundHealAmount = math.min(nHealAmount, nWounds);
				nWounds = nWounds - nWoundHealAmount;
				
				-- Display actual heal amount
				rDamageOutput.nVal = nWoundHealAmount;
				rDamageOutput.sVal = string.format("%01d", nWoundHealAmount);
				
				-- Decrement HD used
				if sTargetType == "pc" and sClassNode then
					local nodeClass = DB.findNode(sClassNode);
					DB.setValue(nodeClass, "hdused", "number", nClassHDUsed + 1);
					rDamageOutput.sVal = rDamageOutput.sVal .. "][HD-1";
				end
			end
		end

	-- Healing
	elseif rDamageOutput.sType == "heal" then
		if nWounds <= 0 then
			table.insert(aNotifications, "[NOT WOUNDED]");
		else
			-- Calculate heal amounts
			local nHealAmount = rDamageOutput.nVal;
			
			-- If healing from zero (or negative), then remove Stable effect and reset wounds to match HP
			if (nHealAmount > 0) and (nWounds >= nTotalHP) then
				EffectManager.removeEffect(ActorManager.getCTNode(rTarget), "Stable");
				nWounds = nTotalHP;
			end
			
			local nWoundHealAmount = math.min(nHealAmount, nWounds);
			nWounds = nWounds - nWoundHealAmount;
			
			-- Display actual heal amount
			rDamageOutput.nVal = nWoundHealAmount;
			rDamageOutput.sVal = string.format("%01d", nWoundHealAmount);
		end

	-- Temporary hit points
	elseif rDamageOutput.sType == "temphp" then
		nTempHP = math.max(nTempHP, nTotal);

	-- Damage
	else
		-- Apply any targeted damage effects 
		-- NOTE: Dice determined randomly, instead of rolled
		if rSource and rTarget and rTarget.nOrder then
			local bCritical = string.match(sDamage, "%[CRITICAL%]");
			local aTargetedDamage = EffectManager.getEffectsBonusByType(rSource, {"DMG"}, true, rDamageOutput.aDamageFilter, rTarget, true);

			local nDamageEffectTotal = 0;
			local nDamageEffectCount = 0;
			for k, v in pairs(aTargetedDamage) do
				local bValid = true;
				local aSplitByDmgType = StringManager.split(k, ",", true);
				for _,vDmgType in ipairs(aSplitByDmgType) do
					if vDmgType == "critical" and not bCritical then
						bValid = false;
					end
				end
				
				if bValid then
					local nSubTotal = StringManager.evalDice(v.dice, v.mod);
					
					local sDamageType = rDamageOutput.sFirstDamageType;
					if sDamageType then
						sDamageType = sDamageType .. "," .. k;
					else
						sDamageType = k;
					end

					rDamageOutput.aDamageTypes[sDamageType] = (rDamageOutput.aDamageTypes[sDamageType] or 0) + nSubTotal;
					
					nDamageEffectTotal = nDamageEffectTotal + nSubTotal;
					nDamageEffectCount = nDamageEffectCount + 1;
				end
			end
			nTotal = nTotal + nDamageEffectTotal;

			if nDamageEffectCount > 0 then
				if nDamageEffectTotal ~= 0 then
					local sFormat = "[" .. Interface.getString("effects_tag") .. " %+d]";
					table.insert(aNotifications, string.format(sFormat, nDamageEffectTotal));
				else
					table.insert(aNotifications, "[" .. Interface.getString("effects_tag") .. "]");
				end
			end
		end
		
		-- Handle avoidance/evasion and half damage
		local isAvoided = false;
		local isHalf = string.match(sDamage, "%[HALF%]");
		local sAttack = string.match(sDamage, "%[DAMAGE[^]]*%] ([^[]+)");
		if sAttack then
			local sDamageState = getDamageState(rSource, rTarget, StringManager.trim(sAttack));
			if sDamageState == "half" then
				isHalf = true;
			elseif sDamageState == "none" then
				isAvoided = true;
			end
		end
		if isAvoided then
			table.insert(aNotifications, "[EVADED]");
			for kType, nType in pairs(rDamageOutput.aDamageTypes) do
				rDamageOutput.aDamageTypes[kType] = 0;
			end
			nTotal = 0;
		elseif isHalf then
			table.insert(aNotifications, "[HALF]");
			for kType, nType in pairs(rDamageOutput.aDamageTypes) do
				rDamageOutput.aDamageTypes[kType] = math.floor(nType / 2);
			end
			nTotal = math.max(math.floor(nTotal / 2), 1);
		end
		
		-- Apply damage type adjustments
		local nDamageAdjust, bVulnerable, bResist = getDamageAdjust(rSource, rTarget, nTotal, rDamageOutput);
		local nAdjustedDamage = nTotal + nDamageAdjust;
		if nAdjustedDamage < 0 then
			nAdjustedDamage = 0;
		end
		if bResist then
			if nAdjustedDamage <= 0 then
				table.insert(aNotifications, "[RESISTED]");
			else
				table.insert(aNotifications, "[PARTIALLY RESISTED]");
			end
		end
		if bVulnerable then
			table.insert(aNotifications, "[VULNERABLE]");
		end
		
		-- Reduce damage by temporary hit points
		if nTempHP > 0 and nAdjustedDamage > 0 then
			if nAdjustedDamage > nTempHP then
				nAdjustedDamage = nAdjustedDamage - nTempHP;
				nTempHP = 0;
				table.insert(aNotifications, "[PARTIALLY ABSORBED]");
			else
				nTempHP = nTempHP - nAdjustedDamage;
				nAdjustedDamage = 0;
				table.insert(aNotifications, "[ABSORBED]");
			end
		end

		-- Apply remaining damage
		if nAdjustedDamage > 0 then
			-- Remember previous wounds
			local nPrevWounds = nWounds;
			
			-- Apply wounds
			nWounds = math.max(nWounds + nAdjustedDamage, 0);
			
			-- Calculate wounds above HP
			if nWounds > nTotalHP then
				nRemainder = nWounds - nTotalHP;
				nWounds = nTotalHP;
			end
			
			-- Prepare for calcs
			local nodeTargetCT = ActorManager.getCTNode(rTarget);

			-- Deal with remainder damage
			if nRemainder >= (nTotalHP+10) then
				table.insert(aNotifications, "[INSTANT DEATH]");
				nDeathSaveFail = 3;
			elseif nRemainder > 0 then
				table.insert(aNotifications, "[DAMAGE EXCEEDS HIT POINTS BY " .. nRemainder.. "]");
				if nPrevWounds >= nTotalHP then
					if rDamageOutput.bCritical then
						nDeathSaveFail = nDeathSaveFail + 2;
					else
						nDeathSaveFail = nDeathSaveFail + 1;
					end
				end
			end
			
			-- Handle stable situation
			EffectManager.removeEffect(nodeTargetCT, "Stable");
			
			-- Disable regeneration next round on correct damage type
			if nodeTargetCT then
				-- Calculate which damage types actually did damage
				local aTempDamageTypes = {};
				local aActualDamageTypes = {};
				for k,v in pairs(rDamageOutput.aDamageTypes) do
					if v > 0 then
						table.insert(aTempDamageTypes, k);
					end
				end
				local aActualDamageTypes = StringManager.split(table.concat(aTempDamageTypes, ","), ",", true);
				
				-- Check target's effects for regeneration effects that match
				for _,v in pairs(DB.getChildren(nodeTargetCT, "effects")) do
					local nActive = DB.getValue(v, "isactive", 0);
					if (nActive == 1) then
						local bMatch = false;
						local sLabel = DB.getValue(v, "label", "");
						local effect_list = EffectManager.parseEffect(sLabel);
						for i = 1, #effect_list do
							if effect_list[i].type == "REGEN" then
								for _,v2 in pairs(effect_list[i].remainder) do
									if StringManager.contains(aActualDamageTypes, v2) then
										bMatch = true;
									end
								end
							end
							
							if bMatch then
								EffectManager.disableEffect(nodeTargetCT, v);
							end
						end
					end
				end
			end
		end
		
		-- Update the damage output variable to reflect adjustments
		rDamageOutput.nVal = nAdjustedDamage;
		rDamageOutput.sVal = string.format("%01d", nAdjustedDamage);
	end
	
	-- Clear death saves if health greater than zero
	if nWounds < nTotalHP then
		nDeathSaveSuccess = 0;
		nDeathSaveFail = 0;
		if EffectManager.hasEffect(rTarget, "Stable") then
			EffectManager.removeEffect(ActorManager.getCTNode(rTarget), "Stable");
		end
	end

	-- Set health fields
	if sTargetType == "pc" then
		DB.setValue(nodeTarget, "hp.deathsavesuccess", "number", math.min(nDeathSaveSuccess, 3));
		DB.setValue(nodeTarget, "hp.deathsavefail", "number", math.min(nDeathSaveFail, 3));
		DB.setValue(nodeTarget, "hp.temporary", "number", nTempHP);
		DB.setValue(nodeTarget, "hp.wounds", "number", (nWounds+nRemainder));
	else
		DB.setValue(nodeTarget, "deathsavesuccess", "number", math.min(nDeathSaveSuccess, 3));
		DB.setValue(nodeTarget, "deathsavefail", "number", math.min(nDeathSaveFail, 3));
		DB.setValue(nodeTarget, "hptemp", "number", nTempHP);
		DB.setValue(nodeTarget, "wounds", "number", nWounds);
	end

	-- Check for status change
	local bShowStatus = false;
	if ActorManager.getFaction(rTarget) == "friend" then
		bShowStatus = not OptionsManager.isOption("SHPC", "off");
	else
		bShowStatus = not OptionsManager.isOption("SHNPC", "off");
	end
	if bShowStatus then
		local _,sNewStatus = ActorManager2.getPercentWounded(rTarget);
		if sOriginalStatus ~= sNewStatus then
			table.insert(aNotifications, "[" .. Interface.getString("combat_tag_status") .. ": " .. sNewStatus .. "]");
		end
	end
	
	-- Output results
	messageDamage(rSource, rTarget, bSecret, rDamageOutput.sTypeOutput, sDamage, rDamageOutput.sVal, table.concat(aNotifications, " "));
end

function messageDamage(rSource, rTarget, bSecret, sDamageType, sDamageDesc, sTotal, sExtraResult)
	if not (rTarget or sExtraResult ~= "") then
		return;
	end
	
	local msgShort = {font = "msgfont"};
	local msgLong = {font = "msgfont"};

	if sDamageType == "Recovery" then
		msgShort.icon = "roll_heal";
		msgLong.icon = "roll_heal";
	elseif sDamageType == "Heal" then
		msgShort.icon = "roll_heal";
		msgLong.icon = "roll_heal";
	else
		msgShort.icon = "roll_damage";
		msgLong.icon = "roll_damage";
	end

	msgShort.text = sDamageType .. " ->";
	msgLong.text = sDamageType .. " [" .. sTotal .. "] ->";
	if rTarget then
		msgShort.text = msgShort.text .. " [to " .. rTarget.sName .. "]";
		msgLong.text = msgLong.text .. " [to " .. rTarget.sName .. "]";
	end
	
	if sExtraResult and sExtraResult ~= "" then
		msgLong.text = msgLong.text .. " " .. sExtraResult;
	end
	
	ActionsManager.messageResult(bSecret, rSource, rTarget, msgLong, msgShort);
end

local aDamageState = {};

function applyDamageState(rSource, rTarget, sAttack, sState)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYDMGSTATE;
	
	msgOOB.sSourceNode = ActorManager.getCTNodeName(rSource);
	msgOOB.sTargetNode = ActorManager.getCTNodeName(rTarget);
	
	msgOOB.sAttack = sAttack;
	msgOOB.sState = sState;

	Comm.deliverOOBMessage(msgOOB, "");
end

function handleApplyDamageState(msgOOB)
	local rSource = ActorManager.getActor("ct", msgOOB.sSourceNode);
	local rTarget = ActorManager.getActor("ct", msgOOB.sTargetNode);
	
	if User.isHost() then
		setDamageState(rSource, rTarget, msgOOB.sAttack, msgOOB.sState);
	end
end

function setDamageState(rSource, rTarget, sAttack, sState)
	if not User.isHost() then
		applyDamageState(rSource, rTarget, sAttack, sState);
		return;
	end
	
	local sSourceCT = ActorManager.getCTNodeName(rSource);
	local sTargetCT = ActorManager.getCTNodeName(rTarget);
	if sSourceCT == "" or sTargetCT == "" then
		return;
	end
	
	if not aDamageState[sSourceCT] then
		aDamageState[sSourceCT] = {};
	end
	if not aDamageState[sSourceCT][sAttack] then
		aDamageState[sSourceCT][sAttack] = {};
	end
	if not aDamageState[sSourceCT][sAttack][sTargetCT] then
		aDamageState[sSourceCT][sAttack][sTargetCT] = {};
	end
	aDamageState[sSourceCT][sAttack][sTargetCT] = sState;
end

function getDamageState(rSource, rTarget, sAttack)
	local sSourceCT = ActorManager.getCTNodeName(rSource);
	local sTargetCT = ActorManager.getCTNodeName(rTarget);
	if sSourceCT == "" or sTargetCT == "" then
		return "";
	end
	
	if not aDamageState[sSourceCT] then
		return "";
	end
	if not aDamageState[sSourceCT][sAttack] then
		return "";
	end
	if not aDamageState[sSourceCT][sAttack][sTargetCT] then
		return "";
	end
	
	local sState = aDamageState[sSourceCT][sAttack][sTargetCT];
	aDamageState[sSourceCT][sAttack][sTargetCT] = nil;
	return sState;
end
