-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerModHandler("recovery", modRecovery);
	ActionsManager.registerResultHandler("recovery", onRecovery);
end

function performRoll(draginfo, rActor, nodeClass)
	local rRoll = {};
	rRoll.sType = "recovery";
	rRoll.sClassNode = nodeClass.getNodeName();
	
	rRoll.sDesc = "[RECOVERY]";
	rRoll.aDice = {};
	rRoll.nMod = 0;

	local aHDDice = DB.getValue(nodeClass, "hddie", {});
	if #aHDDice > 0 then
		table.insert(rRoll.aDice, aHDDice[1]);
	end
	
	local sAbility = "";
	local sAbility2 = "";
	local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if nodeActor and sActorType == "pc" then
		sAbility = DB.getValue(nodeActor, "hp.hdstat", "");
		sAbility2 = DB.getValue(nodeActor, "hp.hdstat2", "");
		rRoll.nMod = DB.getValue(nodeActor, "hp.hdmod", 0);
	end
	if sAbility == "" then
		sAbility = "constitution";
	end
	if sAbility ~= "constitution" then
		local sAbilityEffect = DataCommon.ability_ltos[sAbility];
		if sAbilityEffect then
			rRoll.sDesc = rRoll.sDesc .. " [MOD:" .. sAbilityEffect .. "]";
		end
	end
	rRoll.nMod = rRoll.nMod + ActorManager2.getAbilityBonus(rActor, sAbility);
	if sAbility2 ~= "" then
		local sAbilityEffect2 = DataCommon.ability_ltos[sAbility2];
		if sAbilityEffect2 then
			rRoll.sDesc = rRoll.sDesc .. " [MOD2:" .. sAbilityEffect2 .. "]";
			rRoll.nMod = rRoll.nMod + ActorManager2.getAbilityBonus(rActor, sAbility2);
		end
	end
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modRecovery(rSource, rTarget, rRoll)
	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;
	
	if rSource then
		local bEffects = false;

		-- Determine ability used (if any)
		local sActionStat = nil;
		local sActionStat2 = nil;
		local sModStat = string.match(rRoll.sDesc, "%[MOD:(%w+)%]");
		if sModStat then
			sActionStat = DataCommon.ability_stol[sModStat];
		end
		if not sActionStat then
			sActionStat = "constitution";
		end
		local sModStat2 = string.match(rRoll.sDesc, "%[MOD2:(%w+)%]");
		if sModStat2 then
			sActionStat2 = DataCommon.ability_stol[sModStat2];
		end
		
		-- Determine ability modifiers
		local nBonusStat, nBonusEffects = ActorManager2.getAbilityEffectsBonus(rSource, sActionStat);
		if nBonusEffects > 0 then
			bEffects = true;
			nAddMod = nAddMod + nBonusStat;
		end
		if sActionStat2 then
			local nBonusStat2, nBonusEffects2 = ActorManager2.getAbilityEffectsBonus(rSource, sActionStat2);
			if nBonusEffects2 > 0 then
				bEffects = true;
				nAddMod = nAddMod + nBonusStat2;
			end
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
end

function onRecovery(rSource, rTarget, rRoll)
	-- Get basic roll message and total
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	local nTotal = ActionsManager.total(rRoll);

	-- Handle minimum damage
	if nTotal < 0 and rRoll.aDice and #rRoll.aDice > 0 then
		rMessage.text = rMessage.text .. " [MIN RECOVERY]";
		rMessage.diemodifier = rMessage.diemodifier - nTotal;
		nTotal = 0;
	end
	if ActorManager.isPC(rSource) and CharManager.hasFeat(ActorManager.getCreatureNode(rSource), CharManager.FEAT_DURABLE) then
		local nDurableMin = math.max(ActorManager2.getAbilityBonus(rSource, "constitution"), 1) * 2;
		if nTotal < nDurableMin then
			rMessage.text = string.format("%s [DURABLE %+d]", rMessage.text, nDurableMin - nTotal);
			rMessage.diemodifier = rMessage.diemodifier + (nDurableMin - nTotal);
			nTotal = nDurableMin;
		else
			rMessage.text = rMessage.text .. " [DURABLE]";
		end
	end

	-- Deliver roll message
	Comm.deliverChatMessage(rMessage);
	
	-- Apply recovery
	if rRoll.sClassNode then
		rMessage.text = rMessage.text .. " [NODE:" .. rRoll.sClassNode .. "]";
	end
	ActionDamage.notifyApplyDamage(nil, rSource, false, rMessage.text, nTotal);
end
