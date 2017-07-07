-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

SPELL_LEVELS = 9;

-------------------
-- POWER MANAGEMENT
-------------------

-- Reset powers used
function resetPowers(nodeCaster, bLong)
	local aListGroups = {};
	
	-- Build list of power groups
	for _,vGroup in pairs(DB.getChildren(nodeCaster, "powergroup")) do
		local sGroup = DB.getValue(vGroup, "name", "");
		if not aListGroups[sGroup] then
			local rGroup = {};
			rGroup.sName = sGroup;
			rGroup.sType = DB.getValue(vGroup, "castertype", "");
			rGroup.nUses = DB.getValue(vGroup, "uses", 0);
			rGroup.sUsesPeriod = DB.getValue(vGroup, "usesperiod", "");
			rGroup.nodeGroup = vGroup;
			
			aListGroups[sGroup] = rGroup;
		end
	end
	
	-- Reset power usage
	for _,vPower in pairs(DB.getChildren(nodeCaster, "powers")) do
		local bReset = true;

		local sGroup = DB.getValue(vPower, "group", "");
		local rGroup = aListGroups[sGroup];
		local bCaster = (rGroup and rGroup.sType ~= "");
		
		if not bCaster then
			if rGroup and (rGroup.nUses > 0) then
				if rGroup.sUsesPeriod == "once" then
					bReset = false;
				elseif not bLong and rGroup.sUsesPeriod ~= "enc" then
					bReset = false;
				end
			else
				local sPowerUsesPeriod = DB.getValue(vPower, "usesperiod", "");
				if sPowerUsesPeriod == "once" then
					bReset = false;
				elseif not bLong and sPowerUsesPeriod ~= "enc" then
					bReset = false;
				end
			end
		end
		
		if bReset then
			DB.setValue(vPower, "cast", "number", 0);
		end
	end
	
    -- disabled this because we dont clear the slots till they are cast.
    -- 5e did it differently.
    
	-- -- Reset spell slots
	-- for i = 1, SPELL_LEVELS do
		-- DB.setValue(nodeCaster, "powermeta.pactmagicslots" .. i .. ".used", "number", 0);
	-- end
	-- if bLong then
		-- for i = 1, SPELL_LEVELS do
			-- DB.setValue(nodeCaster, "powermeta.spellslots" .. i .. ".used", "number", 0);
		-- end
	-- end
end

-- add spells dropped on to sheet -celestian
function addPower(sClass, nodeSource, nodeCreature, sGroup)
	-- Validate
	if not nodeSource or not nodeCreature then
		return nil;
	end

	-- Create the powers list entry
	local nodePowers = nodeCreature.createChild("powers");
	if not nodePowers then
		return nil;
	end
	
	-- Create the new power entry
	local nodeNewPower = nodePowers.createChild();
	if not nodeNewPower then
		return nil;
	end
	
    -- add these so that spells copied from other players/sources
    -- get setup immediately --celestian
    local sTypeSource = DB.getValue(nodeSource,"type","");
    DB.setValue(nodeNewPower,"type","string",sTypeSource);
    local sCastingTimeSource = DB.getValue(nodeSource,"castingtime","");
    DB.setValue(nodeNewPower,"castingtime","string",sCastingTimeSource);
    local nLevelSource = DB.getValue(nodeSource,"level",0);
    DB.setValue(nodeNewPower,"level","number",nLevelSource);
    --
    
	-- Copy the power details over
	DB.copyNode(nodeSource, nodeNewPower);
	
	-- Determine group setting
	if sGroup then
		DB.setValue(nodeNewPower, "group", "string", sGroup);
	end
	
    -- Class specific handling
	if sClass == "reference_spell" or sClass == "power" then
		-- DEPRECATED: Used to add spell slot of matching spell level, but deprecated since handled by class drops and doesn't work for warlock
	else
		-- Remove level data
		DB.deleteChild(nodeNewPower, "level");
		
		-- Copy text to description
		local nodeText = nodeNewPower.getChild("text");
		if nodeText then
			local nodeDesc = nodeNewPower.createChild("description", "formattedtext");
			DB.copyNode(nodeText, nodeDesc);
			nodeText.delete();
		end
	end
	
	-- Set locked state for editing detailed record
	DB.setValue(nodeNewPower, "locked", "number", 1);
	
	-- Parse power details to create actions
    local bNeedsActions = false; -- does this power already have actions?
	if DB.getChildCount(nodeNewPower, "actions") == 0 then
		parsePCPower(nodeNewPower);
        bNeedsActions = true;
	end
	
    -- add cast bar for spells with level and type -celestian
    -- also setup vars for castinitiative 
	local nLevel = nodeNewPower.getChild("level").getValue();
	local sSpellType = nodeNewPower.getChild("type").getValue():lower();
	local sCastingTime = nodeNewPower.getChild("castingtime").getValue():lower();
    local nCastTime = getCastingTime(sCastingTime,nLevel);
    if bNeedsActions then
        if (nLevel > 0 and (sSpellType == "arcane" or sSpellType == "divine")) then
            local nodeActions = nodeNewPower.createChild("actions");
            if nodeActions then
                local nodeAction = nodeActions.createChild();
                if nodeAction then
                    DB.setValue(nodeAction, "type", "string", "cast");
                    -- set "savetype" to "spell"
                    DB.setValue(nodeAction, "savetype", "string", "spell");      
                    -- initiative setting
                    DB.setValue(nodeAction, "....castinitiative", "number", nCastTime);
                    DB.setValue(nodeAction, "castinitiative", "number", nCastTime);
                end
            end
        end
    end
    
	return nodeNewPower;
end

-- parse the castingtime of a spell and turn into "init modifier" -celestian
function getCastingTime(sCastingTime,nSpellLevel)
    local nCastTime = 1;
    local nCastBase = sCastingTime:match("(%d+)") or nSpellLevel;
    local sLeftover = sCastingTime:match("%d+(.*)") or "";
    
    nCastTime = nCastBase;
    -- if something other than number/space in string...
    if string.len(sLeftover) > 1 then 
        sLeftover = sLeftover:gsub(" ","");
        if (StringManager.isWord(sLeftover, {"round","rd","rds","rd.","rn","rn."})) then
            nCastTime = nCastBase * 10;
        else
            -- anything more than this we really shouldn't be rolling for init
            nCastTime = 999;
        end
    end
    
    return nCastTime;
end

-------------------------
-- POWER ACTION DISPLAY
-------------------------

function getPowerActionOutputOrder(nodeAction)
	if not nodeAction then
		return 1;
	end
	local nodeActionList = nodeAction.getParent();
	if not nodeActionList then
		return 1;
	end
	
	-- First, pull some ability attributes
	local sType = DB.getValue(nodeAction, "type", "");
	local nOrder = DB.getValue(nodeAction, "order", 0);
	
	-- Iterate through list node
	local nOutputOrder = 1;
	for k, v in pairs(nodeActionList.getChildren()) do
		if DB.getValue(v, "type", "") == sType then
			if DB.getValue(v, "order", 0) < nOrder then
				nOutputOrder = nOutputOrder + 1;
			end
		end
	end
	
	return nOutputOrder;
end

function getPowerRoll(rActor, nodeAction, sSubRoll)
	if not nodeAction then
		return;
	end
	
	local sType = DB.getValue(nodeAction, "type", "");
	
	local rAction = {};
	rAction.type = sType;
	rAction.label = DB.getValue(nodeAction, "...name", "");
	rAction.order = getPowerActionOutputOrder(nodeAction);
	
	if sType == "cast" then
		rAction.subtype = sSubRoll;
		rAction.onmissdamage = DB.getValue(nodeAction, "onmissdamage", "");
		
		local sAttackType = DB.getValue(nodeAction, "atktype", "");
		if sAttackType ~= "" then
			local nGroupMod, sGroupStat = getGroupAttackBonus(rActor, nodeAction, "");
		
			if sAttackType == "melee" then
				rAction.range = "M";
			else
				rAction.range = "R";
			end
			
			local nGroupMod, sGroupStat = getGroupAttackBonus(rActor, nodeAction, "base");

			local sAttackBase = DB.getValue(nodeAction, "atkbase", "");
			if sAttackBase == "fixed" then
				rAction.modifier = DB.getValue(nodeAction, "atkmod", 0);
			elseif sAttackBase == "ability" then
				local sAbility = DB.getValue(nodeAction, "atkstat", "");
				if sAbility == "base" then
					sAbility = sGroupStat;
				end
				local nAttackProf = DB.getValue(nodeAction, "atkprof", 1);
				
				rAction.modifier = ActorManager2.getAbilityBonus(rActor, sAbility, "hitadj") + DB.getValue(nodeAction, "atkmod", 0);
				if nAttackProf == 1 then
					rAction.modifier = rAction.modifier + DB.getValue(ActorManager.getCreatureNode(rActor), "profbonus", 0);
				end
				rAction.stat = sAbility;
			else
				rAction.modifier = nGroupMod + DB.getValue(nodeAction, "atkmod", 0);
				rAction.stat = sGroupStat;
			end
		end
		
		local sSaveType = DB.getValue(nodeAction, "savetype", ""):lower();
		if sSaveType ~= "" then
			local nGroupDC, sGroupStat = PowerManager.getGroupSaveDC(rActor, nodeAction, sSaveType);
			if sSaveType == "base" then
				sSaveType = sGroupStat;
			end
			rAction.save = sSaveType;
			local sSaveBase = DB.getValue(nodeAction, "savedcbase", "");
			if sSaveBase == "fixed" then
				rAction.savemod = DB.getValue(nodeAction, "savedcmod", 0);
			elseif sSaveBase == "ability" then
				local sAbility = DB.getValue(nodeAction, "savedcstat", "");
				if sAbility == "base" then
					sAbility = sGroupStat;
				end
				--local nSaveProf = DB.getValue(nodeAction, "savedcprof", 1);
				--rAction.savemod = 8 + ActorManager2.getAbilityBonus(rActor, sAbility) + DB.getValue(nodeAction, "savedcmod", 0);
				--if nSaveProf == 1 then
				--	rAction.savemod = rAction.savemod + DB.getValue(ActorManager.getCreatureNode(rActor), "profbonus", 0);
				--end
                rAction.savemod = DB.getValue(nodeAction, "savedcmod", 0);
			else
				rAction.savemod = nGroupDC + DB.getValue(nodeAction, "savedcmod", 0);
			end
		else
			rAction.save = "";
			rAction.savemod = 0;
		end
		
	elseif sType == "damage" then
		rAction.clauses = getActionDamage(rActor, nodeAction);
		
	elseif sType == "heal" then
		rAction.sTargeting = DB.getValue(nodeAction, "healtargeting", "");
		rAction.subtype = DB.getValue(nodeAction, "healtype", "");
		
		rAction.clauses = getActionHeal(rActor, nodeAction);
		
	elseif sType == "effect" then
		local sEffect = DB.getValue(nodeAction, "label", "");
		if string.match(sEffect, "%[BASE%]") then
			local sStat = getGroupStat(rActor, nodeAction);
			if DataCommon.ability_ltos[sStat] then
				string.gsub(sEffect, "%[BASE%]", "[" .. DataCommon.ability_ltos[sStat] .. "]");
			end
		end
		rAction.sName = EffectManager.evalEffect(rActor, sEffect);

		rAction.sApply = DB.getValue(nodeAction, "apply", "");
		rAction.sTargeting = DB.getValue(nodeAction, "targeting", "");
		
		rAction.nDuration = DB.getValue(nodeAction, "durmod", 0);
		rAction.sUnits = DB.getValue(nodeAction, "durunit", "");
	end
	
	return rAction;
