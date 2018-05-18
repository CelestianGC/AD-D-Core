-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function getPercentWounded(rActor)
	local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);

	if sActorType == "pc" then
		return getPercentWounded2("pc", nodeActor);
	elseif sActorType == "ct" then
		return getPercentWounded2("ct", nodeActor);
	end
	
	return 0, "";
end

function getPercentWounded2(sNodeType, node)
	local nHP, nWounds, nDeathSaveFail;
	if sNodeType == "pc" then
		nHP = math.max(DB.getValue(node, "hp.total", 0), 0);
		nWounds = math.max(DB.getValue(node, "hp.wounds", 0), 0);
		nDeathSaveFail = DB.getValue(node, "hp.deathsavefail", 0);
	elseif sNodeType == "ct" then
		nHP = math.max(DB.getValue(node, "hptotal", 0), 0);
		nWounds = math.max(DB.getValue(node, "wounds", 0), 0);
		nDeathSaveFail = DB.getValue(node, "deathsavefail", 0);
	end
	
	local nPercentWounded = 0;
	if nHP > 0 then
		nPercentWounded = nWounds / nHP;
	end
	
	local sStatus;
    local nLeftOverHP = (nHP - nWounds);
	if nPercentWounded >= 1 then
        -- AD&D goes to -10 then dead
            if nLeftOverHP <= -10 then
                sStatus = "Dead";
            else
            -- if nDeathSaveFail >= 3 then
                -- sStatus = "Dead";
            -- else
            if EffectManager5E.hasEffect(rActor, "Stable") then
                sStatus = "Unconscious";
            else
                sStatus = "Dying";
            end
    --			if nDeathSaveFail > 0 then
    --				sStatus = sStatus .. " (" .. nDeathSaveFail .. ")";
            if nLeftOverHP < 1 then
                sStatus = sStatus .. " (" .. nLeftOverHP .. ")";
            end
		end
	elseif OptionsManager.isOption("WNDC", "detailed") then
		if nPercentWounded >= .75 then
			sStatus = "Critical";
		elseif nPercentWounded >= .5 then
			sStatus = "Heavy";
		elseif nPercentWounded >= .25 then
			sStatus = "Moderate";
		elseif nPercentWounded > 0 then
			sStatus = "Light";
		else
			sStatus = "Healthy";
		end
	else
		if nPercentWounded >= .5 then
			sStatus = "Heavy";
		elseif nPercentWounded > 0 then
			sStatus = "Wounded";
		else
			sStatus = "Healthy";
		end
	end
	
	return nPercentWounded, sStatus;
end

-- Based on the percent wounded, change the font color for the Wounds field
function getWoundColor(sNodeType, node)
	local nPercentWounded, sStatus = getPercentWounded2(sNodeType, node);
	
	local sColor = ColorManager.getHealthColor(nPercentWounded, false);

	return sColor, nPercentWounded, sStatus;
end

-- Based on the percent wounded, change the token health bar color
function getWoundBarColor(sNodeType, node)
	local nPercentWounded, sStatus = getPercentWounded2(sNodeType, node);
	
	local sColor = ColorManager.getTokenHealthColor(nPercentWounded, true);

	return sColor, nPercentWounded, sStatus;
end

function getAbilityEffectsBonus(rActor, sAbility, sType)
		local nBonus = 0;
		local sEffect = "";
		
	
	if not rActor or not sAbility then
	 return 0, 0;
	end
	
	local sAbilityEffect = DataCommon.ability_ltos[sAbility];
	-- if not sAbilityEffect then
		-- return 0, 0;
	-- end
	
	local nAbilityMod, nAbilityEffects = EffectManager5E.getEffectsBonus(rActor, sAbilityEffect, true);
	
	-- local nAbilityScore = getAbilityScore(rActor, sAbility);
	-- if nAbilityScore > 0 then
		-- local nAffectedScore = math.max(nAbilityScore + nAbilityMod, 0);
		
		-- local nCurrentBonus = math.floor((nAbilityScore - 10) / 2);
		-- local nAffectedBonus = math.floor((nAffectedScore - 10) / 2);
		
		-- nAbilityMod = nAffectedBonus - nCurrentBonus;
	-- else
		-- if nAbilityMod > 0 then
			-- nAbilityMod = math.floor(nAbilityMod / 2);
		-- else
			-- nAbilityMod = math.ceil(nAbilityMod / 2);
		-- end
	-- end

	-- return nAbilityMod, nAbilityEffects;
	-- if (sType) then
		-- nBonus = getAbilityBonus(rActor, sAbility, sType);
		-- sEffect = sAbility .. sType;
	-- end
	
	--Debug.console("manager_ctor2.lua","getAbilityEffectsBonus","nBonus", nBonus);
	--Debug.console("manager_ctor2.lua","getAbilityEffectsBonus","nAbilityEffects", nAbilityEffects);
	return nBonus, nAbilityEffects;
