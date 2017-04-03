-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	CombatManager.setCustomSort(CombatManager.sortfuncDnD);
	CombatManager.setCustomDrop(onDrop);

	CombatManager.setCustomAddNPC(addNPC);
	CombatManager.setCustomNPCSpaceReach(getNPCSpaceReach);

	CombatManager.setCustomTurnStart(onTurnStart);
	CombatManager.setCustomCombatReset(resetInit);

	OptionsManager.registerCallback("HRDD", onHRDistanceChanged);
	onHRDistanceChanged();
end

function onHRDistanceChanged()
	if OptionsManager.isOption("HRDD", "variant") then
		Interface.setDistanceDiagMult(1.5);
	else
		Interface.setDistanceDiagMult(1);
	end
end

--
-- TURN FUNCTIONS
--

function onTurnStart(nodeEntry)
	if not nodeEntry then
		return;
	end
	
	-- Handle beginning of turn changes
	DB.setValue(nodeEntry, "reaction", "number", 0);
	
	-- Check for death saves (based on option)
	if OptionsManager.isOption("HRST", "on") then
		if nodeEntry then
			local sClass, sRecord = DB.getValue(nodeEntry, "link");
			if sClass == "charsheet" and sRecord then
				local nHP = DB.getValue(nodeEntry, "hptotal", 0);
				local nWounds = DB.getValue(nodeEntry, "wounds", 0);
				local nDeathSaveFail = DB.getValue(nodeEntry, "deathsavefail", 0);
				if (nHP > 0) and (nWounds >= nHP) and (nDeathSaveFail < 3) then
					local rActor = ActorManager.getActor("pc", sRecord);
					if not EffectManager.hasEffect(rActor, "Stable") then
						ActionDamage.performDeathRoll(nil, rActor);
					end
				end
			end
		end
	end
	
end

--
-- DROP HANDLING
--

function onDrop(rSource, rTarget, draginfo)
	local sDragType = draginfo.getType();

	-- Effect targeting
	if sDragType == "effect_targeting" then
		if User.isHost() then
			onEffectTargetingDrop(rSource, rTarget, draginfo);
			return true;
		end
	end
end

function onEffectTargetingDrop(rSource, rTarget, draginfo)
	local sTargetCT = ActorManager.getCTNodeName(rTarget);
	if sTargetCT ~= "" then
		local sRefClass, sEffectNode = draginfo.getShortcutData();
		if sRefClass and sEffectNode then
			if sRefClass == "ct_effect" then
				EffectManager.addEffectTarget(sEffectNode, sTargetCT);
			end
		end
	end
end

--
-- ADD FUNCTIONS
--

function getNPCSpaceReach(nodeNPC)
	local nSpace = GameSystem.GameSystem.getDistanceUnitsPerGrid();
	local nReach = nSpace;
	
	local sSize = StringManager.trim(DB.getValue(nodeNPC, "size", ""):lower());
	if sSize == "large" then
		nSpace = nSpace * 2;
	elseif sSize == "huge" then
		nSpace = nSpace * 3;
	elseif sSize == "gargantuan" then
		nSpace = nSpace * 4;
	end

	return nSpace, nReach;
end

function parseResistances(sResistances)
	local aResults = {};
	sResistances = sResistances:lower();

	for _,v in ipairs(StringManager.split(sResistances, ";\r", true)) do
		local aResistTypes = {};
		
		for _,v2 in ipairs(StringManager.split(v, ",", true)) do
			if StringManager.isWord(v2, DataCommon.dmgtypes) then
				table.insert(aResistTypes, v2);
			else
				local aResistWords = StringManager.parseWords(v2);
				
				local i = 1;
				while aResistWords[i] do
					if StringManager.isWord(aResistWords[i], DataCommon.dmgtypes) then
						table.insert(aResistTypes, aResistWords[i]);
					elseif StringManager.isWord(aResistWords[i], "from") and StringManager.isWord(aResistWords[i+1], "nonmagical") and StringManager.isWord(aResistWords[i+2], { "weapons", "attacks" }) then
						i = i + 2;
						table.insert(aResistTypes, "!magic");
					elseif StringManager.isWord(aResistWords[i], "that") and StringManager.isWord(aResistWords[i+1], "aren't") then
						i = i + 2;
						
						if StringManager.isWord(aResistWords[i], "silvered") then
							table.insert(aResistTypes, "!silver");
						elseif StringManager.isWord(aResistWords[i], "adamantine") then
							table.insert(aResistTypes, "!adamantine");
						elseif StringManager.isWord(aResistWords[i], "cold-forged") and StringManager.isWord(aResistWords[i+1], "iron") then
							i = i + 1;
							table.insert(aResistTypes, "!cold-forged iron");
						end
					end
					
					i = i + 1;
				end
			end
		end

		if #aResistTypes > 0 then
			table.insert(aResults, table.concat(aResistTypes, ", "));
		end
	end
	
	return aResults;