end


-- check this -celestian
function onPowerAction(draginfo, nodeAction, sSubRoll)
	if not nodeAction then
		return;
	end
	local rActor = ActorManager.getActor("", nodeAction.getChild("....."));
	if not rActor then
		return;
	end

    -- capture this and increment spells used -celestian
  	local sType = DB.getValue(nodeAction, "type", "");
    if sType == "cast" then 
        if not removeMemorizedSpell(draginfo,nodeAction) then 
            -- spell wasn't memorized so stop here
            return; 
        end
    end
    
    local rAction = getPowerRoll(rActor, nodeAction, sSubRoll);
    
    local sRollType = nil;
    local rRolls = {};

    if rAction.type == "cast" then
        
        if not rAction.subtype then
            table.insert(rRolls, ActionPower.getPowerCastRoll(rActor, rAction));
        end
        
        if not rAction.subtype or rAction.subtype == "atk" then
            if rAction.range then
                table.insert(rRolls, ActionAttack.getRoll(rActor, rAction));
            end
        end

        if not rAction.subtype or rAction.subtype == "save" then
            if rAction.save and rAction.save ~= "" then
                local rRoll = ActionPower.getSaveVsRoll(rActor, rAction);
                if not rAction.subtype then
                    rRoll.sType = "powersave";
                end
                table.insert(rRolls, rRoll);
            end
        end
        
    elseif rAction.type == "damage" then
        table.insert(rRolls, ActionDamage.getRoll(rActor, rAction));
        
    elseif rAction.type == "heal" then
        table.insert(rRolls, ActionHeal.getRoll(rActor, rAction));

    elseif rAction.type == "effect" then
        local rRoll = ActionEffect.getRoll(draginfo, rActor, rAction);
        if rRoll then
            table.insert(rRolls, rRoll);
        end
    end
    
    if #rRolls > 0 then
        ActionsManager.performMultiAction(draginfo, rActor, rRolls[1].sType, rRolls);
    end
end

function getGroupFromAction(rActor, nodeAction)
	local sGroup = DB.getValue(nodeAction, "...group", "");
	for _,v in pairs(DB.getChildren(ActorManager.getCreatureNode(rActor), "powergroup")) do
		if DB.getValue(v, "name", "") == sGroup then
			return v;
		end
	end
	return nil;
end

function getGroupStat(rActor, nodeAction)
	local vGroup = getGroupFromAction(rActor, nodeAction);
	return DB.getValue(vGroup, "stat", "");
end

function getGroupAttackBonus(rActor, nodeAction)
	local vGroup = getGroupFromAction(rActor, nodeAction);

	local sGroupAtkStat = DB.getValue(vGroup, "atkstat", "");
	if sGroupAtkStat == "" then
		sGroupAtkStat = DB.getValue(vGroup, "stat", "");
	end
	local nGroupAtkProf = DB.getValue(vGroup, "atkprof", 1);
	
	local nGroupAtkMod = ActorManager2.getAbilityBonus(rActor, sGroupAtkStat, "hitadj");
	if nGroupAtkProf == 1 then
		nGroupAtkMod = nGroupAtkMod + DB.getValue(ActorManager.getCreatureNode(rActor), "profbonus", 0);
	end
	nGroupAtkMod = nGroupAtkMod + DB.getValue(vGroup, "atkmod", 0);
	
	return nGroupAtkMod, sGroupAtkStat;
end

function getGroupSaveDC(rActor, nodeAction)
	local vGroup = getGroupFromAction(rActor, nodeAction);

	local sGroupSaveStat = DB.getValue(vGroup, "savestat", "");
	if sGroupSaveStat == "" then
		sGroupSaveStat = DB.getValue(vGroup, "stat", "");
	end
	local nGroupSaveProf = DB.getValue(vGroup, "saveprof", 1);
	
--	local nGroupSaveDC = 8 + ActorManager2.getAbilityBonus(rActor, sGroupSaveStat);
	local nGroupSaveDC = 0;
	--if nGroupSaveProf == 1 then
	--	nGroupSaveDC = nGroupSaveDC + DB.getValue(ActorManager.getCreatureNode(rActor), "profbonus", 0);
	--end
	nGroupSaveDC = nGroupSaveDC + DB.getValue(vGroup, "savemod", 0);
	
	return nGroupSaveDC, sGroupSaveStat;
end

function getGroupDamageHealBonus(rActor, nodeAction, sStat)
	if sStat == "base" then
		sStat = getGroupStat(rActor, nodeAction);
	end
	local nMod = ActorManager2.getAbilityBonus(rActor, sStat);
	return nMod, sStat;
end

function getActionDamageText(nodeAction)
	local nodeActor = nodeAction.getChild(".....")
	local rActor = ActorManager.getActor("", nodeActor);

	local clauses = PowerManager.getActionDamage(rActor, nodeAction);
	
	local aOutput = {};
	local aDamage = ActionDamage.getDamageStrings(clauses);
	for _,rDamage in ipairs(aDamage) do
		local sDice = StringManager.convertDiceToString(rDamage.aDice, rDamage.nMod);
		if sDice ~= "" then
			if rDamage.sType ~= "" then
				table.insert(aOutput, string.format("%s %s", sDice, rDamage.sType));
			else
				table.insert(aOutput, sDice);
			end
		end
	end
	
	return table.concat(aOutput, " + ");
end

function getActionDamage(rActor, nodeAction)
	if not nodeAction then
		return {};
	end
	
	local clauses = {};
	local aDamageNodes = UtilityManager.getSortedTable(DB.getChildren(nodeAction, "damagelist"));
	for _,v in ipairs(aDamageNodes) do
		local sDmgAbility = DB.getValue(v, "stat", "");
		local aDmgDice = DB.getValue(v, "dice", {});
		local nDmgMod = DB.getValue(v, "bonus", 0);
		local sDmgType = DB.getValue(v, "type", "");
		
		local nDmgStatMod;
		nDmgStatMod, sDmgAbility = getGroupDamageHealBonus(rActor, nodeAction, sDmgAbility);
		nDmgMod = nDmgMod + nDmgStatMod;
		
		table.insert(clauses, { dice = aDmgDice, stat = sDmgAbility, modifier = nDmgMod, dmgtype = sDmgType });
	end

	return clauses;
end

function getActionHealText(nodeAction)
	local nodeActor = nodeAction.getChild(".....")
	local rActor = ActorManager.getActor("", nodeActor);

	local clauses = PowerManager.getActionHeal(rActor, nodeAction);
	
	local aHealDice = {};
	local nHealMod = 0;
	for _,vClause in ipairs(clauses) do
		for _,vDie in ipairs(vClause.dice) do
			table.insert(aHealDice, vDie);
		end
		nHealMod = nHealMod + vClause.modifier;
	end
	
	local sHeal = StringManager.convertDiceToString(aHealDice, nHealMod);
	if DB.getValue(nodeAction, "healtype", "") == "temp" then
		sHeal = sHeal .. " temporary";
	end
	
	local sTargeting = DB.getValue(nodeAction, "healtargeting", "");
	if sTargeting == "self" then
		sHeal = sHeal .. " [SELF]";
	end
	
	return sHeal;
end

function getActionHeal(rActor, nodeAction)
	if not nodeAction then
		return;
	end
	
	local clauses = {};
	local aHealNodes = UtilityManager.getSortedTable(DB.getChildren(nodeAction, "heallist"));
	for _,v in ipairs(aHealNodes) do
		local sAbility = DB.getValue(v, "stat", "");
		local aDice = DB.getValue(v, "dice", {});
		local nMod = DB.getValue(v, "bonus", 0);
		
		local nStatMod;
		nStatMod, sAbility = getGroupDamageHealBonus(rActor, nodeAction, sAbility);
		nMod = nMod + nStatMod;
		
		table.insert(clauses, { dice = aDice, stat = sAbility, modifier = nMod });
	end

	return clauses;
end