end

function getClassLevel(nodeActor, sValue)
	local sClassName = DataCommon.class_valuetoname[sValue];
	if not sClassName then
		return 0;
	end
	sClassName = sClassName:lower();
	
	for _, vNode in pairs(DB.getChildren(nodeActor, "classes")) do
		if DB.getValue(vNode, "name", ""):lower() == sClassName then
			return DB.getValue(vNode, "level", 0);
		end
	end
	
	return 0;
end

function getAbilityScore(rActor, sAbility)
	if not sAbility then
		return -1;
	end
	local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if not nodeActor then
		return -1;
	end
	
	local nStatScore = -1;
	
	local sShort = string.sub(string.lower(sAbility), 1, 3);
	if sShort == "lev" then
		nStatScore = DB.getValue(nodeActor, "level", 0);
	elseif sShort == "prf" then
		nStatScore = DB.getValue(nodeActor, "profbonus", 0);
	elseif sShort == "str" then
		nStatScore = DB.getValue(nodeActor, "abilities.strength.score", 0);
	elseif sShort == "dex" then
		nStatScore = DB.getValue(nodeActor, "abilities.dexterity.score", 0);
	elseif sShort == "con" then
		nStatScore = DB.getValue(nodeActor, "abilities.constitution.score", 0);
	elseif sShort == "int" then
		nStatScore = DB.getValue(nodeActor, "abilities.intelligence.score", 0);
	elseif sShort == "wis" then
		nStatScore = DB.getValue(nodeActor, "abilities.wisdom.score", 0);
	elseif sShort == "cha" then
		nStatScore = DB.getValue(nodeActor, "abilities.charisma.score", 0);
	elseif StringManager.contains(DataCommon.classes, sAbility) then
		nStatScore = getClassLevel(nodeActor, sAbility);
	end
	
	return nStatScore;
end

-- sAbility "strength, dexterity, constitution/etc"
-- sType "hitadj, damageadj, saveadj, defenseadj
function getAbilityBonus(rActor, sAbility, sType)
	local nAbilityAdj = 0;
	
	if sType then
	end

	if not sAbility then
		 return 0;
	end

	local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if not nodeActor then
		return 0;
	end

	local nStatScore = getAbilityScore(rActor, sAbility);
	if nStatScore < 0 then
		return 0;
	end

	if sType then
		if (sType == "hitadj") then
			local nHitAdj = DB.getValue(nodeActor, "abilities.".. sAbility .. ".hitadj", 0);
			nAbilityAdj = nHitAdj;
		elseif (sType == "damageadj") then
			local nDamageAdj = 0;
			if (sAbility == "strength") then
				nDamageAdj = DB.getValue(nodeActor, "abilities.".. sAbility .. ".dmgadj", 0);
			end
			nAbilityAdj = nDamageAdj;
		elseif (sType == "defenseadj") then
			local nDefAdj = DB.getValue(nodeActor, "abilities.".. sAbility .. ".defenseadj", 0);
			nAbilityAdj = nDefAdj;
		end
	end
	return nAbilityAdj;
end

function getSave(rActor, sSave)
	local bADV = false;
	local bDIS = false;
	local nValue = getAbilityBonus(rActor, sSave, "saveadj");
    local nValue = 0;
	local aAddText = {};
	
	local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if sActorType == "pc" then
		nValue = DB.getValue(nodeActor, "saves." .. sSave .. ".modifier", 0);
	else
    -- need to get save value for npcs someday 
		local sSaves = DB.getValue(nodeActor, "savingthrows", "");
		for _,v in ipairs(StringManager.split(sSaves, ",;\r", true)) do
			local sAbility, sSign, sMod = string.match(v, "(%w+)%s*([%+%-–]?)(%d+)");
			if sAbility then
				if DataCommon.ability_stol[sAbility:upper()] then
					sAbility = DataCommon.ability_stol[sAbility:upper()];
				elseif DataCommon.ability_ltos[sAbility:lower()] then
					sAbility = sAbility:lower();
				else
					sAbility = nil;
				end
				
				if sAbility == sSave then
					nValue = tonumber(sMod) or 0;
					if sSign == "-" or sSign == "–" then
						nValue = 0 - nValue;
					end
					break;
				end
			end
		end
	end
	
	return nValue, bADV, bDIS, table.concat(aAddText, " ");
end