end

-- calculate npc level from HD and return it -msw
-- move to manager_action_save.lua?
function getNPCLevelFromHitDice(nodeEntry, nodeNPC) 
    local bWoops = false;
    local nLevel = 1;
    local sHitDice = DB.getValue(nodeNPC, "hitDice", "1");
    if (sHitDice) then
        DB.setValue(nodeEntry,"hitDice","string", sHitDice);
        -- Match #-#, #+# or just #
        -- (\d+)([\-\+])?(\d+)?
        -- Full match	0-4	`12+3`
        -- Group 1.	0-2	`12`
        -- Group 2.	2-3	`+`
        -- Group 3.	3-4	`3`
        local nAdjustment = 0;
        local nHitDice = 0;
        local match1, match2, match3 = sHitDice:match("(%d+)([%-+])(%d+)");
        if (match1 and not match2) then -- single digit
            nHitDice = tonumber(match1);
        elseif (match1 and match2 and match3) then -- match x-x or x+x
            nHitDice = tonumber(match1);
            -- minus
            if (match2 == "-") then
                nAdjustment = tonumber(match2 .. match3);
            else -- plus
                nAdjustment = tonumber(match3);
            end
            if (nAdjustment ~= 0) then
                local nFourCount = (nAdjustment/4);
                if (nFourCount < 0) then
                    nFourCount = math.ceil(nFourCount);
                else
                    nFourCount = math.floor(nFourCount);
                end
                nLevel = (nHitDice+nFourCount);
            else -- adjust = 0
                nLevel = nHitDice;
            end -- nAdjustment
        else -- didn't find X-X or X+x-x
            match1 = sHitDice:match("(%d+)");
            if (match1) then -- single digit
                nHitDice = tonumber(match1);
                nLevel = nHitDice;
            else
                -- pop up menu and ask them for a decent value? -msw
                ChatManager.SystemMessage("Unable to find a working hitDice [" .. sHitDice .. "] for " .. DB.getValue(nodeNPC, "name", "") .." to calculate saves. It should be # or #+# or #-#."); 
                bWoops = true;
                nAdjustment = 0;
                nHitDice = 0;
            end
        end
    end -- hitDice
    
    return nLevel;
end

-- Set NPC Saves -msw
-- move to manager_action_save.lua?
function updateNPCSaves(nodeEntry, nodeNPC)
    for i=1,10,1 do
        local sSave = DataCommon.saves[i];
        local nSave = DB.getValue(nodeNPC, "saves." .. sSave .. ".score", -1);
        if (nSave <= 0) then
            ActionSave.setNPCSave(nodeEntry, sSave, nodeNPC)
        end
    end
end

function addNPC(sClass, nodeNPC, sName)
	local nodeEntry, nodeLastMatch = CombatManager.addNPCHelper(nodeNPC, sName);
	
    -- update NPC Saves for HD
    updateNPCSaves(nodeEntry, nodeNPC);

	-- Fill in spells
	CampaignDataManager2.updateNPCSpells(nodeEntry);

	-- Set initiative from Dexterity modifier