-------------------------
-- POWER PARSING
-------------------------
-- need to tweak this perhaps to deal with AD&D creatures descriptions? -celestian
function parseAttacks(sPowerName, aWords)
	local attacks = {};
	
	for i = 1, #aWords do
		if StringManager.isWord(aWords[i], "attack") then
			local nIndex = i;
			if StringManager.isWord(aWords[nIndex + 1], ":") then
				nIndex = nIndex + 1;
			end
			if StringManager.isNumberString(aWords[nIndex+1]) and 
					StringManager.isWord(aWords[nIndex+2], "to") and
					StringManager.isWord(aWords[nIndex+3], "hit") then
				local rAttack = {};
				rAttack.startindex = i;
				rAttack.endindex = nIndex + 3;
				
				rAttack.label = sPowerName;
				
				if StringManager.isWord(aWords[i-1], "weapon") then
					rAttack.weapon = true;
					rAttack.startindex = i - 1;
				elseif StringManager.isWord(aWords[i-1], "spell") then
					rAttack.spell = true;
					rAttack.startindex = i - 1;
				end
				
				if StringManager.isWord(aWords[i-2], "melee") then
					rAttack.range = "M";
					rAttack.startindex = i - 2;
				elseif StringManager.isWord(aWords[i-2], "ranged") then
					rAttack.range = "R";
					rAttack.startindex = i - 2;
				end
				
				if StringManager.isWord(aWords[nIndex+4], "reach") then
					rAttack.rangedist = aWords[nIndex+5];
				elseif StringManager.isWord(aWords[nIndex+4], "range") then
					if StringManager.isNumberString(aWords[nIndex+5]) and StringManager.isWord(aWords[nIndex+6], "ft") then
						rAttack.rangedist = aWords[nIndex+5];
						
						local nIndex2 = nIndex + 7;
						if StringManager.isWord(aWords[nIndex2], ".") then
							nIndex2 = nIndex2 + 1;
						end
						if StringManager.isNumberString(aWords[nIndex2]) and StringManager.isWord(aWords[nIndex2+1], "ft") then
							rAttack.rangedist = rAttack.rangedist .. "/" .. aWords[nIndex2];
						end
					end
				end

				rAttack.modifier = tonumber(aWords[nIndex+1]) or 0;

				table.insert(attacks, rAttack);
			else
				local bValid = false;
				if StringManager.isWord(aWords[i-1], {"weapon", "spell"}) and StringManager.isWord(aWords[i-2], {"melee", "ranged"}) and
						StringManager.isWord(aWords[i-3], {"a", "one", "single"}) and StringManager.isWord(aWords[i-4], "make") then
					bValid = true;
				end
				if bValid == true then
					if StringManager.isWord(aWords[i+1], "during") then
						bValid = false;
					elseif StringManager.isWord(aWords[i-5], "you") and StringManager.isWord(aWords[i-6], "when") then
						bValid = false;
					end
				end
				if bValid == true then
					local rAttack = {};
					rAttack.startindex = i - 2;
					rAttack.endindex = i;
					
					rAttack.label = sPowerName;
				
					if StringManager.isWord(aWords[i-1], "weapon") then
						rAttack.weapon = true;
					elseif StringManager.isWord(aWords[i-1], "spell") then
						rAttack.spell = true;
					end
					
					if StringManager.isWord(aWords[i-2], "melee") then
						rAttack.range = "M";
					elseif StringManager.isWord(aWords[i-2], "ranged") then
						rAttack.range = "R";
					end
					
					rAttack.modifier = 0;
					rAttack.nomod = true;
					
					table.insert(attacks, rAttack);
				end
			end
		end
	end
	
	return attacks;
end