function getCheck(rActor, sCheck, sSkill)
	local bADV = false;
	local bDIS = false;
	local nValue = getAbilityBonus(rActor, sCheck, "check");
	local aAddText = {};

    -- dont need this for AD&D.
    
	-- local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);
	-- if sActorType == "pc" then
		-- nValue = nValue + DB.getValue(nodeActor, "abilities." .. sCheck .. ".checkmodifier", 0);

		-- -- Check for armor non-proficiency
		-- if StringManager.contains({"strength", "dexterity"}, sCheck) then
			-- if DB.getValue(nodeActor, "defenses.ac.prof", 1) == 0 then
				-- table.insert(aAddText, Interface.getString("roll_msg_armor_nonprof"));
				-- bDIS = true;
			-- end
		-- end
		
		-- -- Check for armor stealth disadvantage
		-- if sSkill and sSkill:lower() == Interface.getString("skill_value_stealth"):lower() then
			-- if DB.getValue(nodeActor, "defenses.ac.disstealth", 0) == 1 then
				-- table.insert(aAddText, Interface.getString("roll_msg_armor_disstealth"));
				-- bDIS = true;
			-- end
		-- end
	-- end
	
	return nValue, bADV, bDIS, table.concat(aAddText, " ");
end

function getDefenseAdvantage(rAttacker, rDefender, aAttackFilter)
	if not rDefender then
		return false, false;
	end
	
	-- Check effects
	local bADV = false;
	local bDIS = false;
	local bProne = false;
	
	if ActorManager.hasCT(rDefender) then
		if EffectManager5E.hasEffect(rAttacker, "ADVATK", rDefender, true) then
			bADV = true;
		elseif #(EffectManager5E.getEffectsByType(rAttacker, "ADVATK", aAttackFilter, rDefender, true)) > 0 then
			bADV = true;
		end
		if EffectManager5E.hasEffect(rAttacker, "DISATK", rDefender, true) then
			bDIS = true;
		elseif #(EffectManager5E.getEffectsByType(rAttacker, "DISATK", aAttackFilter, rDefender, true)) > 0 then
			bDIS = true;
		end
		if EffectManager5E.hasEffect(rAttacker, "Invisible", rDefender, true) then
			bADV = true;
		end
		if EffectManager5E.hasEffect(rDefender, "GRANTADVATK", rAttacker) then
			bADV = true;
		elseif #(EffectManager5E.getEffectsByType(rDefender, "GRANTADVATK", aAttackFilter, rAttacker)) > 0 then
			bADV = true;
		end
		if EffectManager5E.hasEffect(rDefender, "GRANTDISATK", rAttacker) then
			bDIS = true;
		elseif #(EffectManager5E.getEffectsByType(rDefender, "GRANTDISATK", aAttackFilter, rAttacker)) > 0 then
			bDIS = true;
		end
		if EffectManager5E.hasEffect(rDefender, "Blinded", rAttacker) then
			bADV = true;
		end
		if EffectManager5E.hasEffect(rDefender, "Invisible", rAttacker) then
			bDIS = true;
		end
		if EffectManager5E.hasEffect(rDefender, "Paralyzed", rAttacker) then
			bADV = true;
		end
		if EffectManager5E.hasEffect(rDefender, "Prone", rAttacker) then
			bProne = true;
		end
		if EffectManager5E.hasEffect(rDefender, "Restrained", rAttacker) then
			bADV = true;
		end
		if EffectManager5E.hasEffect(rDefender, "Stunned", rAttacker) then
			bADV = true;
		end
		if EffectManager5E.hasEffect(rDefender, "Unconscious", rAttacker) then
			bADV = true;
			bProne = true;
		end
		if EffectManager5E.hasEffect(rDefender, "Dodge", rAttacker) and 
				not (EffectManager5E.hasEffect(rDefender, "Paralyzed", rAttacker) or
				EffectManager5E.hasEffect(rDefender, "Stunned", rAttacker) or
				EffectManager5E.hasEffect(rDefender, "Incapacitated", rAttacker) or
				EffectManager5E.hasEffect(rDefender, "Unconscious", rAttacker) or
				EffectManager5E.hasEffect(rDefender, "Grappled", rAttacker) or
				EffectManager5E.hasEffect(rDefender, "Restrained", rAttacker)) then
			bDIS = true;
		end
		
		if bProne then
			if StringManager.contains(aAttackFilter, "melee") then
				bADV = true;
			elseif StringManager.contains(aAttackFilter, "ranged") then
				bDIS = true;
			end
		end
	end
	-- if bProne then
		-- local nodeAttacker = ActorManager.getCTNode(rAttacker);
		-- local nodeDefender = ActorManager.getCTNode(rDefender);
		-- if nodeAttacker and nodeDefender then
			-- local tokenAttacker = CombatManager.getTokenFromCT(nodeAttacker);
			-- local tokenDefender = CombatManager.getTokenFromCT(nodeDefender);
			-- if tokenAttacker and tokenDefender then
				-- local nodeAttackerContainer = tokenAttacker.getContainerNode();
				-- local nodeDefenderContainer = tokenDefender.getContainerNode();
				-- if nodeAttackerContainer.getNodeName() == nodeDefenderContainer.getNodeName() then
					-- local nDU = GameSystem.getDistanceUnitsPerGrid();
					-- local nAttackerSpace = math.ceil(DB.getValue(nodeAttacker, "space", nDU) / nDU);
					-- local nDefenderSpace = math.ceil(DB.getValue(nodeDefender, "space", nDU) / nDU);
					-- local xAttacker, yAttacker = tokenAttacker.getPosition();
					-- local xDefender, yDefender = tokenDefender.getPosition();
					-- local nGrid = nodeAttackerContainer.getGridSize();
					
					-- local xDiff = math.abs(xAttacker - xDefender);
					-- local yDiff = math.abs(yAttacker - yDefender);
					-- local gx = math.floor(xDiff / nGrid);
					-- local gy = math.floor(yDiff / nGrid);
					
					-- local nSquares = 0;
					-- local nStraights = 0;
					-- if gx > gy then
						-- nSquares = nSquares + gy;
						-- nSquares = nSquares + gx - gy;
					-- else
						-- nSquares = nSquares + gx;
						-- nSquares = nSquares + gy - gx;
					-- end
					-- nSquares = nSquares - (nAttackerSpace / 2);
					-- nSquares = nSquares - (nDefenderSpace / 2);
					-- -- DEBUG - FINISH - Need to be able to get grid type and grid size from token container node
				-- end
			-- end
		-- end
	-- end

	return bADV, bDIS;