--	local nDex = DB.getValue(nodeNPC, "abilities.dexterity.score", 10);
--	local nDexMod = math.floor((nDex - 10) / 2);
--	DB.setValue(nodeEntry, "init", "number", nDexMod);

	-- base modifier for initiative
    -- we set modifiers based on size per DMG for AD&D -msw
    DB.setValue(nodeEntry, "init", "number", 0);
	
	-- Determine size
	local sSize = StringManager.trim(DB.getValue(nodeEntry, "size", ""):lower());
	local sSizeNoLower = StringManager.trim(DB.getValue(nodeEntry, "size", ""));
	if sSize == "tiny" or string.find(sSizeNoLower,"T") then
        -- tokenscale doesn't work, guessing it's "reset" when
        -- the token is actually dropped on the map
        -- need to figure out a work around -msw
		DB.setValue(nodeEntry, "tokenscale", "number", 0.5);
        DB.setValue(nodeEntry, "init", "number", 0);
	elseif sSize == "small" or string.find(sSizeNoLower,"S") then
        -- tokenscale doesn't work, guessing it's "reset" when
        -- the token is actually dropped on the map
		DB.setValue(nodeEntry, "tokenscale", "number", 0.75);
        DB.setValue(nodeEntry, "init", "number", 3);
	elseif sSize == "medium" or string.find(sSizeNoLower,"M") then
        DB.setValue(nodeEntry, "init", "number", 3);
	elseif sSize == "large" or string.find(sSizeNoLower,"L") then
		DB.setValue(nodeEntry, "space", "number", 10);
        DB.setValue(nodeEntry, "init", "number", 6);
	elseif sSize == "huge" or string.find(sSizeNoLower,"H") then
		DB.setValue(nodeEntry, "space", "number", 15);
        DB.setValue(nodeEntry, "init", "number", 9);
	elseif sSize == "gargantuan" or string.find(sSizeNoLower,"G") then
		DB.setValue(nodeEntry, "space", "number", 20);
        DB.setValue(nodeEntry, "init", "number", 12);
	end
	
	-- Set current hit points
	local sOptHRNH = OptionsManager.getOption("HRNH");
	local nHP = DB.getValue(nodeNPC, "hp", 0);
	local sHD = StringManager.trim(DB.getValue(nodeNPC, "hd", ""));
	if sOptHRNH == "max" and sHD ~= "" then
		nHP = StringManager.evalDiceString(sHD, true, true);
	elseif sOptHRNH == "random" and sHD ~= "" then
		nHP = math.max(StringManager.evalDiceString(sHD, true), 1);
	end
	DB.setValue(nodeEntry, "hptotal", "number", nHP);
	
	
	-- Track additional damage types and intrinsic effects
	local aEffects = {};
	
	-- Vulnerabilities
	local aVulnTypes = parseResistances(DB.getValue(nodeEntry, "damagevulnerabilities", ""));
	if #aVulnTypes > 0 then
		for _,v in ipairs(aVulnTypes) do
			if v ~= "" then
				table.insert(aEffects, "VULN: " .. v);
			end
		end
	end
			
	-- Damage Resistances
	local aResistTypes = parseResistances(DB.getValue(nodeEntry, "damageresistances", ""));
	if #aResistTypes > 0 then
		for _,v in ipairs(aResistTypes) do
			if v ~= "" then
				table.insert(aEffects, "RESIST: " .. v);
			end
		end
	end
	
	-- Damage immunities
	local aImmuneTypes = parseResistances(DB.getValue(nodeEntry, "damageimmunities", ""));
	if #aImmuneTypes > 0 then
		for _,v in ipairs(aImmuneTypes) do
			if v ~= "" then
				table.insert(aEffects, "IMMUNE: " .. v);
			end
		end
	end

	-- Condition immunities
	local aImmuneCondTypes = {};
	local sCondImmune = DB.getValue(nodeEntry, "conditionimmunities", ""):lower();
	for _,v in ipairs(StringManager.split(sCondImmune, ",;\r", true)) do
		if StringManager.isWord(v, DataCommon.conditions) then
			table.insert(aImmuneCondTypes, v);
		end
	end
	if #aImmuneCondTypes > 0 then
		table.insert(aEffects, "IMMUNE: " .. table.concat(aImmuneCondTypes, ", "));
	end
	
	-- Decode traits and actions
    -- if it has no actions... 
    if DB.getChildCount(nodeEntry, "actions") == 0 then
        -- add a single default entry that has at least a melee attack, ranged attack, simple damage and saves for each type. -celestian
        --Debug.console("manager_combat2.lua","addNPC","!Actions",DB.getChildren(nodeEntry, "actions"));
        local nodeDefaultActions = nodeEntry.createChild("actions");
		if nodeDefaultActions then
			local nodeDefaultAction = nodeDefaultActions.createChild();
			if nodeDefaultAction then
				DB.setValue(nodeDefaultAction, "name", "string", "Default:");
				DB.setValue(nodeDefaultAction, "desc", "string", "Melee Weapon Attack: +0 to hit. Ranged Weapon Attack: +0 to hit. Hit: 1d6 slashing damage.\rVictims must make a saving throw versus spell. Victims must make a saving throw versus poison. Victims must make a saving throw versus rod.\rVictims must make a saving throw versus polymorph. Victims must make a saving throw versus breath.");
			end
		end
    end
	for _,v in pairs(DB.getChildren(nodeEntry, "actions")) do
		parseNPCPower(v, aEffects);
	end
	for _,v in pairs(DB.getChildren(nodeEntry, "legendaryactions")) do
		parseNPCPower(v, aEffects);
	end
	for _,v in pairs(DB.getChildren(nodeEntry, "lairactions")) do
		parseNPCPower(v, aEffects);
	end
	for _,v in pairs(DB.getChildren(nodeEntry, "reactions")) do
		parseNPCPower(v, aEffects);
	end
	for _,v in pairs(DB.getChildren(nodeEntry, "traits")) do
		parseNPCPower(v, aEffects);
	end
	for _,v in pairs(DB.getChildren(nodeEntry, "innatespells")) do
		parseNPCPower(v, aEffects, true);
	end
	for _,v in pairs(DB.getChildren(nodeEntry, "spells")) do
		parseNPCPower(v, aEffects, true);
	end

	-- Add special effects
	if #aEffects > 0 then
		EffectManager.addEffect("", "", nodeEntry, { sName = table.concat(aEffects, "; "), nDuration = 0, nGMOnly = 1 }, false);
	end

	-- Roll initiative and sort
	local sOptINIT = OptionsManager.getOption("INIT");
    local nInitiativeRoll = math.random(DataCommon.nDefaultInitiativeDice) + DB.getValue(nodeEntry, "init", 0);
	if sOptINIT == "group" then
		if nodeLastMatch then
			local nLastInit = DB.getValue(nodeLastMatch, "initresult", 0);
			DB.setValue(nodeEntry, "initresult", "number", nLastInit);
		else
			DB.setValue(nodeEntry, "initresult", "number", nInitiativeRoll);
		end
	elseif sOptINIT == "on" then
		DB.setValue(nodeEntry, "initresult", "number", nInitiativeRoll);
	end

	return nodeEntry;