-- Assumes current index points to "damage"
function parseDamagePhrase(aWords, i)
	local rDamageFixed = nil;
	local rDamageVariable = nil;
	
	local bValid = false;
	local nDamageBegin = i;
	while StringManager.isWord(aWords[nDamageBegin - 1], DataCommon.dmgtypes) or
			(StringManager.isWord(aWords[nDamageBegin - 1], "or") and StringManager.isWord(aWords[nDamageBegin - 2], DataCommon.dmgtypes)) do
		nDamageBegin = nDamageBegin - 1;
	end
	while StringManager.isDiceString(aWords[nDamageBegin - 1]) or (StringManager.isWord(aWords[nDamageBegin - 1], "plus") and StringManager.isDiceString(aWords[nDamageBegin - 2])) do
		bValid = true;
		nDamageBegin = nDamageBegin - 1;
	end
	if StringManager.isWord(aWords[nDamageBegin], "+") then
		nDamageBegin = nDamageBegin + 1;
	end
	
	if bValid then
		local nClauses = 0;
		local aFixedClauses = {};
		local aVariableClauses = {};
		local bHasVariableClause = false;
		local nDamageEnd = i;
		
		local j = nDamageBegin - 1;
		while bValid do
			local aDamage = {};

			while StringManager.isDiceString(aWords[j+1]) or (StringManager.isWord(aWords[j+1], "plus") and StringManager.isDiceString(aWords[j+2])) do
				if aWords[j+1] == "plus" then
					table.insert(aDamage, "+");
				else
					table.insert(aDamage, aWords[j+1]);
				end
				j = j + 1;
			end
			
			local aDmgType = {};
			while StringManager.isWord(aWords[j+1], DataCommon.dmgtypes) or
					(StringManager.isWord(aWords[j+1], "or") and StringManager.isWord(aWords[j+2], DataCommon.dmgtypes)) do
				if aWords[j+1] ~= "or" then
					table.insert(aDmgType, aWords[j+1]);
				end
				j = j + 1;
			end
			
			if #aDamage > 0 and StringManager.isWord(aWords[j+1], "damage") then
				j = j + 1;
				
				nClauses = nClauses + 1;
				
				local sDmgType = table.concat(aDmgType, ",");
				if #aDamage > 1 and StringManager.isNumberString(aDamage[1]) then
					bHasVariableClause = true;

					local rClauseFixed = {};
					rClauseFixed.dmgtype = sDmgType;
					rClauseFixed.dice, rClauseFixed.modifier = StringManager.convertStringToDice(aDamage[1]);
					aFixedClauses[nClauses] = rClauseFixed;

					local rClauseVariable = {};
					rClauseVariable.dmgtype = sDmgType;
					rClauseVariable.dice, rClauseVariable.modifier = StringManager.convertStringToDice(table.concat(aDamage, "", 2));
					aVariableClauses[nClauses] = rClauseVariable;
				else
					local rClauseFixed = {};
					rClauseFixed.dmgtype = sDmgType;
					rClauseFixed.dice, rClauseFixed.modifier = StringManager.convertStringToDice(table.concat(aDamage));
					aFixedClauses[nClauses] = rClauseFixed;
					
					local rClauseVariable = {};
					rClauseVariable.dmgtype = sDmgType;
					rClauseVariable.dice, rClauseVariable.modifier = StringManager.convertStringToDice(table.concat(aDamage));
					aVariableClauses[nClauses] = rClauseVariable;
				end
				
				nDamageEnd = j;
			else
				j = j + 1;
				break;
			end

			if StringManager.isWord(aWords[j+1], {"and", "plus", "+"}) then
				j = j + 1;
				bValid = true;
			else
				bValid = false;
			end
		end
		
		i = j;
		
		if nClauses > 0 then
			rDamageFixed = {};
			rDamageFixed.startindex = nDamageBegin;
			rDamageFixed.endindex = nDamageEnd;

			rDamageFixed.clauses = aFixedClauses;
			
			if bHasVariableClause then
				rDamageVariable = {};
				rDamageVariable.startindex = nDamageBegin;
				rDamageVariable.endindex = nDamageEnd;

				rDamageVariable.clauses = aVariableClauses;
			end
		end
	elseif StringManager.isWord(aWords[i+1], "equal") and
			StringManager.isWord(aWords[i+2], "to") then
		local nStart = nDamageBegin;
		local aDamageDice = {};
		local aAbilities = {};
		local nMult = 1;
		
		j = i + 2;
		while aWords[j+1] do
			if StringManager.isDiceString(aWords[j+1]) then
				table.insert(aDamageDice, aWords[j+1]);
				nMult = 1;
			elseif StringManager.isWord(aWords[j+1], "twice") then
				nMult = 2;
			elseif StringManager.isWord(aWords[j+1], "three") and
					StringManager.isWord(aWords[j+2], "times") then
				nMult = 3;
				j = j + 1;
			elseif StringManager.isWord(aWords[j+1], "four") and
					StringManager.isWord(aWords[j+2], "times") then
				nMult = 4;
				j = j + 1;
			elseif StringManager.isWord(aWords[j+1], "five") and
					StringManager.isWord(aWords[j+2], "times") then
				nMult = 5;
				j = j + 1;
			elseif StringManager.isWord(aWords[j+1], "your") and
					StringManager.isWord(aWords[j+2], "spellcasting") and
					StringManager.isWord(aWords[j+3], "ability") and
					StringManager.isWord(aWords[j+4], "modifier") then
				for i = 1, nMult do
					table.insert(aAbilities, "base");
				end
				nMult = 1;
				j = j + 3;
			elseif StringManager.isWord(aWords[j+1], "your") and
					StringManager.isWord(aWords[j+3], "modifier") and
					StringManager.isWord(aWords[j+2], DataCommon.abilities) then
				for i = 1, nMult do
					table.insert(aAbilities, aWords[j+2]);
				end
				nMult = 1;
				j = j + 2;
			elseif StringManager.isWord(aWords[j+1], "your") and
					StringManager.isWord(aWords[j+2], "level") then
				for i = 1, nMult do
					table.insert(aAbilities, "level");
				end
				nMult = 1;
				j = j + 1;
			elseif StringManager.isWord(aWords[j+1], "your") and
					StringManager.isWord(aWords[j+3], "level") and
					DataCommon.class_nametovalue[StringManager.capitalize(aWords[j+2])] then
				for i = 1, nMult do
					table.insert(aAbilities, DataCommon.class_nametovalue[StringManager.capitalize(aWords[j+2])]);
				end
				nMult = 1;
				j = j + 2;
			else
				break;
			end
			
			j = j + 1;
		end
		
		if (#aAbilities > 0) or (#aDamageDice > 0) then
			rDamageFixed = {};
			rDamageFixed.startindex = nStart;
			rDamageFixed.endindex = j;
			
			rDamageFixed.label = sPowerName;
			
			rDamageFixed.clauses = {};
			local rDmgClause = {};
			rDmgClause.dice, rDmgClause.modifier = StringManager.convertStringToDice(table.concat(aDamageDice, ""));
			if #aAbilities > 0 then
				rDmgClause.stat = aAbilities[1];
			end
			
			local aDmgType = {};
			if i ~= nStart then
				local k = nStart;
				while StringManager.isWord(aWords[k], DataCommon.dmgtypes) do
					table.insert(aDmgType, aWords[k]);
					k = k + 1;
				end
			end
			rDmgClause.dmgtype = table.concat(aDmgType, ",");
			
			table.insert(rDamageFixed.clauses, rDmgClause);
			
			for i = 2, #aAbilities do
				table.insert(rDamageFixed.clauses, { dice = {}, modifier = 0, stat = aAbilities[i], dmgtype = sDmgType });
			end
		end
	end
	
	if rDamageVariable then 
		return i, rDamageVariable;
	end
	return i, rDamageFixed;
end

function parseDamages(sPowerName, aWords)
	local damages = {};

	local bMagicAttack = false;
	
  	local i = 1;
  	while aWords[i] do
		-- MAIN TRIGGER ("damage")
		if StringManager.isWord(aWords[i], "damage") then
			local rDamage;
			i, rDamage = parseDamagePhrase(aWords, i);
			if rDamage then
				if StringManager.isWord(aWords[i+1], "at") and 
						StringManager.isWord(aWords[i+2], "the") and
						StringManager.isWord(aWords[i+3], { "start", "end" }) and
						StringManager.isWord(aWords[i+4], "of") then
					rDamage = nil;
				elseif StringManager.isWord(aWords[rDamage.startindex - 1], "extra") then
					rDamage = nil;
				end
			end
			if rDamage then
				rDamage.label = sPowerName;
				if string.match(sPowerName, "^[Rr]anged") then
					rDamage.range = "R";
				elseif string.match(sPowerName, "^[Mm]elee") then
					rDamage.range = "M";
				end
				
				table.insert(damages, rDamage);
			end
  		-- CAPTURE MAGIC DAMAGE MODIFIER
		elseif StringManager.isWord(aWords[i], "attack") and StringManager.isWord(aWords[i-1], "weapon") and 
				StringManager.isWord(aWords[i-2], "magic") and StringManager.isWord(aWords[i-3], "a") and 
				StringManager.isWord(aWords[i-4], "is") and StringManager.isWord(aWords[i-5], "this") then
			bMagicAttack = true;
		end
		
		i = i + 1;
	end	

	-- HANDLE MAGIC DAMAGE MODIFIER
	if bMagicAttack then
		for _,rDamage in ipairs(damages) do
			for _, rClause in ipairs(rDamage.clauses) do
				if not rClause.dmgtype or rClause.dmgtype == "" then
					rClause.dmgtype = "magic";
				else
					rClause.dmgtype = rClause.dmgtype .. ",magic";
				end
			end
		end
	end
	
	-- RESULTS
	return damages;
end

-- [-] regains additional hit points equal to 2 + spell's level.
-- [-] regains at least 1 hit point
-- [-] regains the maximum number of hit points possible from any healing.

-- regains <dice>+ hit points.
-- regains a number of hit points equal to <dice> + your spellcasting ability modifier.
-- regains hit points equal to <dice> + your spellcasting ability modifier.
-- regains hit points equal to <dice> + your spellcasting ability modifier.
-- regains 1 hit point at the start of each of its turns

function parseHeals(sPowerName, aWords)
	local heals = {};
	
  	-- Iterate through the words looking for clauses
  	local i = 1;
  	while aWords[i] do
  		-- Check for hit point gains (temporary or normal)
  		if StringManager.isWord(aWords[i], {"points", "point"}) and StringManager.isWord(aWords[i-1], "hit") then
  			-- Track the healing information
			local rHeal = nil;
  			local sTemp = nil;
   			local aHealDice = {};

  			-- Iterate backwards to determine values
  			local j = i - 2;
  			if StringManager.isWord(aWords[j], "temporary") then
				sTemp = "temp";
				j = j - 1;
   			end
			if StringManager.isWord(aWords[j], "of") and
					StringManager.isWord(aWords[j-1], "number") and
					StringManager.isWord(aWords[j-2], "a") then
				j = j - 3;
			end
 			if StringManager.isWord(aWords[j], "of") and
					StringManager.isWord(aWords[j-1], "number") and
					StringManager.isWord(aWords[j-2], "total") and
					StringManager.isWord(aWords[j-3], "a") then
				j = j - 4;
			end
 			while aWords[j] do
  				if StringManager.isDiceString(aWords[j]) and aWords[j] ~= "0" then
  					table.insert(aHealDice, 1, aWords[j]);
				else
  					break;
  				end
  				
  				j = j - 1;
  			end
			
			-- Make sure we started with "gain(s)" or "regain(s)" or "restore"
			if StringManager.isWord(aWords[j], {"gain", "gains", "regain", "regains", "restore"}) and 
					not StringManager.isWord(aWords[j-1], {"cannot", "can't"}) then
				-- Determine self-targeting
				local bSelf = false;
				if aWords[j] ~= "restore" then
					local nSelfIndex = j;
					if StringManager.isWord(aWords[nSelfIndex-1], "to") and
							StringManager.isWord(aWords[nSelfIndex-2], "action") and
							StringManager.isWord(aWords[nSelfIndex-3], "bonus") and
							StringManager.isWord(aWords[nSelfIndex-4], "a") and
							StringManager.isWord(aWords[nSelfIndex-5], "use") then
						nSelfIndex = nSelfIndex - 5;
					end
 					if StringManager.isWord(aWords[nSelfIndex-1], "can") then
						nSelfIndex = nSelfIndex - 1;
					end
					if StringManager.isWord(aWords[nSelfIndex-1], "you") then
						bSelf = true;
					end
				end
				
				-- Figure out if the values in the text support a heal roll
				if (#aHealDice > 0) then
					local rHealFixedClause = {};
					local rHealVariableClause = {};
					
					local bHasVariableClause = false;
					if #aHealDice > 1 and StringManager.isNumberString(aHealDice[1]) then
						bHasVariableClause = true;

						rHealFixedClause.dice, rHealFixedClause.modifier = StringManager.convertStringToDice(aHealDice[1]);

						rHealVariableClause.dice, rHealVariableClause.modifier = StringManager.convertStringToDice(table.concat(aHealDice, "", 2));
					else
						rHealFixedClause.dice, rHealFixedClause.modifier = StringManager.convertStringToDice(table.concat(aHealDice));
						
						rHealVariableClause.dice, rHealVariableClause.modifier = StringManager.convertStringToDice(table.concat(aHealDice));
					end
					
					rHeal = {};
					rHeal.startindex = j;
					rHeal.endindex = i;
					
					rHeal.label = sPowerName;
					if sTemp then
						rHeal.subtype = "temp";
					end
					if bSelf then
						rHeal.sTargeting = "self";
					end
					
					rHeal.clauses = {};
					if bHasVariableClause then 
						table.insert(rHeal.clauses, rHealVariableClause);
					else
						table.insert(rHeal.clauses, rHealFixedClause);
					end
				
				elseif StringManager.isWord(aWords[i+1], "equal") and
						StringManager.isWord(aWords[i+2], "to") then
					local nStart = j;
					local aAbilities = {};
					local nMult = 1;
					
					j = i + 2;
					while aWords[j+1] do
						if StringManager.isDiceString(aWords[j+1]) then
							table.insert(aHealDice, aWords[j+1]);
							nMult = 1;
						elseif StringManager.isWord(aWords[j+1], "twice") then
							nMult = 2;
						elseif StringManager.isWord(aWords[j+1], "three") and
								StringManager.isWord(aWords[j+2], "times") then
							nMult = 3;
							j = j + 1;
						elseif StringManager.isWord(aWords[j+1], "four") and
								StringManager.isWord(aWords[j+2], "times") then
							nMult = 4;
							j = j + 1;
						elseif StringManager.isWord(aWords[j+1], "five") and
								StringManager.isWord(aWords[j+2], "times") then
							nMult = 5;
							j = j + 1;
						elseif StringManager.isWord(aWords[j+1], "your") and
								StringManager.isWord(aWords[j+2], "spellcasting") and
								StringManager.isWord(aWords[j+3], "ability") and
								StringManager.isWord(aWords[j+4], "modifier") then
							for i = 1, nMult do
								table.insert(aAbilities, "base");
							end
							nMult = 1;
							j = j + 3;
						elseif StringManager.isWord(aWords[j+1], "your") and
								StringManager.isWord(aWords[j+3], "modifier") and
								StringManager.isWord(aWords[j+2], DataCommon.abilities) then
							for i = 1, nMult do
								table.insert(aAbilities, aWords[j+2]);
							end
							nMult = 1;
							j = j + 2;
						elseif StringManager.isWord(aWords[j+1], "your") and
								StringManager.isWord(aWords[j+2], "level") then
							for i = 1, nMult do
								table.insert(aAbilities, "level");
							end
							nMult = 1;
							j = j + 1;
						elseif StringManager.isWord(aWords[j+1], "your") and
								StringManager.isWord(aWords[j+3], "level") and
								DataCommon.class_nametovalue[StringManager.capitalize(aWords[j+2])] then
							-- One off - Lay on Hands
							local bAddOne = false;
							if StringManager.isWord(aWords[j+4], "x5") then
								bAddOne = true;
								nMult = 5;
							end
							for i = 1, nMult do
								table.insert(aAbilities, DataCommon.class_nametovalue[StringManager.capitalize(aWords[j+2])]);
							end
							nMult = 1;
							j = j + 2;
							if bAddOne then
								j = j + 1;
							end
						else
							break;
						end
						
						j = j + 1;
					end
					
					if (#aAbilities > 0) or (#aHealDice > 0) then
						rHeal = {};
						rHeal.startindex = nStart;
						rHeal.endindex = j;
						
						rHeal.label = sPowerName;
						if sTemp then
							rHeal.subtype = "temp";
						end
						if bSelf then
							rHeal.sTargeting = "self";
						end
						
						rHeal.clauses = {};
						local rHealClause = {};
						rHealClause.dice, rHealClause.modifier = StringManager.convertStringToDice(table.concat(aHealDice, ""));
						if #aAbilities > 0 then
							rHealClause.stat = aAbilities[1];
						end
						table.insert(rHeal.clauses, rHealClause);
						
						for i = 2, #aAbilities do
							table.insert(rHeal.clauses, { dice = {}, modifier = 0, stat = aAbilities[i] });
						end
					end
				end
			end
   		
			if rHeal then
				table.insert(heals, rHeal);
			end
		end
		
		-- Increment our counter
		i = i + 1;
	end	

	return heals;
end

function parseSaves(sPowerName, aWords, bPC)
	local saves = {};
	
	for i = 1, #aWords do
        -- AD&D style entries -celestian
        -- "saving throw versus breath for half damage" ?
		if StringManager.isWord(aWords[i], {"throw","throws"}) and
				StringManager.isWord(aWords[i+1], {"versus", "vrs", "vrs.", "vr","vr.","v","v."}) and
                StringManager.isWord(aWords[i+2], DataCommon.saves_shortnames) then
			local rSave = nil;
			local bValid = true; --for now, if we get above I consider it valid, might change later.
			local bHalf = false;
			local nStart = i;
			local nDC = nil;

            if StringManager.isWord(aWords[nStart + 1], { "half" }) then
                bHalf = true;
			end

			if bValid then
				rSave = {};
				rSave.startindex = nStart;
				rSave.endindex = i+2;
				rSave.label = sPowerName;
				rSave.save = aWords[i+2];
                if (bHalf) then
                    rSave.onmissdamage = "half";
                end
				if nDC then
					rSave.savemod = nDC;
				else
					--rSave.spell = true;
					rSave.savemod = 0;
				end
			end
			if rSave then
				table.insert(saves, rSave);
				-- Only pick up first save for PC powers
				if bPC then
					break;
				end
			end
        
        -- 5e style entries
        elseif StringManager.isWord(aWords[i], "throw") and
				StringManager.isWord(aWords[i-1], "saving") and
--				StringManager.isWord(aWords[i-2], DataCommon.abilities) then
                StringManager.isWord(aWords[i-2], DataCommon.saves_shortnames) then
			
			local rSave = nil;
			local bValid = false;
			local nStart = i - 2;
			local nDC = nil;
			if StringManager.isWord(aWords[nStart - 1], { "a", "an" }) then
				nStart = nStart - 1;
				if StringManager.isWord(aWords[nStart - 1], "fails") then
					bValid = true;
					nStart = nStart - 1;
				elseif StringManager.isWord(aWords[nStart - 1], "make") and
						StringManager.isWord(aWords[nStart - 2], {"must", "to"}) then
					bValid = true;
					nStart = nStart - 2;
				elseif StringManager.isWord(aWords[nStart - 1], "on") and
						StringManager.isWord(aWords[nStart - 2], "succeed") and
						StringManager.isWord(aWords[nStart - 3], "must") then
					bValid = true;
					nStart = nStart - 3;
				end
				
			elseif StringManager.isNumberString(aWords[i-3]) and 
					StringManager.isWord(aWords[i-4], "dc") then
				bValid = true;
				nStart = i - 4;
				nDC = tonumber(aWords[i-3]) or 0;
			end
				
			if bValid then
				rSave = {};
				rSave.startindex = nStart;
				rSave.endindex = i;
				rSave.label = sPowerName;
				rSave.save = aWords[i-2];
				if nDC then
					rSave.savemod = nDC;
				else
					rSave.spell = true;
					rSave.savemod = 8;
				end
			end
		
			if rSave then
				table.insert(saves, rSave);
				
				-- Only pick up first save for PC powers
				if bPC then
					break;
				end
			end
		elseif StringManager.isWord(aWords[i], "throw") and
				StringManager.isWord(aWords[i-1], "saving") and
				StringManager.isWord(aWords[i-2], "this") and
				StringManager.isWord(aWords[i-3], "for") and
				StringManager.isWord(aWords[i-4], "dc") and
				StringManager.isWord(aWords[i+1], "equals") and
				StringManager.isWord(aWords[i+2], "8") and
				StringManager.isWord(aWords[i+3], "+") and
				StringManager.isWord(aWords[i+4], "your") and
--				StringManager.isWord(aWords[i+5], DataCommon.abilities) and
				StringManager.isWord(aWords[i+5], DataCommon.saves_shortnames) and
				StringManager.isWord(aWords[i+6], "modifier") and
				StringManager.isWord(aWords[i+7], "+") and
				StringManager.isWord(aWords[i+8], "your") and
				StringManager.isWord(aWords[i+9], "proficiency") and
				StringManager.isWord(aWords[i+10], "bonus") then
			
			rSave = {};
			rSave.startindex = i-4;
			rSave.endindex = i+10;
			rSave.label = sPowerName;
			rSave.save = "base";
			rSave.savemod = 8;
			rSave.savestat = aWords[i+5];
		
			table.insert(saves, rSave);
			
			-- Only pick up first save for PC powers
			if bPC then
				break;
			end
		end
	end
	
	for i = 1,#saves do
		local nHalfCheckStart = saves[i].startindex;
		local nHalfCheckEnd = #aWords;
		if i < #saves then
			nHalfCheckEnd = saves[i+1].startindex - 1;
		end
		for j = nHalfCheckStart,nHalfCheckEnd do
			if StringManager.isWord(aWords[j], "half") then
				if StringManager.isWord(aWords[j+1], "as") and
						StringManager.isWord(aWords[j+2], "much") and
						StringManager.isWord(aWords[j+3], "damage") then
					saves[i].onmissdamage = "half";
				else
					local k = j;
					if StringManager.isWord(aWords[k-1], "only") then
						k = k - 1;
					end
					if StringManager.isWord(aWords[k-1], "takes") and
							StringManager.isWord(aWords[k-2], {"creature", "target"}) then
						-- Exception: Air Elemental - Whirlwind
						if sPowerName:match("^Whirlwind") then
							saves[1].onmissdamage = "half";
						else
							saves[i].onmissdamage = "half";
						end
					end
				end
			end
			
		end
	end
	
	return saves;
end

function parseEffectsAdd(aWords, i, rEffect, effects)
	local nDurIndex = rEffect.endindex + 1;
	if StringManager.isWord(aWords[nDurIndex], "by") 
			and StringManager.isWord(aWords[nDurIndex + 1], "the") then
		nDurIndex = nDurIndex + 3;
	end
	
	-- Handle expiration phrases
	if StringManager.isWord(aWords[nDurIndex], "for") 
			and StringManager.isNumberString(aWords[nDurIndex + 1]) 
			and StringManager.isWord(aWords[nDurIndex + 2], {"round", "rounds", "minute", "minutes", "hour", "hours", "day", "days"}) then
		rEffect.nDuration = tonumber(aWords[nDurIndex + 1]) or 0;
		if StringManager.isWord(aWords[nDurIndex + 2], {"minute", "minutes"}) then
			rEffect.sUnits = "minute";
		elseif StringManager.isWord(aWords[nDurIndex + 2], {"hour", "hours"}) then
			rEffect.sUnits = "hour";
		elseif StringManager.isWord(aWords[nDurIndex + 2], {"day", "days"}) then
			rEffect.sUnits = "day";
		end
		rEffect.endindex = nDurIndex + 2;
		
	elseif StringManager.isWord(aWords[nDurIndex], "until")
			and StringManager.isWord(aWords[nDurIndex + 1], "the")
			and StringManager.isWord(aWords[nDurIndex + 2], { "start", "end" })
			and StringManager.isWord(aWords[nDurIndex + 3], "of")
			and StringManager.isWord(aWords[nDurIndex + 4], "its")
			and StringManager.isWord(aWords[nDurIndex + 5], "next")
			and StringManager.isWord(aWords[nDurIndex + 6], "turn") then
		rEffect.nDuration = 1;
		rEffect.endindex = nDurIndex + 6;

	elseif StringManager.isWord(aWords[nDurIndex], "until")
			and StringManager.isWord(aWords[nDurIndex + 1], "its")
			and StringManager.isWord(aWords[nDurIndex + 2], "next")
			and StringManager.isWord(aWords[nDurIndex + 3], "turn") then
		rEffect.nDuration = 1;
		rEffect.endindex = nDurIndex + 3;

	elseif StringManager.isWord(aWords[nDurIndex], "until")
			and StringManager.isWord(aWords[nDurIndex + 1], "the")
			and StringManager.isWord(aWords[nDurIndex + 3], "next")
			and StringManager.isWord(aWords[nDurIndex + 4], "turn") then
		rEffect.nDuration = 1;
		rEffect.endindex = nDurIndex + 4;
	elseif StringManager.isWord(aWords[nDurIndex], "while")
			and StringManager.isWord(aWords[nDurIndex + 1], "poisoned") then
		if #effects > 0 and rEffect.sName == "Unconscious" and effects[#effects].sName == "Poisoned" then
			local rComboEffect = effects[#effects];
			rComboEffect.sName = rComboEffect.sName .. "; " .. rEffect.sName;
			rComboEffect.endindex = rEffect.endindex;
			return;
		end
	end

	-- Add or combine effect
	if #effects > 0 and effects[#effects].endindex + 1 == rEffect.startindex and not effects[#effects].nDuration then
		local rComboEffect = effects[#effects];
		rComboEffect.sName = rComboEffect.sName .. "; " .. rEffect.sName;
		rComboEffect.endindex = rEffect.endindex;
		rComboEffect.nDuration = rEffect.nDuration;
		rComboEffect.sUnits = rEffect.sUnits;
	else
		table.insert(effects, rEffect);
	end
end

function parseEffects(sPowerName, aWords)
	local effects = {};
	
	local rCurrent = nil;
	
	local i = 1;
	while aWords[i] do
		if StringManager.isWord(aWords[i], "damage") then
			i, rCurrent = parseDamagePhrase(aWords, i);
			if rCurrent then
				if StringManager.isWord(aWords[i+1], "at") and 
						StringManager.isWord(aWords[i+2], "the") and
						StringManager.isWord(aWords[i+3], { "start", "end" }) and
						StringManager.isWord(aWords[i+4], "of") then
					
					local nTrigger = i + 4;
					if StringManager.isWord(aWords[nTrigger+1], "each") and
							StringManager.isWord(aWords[nTrigger+2], "of") then
						if StringManager.isWord(aWords[nTrigger+3], "its") then
							nTrigger = nTrigger + 3;
						else
							nTrigger = nTrigger + 4;
						end
					elseif StringManager.isWord(aWords[nTrigger+1], "its") then
						if StringManager.isWord(aWords[nTrigger+2], "next") then
							nTrigger = nTrigger + 2;
						else
							nTrigger = nTrigger + 1;
						end
					elseif StringManager.isWord(aWords[nTrigger+1], "your") then
						nTrigger = nTrigger + 1;
					end
					if StringManager.isWord(aWords[nTrigger+1], { "turn", "turns" }) then
						nTrigger = nTrigger + 1;
					end
					rCurrent.endindex = nTrigger;
					
					if StringManager.isWord(aWords[rCurrent.startindex - 1], "takes") and
							StringManager.isWord(aWords[rCurrent.startindex - 2], "and") and
							StringManager.isWord(aWords[rCurrent.startindex - 3], DataCommon.conditions) then
						rCurrent.startindex = rCurrent.startindex - 2;
					end
					
					local aName = {};
					for _,v in ipairs(rCurrent.clauses) do
						local sDmg = StringManager.convertDiceToString(v.dice, v.modifier);
						if v.dmgtype and v.dmgtype ~= "" then
							sDmg = sDmg .. " " .. v.dmgtype;
						end
						table.insert(aName, "DMGO: " .. sDmg);
					end
					rCurrent.clauses = nil;
					rCurrent.sName = table.concat(aName, "; ");
				elseif StringManager.isWord(aWords[rCurrent.startindex - 1], "extra") then
					rCurrent.startindex = rCurrent.startindex - 1;
					rCurrent.sTargeting = "self";
					rCurrent.sApply = "roll";
					
					local aName = {};
					for _,v in ipairs(rCurrent.clauses) do
						local sDmg = StringManager.convertDiceToString(v.dice, v.modifier);
						if v.dmgtype and v.dmgtype ~= "" then
							sDmg = sDmg .. " " .. v.dmgtype;
						end
						table.insert(aName, "DMG: " .. sDmg);
					end
					rCurrent.clauses = nil;
					rCurrent.sName = table.concat(aName, "; ");
				else
					rCurrent = nil;
				end
			end

		elseif (i > 1) and StringManager.isWord(aWords[i], DataCommon.conditions) then
			local bValidCondition = false;
			local nConditionStart = i;
			local j = i - 1;
			
			while aWords[j] do
				if StringManager.isWord(aWords[j], "be") then
					if StringManager.isWord(aWords[j-1], "or") then
						bValidCondition = true;
						nConditionStart = j;
						break;
					end
				
				elseif StringManager.isWord(aWords[j], "also") then
				
				-- Special handling: Blindness/Deafness
				elseif StringManager.isWord(aWords[j], "or") and StringManager.isWord(aWords[j-1], DataCommon.conditions) and 
						StringManager.isWord(aWords[j-2], "either") and StringManager.isWord(aWords[j-3], "is") then
					bValidCondition = true;
					break;
					
				elseif StringManager.isWord(aWords[j], { "while", "when", "cannot", "not", "if", "be", "or" }) then
					bValidCondition = false;
					break;
				
				elseif StringManager.isWord(aWords[j], { "target", "creature", "it" }) then
					if StringManager.isWord(aWords[j-1], "the") then
						j = j - 1;
					end
					nConditionStart = j;
					
				elseif StringManager.isWord(aWords[j], "and") then
					if #effects == 0 then
						break;
					elseif effects[#effects].endindex ~= j - 1 then
						if not StringManager.isWord(aWords[i], "unconscious") and not StringManager.isWord(aWords[j-1], "minutes") then
							break;
						end
					end
					bValidCondition = true;
					nConditionStart = j;
					
				elseif StringManager.isWord(aWords[j], "is") then
					if bValidCondition or StringManager.isWord(aWords[i], "prone") or
							(StringManager.isWord(aWords[i], "invisible") and StringManager.isWord(aWords[j-1], {"wearing", "wears", "carrying", "carries"})) then
						break;
					end
					bValidCondition = true;
					nConditionStart = j;
				
				elseif StringManager.isWord(aWords[j], DataCommon.conditions) then
					break;

				elseif StringManager.isWord(aWords[i], "poisoned") then
					if (StringManager.isWord(aWords[j], "instead") and StringManager.isWord(aWords[j-1], "is")) then
						bValidCondition = true;
						nConditionStart = j - 1;
						break;
					elseif StringManager.isWord(aWords[j], "become") then
						bValidCondition = true;
						nConditionStart = j;
						break;
					end
				
				elseif StringManager.isWord(aWords[j], {"knock", "knocks", "knocked", "fall", "falls"}) and StringManager.isWord(aWords[i], "prone")  then
					bValidCondition = true;
					nConditionStart = j;
					
				elseif StringManager.isWord(aWords[j], {"knock", "knocks", "fall", "falls", "falling", "remain", "is"}) and StringManager.isWord(aWords[i], "unconscious") then
					if StringManager.isWord(aWords[j], "falling") and StringManager.isWord(aWords[j-1], "of") and StringManager.isWord(aWords[j-2], "instead") then
						break;
					end
					if StringManager.isWord(aWords[j], "fall") and StringManager.isWord(aWords[j-1], "you") and StringManager.isWord(aWords[j-1], "if") then
						break;
					end
					if StringManager.isWord(aWords[j], "falls") and StringManager.isWord(aWords[j-1], "or") then
						break;
					end
					bValidCondition = true;
					nConditionStart = j;
					if StringManager.isWord(aWords[j], "fall") and StringManager.isWord(aWords[j-1], "or") then
						break;
					end
					
				elseif StringManager.isWord(aWords[j], {"become", "becomes"}) and StringManager.isWord(aWords[i], "frightened")  then
					bValidCondition = true;
					nConditionStart = j;
					break;
					
				elseif StringManager.isWord(aWords[j], {"turns", "become", "becomes"}) 
						and StringManager.isWord(aWords[i], {"incorporeal", "invisible"}) then
					if StringManager.isWord(aWords[j-1], {"can't", "cannot"}) then
						break;
					end
					bValidCondition = true;
					nConditionStart = j;
				
				-- Special handling: Blindness/Deafness
				elseif StringManager.isWord(aWords[j], "either") and StringManager.isWord(aWords[j-1], "is") then
					bValidCondition = true;
					break;
				
				else
					break;
				end

				j = j - 1;
			end
			
			if bValidCondition then
				rCurrent = {};
				rCurrent.sName = StringManager.capitalize(aWords[i]);
				rCurrent.startindex = nConditionStart;
				rCurrent.endindex = i;
			end
		end
		
		if rCurrent then
			parseEffectsAdd(aWords, i, rCurrent, effects);
			rCurrent = nil;
		end
		
		i = i + 1;
	end

	if rCurrent then
		parseEffectsAdd(aWords, i - 1, rCurrent, effects);
	end
	
	-- Handle duration field in NPC spell translations
	i = 1;
	while aWords[i] do
		if StringManager.isWord(aWords[i], "duration") and StringManager.isWord(aWords[i+1], ":") then
			j = i + 2;
			local bConc = false;
			if StringManager.isWord(aWords[j], "concentration") and StringManager.isWord(aWords[j+1], "up") and StringManager.isWord(aWords[j+2], "to") then
				bConc = true;
				j = j + 3;
			end
			if StringManager.isNumberString(aWords[j]) and StringManager.isWord(aWords[j+1], {"round", "rounds", "minute", "minutes", "hour", "hours", "day", "days"}) then
				local nDuration = tonumber(aWords[j]) or 0;
				local sUnits = "";
				if StringManager.isWord(aWords[j+1], {"minute", "minutes"}) then
					sUnits = "minute";
				elseif StringManager.isWord(aWords[j+1], {"hour", "hours"}) then
					sUnits = "hour";
				elseif StringManager.isWord(aWords[j+1], {"day", "days"}) then
					sUnits = "day";
				end
				for _,vEffect in ipairs(effects) do
					if not vEffect.nDuration then
						vEffect.sName = vEffect.sName .. "; (C)";
						vEffect.nDuration = nDuration;
						vEffect.sUnits = sUnits;
					end
				end
			end
		end
		i = i + 1;
	end
	
	return effects;
end

function parseHelper(s, words, words_stats)
  	local final_words = {};
  	local final_words_stats = {};
  	
  	-- Separate words ending in periods, colons and semicolons
  	for i = 1, #words do
		local nSpecialChar = string.find(words[i], "[%.:;\n]");
		if nSpecialChar then
			local sWord = words[i];
			local nStartPos = words_stats[i].startpos;
			while nSpecialChar do
				if nSpecialChar > 1 then
					table.insert(final_words, string.sub(sWord, 1, nSpecialChar - 1));
					table.insert(final_words_stats, {startpos = nStartPos, endpos = nStartPos + nSpecialChar - 1});
				end
				
				table.insert(final_words, string.sub(sWord, nSpecialChar, nSpecialChar));
				table.insert(final_words_stats, {startpos = nStartPos + nSpecialChar - 1, endpos = nStartPos + nSpecialChar});
				
				nStartPos = nStartPos + nSpecialChar;
				sWord = string.sub(sWord, nSpecialChar + 1);
				
				nSpecialChar = string.find(sWord, "[%.:;\n]");
			end
			if string.len(sWord) > 0 then
				table.insert(final_words, sWord);
				table.insert(final_words_stats, {startpos = nStartPos, endpos = words_stats[i].endpos});
			end
		else
			table.insert(final_words, words[i]);
			table.insert(final_words_stats, words_stats[i]);
		end
  	end
  	
	return final_words, final_words_stats;
end

function consolidationHelper(aMasterAbilities, aWordStats, sAbilityType, aNewAbilities)
	-- Iterate through new abilities
	for i = 1, #aNewAbilities do

		-- Add type
		aNewAbilities[i].type = sAbilityType;

		-- Convert word indices to character positions
		aNewAbilities[i].startpos = aWordStats[aNewAbilities[i].startindex].startpos;
		aNewAbilities[i].endpos = aWordStats[aNewAbilities[i].endindex].endpos;
		aNewAbilities[i].startindex = nil;
		aNewAbilities[i].endindex = nil;

		-- Add to master abilities list
		table.insert(aMasterAbilities, aNewAbilities[i]);
	end
end

function parsePower(sPowerName, sPowerDesc, bPC)
	-- Get rid of some problem characters, and make lowercase
	local sLocal = string.gsub(sPowerDesc, "’", "'");
	sLocal = string.gsub(sLocal, "–", "-");
	sLocal = string.lower(sLocal);
	
	-- Parse the words
	local aWords, aWordStats = StringManager.parseWords(sLocal, ".:;\n");
	
	-- Add/separate markers for end of sentence, end of clause and clause label separators
	aWords, aWordStats = parseHelper(sPowerDesc, aWords, aWordStats);
	
	-- Build master list of all power abilities
	local aMasterAbilities = {};
	consolidationHelper(aMasterAbilities, aWordStats, "attack", parseAttacks(sPowerName, aWords));
	consolidationHelper(aMasterAbilities, aWordStats, "damage", parseDamages(sPowerName, aWords));
	consolidationHelper(aMasterAbilities, aWordStats, "heal", parseHeals(sPowerName, aWords));
	consolidationHelper(aMasterAbilities, aWordStats, "powersave", parseSaves(sPowerName, aWords, bPC));
	consolidationHelper(aMasterAbilities, aWordStats, "effect", parseEffects(sPowerName, aWords));
	
	-- Sort the abilities
	table.sort(aMasterAbilities, function(a,b) return a.startpos < b.startpos end)
	
	return aMasterAbilities;
end

function parseNPCPower(nodePower, bAllowSpellDataOverride)
	local sPowerName = DB.getValue(nodePower, "name", "");
	local sPowerDesc = DB.getValue(nodePower, "desc", "");
	
	if bAllowSpellDataOverride then
		local sPowerNameLower = StringManager.trim(sPowerName:lower());
		if sPowerNameLower:match(" - ") then
			sPowerNameLower = sPowerNameLower:gsub(" %- .*$", "");
		end
		if DataSpell.parsedata[sPowerNameLower] then
			local nAtk = nil;
			local nSave = nil;
			local aWords = StringManager.parseWords(sPowerDesc:gsub("’", "'"):gsub("–", "-"):lower(), ".:;\n");
			for i = 1, #aWords do
				if not nAtk and StringManager.isWord(aWords[i+1], "to") and StringManager.isWord(aWords[i+2], "hit") and StringManager.isNumberString(aWords[i]) then
					nAtk = tonumber(aWords[i]) or 0;
				elseif not nSave and StringManager.isWord(aWords[i], "DC") and StringManager.isNumberString(aWords[i+1]) then
					nSave = tonumber(aWords[i+1]) or 10;
				elseif nAtk and nSave then
					break;
				end
			end
			
			local aDataSpellCopy = UtilityManager.copyDeep(DataSpell.parsedata[sPowerNameLower]);
			for _,v in ipairs(aDataSpellCopy) do
				if v.type == "attack" then
					v.modifier = nAtk or 0;
				elseif v.type == "powersave" then
					v.savemod = nSave or 10;
				end
			end
			
			return aDataSpellCopy;
		end
	end
	
	return parsePower(sPowerName, sPowerDesc);
end

-- review this to add in casttime/spell level? -celestian
function parsePCPower(nodePower)
	-- CLean out old actions
	local nodeActions = nodePower.createChild("actions");
	for _,v in pairs(nodeActions.getChildren()) do
		v.delete();
	end
	
    
	-- Track whether cast action already created
	local nodeCastAction = nil;
	
	-- Get the power name
	local sPowerName = DB.getValue(nodePower, "name", "");
	local sPowerNameLower = StringManager.trim(sPowerName:lower());
	
	-- Pull the actions from the spell data table (if available)
	if DataSpell.parsedata[sPowerNameLower] then
		for _,vAction in ipairs(DataSpell.parsedata[sPowerNameLower]) do
			if vAction.type then
				if vAction.type == "attack" then
					if not nodeCastAction then
						nodeCastAction = DB.createChild(nodeActions);
						DB.setValue(nodeCastAction, "type", "string", "cast");
					end
					if nodeCastAction then
						if vAction.range == "R" then
							DB.setValue(nodeCastAction, "atktype", "string", "ranged");
						else
							DB.setValue(nodeCastAction, "atktype", "string", "melee");
						end
						
						if vAction.modifier then
							DB.setValue(nodeCastAction, "atkbase", "string", "fixed");
							DB.setValue(nodeCastAction, "atkmod", "number", tonumber(vAction.modifier) or 0);
						end
					end
				
				elseif vAction.type == "damage" then
					local nodeAction = DB.createChild(nodeActions);
					DB.setValue(nodeAction, "type", "string", "damage");
					
					local nodeDmgList = DB.createChild(nodeAction, "damagelist");
					for _,vDamage in ipairs(vAction.clauses) do
						local nodeEntry = DB.createChild(nodeDmgList);
						
						DB.setValue(nodeEntry, "dice", "dice", vDamage.dice);
						DB.setValue(nodeEntry, "bonus", "number", vDamage.bonus);
						if vDamage.stat then
							DB.setValue(nodeEntry, "stat", "string", vDamage.stat);
						end
						DB.setValue(nodeEntry, "type", "string", vDamage.type);
					end
				
				elseif vAction.type == "heal" then
					local nodeAction = DB.createChild(nodeActions);
					DB.setValue(nodeAction, "type", "string", "heal");
						
					if vAction.subtype == "temp" then
						DB.setValue(nodeAction, "healtype", "string", "temp");
					end
					if vAction.sTargeting then
						DB.setValue(nodeAction, "healtargeting", "string", vAction.sTargeting);
					end
					
					local nodeHealList = DB.createChild(nodeAction, "heallist");
					for _,vHeal in ipairs(vAction.clauses) do
						local nodeEntry = DB.createChild(nodeHealList);
						
						DB.setValue(nodeEntry, "dice", "dice", vHeal.dice);
						DB.setValue(nodeEntry, "bonus", "number", vHeal.bonus);
						if vHeal.stat then
							DB.setValue(nodeEntry, "stat", "string", vHeal.stat);
						end
					end

				elseif vAction.type == "save" then
					if not nodeCastAction then
						nodeCastAction = DB.createChild(nodeActions);
						DB.setValue(nodeCastAction, "type", "string", "cast");
					end
					if nodeCastAction then
						DB.setValue(nodeCastAction, "savetype", "string", vAction.save);
						
						if vAction.savemod then
							DB.setValue(nodeCastAction, "savedcbase", "string", "fixed");
							DB.setValue(nodeCastAction, "savedcmod", "number", tonumber(vAction.savemod) or 8);
						elseif vAction.savestat then
							DB.setValue(nodeCastAction, "savedcbase", "string", "ability");
							DB.setValue(nodeCastAction, "savedcstat", "string", vAction.savestat);
						end
						if vAction.onmissdamage == "half" then
							DB.setValue(nodeCastAction, "onmissdamage", "string", "half");
						end
					end
				
				elseif vAction.type == "effect" then
					local nodeAction = DB.createChild(nodeActions);
					DB.setValue(nodeAction, "type", "string", "effect");
					
					DB.setValue(nodeAction, "label", "string", vAction.sName);

					if vAction.sTargeting then
						DB.setValue(nodeAction, "targeting", "string", vAction.sTargeting);
					end
					if vAction.sApply then
						DB.setValue(nodeAction, "apply", "string", vAction.sApply);
					end
					
					local nDuration = tonumber(vAction.nDuration) or 0;
					if nDuration ~= 0 then
						DB.setValue(nodeAction, "durmod", "number", nDuration);
						DB.setValue(nodeAction, "durunit", "string", vAction.sUnits);
					end

				end
			end
		end
	-- Otherwise, parse the power description for actions
	else
		-- Get the power duration
		local nDuration = 0;
		local sDurationUnits = "";
		local bConcentration = false;
		local sPowerDuration = DB.getValue(nodePower, "duration", "");
		local aDurationWords = StringManager.parseWords(sPowerDuration:lower());
		
		local j = 1;
		if StringManager.isWord(aDurationWords[j], "concentration") and StringManager.isWord(aDurationWords[j+1], "up") and StringManager.isWord(aDurationWords[j+2], "to") then
			bConcentration = true;
			j = j + 3;
		end
		if StringManager.isNumberString(aDurationWords[j]) and StringManager.isWord(aDurationWords[j+1], {"round", "rounds", "minute", "minutes", "hour", "hours", "day", "days"}) then
			nDuration = tonumber(aDurationWords[j]) or 0;
			if StringManager.isWord(aDurationWords[j+1], {"minute", "minutes"}) then
				sDurationUnits = "minute";
			elseif StringManager.isWord(aDurationWords[j+1], {"hour", "hours"}) then
				sDurationUnits = "hour";
			elseif StringManager.isWord(aDurationWords[j+1], {"day", "days"}) then
				sDurationUnits = "day";
			end
		end
		
		-- Parse the description
		local sPowerDesc = DB.getValue(nodePower, "description", "");
		local aActions = parsePower(sPowerName, sPowerDesc, true);
		
		-- Translate parsed power records into entries in the PC Actions tab
		local bAttackFound = false;
		for _, v in pairs(aActions) do
			if v.type == "attack" then
				if not bAttackFound then
					bAttackFound = true;
					if not nodeCastAction then
						nodeCastAction = DB.createChild(nodeActions);
						DB.setValue(nodeCastAction, "type", "string", "cast");
					end
					if nodeCastAction then
						if v.range == "R" then
							DB.setValue(nodeCastAction, "atktype", "string", "ranged");
						else
							DB.setValue(nodeCastAction, "atktype", "string", "melee");
						end
						
						if v.spell then
							-- Use group attack mod
						else
							DB.setValue(nodeCastAction, "atkbase", "string", "fixed");
							DB.setValue(nodeCastAction, "atkmod", "number", v.modifier);
						end
					end
				end
			
			elseif v.type == "damage" then
				local nodeAction = DB.createChild(nodeActions);
				DB.setValue(nodeAction, "type", "string", "damage");
				
				local nodeDmgList = DB.createChild(nodeAction, "damagelist");
				for _,vDamage in ipairs(v.clauses) do
					local nodeEntry = DB.createChild(nodeDmgList);
					
					DB.setValue(nodeEntry, "dice", "dice", vDamage.dice);
					DB.setValue(nodeEntry, "bonus", "number", vDamage.modifier);
					if vDamage.stat then
						DB.setValue(nodeEntry, "stat", "string", vDamage.stat);
					end
					DB.setValue(nodeEntry, "type", "string", vDamage.dmgtype);
				end

			elseif v.type == "heal" then
				local nodeAction = DB.createChild(nodeActions);
				DB.setValue(nodeAction, "type", "string", "heal");
					
				if v.subtype == "temp" then
					DB.setValue(nodeAction, "healtype", "string", "temp");
				end
				if v.sTargeting then
					DB.setValue(nodeAction, "healtargeting", "string", v.sTargeting);
				end
				
				local nodeHealList = DB.createChild(nodeAction, "heallist");
				for _,vHeal in ipairs(v.clauses) do
					local nodeEntry = DB.createChild(nodeHealList);
					
					DB.setValue(nodeEntry, "dice", "dice", vHeal.dice);
					DB.setValue(nodeEntry, "bonus", "number", vHeal.modifier);
					if vHeal.stat then
						DB.setValue(nodeEntry, "stat", "string", vHeal.stat);
					end
				end

			elseif v.type == "powersave" then
				if not nodeCastAction then
					nodeCastAction = DB.createChild(nodeActions);
					DB.setValue(nodeCastAction, "type", "string", "cast");
				end
				if nodeCastAction then
					DB.setValue(nodeCastAction, "savetype", "string", v.save);
					if v.spell then
						-- Use group save DC
					elseif v.savestat then
						DB.setValue(nodeCastAction, "savedcbase", "string", "ability");
						DB.setValue(nodeCastAction, "savedcstat", "string", v.savestat);
					elseif v.savemod then
						DB.setValue(nodeCastAction, "savedcbase", "string", "fixed");
						DB.setValue(nodeCastAction, "savedcmod", "number", v.savemod);
					end
					if v.onmissdamage == "half" then
						DB.setValue(nodeCastAction, "onmissdamage", "string", "half");
					end
				end
				
			elseif v.type == "effect" then
				local nodeAction = DB.createChild(nodeActions);
				if nodeAction then
					DB.setValue(nodeAction, "type", "string", "effect");
					
					if v.sTargeting then
						DB.setValue(nodeAction, "targeting", "string", v.sTargeting);
					end
					if v.sApply then
						DB.setValue(nodeAction, "apply", "string", v.sApply);
					end
					
					local sEffect = v.sName;
					if v.nDuration and v.nDuration ~= 0 then
						DB.setValue(nodeAction, "durmod", "number", v.nDuration);
						DB.setValue(nodeAction, "durunit", "string", v.sUnits);
					elseif nDuration ~= 0 and sEffect ~= "Prone" then
						if bConcentration then
							sEffect = sEffect .. "; (C)";
						end
						DB.setValue(nodeAction, "durmod", "number", nDuration);
						DB.setValue(nodeAction, "durunit", "string", sDurationUnits);
					end
					DB.setValue(nodeAction, "label", "string", sEffect);
				end

			end
		end
	end
end

-- return true if the spell can be memorized.
function canMemorizeSpell(nodeSpell)
    local nLevel = DB.getValue(nodeSpell, "level", 0);
    local sSpellType = DB.getValue(nodeSpell, "type", ""):lower();
    local sNodePath = nodeSpell.getPath();
    
    local bCanMemorize = 
        (nLevel>0 and (isArcaneSpellType(sSpellType) or isDivineSpellType(sSpellType)))

    -- if this is coming from spell record then no, nothing will memorize
    if string.match(sNodePath,"^spell") then
            bCanMemorize = false;
    end
       
    return bCanMemorize;
end

-- commit a spell to memoriy --celestian
function memorizeSpell(draginfo, nodeSpell)
--Debug.console("manager_power.lua","memorizeSpell","nodeSpell",nodeSpell);
    local bSuccess = true;
	if not nodeSpell then
		return false;
	end
	local nodeChar = nodeSpell.getChild("...");
	if not nodeChar then
		return false;
	end

    
    local sName = DB.getValue(nodeSpell, "name", "");
    local nLevel = DB.getValue(nodeSpell, "level", 0);
    local sSpellType = DB.getValue(nodeSpell, "type", ""):lower();
    local sSource = DB.getValue(nodeSpell, "source", ""):lower();
    local sCastTime = DB.getValue(nodeSpell, "castingtime", "");
    local sDuration = DB.getValue(nodeSpell, "duration", "");
    local nMemorized = DB.getValue(nodeSpell, "memorized", 0);
    
    if (nLevel>0 and (isArcaneSpellType(sSpellType) or isArcaneSpellType(sSource) or isDivineSpellType(sSpellType) or isDivineSpellType(sSource)) ) then
        local nUsedArcane = DB.getValue(nodeChar, "powermeta.spellslots" .. nLevel .. ".used", 0);
        local nMaxArcane = DB.getValue(nodeChar, "powermeta.spellslots" .. nLevel .. ".max", 0);
        local nUsedDivine = DB.getValue(nodeChar, "powermeta.pactmagicslots" .. nLevel .. ".used", 0);
        local nMaxDivine = DB.getValue(nodeChar, "powermeta.pactmagicslots" .. nLevel .. ".max", 0);

        if (isArcaneSpellType(sSpellType) or isArcaneSpellType(sSource)) then
            if (nUsedArcane+1 <= nMaxArcane) then
                DB.setValue(nodeChar,"powermeta.spellslots" .. nLevel .. ".used","number",(nUsedArcane+1));
                DB.setValue(nodeSpell,"memorized","number",(nMemorized+1));
                ChatManager.Message(Interface.getString("message_youmemorize") .. " " .. sName .. ".", true, ActorManager.getActor("pc", nodeChar));
            else
                -- not enough slots left
                bSuccess = false;
                ChatManager.Message(Interface.getString("message_nomoreslots"), true, ActorManager.getActor("pc", nodeChar));
            end
        elseif (isDivineSpellType(sSpellType) or isDivineSpellType(sSource)) then
            if (nUsedDivine+1 <= nMaxDivine) then
                DB.setValue(nodeChar,"powermeta.pactmagicslots" .. nLevel .. ".used","number",(nUsedDivine+1));
                DB.setValue(nodeSpell,"memorized","number",(nMemorized+1));
                ChatManager.Message(Interface.getString("message_youmemorize") .. " " .. sName .. ".", true, ActorManager.getActor("pc", nodeChar));
            else
                -- not enough slots left
                bSuccess = false;
                ChatManager.Message(Interface.getString("message_nomoreslots"), true, ActorManager.getActor("pc", nodeChar));
            end
        end -- spelltype
    end -- nLevel > 0
    
    return bSuccess;
end

-- cast spell
function removeMemorizedSpell(draginfo, node)
	local nodeSpell = node.getChild("...");
    local bSuccess = true;
	if not nodeSpell then
		return;
	end
	local nodeChar = nodeSpell.getChild("...");
	if not nodeChar then
		return false;
	end
-- Debug.console("manager_power.lua","removeMemorizedSpell","node",node);
-- Debug.console("manager_power.lua","removeMemorizedSpell","nodeSpell",nodeSpell);
-- Debug.console("manager_power.lua","removeMemorizedSpell","nodeChar",nodeChar);

    local bisNPC = (not ActorManager.isPC(nodeChar));
    local sName = DB.getValue(nodeSpell, "name", "");
    local nLevel = DB.getValue(nodeSpell, "level", 0);
    local sSpellType = DB.getValue(nodeSpell, "type", ""):lower();
    local sSource = DB.getValue(nodeSpell, "source", ""):lower();
    local sCastTime = DB.getValue(nodeSpell, "castingtime", "");
    local sDuration = DB.getValue(nodeSpell, "duration", "");
    local nMemorized = DB.getValue(nodeSpell, "memorized", 0);

    -- this should let 5e spells work
    if (nLevel>0 and (isArcaneSpellType(sSpellType) or isArcaneSpellType(sSource) or isDivineSpellType(sSpellType) or isDivineSpellType(sSource)) ) then
        local nUsedArcane = DB.getValue(nodeChar, "powermeta.spellslots" .. nLevel .. ".used", 0);
        local nMaxArcane = DB.getValue(nodeChar, "powermeta.spellslots" .. nLevel .. ".max", 0);
        local nUsedDivine = DB.getValue(nodeChar, "powermeta.pactmagicslots" .. nLevel .. ".used", 0);
        local nMaxDivine = DB.getValue(nodeChar, "powermeta.pactmagicslots" .. nLevel .. ".max", 0);

        if (nMemorized > 0 or bisNPC) then
            if (nMemorized < 1) then -- sanity check, to make sure memorize never less than 0.
                nMemorized = 1;
            end
            DB.setValue(nodeSpell,"memorized","number",(nMemorized-1));
            if (isArcaneSpellType(sSpellType) or isArcaneSpellType(sSource)) then
                local nLeftOver = (nUsedArcane - 1);
                if nLeftOver < 0 then nLeftOver = 0; end
                DB.setValue(nodeChar,"powermeta.spellslots" .. nLevel .. ".used","number",nLeftOver);
            elseif (isDivineSpellType(sSpellType) or isDivineSpellType(sSource)) then
                local nLeftOver = (nUsedDivine - 1);
                if nLeftOver < 0 then nLeftOver = 0; end
                DB.setValue(nodeChar,"powermeta.pactmagicslots" .. nLevel .. ".used","number",nLeftOver);
            end
        else
            -- didnt have any more memorized copies of the spell to cast
            bSuccess = false;
   			ChatManager.Message(Interface.getString("message_notmemorized"), true, ActorManager.getActor("pc", nodeChar));
        end
    end

        return bSuccess;
end

-- return try if spelltype is valid arcane spell type, this is strictly because I also wanted
-- to also allow the 5e spells if someone happened to use them and 5e uses "source" not type
function isArcaneSpellType(sSpellType)


    local bValid = false;
    local aArcane = {};
        aArcane[1] = "arcane";
        aArcane[2] = "wizard";
    local nMaxArcane = 2;

    for i = 1, nMaxArcane do
        if string.find(sSpellType,aArcane[i]) then
            bValid = true;
            break;
        end
	end        
    return bValid
end
function isDivineSpellType(sSpellType)
    local bValid = false;
    local aDivine = {};
        aDivine[1] = "divine";
        aDivine[2] = "cleric";
        aDivine[3] = "bard";
        aDivine[4] = "druid";
        aDivine[5] = "paladin";
        aDivine[6] = "ranger";
    local nMaxDivine = 6;

    for i = 1, nMaxDivine do
        if string.find(sSpellType,aDivine[i]) then
            bValid = true;
            break;
        end
	end        
    return bValid
end