end

-- this is to convert decending AC (below MAC 10 stuff) to ascending AC
-- 20 - (-5) = 25, 20 - 5 = 15 and so on
function ascendingDefense(nDefense)
    if (nDefense < 10) then
      nDefense = (20 - nDefense);
    end
  return nDefense;
end

function getDefenseValue(rAttacker, rDefender, rRoll)
	local nDefense = 10;
  local bPsionic = false;
  
  if (rRoll) then -- need to get defense value from psionic power
    bPsionic = rRoll.bPsionic == "true";
    if (bPsionic) then
      nDefense = tonumber(rRoll.Psionic_MAC) or 10;
      nDefense = ascendingDefense(nDefense);
    end
  end

	if not rDefender and rRoll and bPsionic then -- no defender but psionic power target
    return nDefense, 0, 0, false, false;
	elseif not rDefender or not rRoll then
		return nil, 0, 0, false, false;
	end
	
	-- Base calculations
	local sAttack = rRoll.sDesc;
	
	local sAttackType = string.match(sAttack, "%[ATTACK.*%((%w+)%)%]");
	local bOpportunity = string.match(sAttack, "%[OPPORTUNITY%]");
	local nCover = tonumber(string.match(sAttack, "%[COVER %-(%d)%]")) or 0;

  -- Effects
  local nAttackEffectMod = 0;
  local nDefenseEffectMod = 0;
  local bADV = false;
  local bDIS = false;
  
	local sDefenseStat = "dexterity";

  local sDefenderType, nodeDefender = ActorManager.getTypeAndNode(rDefender);
  if not nodeDefender then
    return nil, 0, 0, false, false;
  end

  if bPsionic then -- calculate defenses for psionics
    if rRoll.Psionic_DisciplineType:match("attack") then -- mental attack
      nDefense = DB.getValue(nodeDefender,"combat.mac.score",10);
      -- need to get effects/adjustments for MAC/BMAC/etc.
      -- grab BAC value if exists in effects
      local nBonusMACBase, nBonusMACBaseEffects = EffectManager5E.getEffectsBonus(rDefender, "BMAC",true);
      if (nBonusMACBaseEffects > 0 and nBonusMACBase < nDefense) then
        nDefense = nBonusMACBase;
      end
      local nBonusMAC, nBonusMACEffects = EffectManager5E.getEffectsBonus(rDefender, "MAC",true);
      if (nBonusMACEffects > 0) then
        nDefense = nDefense + nBonusMAC;
      end
    else -- using a power with a MAC
      nDefense = tonumber(rRoll.Psionic_MAC) or 10;
    end
    nDefense = ascendingDefense(nDefense);

    -- if psionic attack, check psionic defenses
    if rRoll.Psionic_DisciplineType == "attack" then
      local nodeSpell = DB.findNode(rRoll.sSpellSource);
      if (nodeSpell) then
        local sSpellName = DB.getValue(nodeSpell,"name",""):lower();
        if sSpellName ~= "" then 
          nAttackEffectMod = getPsionicAttackVersusDefenseMode(rDefender,rAttacker,sSpellName,nAttackEffectMod);
        end
      end
    end

  else -- calculate defenses for melee/range attacks
    local nACTemp = 0;
    local nACBase = 10;
    local nACArmor = 0;
    local nACShield = 0;
    local nACMisc = 0;
    
  --Debug.console("manager_actor2.lua","getDefenseValue","rRoll.range",rRoll.range);  

    local bAttackRanged = (rRoll.range and rRoll.range == "R");
    local bAttackMelee = (rRoll.range and rRoll.range == "M");

    local nBaseRangeAC = 10;
    local nRangeACEffect = 0;
    local nRangeACMod = 0;
    local nRangeACModEffect = 0;

    local nBaseMeleeAC = 10;
    local nMeleeACEffect = 0;
    local nMeleeACMod = 0;
    local nMeleeACModEffect = 0;
    
    -- grab BAC value if exists in effects
    local nBonusACBase, nBonusACEffects = EffectManager5E.getEffectsBonus(rDefender, "BAC",true);

    if (bAttackMelee) then
      nBaseMeleeAC, nMeleeACEffect = EffectManager5E.getEffectsBonus(rDefender, "BMELEEAC",true);
      nMeleeACMod, nMeleeACModEffect = EffectManager5E.getEffectsBonus(rDefender, "MELEEAC",true);
    end
    
    if (bAttackRanged) then
      nBaseRangeAC, nRangeACEffect = EffectManager5E.getEffectsBonus(rDefender, "BRANGEAC",true);
      nRangeACMod, nRangeACModEffect = EffectManager5E.getEffectsBonus(rDefender, "RANGEAC",true);
    end
    
    -- if PC
    if sDefenderType == "pc" then
      local nodeDefender = DB.findNode(rDefender.sCreatureNode);
      -- new nDefense Calc
      -- nDefense = DB.getValue(nodeDefender, "defenses.ac.total", 10);

      -- we get dex down a ways for pc and npc
      --local nDexBonus = ActorManager2.getAbilityBonus(rDefender, "dexterity","defenseadj");
      nACTemp = DB.getValue(nodeDefender, "defenses.ac.temporary",0);
      nACBase = DB.getValue(nodeDefender, "defenses.ac.base",10);
      nACArmor = DB.getValue(nodeDefender, "defenses.ac.armor",0);
      nACShield = DB.getValue(nodeDefender, "defenses.ac.shield",0);
      nACMisc = DB.getValue(nodeDefender, "defenses.ac.misc",0);
      
  -- Debug.console("manager_actor2.lua","getDefenseValue","nACBase2",nACBase);
  -- Debug.console("manager_actor2.lua","getDefenseValue","nACTemp",nACTemp);
  -- Debug.console("manager_actor2.lua","getDefenseValue","nACArmor",nACArmor);
  -- Debug.console("manager_actor2.lua","getDefenseValue","nACShield",nACShield);
  -- Debug.console("manager_actor2.lua","getDefenseValue","nACMisc",nACMisc);
      --
  --		sDefenseStat = DB.getValue(nodeDefender, "ac.sources.ability", "");
      nDefense = nACBase;
    else
      -- ELSE NPC
      nDefense = DB.getValue(nodeDefender, "ac", 10);
    end

  -- Debug.console("manager_actor2.lua","getDefenseValue","nBonusACBase",nBonusACBase);
  -- Debug.console("manager_actor2.lua","getDefenseValue","nBaseMeleeAC",nBaseMeleeAC);
  -- Debug.console("manager_actor2.lua","getDefenseValue","nBaseRangeAC",nBaseRangeAC);
  -- Debug.console("manager_actor2.lua","getDefenseValue","nMeleeACMod",nMeleeACMod);
  -- Debug.console("manager_actor2.lua","getDefenseValue","nRangeACMod",nRangeACMod);

    -- use BAC style effects if exist
    if nBonusACEffects > 0 then
      if nBonusACBase < nDefense then
        nDefense = nBonusACBase;
      end
    end
    if (bAttackMelee and nMeleeACEffect > 0) then
      if (nBaseMeleeAC < nDefense) then
        nDefense = nBaseMeleeAC;
      end
    end
    if (bAttackRanged and nRangeACEffect > 0) then
      if (nBaseRangeAC < nDefense) then
        nDefense = nBaseRangeAC;
      end
    end
    if (bAttackMelee and nMeleeACModEffect > 0) then
      nACTemp = nACTemp + (nACTemp - nMeleeACMod); -- (minus the mod, +3 is good, so we reduce AC by 3, -3 would be worse)
    end
    if (bAttackRanged and nRangeACModEffect > 0) then
      nACTemp = nACTemp + (nACTemp - nRangeACMod); -- (minus the mod, +3 is good, so we reduce AC by 3, -3 would be worse)
    end
    -- 
    
    if sDefenderType == "pc" then
      nDefense = nDefense + nACTemp + nACArmor + nACShield + nACMisc;
    else -- npc
      nDefense = nDefense + nACTemp; -- nACTemp are "modifiders"
    end
    
  --Debug.console("manager_actor2.lua","getDefenseValue","nDefense",nDefense);
    
    nDefenseStatMod = getAbilityBonus(rDefender, sDefenseStat, "defenseadj");
    nDefense = nDefense + nDefenseStatMod;
      
    -- Debug.console("manager_actor2.lua","getDefenseValue","nDefense",nDefense);
    -- Debug.console("manager_actor2.lua","getDefenseValue","nDefenseStatMod",nDefenseStatMod);
    
    nDefense = ascendingDefense(nDefense);
    
    if ActorManager.hasCT(rDefender) then
      local nBonusAC = 0;
      local nBonusStat = 0;
      local nBonusSituational = 0;
      
      local aAttackFilter = {};
      if sAttackType == "M" then
        table.insert(aAttackFilter, "melee");
      elseif sAttackType == "R" then
        table.insert(aAttackFilter, "ranged");
      end
      if bOpportunity then
        table.insert(aAttackFilter, "opportunity");
      end

      local aBonusTargetedAttackDice, nBonusTargetedAttack = EffectManager5E.getEffectsBonus(rAttacker, "ATK", false, aAttackFilter, rDefender, true);
      nAttackEffectMod = nAttackEffectMod + StringManager.evalDice(aBonusTargetedAttackDice, nBonusTargetedAttack);
            
      local aACEffects, nACEffectCount = EffectManager5E.getEffectsBonusByType(rDefender, {"AC"}, true, aAttackFilter, rAttacker);
      for _,v in pairs(aACEffects) do
        nBonusAC = nBonusAC + v.mod;
      end
      
      nBonusStat = getAbilityEffectsBonus(rDefender, sDefenseStat);
      
      local bProne = false;
      if EffectManager5E.hasEffect(rAttacker, "ADVATK", rDefender, true) then
        bADV = true;
      end
      if EffectManager5E.hasEffect(rAttacker, "DISATK", rDefender, true) then
        bDIS = true;
      end
      if EffectManager5E.hasEffect(rAttacker, "Invisible", rDefender, true) then
        bADV = true;
      end
      if EffectManager5E.hasEffect(rDefender, "GRANTADVATK", rAtracker) then
        bADV = true;
      end
      if EffectManager5E.hasEffect(rDefender, "GRANTDISATK", rAtracker) then
        bDIS = true;
      end
      if EffectManager5E.hasEffect(rDefender, "Invisible", rAttacker) then
        bDIS = true;
      end
      if EffectManager5E.hasEffect(rDefender, "Paralyzed", rAttacker) then
        bADV = true;
      end
      if EffectManager5E.hasEffect(rDefender, "Prone", rAttacker) then
        bProne = true;
      end
      if EffectManager5E.hasEffect(rDefender, "Restrained", rAttacker) then
        bADV = true;
      end
      if EffectManager5E.hasEffect(rDefender, "Stunned", rAttacker) then
        bADV = true;
      end
      if EffectManager5E.hasEffect(rDefender, "Unconscious", rAttacker) then
        bADV = true;
        bProne = true;
      end
      
    if bProne then
        if sAttackType == "M" then
          bADV = true;
        elseif sAttackType == "R" then
          bDIS = true;
        end
      end
      
      if nCover < 5 then
        local aCover = EffectManager5E.getEffectsByType(rDefender, "SCOVER", aAttackFilter, rAttacker);
        if #aCover > 0 or EffectManager5E.hasEffect(rDefender, "SCOVER", rAttacker) then
          nBonusSituational = nBonusSituational + 5 - nCover;
        elseif nCover < 2 then
          aCover = EffectManager5E.getEffectsByType(rDefender, "COVER", aAttackFilter, rAttacker);
          if #aCover > 0 or EffectManager5E.hasEffect(rDefender, "COVER", rAttacker) then
            nBonusSituational = nBonusSituational + 2 - nCover;
          end
        end
      end
      
      nDefenseEffectMod = nBonusAC + nBonusStat + nBonusSituational;
    end
    
  end -- end if bPsionic
	
	-- Results
	return nDefense, nAttackEffectMod, nDefenseEffectMod, bADV, bDIS;