end

-- review this to deal with AD&D monster/spells descriptions better? -msw
function parseNPCPower(nodePower, aEffects, bAllowSpellDataOverride)
	local sDisplay = DB.getValue(nodePower, "name", "");
	local aDisplayOptions = {};
	
	local sName = StringManager.trim(sDisplay:lower());
	if sName == "incorporeal" then
		table.insert(aEffects, "Incorporeal");
	elseif sName == "avoidance" then
		table.insert(aEffects, "Avoidance");
	elseif sName == "evasion" then
		table.insert(aEffects, "Evasion");
	elseif sName == "magic resistance" then
		table.insert(aEffects, "NOTE: Magic Resist");
	elseif sName == "magic weapons" or sName == "hellish weapons" or sName == "angelic weapons" then
		table.insert(aEffects, "DMGTYPE: magic");
	elseif sName == "improved critical" then
		table.insert(aEffects, "CRIT: 19");
	elseif sName == "regeneration" then
		local sDesc = StringManager.trim(DB.getValue(nodePower, "desc", ""):lower());
		local aPowerWords = StringManager.parseWords(sDesc);
		
		local sRegenAmount = nil;
		local aRegenBlockTypes = {};
		local i = 1;
		while aPowerWords[i] do
			if StringManager.isWord(aPowerWords[i], "regains") and StringManager.isDiceString(aPowerWords[i+1]) then
				i = i + 1;
				sRegenAmount = aPowerWords[i];
			elseif StringManager.isWord(aPowerWords[i], "takes") then
				while aPowerWords[i+1] do
					if StringManager.isWord(aPowerWords[i+1], {"or"}) then
						-- SKIP
					elseif StringManager.isWord(aPowerWords[i+1], DataCommon.dmgtypes) then
						table.insert(aRegenBlockTypes, aPowerWords[i+1]);
					else
						break;
					end

					i = i + 1;
				end
			end 
			
			i = i + 1;
		end
		
		if sRegenAmount then
			local sRegen = "REGEN: " .. sRegenAmount;
			if #aRegenBlockTypes > 0 then
				sRegen = sRegen .. " " .. table.concat(aRegenBlockTypes, ",");
			end
			table.insert(aEffects, sRegen);
		end
	-- Handle all the other traits and actions (i.e. look for recharge, attacks, damage, saves, reach, etc.)
	else
		local aAbilities = PowerManager.parseNPCPower(nodePower, bAllowSpellDataOverride);
		for _,v in ipairs(aAbilities) do
			if v.type == "attack" then
				if v.nomod then
					if v.range then
						table.insert(aDisplayOptions, string.format("[%s]", v.range));
					end
					if v.spell then
						table.insert(aDisplayOptions, "[ATK: SPELL]");
					elseif v.weapon then
						table.insert(aDisplayOptions, "[ATK: WEAPON]");
					else
						table.insert(aDisplayOptions, "[ATK]");
					end
				else
					if v.range then
						table.insert(aDisplayOptions, string.format("[%s]", v.range));
						if v.rangedist and v.rangedist ~= "5" then
							table.insert(aDisplayOptions, string.format("[RNG: %s]", v.rangedist));
						end
					end
					table.insert(aDisplayOptions, string.format("[ATK: %+d]", v.modifier or 0));
				end
			
			elseif v.type == "powersave" then
				local sSaveVs = string.format("[SAVEVS: %s", v.save);
				if not v.spell then
					sSaveVs = sSaveVs .. " " .. v.savemod;
				end
				if v.onmissdamage == "half" then
					sSaveVs = sSaveVs .. " (H)";
				end
				sSaveVs = sSaveVs .. "]";
				table.insert(aDisplayOptions, sSaveVs);
			
			elseif v.type == "damage" then
				local aDmgDisplay = {};
				for _,vClause in ipairs(v.clauses) do
					local sDmg = StringManager.convertDiceToString(vClause.dice, vClause.modifier);
					if vClause.dmgtype and vClause.dmgtype ~= "" then
						sDmg = sDmg .. " " .. vClause.dmgtype;
					end
					table.insert(aDmgDisplay, sDmg);
				end
				table.insert(aDisplayOptions, string.format("[DMG: %s]", table.concat(aDmgDisplay, " + ")));
				
			elseif v.type == "heal" then
				local aHealDisplay = {};
				for _,vClause in ipairs(v.clauses) do
					local sHeal = StringManager.convertDiceToString(vClause.dice, vClause.modifier);
					table.insert(aHealDisplay, sHeal);
				end
				
				local sHeal = table.concat(aHealDisplay, " + ");
				if v.subtype then
					sHeal = sHeal .. " " .. v.subtype;
				end
				
				table.insert(aDisplayOptions, string.format("[HEAL: %s]", sHeal));
			
			elseif v.type == "effect" then
				table.insert(aDisplayOptions, ActionEffect.encodeEffectForCT(v));
			
			end
		end

		-- Remove melee / ranged attack in title
		sDisplay = sName:gsub("^[Mm]elee attack%s*[-–]+%s*", "");
		sDisplay = sDisplay:gsub("^[Rr]anged attack%s*[-–]+%s*", "");
		sDisplay = StringManager.capitalize(sDisplay);

		-- Remove recharge in title, and move to details
		local sRecharge = string.match(sName, "recharge (%d)");
		if sRecharge then
			sDisplay = string.gsub(sDisplay, "%s?%([Rr]echarge %d[-–]*%d?%)", "");
			table.insert(aDisplayOptions, "[R:" .. sRecharge .. "]");
		end
	end
	
	-- Set the value field to the short version
	if #aDisplayOptions > 0 then
		sDisplay = sDisplay .. " " .. table.concat(aDisplayOptions, " ");
	end
	DB.setValue(nodePower, "value", "string", sDisplay);
end

--
-- RESET FUNCTIONS
--

function resetInit()
	for _,vChild in pairs(DB.getChildren(CombatManager.CT_LIST)) do
		DB.setValue(vChild, "initresult", "number", 0);
		DB.setValue(vChild, "reaction", "number", 0);
	end
end

function resetEffects()
	for _,vChild in pairs(DB.getChildren(CombatManager.CT_LIST)) do
		local nodeEffects = vChild.getChild("effects");
		if nodeEffects then
			for _, vEffect in pairs(nodeEffects.getChildren()) do
				vEffect.delete();
			end
		end
	end
end

function resetHealth(nodeCT, bLong)
	if bLong then
		DB.setValue(nodeCT, "wounds", "number", 0);
		DB.setValue(nodeCT, "hptemp", "number", 0);
		DB.setValue(nodeCT, "deathsavesuccess", "number", 0);
		DB.setValue(nodeCT, "deathsavefail", "number", 0);
		
		EffectManager.removeEffect(nodeCT, "Stable");
		
		local nExhaustMod = EffectManager.getEffectsBonus(ActorManager.getActor("ct", nodeCT), {"EXHAUSTION"}, true);
		if nExhaustMod > 0 then
			nExhaustMod = nExhaustMod - 1;
			EffectManager.removeEffectByType(nodeCT, "EXHAUSTION");
			if nExhaustMod > 0 then
				EffectManager.addEffect("", "", nodeCT, { sName = "EXHAUSTION: " .. nExhaustMod, nDuration = 0 }, false);
			end
		end
	end
end

function clearExpiringEffects(bLong)
	for _,vChild in pairs(DB.getChildren(CombatManager.CT_LIST)) do
		local nodeEffects = vChild.getChild("effects");
		if nodeEffects then
			for _, vEffect in pairs(nodeEffects.getChildren()) do
				local sLabel = DB.getValue(vEffect, "label", "");
				local nDuration = DB.getValue(vEffect, "duration", 0);
				local sApply = DB.getValue(vEffect, "apply", "");
				
				if nDuration ~= 0 or sApply ~= "" or sLabel == "" then
					vEffect.delete();
				end
			end
		end
	end