end

function isAlignment(rActor, sAlignCheck)
	local nCheckLawChaosAxis = 0;
	local nCheckGoodEvilAxis = 0;
	local aCheckSplit = StringManager.split(sAlignCheck:lower(), " ", true);
	for _,v in ipairs(aCheckSplit) do
		if nCheckLawChaosAxis == 0 and DataCommon.alignment_lawchaos[v] then
			nCheckLawChaosAxis = DataCommon.alignment_lawchaos[v];
		end
		if nCheckGoodEvilAxis == 0 and DataCommon.alignment_goodevil[v] then
			nCheckGoodEvilAxis = DataCommon.alignment_goodevil[v];
		end
	end
	if nCheckLawChaosAxis == 0 and nCheckGoodEvilAxis == 0 then
		return false;
	end
	
	local nActorLawChaosAxis = 2;
	local nActorGoodEvilAxis = 2;
	local sType, nodeActor = ActorManager.getTypeAndNode(rActor);
	local sField = "alignment";
	local aActorSplit = StringManager.split(DB.getValue(nodeActor, sField, ""):lower(), " ", true);
	for _,v in ipairs(aActorSplit) do
		if nActorLawChaosAxis == 2 and DataCommon.alignment_lawchaos[v] then
			nActorLawChaosAxis = DataCommon.alignment_lawchaos[v];
		end
		if nActorGoodEvilAxis == 2 and DataCommon.alignment_goodevil[v] then
			nActorGoodEvilAxis = DataCommon.alignment_goodevil[v];
		end
	end
	
	local bLCReturn = true;
	if nCheckLawChaosAxis > 0 then
		if nActorLawChaosAxis > 0 then
			bLCReturn = (nActorLawChaosAxis == nCheckLawChaosAxis);
		else
			bLCReturn = false;
		end
	end
	
	local bGEReturn = true;
	if nCheckGoodEvilAxis > 0 then
		if nActorGoodEvilAxis > 0 then
			bGEReturn = (nActorGoodEvilAxis == nCheckGoodEvilAxis);
		else
			bGEReturn = false;
		end
	end
	
	return (bLCReturn and bGEReturn);