end

function rest(bLong)
	CombatManager.resetInit();
	clearExpiringEffects(bLong);

	for _,vChild in pairs(DB.getChildren(CombatManager.CT_LIST)) do
		local bHandled = false;
		local sClass, sRecord = DB.getValue(vChild, "link", "", "");
		if sClass == "charsheet" and sRecord ~= "" then
			local nodePC = DB.findNode(sRecord);
			if nodePC then
				CharManager.rest(nodePC, bLong);
				bHandled = true;
			end
		end
		
		if not bHandled then
			resetHealth(vChild, bLong);
		end
	end
end

function rollRandomInit(nMod, bADV)
	local nInitResult = math.random(DataCommon.nDefaultInitiativeDice);
	if bADV then
		nInitResult = math.max(nInitResult, math.random(DataCommon.nDefaultInitiativeDice));
	end
	nInitResult = nInitResult + nMod;
	return nInitResult;
end

function rollEntryInit(nodeEntry)
	if not nodeEntry then
		return;
	end
	
	-- Start with the base initiative bonus
	local nInit = DB.getValue(nodeEntry, "init", 0);
	
	-- Get any effect modifiers
	local rActor = ActorManager.getActorFromCT(nodeEntry);
	local aEffectDice, nEffectBonus = EffectManager.getEffectsBonus(rActor, "INIT");
	nInit = nInit + StringManager.evalDice(aEffectDice, nEffectBonus);
	
	-- Check for the ADVINIT effect
	local bADV = EffectManager.hasEffectCondition(rActor, "ADVINIT");

	-- For PCs, we always roll unique initiative
	local sClass, sRecord = DB.getValue(nodeEntry, "link", "", "");
	if sClass == "charsheet" then
		local nInitResult = rollRandomInit(nInit, bADV);
		DB.setValue(nodeEntry, "initresult", "number", nInitResult);
		return;
	end
	
	-- For NPCs, if NPC init option is not group, then roll unique initiative
	local sOptINIT = OptionsManager.getOption("INIT");
	if sOptINIT ~= "group" then
		local nInitResult = rollRandomInit(nInit, bADV);
		DB.setValue(nodeEntry, "initresult", "number", nInitResult);
		return;
	end

	-- For NPCs with group option enabled
	
	-- Get the entry's database node name and creature name
	local sStripName = CombatManager.stripCreatureNumber(DB.getValue(nodeEntry, "name", ""));
	if sStripName == "" then
		local nInitResult = rollRandomInit(nInit, bADV);
		DB.setValue(nodeEntry, "initresult", "number", nInitResult);
		return;
	end
		
	-- Iterate through list looking for other creature's with same name
	local nLastInit = nil;
	for _,vChild in pairs(DB.getChildren(CombatManager.CT_LIST)) do
		if vChild.getName() ~= nodeEntry.getName() then
			local sTemp = CombatManager.stripCreatureNumber(DB.getValue(vChild, "name", ""));
			if sTemp == sStripName then
				local nChildInit = DB.getValue(vChild, "initresult", 0);
				if nChildInit ~= -10000 then
					nLastInit = nChildInit;
				end
			end
		end
	end
	
	-- If we found similar creatures, then match the initiative of the last one found
	if nLastInit then
		DB.setValue(nodeEntry, "initresult", "number", nLastInit);
	else
		local nInitResult = rollRandomInit(nInit, bADV);
		DB.setValue(nodeEntry, "initresult", "number", nInitResult);
	end
end

function rollInit(sType)
	for _,vChild in pairs(DB.getChildren(CombatManager.CT_LIST)) do
		local bRoll = true;
		if sType then
			local sClass,_ = DB.getValue(vChild, "link", "", "");
			if sType == "npc" and sClass == "charsheet" then
				bRoll = false;
			elseif sType == "pc" and sClass ~= "charsheet" then
				bRoll = false;
			end
		end
		
		if bRoll then
			DB.setValue(vChild, "initresult", "number", -10000);
		end
	end

	for _,vChild in pairs(DB.getChildren(CombatManager.CT_LIST)) do
		local bRoll = true;
		if sType then
			local sClass,_ = DB.getValue(vChild, "link", "", "");
			if sType == "npc" and sClass == "charsheet" then
				bRoll = false;
			elseif sType == "pc" and sClass ~= "charsheet" then
				bRoll = false;
			end
		end
		
		if bRoll then
			rollEntryInit(vChild);
		end
	end
end

--
-- PARSE CT ATTACK LINE
--

function parseAttackLine(sLine)
	local rPower = nil;
	
	local nIntroStart, nIntroEnd, sName = sLine:find("([^%[]*)[%[]?");
	if nIntroStart then
		rPower = {};
		rPower.name = StringManager.trim(sName);
		rPower.aAbilities = {};

		nIndex = nIntroEnd;
		local nAbilityStart, nAbilityEnd, sAbility = sLine:find("%[([^%]]+)%]", nIntroEnd);
		while nAbilityStart do
			if sAbility == "M" or sAbility == "R" then
				rPower.range = sAbility;

			elseif sAbility:sub(1,4) == "ATK:" and #sAbility > 4 then
				local rAttack = {};
				rAttack.sType = "attack";
				rAttack.nStart = nAbilityStart + 1;
				rAttack.nEnd = nAbilityEnd;
				rAttack.label = rPower.name;
				rAttack.range = rPower.range;
				local sAttack, sCritRange = string.match(sAbility:sub(7), "([+-]?%d+)%s*%((%d+)%)");
				if sAttack then
					rAttack.modifier = tonumber(sAttack) or 0;
					rAttack.nCritRange = tonumber(sCritRange) or 0;
					if rAttack.nCritRange < 2 or rAttack.nCritRange > 19 then
						rAttack.nCritRange = nil;
					end
				else
					rAttack.modifier = tonumber(sAbility:sub(5)) or 0;
				end
				table.insert(rPower.aAbilities, rAttack);

			elseif sAbility:sub(1,7) == "SAVEVS:" and #sAbility > 7 then
				local rSave = {};
				rSave.sType = "powersave";
				rSave.nStart = nAbilityStart + 1;
				rSave.nEnd = nAbilityEnd;
				rSave.label = rPower.name;
				local sSave, sSaveMod, bSaveHalf = string.match(sAbility:sub(7), "(%w+) (%d+) (%(H%))");
				if not sSave then
					sSave, sSaveMod = string.match(sAbility:sub(7), "(%w+) (%d+)");
					if not sSave then
						sSave = StringManager.trim(sAbility:sub(7):lower());
					end
				end
				rSave.save = sSave;
				rSave.savemod = tonumber(sSaveMod) or 0;
				if bSaveHalf then
					rSave.onmissdamage = "half";
				end
				table.insert(rPower.aAbilities, rSave);

			elseif sAbility:sub(1,4) == "DMG:" and #sAbility > 4 then
				local rDamage = {};
				rDamage.sType = "damage";
				rDamage.nStart = nAbilityStart + 1;
				rDamage.nEnd = nAbilityEnd;
				rDamage.label = rPower.name;
				rDamage.range = rPower.range;
				rDamage.clauses = {};
				
				local aPowerWords = StringManager.parseWords(sAbility:sub(5));
				local i = 1;
				while aPowerWords[i] do
					if StringManager.isDiceString(aPowerWords[i]) then
						local aDmgDiceStr = {};
						table.insert(aDmgDiceStr, aPowerWords[i]);
						while StringManager.isDiceString(aPowerWords[i+1]) do
							table.insert(aDmgDiceStr, aPowerWords[i+1]);
							i = i + 1;
						end
						local aClause = {};
						aClause.dice, aClause.modifier = StringManager.convertStringToDice(table.concat(aDmgDiceStr));
						
						local aDmgType = {};
						while aPowerWords[i+1] and not StringManager.isDiceString(aPowerWords[i+1]) and not StringManager.isWord(aPowerWords[i+1], {"and", "plus"}) do
							table.insert(aDmgType, aPowerWords[i+1]);
							i = i + 1;
						end
						aClause.dmgtype = table.concat(aDmgType, ",");
						
						table.insert(rDamage.clauses, aClause);
					end
					
					i = i + 1;
				end
				table.insert(rPower.aAbilities, rDamage);

			elseif sAbility:sub(1,5) == "HEAL:" and #sAbility > 5 then
				local rHeal = {};
				rHeal.sType = "heal";
				rHeal.nStart = nAbilityStart + 1;
				rHeal.nEnd = nAbilityEnd;
				rHeal.label = rPower.name;
				rHeal.clauses = {};

				local aPowerWords = StringManager.parseWords(sAbility:sub(6));
				local i = 1;
				local aHealDiceStr = {};
				while StringManager.isDiceString(aPowerWords[i]) do
					table.insert(aHealDiceStr, aPowerWords[i]);
					i = i + 1;
				end

				local aClause = {};
				aClause.dice, aClause.modifier = StringManager.convertStringToDice(table.concat(aHealDiceStr));
				table.insert(rHeal.clauses, aClause);
				
				if StringManager.isWord(aPowerWords[i], "temp") then
					rHeal.subtype = "temp";
				end

				table.insert(rPower.aAbilities, rHeal);
				
			elseif sAbility:sub(1,4) == "EFF:" and #sAbility > 4 then
				local rEffect = ActionEffect.decodeEffectFromCT(sAbility);
				if rEffect then
					rEffect.nStart = nAbilityStart + 1;
					rEffect.nEnd = nAbilityEnd;
					table.insert(rPower.aAbilities, rEffect);
				end
			
			elseif sAbility:sub(1,2) == "R:" and #sAbility == 3 then
				local rUsage = {};
				rUsage.sType = "usage";

				local nUsedStart, nUsedEnd, sUsage = string.find(sLine, "%[(USED)%]", nIndex);
				if nUsedStart then
					rUsage.nStart = nUsedStart + 1;
					rUsage.nEnd = nUsedEnd;
				else
					rUsage.nStart = nAbilityStart + 1;
					rUsage.nEnd = nAbilityEnd;
					sUsage = sAbility;
				end
				table.insert(rPower.aAbilities, rUsage);
				
				rPower.sUsage = sUsage;
				rPower.nUsageStart = rUsage.nStart;
				rPower.nUsageEnd = rUsage.nEnd;
			end
			
			nAbilityStart, nAbilityEnd, sAbility = sLine:find("%[([^%]]+)%]", nAbilityEnd + 1);
		end
	end
	
	return rPower;