end

function isSize(rActor, sSizeCheck)
	local sSizeCheckLower = StringManager.trim(sSizeCheck:lower());

	local sCheckOp = sSizeCheckLower:match("^[<>]?=?");
	if sCheckOp then
		sSizeCheckLower = StringManager.trim(sSizeCheckLower:sub(#sCheckOp + 1));
	end
	
	local nCheckSize = 0;
	if DataCommon.creaturesize[sSizeCheckLower] then
		nCheckSize = DataCommon.creaturesize[sSizeCheckLower];
	end
	if nCheckSize == 0 then
		return false;
	end
	
	local nActorSize = 0;
	local sType, nodeActor = ActorManager.getTypeAndNode(rActor);
	local sField = "size";
	local aActorSplit = StringManager.split(DB.getValue(nodeActor, sField, ""):lower(), " ", true);
	for _,v in ipairs(aActorSplit) do
		if nActorSize == 0 and DataCommon.creaturesize[v] then
			nActorSize = DataCommon.creaturesize[v];
			break;
		end
	end
	if nActorSize == 0 then
		nActorSize = 3;
	end
	
	local bReturn = true;
	if sCheckOp then
		if sCheckOp == "<" then
			bReturn = (nActorSize < nCheckSize);
		elseif sCheckOp == ">" then
			bReturn = (nActorSize > nCheckSize);
		elseif sCheckOp == "<=" then
			bReturn = (nActorSize <= nCheckSize);
		elseif sCheckOp == ">=" then
			bReturn = (nActorSize >= nCheckSize);
		else
			bReturn = (nActorSize == nCheckSize);
		end
	else
		bReturn = (nActorSize == nCheckSize);
	end
	
	return bReturn;
end

function getCreatureTypeHelper(sTypeCheck, bUseDefaultType)
	local aCheckSplit = StringManager.split(sTypeCheck:lower(), ", %(%)", true);
	
	local aTypeCheck = {};
	local aSubTypeCheck = {};
	
	-- Handle half races
	local nHalfRace = 0;
	for k = 1, #aCheckSplit do
		if aCheckSplit[k]:sub(1, #DataCommon.creaturehalftype) == DataCommon.creaturehalftype then
			aCheckSplit[k] = aCheckSplit[k]:sub(#DataCommon.creaturehalftype + 1);
			nHalfRace = nHalfRace + 1;
		end
	end
	if nHalfRace == 1 then
		if not StringManager.contains (aCheckSplit, DataCommon.creaturehalftypesubrace) then
			table.insert(aCheckSplit, DataCommon.creaturehalftypesubrace);
		end
	end
	
	-- Check each word combo in the creature type string against standard creature types and subtypes
	for k = 1, #aCheckSplit do
		for _,sMainType in ipairs(DataCommon.creaturetype) do
			local aMainTypeSplit = StringManager.split(sMainType, " ", true);
			if #aMainTypeSplit > 0 then
				local bMatch = true;
				for i = 1, #aMainTypeSplit do
					if aMainTypeSplit[i] ~= aCheckSplit[k - 1 + i] then
						bMatch = false;
						break;
					end
				end
				if bMatch then
					table.insert(aTypeCheck, sMainType);
					k = k + (#aMainTypeSplit - 1);
				end
			end
		end
		for _,sSubType in ipairs(DataCommon.creaturesubtype) do
			local aSubTypeSplit = StringManager.split(sSubType, " ", true);
			if #aSubTypeSplit > 0 then
				local bMatch = true;
				for i = 1, #aSubTypeSplit do
					if aSubTypeSplit[i] ~= aCheckSplit[k - 1 + i] then
						bMatch = false;
						break;
					end
				end
				if bMatch then
					table.insert(aSubTypeCheck, sSubType);
					k = k + (#aSubTypeSplit - 1);
				end
			end
		end
	end
	
	-- Make sure we have a default creature type (if requested)
	if bUseDefaultType then
		if #aTypeCheck == 0 then
			table.insert(aTypeCheck, DataCommon.creaturedefaulttype);
		end
	end
	
	-- Combine into a single list
	for _,vSubType in ipairs(aSubTypeCheck) do
		table.insert(aTypeCheck, vSubType);
	end
	
	return aTypeCheck;
end

function isCreatureType(rActor, sTypeCheck)
	local aTypeCheck = getCreatureTypeHelper(sTypeCheck, false);
	if #aTypeCheck == 0 then
		return false;
	end
	
	local sType, nodeActor = ActorManager.getTypeAndNode(rActor);
	local sField = "race";
	if sType ~= "pc" then
		sField = "type";
	end
	local aTypeActor = getCreatureTypeHelper(DB.getValue(nodeActor, sField, ""), true);

	local bReturn = false;
	for kCheck,vCheck in ipairs(aTypeCheck) do
		if StringManager.contains(aTypeActor, vCheck) then
			bReturn = true;
			break;
		end
	end
	return bReturn;
end

--- psionic nonsense
function getPercentWoundedPSP(rActor)
	local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);

	if sActorType == "pc" then
		return getPercentWounded2PSP("pc", nodeActor);
	elseif sActorType == "ct" then
		return getPercentWounded2PSP("ct", nodeActor);
	end
	
	return 0, "";
end

function getPercentWounded2PSP(sNodeType, node)
	local nHP, nWounds;
  nHP = DB.getValue(nodeTarget, "combat.psp.score", 0);
  nWounds = DB.getValue(nodeTarget, "combat.psp.expended", 0);
  
	local nPercentWounded = 0;
	if nHP > 0 then
		nPercentWounded = nWounds / nHP;
	end
	
	local sStatus;
    local nLeftOverHP = (nHP - nWounds);
	if nPercentWounded >= 1 then
    if nLeftOverHP <= 0 then
          sStatus = "Opened";
    else
      if not EffectManager5E.hasEffect(rActor, "OpenedMind") then
          sStatus = "OpenedMind";
      end
      if nLeftOverHP < 1 then
          sStatus = sStatus .. " (" .. nLeftOverHP .. ")";
      end
		end
	elseif OptionsManager.isOption("WNDC", "detailed") then
		if nPercentWounded >= .75 then
			sStatus = "Critical";
		elseif nPercentWounded >= .5 then
			sStatus = "Heavy";
		elseif nPercentWounded >= .25 then
			sStatus = "Moderate";
		elseif nPercentWounded > 0 then
			sStatus = "Light";
		else
			sStatus = "Healthy";
		end
	else
		if nPercentWounded >= .5 then
			sStatus = "Heavy";
		elseif nPercentWounded > 0 then
			sStatus = "Wounded";
		else
			sStatus = "Healthy";
		end
	end
	
	return nPercentWounded, sStatus;
end

-- get a attack modifier value with an attack type versus a defense type
function getPsionicAttackVersusDefenseMode(rDefender,rAttacker,sSpellName,nAttackEffectMod)
  local nAttackMod = nAttackEffectMod;
  local nAtkIndex = getPsionicAttackIndex(sSpellName);
  local nDefIndex = getPsionicDefenseIndex(rDefender,rAttacker);
  if (nAtkIndex > 0 and nDefIndex > 0) then
    -- get the modifier for the attack type versus index using psionic_attack_v_defense_table
    local nAdjustment = DataCommonADND.psionic_attack_v_defense_table[nAtkIndex][nDefIndex];
    nAttackMod = nAttackMod + nAdjustment;
  end
  return nAttackMod;
end
--get the psionic attack index # of this attack name
function getPsionicAttackIndex(sName)
  local nIndex = 0;
  for sValue,index in pairs(DataCommonADND.psionic_attack_index) do
    if (sValue == sName) then
      nIndex = index;
      break;
    end
  end

  return nIndex;
end
--flip through all of the psionic defenses and find (first) one that is
--exists in the defense psionic_defense_index and return it's index. 
function getPsionicDefenseIndex(rDefender,rAttacker)
  local nIndex = 0;
  for sValue,index in pairs(DataCommonADND.psionic_defense_index) do
    if EffectManager5E.hasEffect(rDefender, sValue, rAttacker) then
      nIndex = index;
      break;
    end
  end

  return nIndex;
end