end

--
--	XP FUNCTIONS
--

function calcBattleXP(nodeBattle)
	local sTargetNPCList = LibraryData.getCustomData("battle", "npclist") or "npclist";

	local nXP = 0;
	for _, vNPCItem in pairs(DB.getChildren(nodeBattle, sTargetNPCList)) do
		local sClass, sRecord = DB.getValue(vNPCItem, "link", "", "");
		if sRecord ~= "" then
			local nodeNPC = DB.findNode(sRecord);
			if nodeNPC then
				nXP = nXP + (DB.getValue(vNPCItem, "count", 0) * DB.getValue(nodeNPC, "xp", 0));
			else
				local sMsg = string.format(Interface.getString("enc_message_refreshxp_missingnpclink"), DB.getValue(vNPCItem, "name", ""));
				ChatManager.SystemMessage(sMsg);
			end
		end
	end
	
	DB.setValue(nodeBattle, "exp", "number", nXP);
end
	
function calcBattleCR(nodeBattle)
	calcBattleXP(nodeBattle);

	local nXP = DB.getValue(nodeBattle, "exp", 0);

	local sCR = "";
	if nXP > 0 then
		if nXP <= 10 then
			sCR = "0";
		elseif nXP <= 25 then
			sCR = "1/8";
		elseif nXP <= 50 then
			sCR = "1/4";
		elseif nXP <= 100 then
			sCR = "1/2";
		elseif nXP <= 200 then
			sCR = "1";
		elseif nXP <= 450 then
			sCR = "2";
		elseif nXP <= 700 then
			sCR = "3";
		elseif nXP <= 1100 then
			sCR = "4";
		elseif nXP <= 1800 then
			sCR = "5";
		elseif nXP <= 2300 then
			sCR = "6";
		elseif nXP <= 2900 then
			sCR = "7";
		elseif nXP <= 3900 then
			sCR = "8";
		elseif nXP <= 5000 then
			sCR = "9";
		elseif nXP <= 5900 then
			sCR = "10";
		elseif nXP <= 7200 then
			sCR = "11";
		elseif nXP <= 8400 then
			sCR = "12";
		elseif nXP <= 10000 then
			sCR = "13";
		elseif nXP <= 11500 then
			sCR = "14";
		elseif nXP <= 13000 then
			sCR = "15";
		elseif nXP <= 15000 then
			sCR = "16";
		elseif nXP <= 18000 then
			sCR = "17";
		elseif nXP <= 20000 then
			sCR = "18";
		elseif nXP <= 22000 then
			sCR = "19";
		elseif nXP <= 25000 then
			sCR = "20";
		elseif nXP <= 33000 then
			sCR = "21";
		elseif nXP <= 41000 then
			sCR = "22";
		elseif nXP <= 50000 then
			sCR = "23";
		elseif nXP <= 62000 then
			sCR = "24";
		elseif nXP <= 75000 then
			sCR = "25";
		elseif nXP <= 90000 then
			sCR = "26";
		elseif nXP <= 105000 then
			sCR = "27";
		elseif nXP <= 120000 then
			sCR = "28";
		elseif nXP <= 135000 then
			sCR = "29";
		elseif nXP <= 155000 then
			sCR = "30";
		else
			sCR = "31+";
		end
	end

	DB.setValue(nodeBattle, "cr", "string", sCR);
end
