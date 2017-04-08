-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

RACE_DWARF = "dwarf";
RACE_DUERGAR = "duergar";

CLASS_BARBARIAN = "barbarian";
CLASS_MONK = "monk";
CLASS_SORCERER = "sorcerer";

TRAIT_DWARVEN_TOUGHNESS = "dwarven toughness";
TRAIT_POWERFUL_BUILD = "powerful build";
TRAIT_NATURAL_ARMOR = "natural armor";
TRAIT_CATS_CLAWS = "cat's claws";

FEATURE_UNARMORED_DEFENSE = "unarmored defense";
FEATURE_DRACONIC_RESILIENCE = "draconic resilience";
FEATURE_PACT_MAGIC = "pact magic";
FEATURE_SPELLCASTING = "spellcasting";

FEAT_TOUGH = "tough";

function onInit()
	ItemManager.setCustomCharAdd(onCharItemAdd);
	ItemManager.setCustomCharRemove(onCharItemDelete);
	initWeaponIDTracking();
end

--
-- CLASS MANAGEMENT
--

function sortClasses(a,b)
	return DB.getValue(a, "name", "") < DB.getValue(b, "name", "");
end

function getClassLevelSummary(nodeChar, bShort)
	if not nodeChar then
		return "";
	end
	
	local aClasses = {};

	local aSorted = {};
	for _,nodeChild in pairs(DB.getChildren(nodeChar, "classes")) do
		table.insert(aSorted, nodeChild);
	end
	table.sort(aSorted, sortClasses);
			
	for _,nodeChild in pairs(aSorted) do
		local sClass = DB.getValue(nodeChild, "name", "");
		local nLevel = DB.getValue(nodeChild, "level", 0);
		if nLevel > 0 then
			if bShort then
				sClass = sClass:sub(1,3);
			end
			table.insert(aClasses, sClass .. " " .. math.floor(nLevel*100)*0.01);
		end
	end

	local sSummary = table.concat(aClasses, " / ");
	return sSummary;
end

function getClassHDUsage(nodeChar)
	local nHD = 0;
	local nHDUsed = 0;
	
	for _,nodeChild in pairs(DB.getChildren(nodeChar, "classes")) do
		local nLevel = DB.getValue(nodeChild, "level", 0);
		local nHDMult = #(DB.getValue(nodeChild, "hddie", {}));
		nHD = nHD + (nLevel * nHDMult);
		nHDUsed = nHDUsed + DB.getValue(nodeChild, "hdused", 0);
	end
	
	return nHDUsed, nHD;
end

--
-- ITEM/FOCUS MANAGEMENT
--

function onCharItemAdd(nodeItem)
	local sTypeLower = StringManager.trim(DB.getValue(DB.getPath(nodeItem, "type"), ""):lower());
	if StringManager.contains({"mounts and other animals", "waterborne vehicles", "tack, harness, and drawn vehicles" }, sTypeLower) then
		DB.setValue(nodeItem, "carried", "number", 0);
	else
		DB.setValue(nodeItem, "carried", "number", 1);
	end
	
	addToArmorDB(nodeItem);
	addToWeaponDB(nodeItem);
end

function onCharItemDelete(nodeItem)
	removeFromArmorDB(nodeItem);
	removeFromWeaponDB(nodeItem);
end

function updateEncumbrance(nodeChar)
	local nEncTotal = 0;

	local nCount, nWeight;
	for _,vNode in pairs(DB.getChildren(nodeChar, "inventorylist")) do
		if DB.getValue(vNode, "carried", 0) ~= 0 then
			nCount = DB.getValue(vNode, "count", 0);
			if nCount < 1 then
				nCount = 1;
			end
			nWeight = DB.getValue(vNode, "weight", 0);
			
			nEncTotal = nEncTotal + (nCount * nWeight);
		end
	end

	DB.setValue(nodeChar, "encumbrance.load", "number", nEncTotal);
end

function getEncumbranceMult(nodeChar)
	local sSize = StringManager.trim(DB.getValue(nodeChar, "size", ""):lower());
	
	local nSize = 2; -- Medium
	if sSize == "tiny" then
		nSize = 0;
	elseif sSize == "small" then
		nSize = 1;
	elseif sSize == "large" then
		nSize = 3;
	elseif sSize == "huge" then
		nSize = 4;
	elseif sSize == "gargantuan" then
		nSize = 5;
	end
	if hasTrait(nodeChar, TRAIT_POWERFUL_BUILD) then
		nSize = nSize + 1;
	end
	
	local nMult = 1; -- Both Small and Medium use a multiplier of 1
	if nSize == 0 then
		nMult = 0.5;
	elseif nSize == 3 then
		nMult = 2;
	elseif nSize == 4 then
		nMult = 4;
	elseif nSize == 5 then
		nMult = 8;
	elseif nSize == 6 then
		nMult = 16;
	end
	
	return nMult;
end

--
-- ARMOR MANAGEMENT
-- 

function removeFromArmorDB(nodeItem)
	-- Parameter validation
	if not ItemManager2.isArmor(nodeItem) then
		return;
	end
	
	-- If this armor was worn, recalculate AC
	if DB.getValue(nodeItem, "carried", 0) == 2 then
		DB.setValue(nodeItem, "carried", "number", 1);
	end
end

function addToArmorDB(nodeItem)
	-- Parameter validation
	local bIsArmor, _, sSubtypeLower = ItemManager2.isArmor(nodeItem);
	if not bIsArmor then
		return;
	end
	local bIsShield = (sSubtypeLower == "shield");
	
	-- Determine whether to auto-equip armor
	local bArmorAllowed = true;
	local bShieldAllowed = true;
	local nodeChar = nodeItem.getChild("...");
	if hasFeature(nodeChar, FEATURE_UNARMORED_DEFENSE) then
		bArmorAllowed = false;
		
		for _,v in pairs(nodeList.getChildren()) do
			local sClassName = StringManager.trim(DB.getValue(v, "name", "")):lower();
			if (sClassName == CLASS_BARBARIAN) then
				break;
			elseif (sClassName == CLASS_MONK) then
				bShieldAllowed = false;
				break;
			end
		end
	end
	if hasTrait(nodeChar, TRAIT_NATURAL_ARMOR) then
		bArmorAllowed = false;
		bShieldAllowed = false;
	end
	if (bArmorAllowed and not bIsShield) or (bShieldAllowed and bIsShield) then
		local bArmorEquipped = false;
		local bShieldEquipped = false;
		for _,v in pairs(DB.getChildren(nodeItem, "..")) do
			if DB.getValue(v, "carried", 0) == 2 then
				local bIsItemArmor, _, sItemSubtypeLower = ItemManager2.isArmor(v);
				if bIsItemArmor then
					if (sItemSubtypeLower == "shield") then
						bShieldEquipped = true;
					else
						bArmorEquipped = true;
					end
				end
			end
		end
		if bShieldAllowed and bIsShield and not bShieldEquipped then
			DB.setValue(nodeItem, "carried", "number", 2);
		elseif bArmorAllowed and not bIsShield and not bArmorEquipped then
			DB.setValue(nodeItem, "carried", "number", 2);
		end
	end
end

-- calculate armor class and set? -msw
function calcItemArmorClass(nodeChar)
	local nMainArmorBase = 10;
	local nMainArmorTotal = 0;
	local nMainShieldTotal = 0;
	local sMainDexBonus = "";
	local nMainStealthDis = 0;
	local nMainStrRequired = 0;

	for _,vNode in pairs(DB.getChildren(nodeChar, "inventorylist")) do
		if DB.getValue(vNode, "carried", 0) == 2 then
			local bIsArmor, _, sSubtypeLower = ItemManager2.isArmor(vNode);
			if bIsArmor then
                -- no clue what bID is for yet -msw, need to look at getIDState
				local bID = LibraryData.getIDState("item", vNode, true);
				
                -- we only want the "bonus" value for ring/cloaks/robes
				local bIsRingOrCloak = (sSubtypeLower == "ring" or sSubtypeLower == "cloak" or sSubtypeLower == "robe");
                
				local bIsShield = (sSubtypeLower == "shield");

				if bIsShield then
					if bID then
						nMainShieldTotal = nMainShieldTotal + (DB.getValue(vNode, "ac", 0)) + (DB.getValue(vNode, "bonus", 0));
					else
						nMainShieldTotal = nMainShieldTotal + (DB.getValue(vNode, "ac", 0)) + (DB.getValue(vNode, "bonus", 0));
--						nMainShieldTotal = nMainShieldTotal - DB.getValue(vNode, "ac", 0);
					end
				elseif bIsRingOrCloak then 
					if bID then
						nMainShieldTotal = nMainShieldTotal + DB.getValue(vNode, "bonus", 0);
					else
						nMainShieldTotal = nMainShieldTotal + DB.getValue(vNode, "bonus", 0);
--						nMainShieldTotal = nMainShieldTotal - DB.getValue(vNode, "ac", 0);
					end
				else
--					if bID then
--						nMainArmorTotal = nMainArmorTotal + (DB.getValue(vNode, "ac", 0) - 10) + DB.getValue(vNode, "bonus", 0);
--					else
--						nMainArmorTotal = nMainArmorTotal + (DB.getValue(vNode, "ac", 0) - 10);
--					end
					if bID then
						nMainArmorBase = DB.getValue(vNode, "ac", 0);
					else
						nMainArmorBase = DB.getValue(vNode, "ac", 0);
					end
                    -- convert bonus from +bonus to -bonus to adjust AC down for decending AC
					if bID then
						nMainArmorTotal = nMainArmorTotal -(DB.getValue(vNode, "bonus", 0));
					else
						nMainArmorTotal = nMainArmorTotal -(DB.getValue(vNode, "bonus", 0));
					end
					
					-- local sItemDexBonus = DB.getValue(vNode, "dexbonus", ""):lower();
					-- if sItemDexBonus:match("yes") then
						-- local nMaxBonus = tonumber(sItemDexBonus:match("max (%d)")) or 0;
						-- if nMaxBonus == 2 then
							-- if sMainDexBonus == "" or sMainDexBonus == "max3" then
								-- sMainDexBonus = "max2";
							-- end
						-- elseif nMaxBonus == 3 then
							-- if sMainDexBonus == "" then
								-- sMainDexBonus = "max3";
							-- end
						-- end
					-- else
						-- sMainDexBonus = "no";
					-- end
					
					-- local sItemStealth = DB.getValue(vNode, "stealth", ""):lower();
					-- if sItemStealth == "disadvantage" then
						-- nMainStealthDis = 1;
					-- end
					
					-- local sItemStrength = StringManager.trim(DB.getValue(vNode, "strength", "")):lower();
					-- local nItemStrRequired = tonumber(sItemStrength:match("str (%d+)")) or 0;
					-- if nItemStrRequired > 0 then
						-- nMainStrRequired = math.max(nMainStrRequired, nItemStrRequired);
					-- end
				end
			end
		end
	end
	
	if (nMainArmorTotal == 0) and (nMainShieldTotal == 0) and hasTrait(nodeChar, TRAIT_NATURAL_ARMOR) then
		nMainArmorTotal = 3;
	end
    -- flip value for decending ac in nMainShieldTotal -msw
    nMainShieldTotal = -(nMainShieldTotal);
    
	DB.setValue(nodeChar, "defenses.ac.base", "number", nMainArmorBase);
	DB.setValue(nodeChar, "defenses.ac.armor", "number", nMainArmorTotal);
	DB.setValue(nodeChar, "defenses.ac.shield", "number", nMainShieldTotal);
    --steal/dex not used here
	DB.setValue(nodeChar, "defenses.ac.dexbonus", "string", sMainDexBonus);
	DB.setValue(nodeChar, "defenses.ac.disstealth", "number", nMainStealthDis);
	
	local bArmorSpeedPenalty = false;
	-- if nMainStrRequired > 0 then
		-- local nPCStr = ActorManager2.getAbilityScore(ActorManager.getActor("pc", nodeChar), "strength");
		-- if nPCStr < nMainStrRequired then
			-- bArmorSpeedPenalty = true;
			
			-- local sRace = DB.getValue(nodeChar, "race", ""):lower();
			-- if sRace:match(RACE_DWARF) or sRace:match(RACE_DUERGAR) then
				-- bArmorSpeedPenalty = false;
			-- end
		-- end
	-- end
	local nArmorSpeed = 0;
	if bArmorSpeedPenalty then
		nArmorSpeed = -10;
	end
	DB.setValue(nodeChar, "speed.armor", "number", nArmorSpeed);
	local nSpeedTotal = DB.getValue(nodeChar, "speed.base", 12) + nArmorSpeed + DB.getValue(nodeChar, "speed.misc", 0) + DB.getValue(nodeChar, "speed.temporary", 0);
	DB.setValue(nodeChar, "speed.total", "number", nSpeedTotal);
end

--
-- WEAPON MANAGEMENT
--

function removeFromWeaponDB(nodeItem)
	if not nodeItem then
		return false;
	end
	
	-- Check to see if any of the weapon nodes linked to this item node should be deleted
	local sItemNode = nodeItem.getNodeName();
	local sItemNode2 = "....inventorylist." .. nodeItem.getName();
	local bFound = false;
	for _,v in pairs(DB.getChildren(nodeItem, "...weaponlist")) do
		local sClass, sRecord = DB.getValue(v, "shortcut", "", "");
		if sRecord == sItemNode or sRecord == sItemNode2 then
			bFound = true;
			v.delete();
		end
	end

	return bFound;
end

function addToWeaponDB(nodeItem)
	-- Parameter validation
	if not ItemManager2.isWeapon(nodeItem) then
		return;
	end
	
	-- Get the weapon list we are going to add to
	local nodeChar = nodeItem.getChild("...");
	local nodeWeapons = nodeChar.createChild("weaponlist");
	if not nodeWeapons then
		return;
	end
	
	-- Set new weapons as equipped
	DB.setValue(nodeItem, "carried", "number", 2);
    
    local nSpeedFactor = DB.getValue(nodeItem, "speedfactor", 0);
    
	-- Determine identification
	local nItemID = 0;
	if LibraryData.getIDState("item", nodeItem, true) then
		nItemID = 1;
	end
	
	-- Grab some information from the source node to populate the new weapon entries
	local sName;
	if nItemID == 1 then
		sName = DB.getValue(nodeItem, "name", "");
	else
		sName = DB.getValue(nodeItem, "nonid_name", "");
		if sName == "" then
			sName = Interface.getString("item_unidentified");
		end
		sName = "** " .. sName .. " **";
	end
	local nBonus = 0;
	if nItemID == 1 then
		nBonus = DB.getValue(nodeItem, "bonus", 0);
	end

	-- Handle special weapon properties
	local aWeaponProps = StringManager.split(DB.getValue(nodeItem, "properties", ""):lower(), ",", true);
	
	local bThrown = false;
	local bMissile = false;
	local bFinesse = false;
	local bMagic = false;
	local bSpecial = false;
	for _,vProperty in ipairs(aWeaponProps) do
		if vProperty:match("^thrown %(?range ") then
			bThrown = true;
		elseif vProperty:match("^missile %(?range ") or vProperty:match("^ammunition %(?range ") then
			bMissile = true;
		elseif vProperty:match("^special$") then
			bSpecial = true;
		elseif vProperty:match("^finesse$") then
			bFinesse = true;
		elseif vProperty:match("^magic$") then
			bMagic = true;
		end
	end
	
	local bMelee = true;
	local bRanged = false;
	if bThrown then
		if bSpecial then
			bMelee = false;
		end
	elseif bMissile then
		bRanged = true;
		bMelee = false;
	end
	
	-- Parse damage field
	local sDamage = DB.getValue(nodeItem, "damage", "");
	
	local aDmgClauses = {};
	local aWords = StringManager.parseWords(sDamage);
	local i = 1;
	while aWords[i] do
		local aDiceString = {};
		
		while StringManager.isDiceString(aWords[i]) do
			table.insert(aDiceString, aWords[i]);
			i = i + 1;
		end
		if #aDiceString == 0 then
			break;
		end
		
		local aDamageTypes = {};
		while StringManager.contains(DataCommon.dmgtypes, aWords[i]) do
			table.insert(aDamageTypes, aWords[i]);
			i = i + 1;
		end
		if bMagic then
			table.insert(aDamageTypes, "magic");
		end
		
		local rDmgClause = {};
		rDmgClause.aDice, rDmgClause.nMod = StringManager.convertStringToDice(table.concat(aDiceString, " "));
		rDmgClause.dmgtype = table.concat(aDamageTypes, ",");
		table.insert(aDmgClauses, rDmgClause);
		
		if StringManager.contains({ "+", "plus" }, aWords[i]) then
			i = i + 1;
		end
	end
	
	-- Create weapon entries
	if bMelee then
		local nodeWeapon = nodeWeapons.createChild();
		if nodeWeapon then
			DB.setValue(nodeWeapon, "isidentified", "number", nItemID);
			DB.setValue(nodeWeapon, "shortcut", "windowreference", "item", "....inventorylist." .. nodeItem.getName());
			
			local sAttackAbility = "";
			local sDamageAbility = "base";
			if bFinesse then
				if DB.getValue(nodeChar, "abilities.strength.score", 10) < DB.getValue(nodeChar, "abilities.dexterity.score", 10) then
					sAttackAbility = "dexterity";
					sDamageAbility = "dexterity";
				end
			end
			
			DB.setValue(nodeWeapon, "name", "string", sName);
			DB.setValue(nodeWeapon, "type", "number", 0);
			DB.setValue(nodeWeapon, "properties", "string", sProps);

			DB.setValue(nodeWeapon, "attackstat", "string", sAttackAbility);
			DB.setValue(nodeWeapon, "attackbonus", "number", nBonus);

			DB.setValue(nodeWeapon, "speedfactor", "number", nSpeedFactor);

			local nodeDmgList = DB.createChild(nodeWeapon, "damagelist");
			if nodeDmgList then
				for kClause,rClause in ipairs(aDmgClauses) do
					local nodeDmg = DB.createChild(nodeDmgList);
					if nodeDmg then
						DB.setValue(nodeDmg, "dice", "dice", rClause.aDice);
						if kClause == 1 then
							DB.setValue(nodeDmg, "stat", "string", sDamageAbility);
							DB.setValue(nodeDmg, "bonus", "number", nBonus + rClause.nMod);
						else
							DB.setValue(nodeDmg, "bonus", "number", rClause.nMod);
						end
						DB.setValue(nodeDmg, "type", "string", rClause.dmgtype);
					end
				end
			end
		end
	end

	if bRanged then
		local nodeWeapon = nodeWeapons.createChild();
		if nodeWeapon then
			DB.setValue(nodeWeapon, "isidentified", "number", nItemID);
			DB.setValue(nodeWeapon, "shortcut", "windowreference", "item", "....inventorylist." .. nodeItem.getName());
			
			local sAttackAbility = "";
			local sDamageAbility = "base";
				
			DB.setValue(nodeWeapon, "name", "string", sName);
			DB.setValue(nodeWeapon, "type", "number", 1);
			DB.setValue(nodeWeapon, "properties", "string", sProps);

			DB.setValue(nodeWeapon, "attackstat", "string", sAttackAbility);
			DB.setValue(nodeWeapon, "attackbonus", "number", nBonus);

			DB.setValue(nodeWeapon, "speedfactor", "number", nSpeedFactor);

			local nodeDmgList = DB.createChild(nodeWeapon, "damagelist");
			if nodeDmgList then
				for kClause,rClause in ipairs(aDmgClauses) do
					local nodeDmg = DB.createChild(nodeDmgList);
					if nodeDmg then
						DB.setValue(nodeDmg, "dice", "dice", rClause.aDice);
						if kClause == 1 then
							DB.setValue(nodeDmg, "stat", "string", sDamageAbility);
							DB.setValue(nodeDmg, "bonus", "number", nBonus + rClause.nMod);
						else
							DB.setValue(nodeDmg, "bonus", "number", rClause.nMod);
						end
						DB.setValue(nodeDmg, "type", "string", rClause.dmgtype);
					end
				end
			end
		end
	end
	
	if bThrown then
		local nodeWeapon = nodeWeapons.createChild();
		if nodeWeapon then	
			DB.setValue(nodeWeapon, "isidentified", "number", nItemID);
			DB.setValue(nodeWeapon, "shortcut", "windowreference", "item", "....inventorylist." .. nodeItem.getName());
			
			local sAttackAbility = "";
			local sDamageAbility = "base";
			if bFinesse then
				if DB.getValue(nodeChar, "abilities.strength.score", 10) < DB.getValue(nodeChar, "abilities.dexterity.score", 10) then
					sAttackAbility = "dexterity";
					sDamageAbility = "dexterity";
				end
			end
				
			DB.setValue(nodeWeapon, "name", "string", sName);
			DB.setValue(nodeWeapon, "type", "number", 2);
			DB.setValue(nodeWeapon, "properties", "string", sProps);

			DB.setValue(nodeWeapon, "attackstat", "string", sAttackAbility);
			DB.setValue(nodeWeapon, "attackbonus", "number", nBonus);

			DB.setValue(nodeWeapon, "speedfactor", "number", nSpeedFactor);

			local nodeDmgList = DB.createChild(nodeWeapon, "damagelist");
			if nodeDmgList then
				for kClause,rClause in ipairs(aDmgClauses) do
					local nodeDmg = DB.createChild(nodeDmgList);
					if nodeDmg then
						DB.setValue(nodeDmg, "dice", "dice", rClause.aDice);
						if kClause == 1 then
							DB.setValue(nodeDmg, "stat", "string", sDamageAbility);
							DB.setValue(nodeDmg, "bonus", "number", nBonus + rClause.nMod);
						else
							DB.setValue(nodeDmg, "bonus", "number", rClause.nMod);
						end
						DB.setValue(nodeDmg, "type", "string", rClause.dmgtype);
					end
				end
			end
		end
	end
end

function initWeaponIDTracking()
	OptionsManager.registerCallback("MIID", onIDOptionChanged);
	DB.addHandler("charsheet.*.inventorylist.*.isidentified", "onUpdate", onItemIDChanged);
end

function onIDOptionChanged()
	for _,vChar in pairs(DB.getChildren("charsheet")) do
		for _,vWeapon in pairs(DB.getChildren(vChar, "weaponlist")) do
			checkWeaponIDChange(vWeapon);
		end
	end
end

function onItemIDChanged(nodeItemID)
	local nodeItem = nodeItemID.getChild("..");
	local nodeChar = nodeItemID.getChild("....");
	
	local sPath = nodeItem.getPath();
	for _,vWeapon in pairs(DB.getChildren(nodeChar, "weaponlist")) do
		local _,sRecord = DB.getValue(vWeapon, "shortcut", "", "");
		if sRecord == sPath then
			checkWeaponIDChange(vWeapon);
		end
	end
end

function checkWeaponIDChange(nodeWeapon)
	local _,sRecord = DB.getValue(nodeWeapon, "shortcut", "", "");
	if sRecord == "" then
		return;
	end
	local nodeItem = DB.findNode(sRecord);
	if not nodeItem then
		return;
	end
	
	local bItemID = LibraryData.getIDState("item", DB.findNode(sRecord), true);
	local bWeaponID = (DB.getValue(nodeWeapon, "isidentified", 1) == 1);
	if bItemID == bWeaponID then
		return;
	end
	
	local sName;
	if bItemID then
		sName = DB.getValue(nodeItem, "name", "");
	else
		sName = DB.getValue(nodeItem, "nonid_name", "");
		if sName == "" then
			sName = Interface.getString("item_unidentified");
		end
		sName = "** " .. sName .. " **";
	end
	DB.setValue(nodeWeapon, "name", "string", sName);
	
	local nBonus = 0;
	if bItemID then
		DB.setValue(nodeWeapon, "attackbonus", "number", DB.getValue(nodeWeapon, "attackbonus", 0) + DB.getValue(nodeItem, "bonus", 0));
		local aDamageNodes = UtilityManager.getSortedTable(DB.getChildren(nodeWeapon, "damagelist"));
		if #aDamageNodes > 0 then
			DB.setValue(aDamageNodes[1], "bonus", "number", DB.getValue(aDamageNodes[1], "bonus", 0) + DB.getValue(nodeItem, "bonus", 0));
		end
	else
		DB.setValue(nodeWeapon, "attackbonus", "number", DB.getValue(nodeWeapon, "attackbonus", 0) - DB.getValue(nodeItem, "bonus", 0));
		local aDamageNodes = UtilityManager.getSortedTable(DB.getChildren(nodeWeapon, "damagelist"));
		if #aDamageNodes > 0 then
			DB.setValue(aDamageNodes[1], "bonus", "number", DB.getValue(aDamageNodes[1], "bonus", 0) - DB.getValue(nodeItem, "bonus", 0));
		end
	end
	
	if bItemID then
		DB.setValue(nodeWeapon, "isidentified", "number", 1);
	else
		DB.setValue(nodeWeapon, "isidentified", "number", 0);
	end
end

--
-- ACTIONS
--

function rest(nodeChar, bLong)
	PowerManager.resetPowers(nodeChar, bLong);
	resetHealth(nodeChar, bLong);
end

function resetHealth(nodeChar, bLong)
	local bResetWounds = false;
	local bResetTemp = false;
	local bResetHitDice = false;
	local bResetHalfHitDice = false;
	local bResetQuarterHitDice = false;
	
	local sOptHRHV = OptionsManager.getOption("HRHV");
	if sOptHRHV == "fast" then
		if bLong then
			bResetWounds = true;
			bResetTemp = true;
			bResetHitDice = true;
		else
			bResetQuarterHitDice = true;
		end
	elseif sOptHRHV == "slow" then
		if bLong then
			bResetTemp = true;
			bResetHalfHitDice = true;
		end
	else
		if bLong then
			bResetWounds = true;
			bResetTemp = true;
			bResetHalfHitDice = true;
		end
	end
	
	-- Reset health fields and conditions
	if bResetWounds then
        -- in AD&D we dont just reset all health on a rest.
		--DB.setValue(nodeChar, "hp.wounds", "number", 0);
        --
		DB.setValue(nodeChar, "hp.deathsavesuccess", "number", 0);
		DB.setValue(nodeChar, "hp.deathsavefail", "number", 0);
	end
	if bResetTemp then
		DB.setValue(nodeChar, "hp.temporary", "number", 0);
	end
	
	-- Reset all hit dice
	if bResetHitDice then
		for _,vClass in pairs(DB.getChildren(nodeChar, "classes")) do
			DB.setValue(vClass, "hdused", "number", 0);
		end
	end

	-- Reset half or quarter of hit dice (assume biggest hit dice selected first)
	if bResetHalfHitDice or bResetQuarterHitDice then
		local nHDUsed, nHDTotal = getClassHDUsage(nodeChar);
		if nHDUsed > 0 then
			local nHDRecovery;
			if bResetQuarterHitDice then
				nHDRecovery = math.max(math.floor(nHDTotal / 4), 1);
			else
				nHDRecovery = math.max(math.floor(nHDTotal / 2), 1);
			end
			if nHDRecovery >= nHDUsed then
				for _,vClass in pairs(DB.getChildren(nodeChar, "classes")) do
					DB.setValue(vClass, "hdused", "number", 0);
				end
			else
				local nodeClassMax, nClassMaxHDSides, nClassMaxHDUsed;
				while nHDRecovery > 0 do
					nodeClassMax = nil;
					nClassMaxHDSides = 0;
					nClassMaxHDUsed = 0;
					
					for _,vClass in pairs(DB.getChildren(nodeChar, "classes")) do
						local nClassHDUsed = DB.getValue(vClass, "hdused", 0);
						if nClassHDUsed > 0 then
							local aClassDice = DB.getValue(vClass, "hddie", {});
							if #aClassDice > 0 then
								local nClassHDSides = tonumber(aClassDice[1]:sub(2)) or 0;
								if nClassHDSides > 0 and nClassMaxHDSides < nClassHDSides then
									nodeClassMax = vClass;
									nClassMaxHDSides = nClassHDSides;
									nClassMaxHDUsed = nClassHDUsed;
								end
							end
						end
					end
					
					if nodeClassMax then
						if nHDRecovery >= nClassMaxHDUsed then
							DB.setValue(nodeClassMax, "hdused", "number", 0);
							nHDRecovery = nHDRecovery - nClassMaxHDUsed;
						else
							DB.setValue(nodeClassMax, "hdused", "number", nClassMaxHDUsed - nHDRecovery);
							nHDRecovery = 0;						
						end
					else
						break;
					end
				end
			end
		end
	end
end

--
-- CHARACTER SHEET DROPS
--

function addInfoDB(nodeChar, sClass, sRecord)
	-- Validate parameters
	if not nodeChar then
		return false;
	end
	
	if sClass == "reference_background" then
		addBackgroundRef(nodeChar, sClass, sRecord);
	elseif sClass == "reference_backgroundfeature" then
		addClassFeatureDB(nodeChar, sClass, sRecord);
	elseif sClass == "reference_race" or sClass == "reference_subrace" then
		addRaceRef(nodeChar, sClass, sRecord);
	elseif sClass == "reference_class" then
		addClassRef(nodeChar, sClass, sRecord);
	elseif sClass == "reference_classproficiency" then
		addClassProficiencyDB(nodeChar, sClass, sRecord);
	elseif sClass == "reference_classability" or sClass == "reference_classfeature" then
		addClassFeatureDB(nodeChar, sClass, sRecord);
	elseif sClass == "reference_feat" then
		addFeatDB(nodeChar, sClass, sRecord);
	elseif sClass == "reference_skill" then
		addSkillRef(nodeChar, sClass, sRecord);
	elseif sClass == "reference_racialtrait" or sClass == "reference_subracialtrait" then
		addTraitDB(nodeChar, sClass, sRecord);
	elseif sClass == "ref_adventure" then
		addAdventureDB(nodeChar, sClass, sRecord);
	else
		return false;
	end
	
	return true;
end

function resolveRefNode(sRecord)
	local nodeSource = DB.findNode(sRecord);
	if not nodeSource then
		local sRecordSansModule = StringManager.split(sRecord, "@")[1];
		nodeSource = DB.findNode(sRecordSansModule .. "@*");
		if not nodeSource then
			ChatManager.SystemMessage(Interface.getString("char_error_missingrecord"));
		end
	end
	return nodeSource;
end

function addClassProficiencyDB(nodeChar, sClass, sRecord)
	local nodeSource = resolveRefNode(sRecord);
	if not nodeSource then
		return;
	end
	
	local sType = nodeSource.getName();
	
	-- Armor, Weapon or Tool Proficiencies
	if StringManager.contains({"armor", "weapons", "tools"}, sType) then
		local sText = DB.getText(nodeSource, "text");
		addProficiencyDB(nodeChar, sType, sText);
		
	-- Saving Throw Proficiencies
	elseif sType == "savingthrows" then
		local sText = DB.getText(nodeSource, "text");
		for sProf in string.gmatch(sText, "(%a[%a%s]+)%,?") do
			local sProfLower = StringManager.trim(sProf:lower());
			if StringManager.contains(DataCommon.abilities, sProfLower) then
				DB.setValue(nodeChar, "abilities." .. sProfLower .. ".saveprof", "number", 1);
				
				local sFormat = Interface.getString("char_abilities_message_saveadd");
				local sMsg = string.format(sFormat, sProf, DB.getValue(nodeChar, "name", ""));
				ChatManager.SystemMessage(sMsg);
			end
		end

	-- Skill Proficiencies
	elseif sType == "skills" then
		-- Parse the skill choice text
		local sText = DB.getText(nodeSource, "text");
		
		local aSkills = {};
		local sPicks;
		
		if sText:match("Choose any ") then
			sPicks = sText:match("Choose any (%w+)");
			
			for k,_ in pairs(DataCommon.skilldata) do
				table.insert(aSkills, k);
			end
			
		elseif sText:match("Choose ") then
			sPicks = sText:match("Choose (%w+) ");
			
			sText = sText:gsub("Choose (%w+) from ", "");
			sText = sText:gsub("Choose (%w+) skills? from ", "");
			sText = sText:gsub("and ", "");
			sText = sText:gsub("or ", "");
			
			for sSkill in string.gmatch(sText, "(%a[%a%s]+)%,?") do
				local sTrim = StringManager.trim(sSkill);
				table.insert(aSkills, sTrim);
			end
		end
		
		local nPicks = 0;
		if sPicks == "one" then
			nPicks = 1;
		elseif sPicks == "two" then
			nPicks = 2;
		elseif sPicks == "three" then
			nPicks = 3;
		elseif sPicks == "four" then
			nPicks = 4;
		end
		
		if nPicks == 0 or #aSkills == 0 then
			ChatManager.SystemMessage(Interface.getString("char_error_addskill"));
			return nil;
		end
		
		pickSkills(nodeChar, aSkills, nPicks);
	else
		ChatManager.SystemMessage(Interface.getString("char_error_addclassprof") .. " (" .. sType .. ")");
	end
	
	return true;
end

function onRaceAbilitySelect(aSelection, nodeChar)
	for _,sAbility in ipairs(aSelection) do
		local k = sAbility:lower();
		if StringManager.contains(DataCommon.abilities, k) then
			local sPath = "abilities." .. k .. ".score";
			DB.setValue(nodeChar, sPath, "number", DB.getValue(nodeChar, sPath, 10) + 1);
		end
	end
end

function onClassSkillSelect(aSelection, rSkillAdd)
	-- For each selected skill, add it to the character
	for _,sSkill in ipairs(aSelection) do
		addSkillDB(rSkillAdd.nodeChar, sSkill, rSkillAdd.nProf or 1);
	end
end

function addProficiencyDB(nodeChar, sType, sText)
	-- Get the list we are going to add to
	local nodeList = nodeChar.createChild("proficiencylist");
	if not nodeList then
		return nil;
	end

	-- If proficiency is not none, then add it to the list
	if sText == "None" then
		return nil;
	end
	
	-- Make sure this item does not already exist
	for _,vProf in pairs(nodeList.getChildren()) do
		if DB.getValue(vProf, "name", "") == sText then
			return vProf;
		end
	end
	
	local nodeEntry = nodeList.createChild();
	local sValue;
	if sType == "armor" then
		sValue = Interface.getString("char_label_addprof_armor");
	elseif sType == "weapons" then
		sValue = Interface.getString("char_label_addprof_weapon");
	else
		sValue = Interface.getString("char_label_addprof_tool");
	end
	sValue = sValue .. ": " .. sText;
	DB.setValue(nodeEntry, "name", "string", sValue);

	-- Announce
	local sFormat = Interface.getString("char_abilities_message_profadd");
	local sMsg = string.format(sFormat, DB.getValue(nodeEntry, "name", ""), DB.getValue(nodeChar, "name", ""));
	ChatManager.SystemMessage(sMsg);

	return nodeEntry;
end

function addSkillDB(nodeChar, sSkill, nProficient)
	-- Get the list we are going to add to
	local nodeList = nodeChar.createChild("skilllist");
	if not nodeList then
		return nil;
	end
	
	-- Make sure this item does not already exist
	local nodeSkill = nil;
	for _,vSkill in pairs(nodeList.getChildren()) do
		if DB.getValue(vSkill, "name", "") == sSkill then
			nodeSkill = vSkill;
			break;
		end
	end
		
	-- Add the item
	if not nodeSkill then
		nodeSkill = nodeList.createChild();
		DB.setValue(nodeSkill, "name", "string", sSkill);
		if DataCommon.skilldata[sSkill] then
--			DB.setValue(nodeSkill, "stat", "string", DataCommon.skilldata[sSkill].stat);
			DB.setValue(nodeSkill, "stat", "string",DB.getValue(nodeSkill, "stat", ""));
			DB.setValue(nodeSkill, "adj_mod", "number",DB.getValue(nodeSkill, "adj_mod", 0));
			DB.setValue(nodeSkill, "base_check", "number",DB.getValue(nodeSkill, "base_check", 0));
		end
	end
	if nProficient then
		if nProficient and type(nProficient) ~= "number" then
			nProficient = 1;
		end
		DB.setValue(nodeSkill, "prof", "number", nProficient);
	end

	-- Announce
	local sFormat = Interface.getString("char_abilities_message_skilladd");
	local sMsg = string.format(sFormat, DB.getValue(nodeSkill, "name", ""), DB.getValue(nodeChar, "name", ""));
	ChatManager.SystemMessage(sMsg);
	
	return nodeSkill;
end

function addClassFeatureDB(nodeChar, sClass, sRecord, nodeClass)
	local nodeSource = resolveRefNode(sRecord);
	if not nodeSource then
		return;
	end
	
	-- Get the list we are going to add to
	local nodeList = nodeChar.createChild("featurelist");
	if not nodeList then
		return false;
	end
	
	-- Get the class name
	local sClassName = DB.getValue(nodeSource, "...name", "");
	
	-- Make sure this item does not already exist
	local sOriginalName = DB.getValue(nodeSource, "name", "");
	local sOriginalNameLower = StringManager.trim(sOriginalName:lower());
	local sFeatureName = sOriginalName;
	for _,v in pairs(nodeList.getChildren()) do
		if DB.getValue(v, "name", ""):lower() == sOriginalNameLower then
			if sOriginalNameLower == FEATURE_SPELLCASTING or sOriginalNameLower == FEATURE_PACT_MAGIC then
				sFeatureName = sFeatureName .. " (" .. sClassName .. ")";
			else
				return false;
			end
		end
	end
	
	-- Pull the feature level
	local nFeatureLevel = DB.getValue(nodeSource, "level", 0);

	-- Add the item
	local vNew = nodeList.createChild();
	DB.copyNode(nodeSource, vNew);
	DB.setValue(vNew, "name", "string", sFeatureName);
	DB.setValue(vNew, "source", "string", DB.getValue(nodeSource, "...name", ""));
	DB.setValue(vNew, "locked", "number", 1);

	-- Special handling
	if sOriginalNameLower == FEATURE_SPELLCASTING then
		-- Add spell casting ability
		local sSpellcasting = DB.getText(vNew, "text", "");
		local sAbility = sSpellcasting:match("(%a+) is your spellcasting ability");
		if sAbility then
			local sSpellsLabel = Interface.getString("power_label_groupspells");
			local sLowerSpellsLabel = sSpellsLabel:lower();
			
			local bFoundSpellcasting = false;
			for _,vGroup in pairs (DB.getChildren(nodeChar, "powergroup")) do
				if DB.getValue(vGroup, "name", ""):lower() == sLowerSpellsLabel then
					bFoundSpellcasting = true;
					break;
				end
			end
			
			local sNewGroupName = sSpellsLabel;
			if bFoundSpellcasting then
				sNewGroupName = sNewGroupName .. " (" .. sClassName .. ")";
			end
			
			local nodePowerGroups = DB.createChild(nodeChar, "powergroup");
			local nodeNewGroup = nodePowerGroups.createChild();
			DB.setValue(nodeNewGroup, "castertype", "string", "memorization");
			DB.setValue(nodeNewGroup, "stat", "string", sAbility:lower());
			DB.setValue(nodeNewGroup, "name", "string", sNewGroupName);
			
			if sSpellcasting:match("Preparing and Casting Spells") then
				local rActor = ActorManager.getActor("pc", nodeChar);
				DB.setValue(nodeNewGroup, "prepared", "number", math.min(1 + ActorManager2.getAbilityBonus(rActor, sAbility:lower())));
			end
		end
		
		-- Add spell slot calculation info
		if nodeClass and nFeatureLevel > 0 then
			DB.setValue(nodeClass, "casterlevelinvmult", "number", nFeatureLevel);
		end

	elseif sOriginalNameLower == FEATURE_PACT_MAGIC then
		-- Add spell casting ability
		local sAbility = DB.getText(vNew, "text", ""):match("(%a+) is your spellcasting ability");
		if sAbility then
			local sSpellsLabel = Interface.getString("power_label_groupspells");
			local sLowerSpellsLabel = sSpellsLabel:lower();
			
			local bFoundSpellcasting = false;
			for _,vGroup in pairs (DB.getChildren(nodeChar, "powergroup")) do
				if DB.getValue(vGroup, "name", ""):lower() == sLowerSpellsLabel then
					bFoundSpellcasting = true;
					break;
				end
			end
			
			local sNewGroupName = sSpellsLabel;
			if bFoundSpellcasting then
				sNewGroupName = sNewGroupName .. " (" .. sClassName .. ")";
			end
			
			local nodePowerGroups = DB.createChild(nodeChar, "powergroup");
			local nodeNewGroup = nodePowerGroups.createChild();
			DB.setValue(nodeNewGroup, "castertype", "string", "memorization");
			DB.setValue(nodeNewGroup, "stat", "string", sAbility:lower());
			DB.setValue(nodeNewGroup, "name", "string", sNewGroupName);

		end
		
		-- Add spell slot calculation info
		DB.setValue(nodeClass, "casterpactmagic", "number", 1);
		if nodeClass and nFeatureLevel > 0 then
			DB.setValue(nodeClass, "casterlevelinvmult", "number", nFeatureLevel);
		end
	
	elseif sOriginalNameLower == FEATURE_DRACONIC_RESILIENCE then
		applyDraconicResilience(nodeChar, true);
	elseif sOriginalNameLower == FEATURE_UNARMORED_DEFENSE then
		applyUnarmoredDefense(nodeChar, nodeClass);
	else
		local sText = DB.getText(vNew, "text", "");
		checkSkillProficiencies(nodeChar, sText);
	end
	
	-- Announce
	local sFormat = Interface.getString("char_abilities_message_featureadd");
	local sMsg = string.format(sFormat, DB.getValue(vNew, "name", ""), DB.getValue(nodeChar, "name", ""));
	ChatManager.SystemMessage(sMsg);
	
	return true;
end

function addTraitDB(nodeChar, sClass, sRecord)
	local nodeSource = resolveRefNode(sRecord);
	if not nodeSource then
		return;
	end

	local sTraitType = CampaignDataManager2.sanitize(DB.getValue(nodeSource, "name", ""));
	if sTraitType == "" then
		sTraitType = nodeSource.getName();
	end
	
	if sTraitType == "abilityscoreincrease" then
		local bApplied = false;
		local sAdjust = DB.getText(nodeSource, "text"):lower();
		
		if sAdjust:match("your ability scores each increase") then
			for _,v in pairs(DataCommon.abilities) do
				local sPath = "abilities." .. v .. ".score";
				DB.setValue(nodeChar, sPath, "number", DB.getValue(nodeChar, sPath, 10) + 1);
				bApplied = true;
			end
		else
			local aIncreases = {};
			
			local n1, n2;
			local a1, a2, sIncrease = sAdjust:match("your (%w+) and (%w+) scores increase by (%d+)");
			if a1 then
				local nIncrease = tonumber(sIncrease) or 0;
				aIncreases[a1:lower()] = nIncrease;
				aIncreases[a2:lower()] = nIncrease;
			else
				for a1, sIncrease in sAdjust:gmatch("your (%w+) score increases by (%d+)") do
					local nIncrease = tonumber(sIncrease) or 0;
					aIncreases[a1:lower()] = nIncrease;
				end
				for a1, sDecrease in sAdjust:gmatch("your (%w+) score is reduced by (%d+)") do
					local nDecrease = tonumber(sDecrease) or 0;
					aIncreases[a1:lower()] = nDecrease * -1;
				end
			end
			
			for k,v in pairs(aIncreases) do
				if StringManager.contains(DataCommon.abilities, k) then
					local sPath = "abilities." .. k .. ".score";
					DB.setValue(nodeChar, sPath, "number", DB.getValue(nodeChar, sPath, 10) + v);
					bApplied = true;
				end
			end
			
			if sAdjust:match("two other ability scores of your choice increase") or 
					sAdjust:match("two different ability scores of your choice increase") then
				local aAbilities = {};
				for _,v in ipairs(DataCommon.abilities) do
					if not aIncreases[v] then
						table.insert(aAbilities, StringManager.capitalize(v));
					end
				end
				local wSelect = Interface.openWindow("select_dialog", "");
				local sTitle = Interface.getString("char_build_title_selectabilityincrease");
				local sMessage = string.format(Interface.getString("char_build_message_selectabilityincrease"), 2);
				wSelect.requestSelection(sTitle, sMessage, aAbilities, CharManager.onRaceAbilitySelect, nodeChar, 2);
			end
		end
		if not bApplied then
			return false;
		end

	elseif sTraitType == "age" then
		return false;

	elseif sTraitType == "alignment" then
		return false;

	elseif sTraitType == "size" then
		local sSize = DB.getText(nodeSource, "text");
		sSize = sSize:match("[Yy]our size is (%w+)");
		if not sSize then
			sSize = "Medium";
		end
		DB.setValue(nodeChar, "size", "string", sSize);

	elseif sTraitType == "speed" then
		local sSpeed = DB.getText(nodeSource, "text");
		
		local sWalkSpeed = sSpeed:match("walking speed is (%d+) feet");
		if not sWalkSpeed then
			sWalkSpeed = sSpeed:match("land speed is (%d+) feet");
		end
		if sWalkSpeed then
			local nSpeed = tonumber(sWalkSpeed) or 30;
			DB.setValue(nodeChar, "speed.base", "number", nSpeed);
		end
		
		local aSpecial = {};
		local bSpecialChanged = false;
		local sSpecial = StringManager.trim(DB.getValue(nodeChar, "speed.special", ""));
		if sSpecial ~= "" then
			table.insert(aSpecial, sSpecial);
		end
		
		local sSwimSpeed = sSpeed:match("swimming speed of (%d+) feet");
		if sSwimSpeed then
			bSpecialChanged = true;
			table.insert(aSpecial, "Swim " .. sSwimSpeed .. " ft.");
		end

		local sFlySpeed = sSpeed:match("flying speed of (%d+) feet");
		if sFlySpeed then
			bSpecialChanged = true;
			table.insert(aSpecial, "Fly " .. sFlySpeed .. " ft.");
		end

		local sClimbSpeed = sSpeed:match("climbing speed of (%d+) feet");
		if sClimbSpeed then
			bSpecialChanged = true;
			table.insert(aSpecial, "Climb " .. sClimbSpeed .. " ft.");
		end
		
		if bSpecialChanged then
			DB.setValue(nodeChar, "speed.special", "string", table.concat(aSpecial, ", "));
		end

	elseif sTraitType == "fleetoffoot" then
		local sFleetOfFoot = DB.getText(nodeSource, "text");
		
		local sWalkSpeedIncrease = sFleetOfFoot:match("walking speed increases to (%d+) feet");
		if sWalkSpeedIncrease then
			DB.setValue(nodeChar, "speed.base", "number", tonumber(sWalkSpeedIncrease));
		end

	elseif sTraitType == "darkvision" then
		local sSenses = DB.getValue(nodeChar, "senses", "");
		if sSenses ~= "" then
			sSenses = sSenses .. ", ";
		end
		sSenses = sSenses .. DB.getValue(nodeSource, "name", "");
		
		local sText = DB.getText(nodeSource, "text");
		if sText then
			local sDist = sText:match("%d+");
			if sDist then
				sSenses = sSenses .. " " .. sDist;
			end
		end
		
		DB.setValue(nodeChar, "senses", "string", sSenses);
		
	elseif sTraitType == "superiordarkvision" then
		local sSenses = DB.getValue(nodeChar, "senses", "");

		local sDist = nil;
		local sText = DB.getText(nodeSource, "text");
		if sText then
			sDist = sText:match("%d+");
		end
		if not sDist then
			return false;
		end

		-- Check for regular Darkvision
		local sTraitName = DB.getValue(nodeSource, "name", "");
		if sSenses:find("Darkvision (%d+)") then
			sSenses = sSenses:gsub("Darkvision (%d+)", sTraitName .. " " .. sDist);
		else
			if sSenses ~= "" then
				sSenses = sSenses .. ", ";
			end
			sSenses = sSenses .. sTraitName .. " " .. sDist;
		end
		
		DB.setValue(nodeChar, "senses", "string", sSenses);

	elseif sTraitType == "languages" then
		local bApplied = false;
		local sText = DB.getText(nodeSource, "text");
		local sLanguages = sText:match("You can speak, read, and write ([^.]+)");
		if not sLanguages then
			sLanguages = sText:match("You can read and write ([^.]+)");
		end
		if not sLanguages then
			return false;
		end

		sLanguages = sLanguages:gsub("and ", ",");
		sLanguages = sLanguages:gsub("one extra language of your choice", "Choice");
		sLanguages = sLanguages:gsub("one other language of your choice", "Choice");
		-- EXCEPTION - Kenku - Languages - Volo
		sLanguages = sLanguages:gsub(", but you.*$", "");
		for s in string.gmatch(sLanguages, "(%a[%a%s]+)%,?") do
			addLanguageDB(nodeChar, s);
			bApplied = true;
		end
		return bApplied;
		
	elseif sTraitType == "extralanguage" then
		addLanguageDB(nodeChar, "Choice");
		return true;
	
	elseif sTraitType == "subrace" then
		return false;
		
	else
		local sText = DB.getText(nodeSource, "text", "");
		
		if sTraitType == "stonecunning" then
			-- Note: Bypass due to false positive in skill proficiency detection
		else
			checkSkillProficiencies(nodeChar, sText);
		end
		
		-- Get the list we are going to add to
		local nodeList = nodeChar.createChild("traitlist");
		if not nodeList then
			return false;
		end
		
		-- Add the item
		local vNew = nodeList.createChild();
		DB.copyNode(nodeSource, vNew);
		DB.setValue(vNew, "source", "string", DB.getValue(nodeSource, "...name", ""));
		DB.setValue(vNew, "locked", "number", 1);
	
		if sClass == "reference_racialtrait" then
			DB.setValue(vNew, "type", "string", "racial");
		elseif sClass == "reference_subracialtrait" then
			DB.setValue(vNew, "type", "string", "subracial");
		elseif sClass == "reference_backgroundtrait" then
			DB.setValue(vNew, "type", "string", "background");
		end
		
		-- Special handling
		local sNameLower = DB.getValue(nodeSource, "name", ""):lower();
		if sNameLower == TRAIT_DWARVEN_TOUGHNESS then
			applyDwarvenToughness(nodeChar, true);
		elseif sNameLower == TRAIT_NATURAL_ARMOR then
			calcItemArmorClass(nodeChar);
		elseif sNameLower == TRAIT_CATS_CLAWS then
			local aSpecial = {};
			local sSpecial = StringManager.trim(DB.getValue(nodeChar, "speed.special", ""));
			if sSpecial ~= "" then
				table.insert(aSpecial, sSpecial);
			end
			table.insert(aSpecial, "Climb 20 ft.");
			DB.setValue(nodeChar, "speed.special", "string", table.concat(aSpecial, ", "));
		end
	end
	
	-- Announce
	local sFormat = Interface.getString("char_abilities_message_traitadd");
	local sMsg = string.format(sFormat, DB.getValue(nodeSource, "name", ""), DB.getValue(nodeChar, "name", ""));
	ChatManager.SystemMessage(sMsg);
	
	return true;
end

function parseSkillsFromString(sSkills)
	local aSkills = {};
	sSkills = sSkills:gsub("and ", "");
	sSkills = sSkills:gsub("or ", "");
	local nPeriod = sSkills:match("%.()");
	if nPeriod then
		sSkills = sSkills:sub(1, nPeriod);
	end
	for sSkill in string.gmatch(sSkills, "(%a[%a%s]+)%,?") do
		local sTrim = StringManager.trim(sSkill);
		table.insert(aSkills, sTrim);
	end
	return aSkills;
end

function pickSkills(nodeChar, aSkills, nPicks, nProf)
	-- Add links (if we can find them)
	for k,v in ipairs(aSkills) do
		local rSkillData = DataCommon.skilldata[v];
		if rSkillData then
			aSkills[k] = { text = v, linkclass = "reference_skill", linkrecord = "reference.skilldata." .. rSkillData.lookup .. "@*" };
		end
	end
	
	-- Display dialog to choose skill selection
	local rSkillAdd = { nodeChar = nodeChar, nProf = nProf };
	local wSelect = Interface.openWindow("select_dialog", "");
	local sTitle = Interface.getString("char_build_title_selectskills");
	local sMessage = string.format(Interface.getString("char_build_message_selectskills"), nPicks);
	wSelect.requestSelection (sTitle, sMessage, aSkills, CharManager.onClassSkillSelect, rSkillAdd, nPicks);
end

function checkSkillProficiencies(nodeChar, sText)
	-- Elf - Keen Senses - PHB
	-- Half-Orc - Menacing - PHB
	-- Goliath - Natural Athlete - Volo
	local sSkill = sText:match("proficiency in the (%w+) skill");
	if sSkill then
		CharManager.addSkillDB(nodeChar, sSkill, 1);
		return true;
	end
	-- Bugbear - Sneaky - Volo
	-- (FALSE POSITIVE) Dwarf - Stonecunning
	sSkill = sText:match("proficient in the (%w+) skill");
	if sSkill then
		CharManager.addSkillDB(nodeChar, sSkill, 1);
		return true;
	end
	-- Orc - Menacing - Volo
	sSkill = sText:match("trained in the (%w+) skill");
	if sSkill then
		CharManager.addSkillDB(nodeChar, sSkill, 1);
		return true;
	end
	-- Tabaxi - Cat's Talent - Volo
	local sSkill, sSkill2 = sText:match("proficiency in the (%w+) and (%w+) skills");
	if sSkill and sSkill2 then
		CharManager.addSkillDB(nodeChar, sSkill, 1);
		CharManager.addSkillDB(nodeChar, sSkill2, 1);
		return true;
	end

	-- Half-Elf - Skill Versatility - PHB
	-- Human (Variant) - Skills - PHB
	local sPicks = sText:match("proficiency in (%w+) skills? of your choice");
	if sPicks then
		local aSkills = {};
		for kSkill,_ in pairs(DataCommon.skilldata) do
			table.insert(aSkills, kSkill);
		end
		table.sort(aSkills);
		local nPicks = 0;
		if sPicks == "one" then
			nPicks = 1;
		elseif sPicks == "two" then
			nPicks = 2;
		elseif sPicks == "three" then
			nPicks = 3;
		elseif sPicks == "four" then
			nPicks = 4;
		end
		pickSkills(nodeChar, aSkills, nPicks);
		return true;
	end
	-- Cleric - Acolyte of Nature - PHB
	local nMatchEnd = sText:match("proficiency in one of the following skills of your choice()")
	if nMatchEnd then
		pickSkills(nodeChar, parseSkillsFromString(sText:sub(nMatchEnd)), 1);
		return true;
	end
	-- Lizardfolk - Hunter's Lore - Volo
	sPicks, nMatchEnd = sText:match("proficiency with (%w+) of the following skills of your choice()")
	if sPicks then
		local nPicks = 0;
		if sPicks == "one" then
			nPicks = 1;
		elseif sPicks == "two" then
			nPicks = 2;
		elseif sPicks == "three" then
			nPicks = 3;
		elseif sPicks == "four" then
			nPicks = 4;
		end
		pickSkills(nodeChar, parseSkillsFromString(sText:sub(nMatchEnd)), nPicks);
		return true;
	end
	-- Cleric - Blessings of Knowledge - PHB
	-- Kenku - Kenuku Training - Volo
	sPicks, nMatchEnd = sText:match("proficient in your choice of (%w+) of the following skills()")
	if sPicks then
		local nPicks = 0;
		if sPicks == "one" then
			nPicks = 1;
		elseif sPicks == "two" then
			nPicks = 2;
		elseif sPicks == "three" then
			nPicks = 3;
		elseif sPicks == "four" then
			nPicks = 4;
		end
		local nProf = 1;
		if sText:match("proficiency bonus is doubled") then
			nProf = 2;
		end
		pickSkills(nodeChar, parseSkillsFromString(sText:sub(nMatchEnd)), nPicks, nProf);
		return true;
	end
	return false;
end

function addFeatDB(nodeChar, sClass, sRecord)
	local nodeSource = resolveRefNode(sRecord);
	if not nodeSource then
		return;
	end

	-- Get the list we are going to add to
	local nodeList = nodeChar.createChild("featlist");
	if not nodeList then
		return false;
	end
	
	-- Make sure this item does not already exist
	local sName = DB.getValue(nodeSource, "name", "");
	for _,v in pairs(nodeList.getChildren()) do
		if DB.getValue(v, "name", "") == sName then
			return flase;
		end
	end

	-- Add the item
	local vNew = nodeList.createChild();
	DB.copyNode(nodeSource, vNew);
	DB.setValue(vNew, "locked", "number", 1);

	-- Special handling
	local sNameLower = sName:lower();
	if sNameLower == FEAT_TOUGH then
		applyTough(nodeChar, true);
	end
	
	-- Announce
	local sFormat = Interface.getString("char_abilities_message_featadd");
	local sMsg = string.format(sFormat, DB.getValue(vNew, "name", ""), DB.getValue(nodeChar, "name", ""));
	ChatManager.SystemMessage(sMsg);
	
	return true;
end

function addLanguageDB(nodeChar, sLanguage)
	-- Get the list we are going to add to
	local nodeList = nodeChar.createChild("languagelist");
	if not nodeList then
		return false;
	end
	
	-- Make sure this item does not already exist
	if sLanguage ~= "Choice" then
		for _,v in pairs(nodeList.getChildren()) do
			if DB.getValue(v, "name", "") == sLanguage then
				return false;
			end
		end
	end

	-- Add the item
	local vNew = nodeList.createChild();
	DB.setValue(vNew, "name", "string", sLanguage);

	-- Announce
	local sFormat = Interface.getString("char_abilities_message_languageadd");
	local sMsg = string.format(sFormat, DB.getValue(vNew, "name", ""), DB.getValue(nodeChar, "name", ""));
	ChatManager.SystemMessage(sMsg);
	
	return true;
end

function addBackgroundRef(nodeChar, sClass, sRecord)
	local nodeSource = resolveRefNode(sRecord);
	if not nodeSource then
		return;
	end

	-- Notify
	local sFormat = Interface.getString("char_abilities_message_backgroundadd");
	local sMsg = string.format(sFormat, DB.getValue(nodeSource, "name", ""), DB.getValue(nodeChar, "name", ""));
	ChatManager.SystemMessage(sMsg);
	
	-- Add the name and link to the main character sheet
	DB.setValue(nodeChar, "background", "string", DB.getValue(nodeSource, "name", ""));
	DB.setValue(nodeChar, "backgroundlink", "windowreference", sClass, nodeSource.getNodeName());
		
	for _,v in pairs(DB.getChildren(nodeSource, "features")) do
		addClassFeatureDB(nodeChar, "reference_backgroundfeature", v.getPath());
	end

	local sSkills = DB.getValue(nodeSource, "skill", "");
	if sSkills ~= "" and sSkills ~= "None" then
		local nPicks = 0;
		local aPickSkills = {};
		if sSkills:match("Choose %w+ from among ") then
			local sPicks, sPickSkills = sSkills:match("Choose (%w+) from among (.*)");
			sPickSkills = sPickSkills:gsub("and ", "");

			sSkills = "";
			
			if sPicks == "one" then
				nPicks = 1;
			elseif sPicks == "two" then
				nPicks = 2;
			elseif sPicks == "three" then
				nPicks = 3;
			elseif sPicks == "four" then
				nPicks = 4;
			end
			
			for sSkill in string.gmatch(sPickSkills, "(%a[%a%s]+)%,?") do
				local sTrim = StringManager.trim(sSkill);
				table.insert(aPickSkills, sTrim);
			end
		elseif sSkills:match("plus one from among") then
			local sPickSkills = sSkills:match("plus one from among (.*)");
			sPickSkills = sPickSkills:gsub("and ", "");
			sPickSkills = sPickSkills:gsub(", as appropriate for your order", "");
			
			sSkills = sSkills:gsub("plus one from among (.*)", "");
			
			nPicks = 1;
			for sSkill in string.gmatch(sPickSkills, "(%a[%a%s]+)%,?") do
				local sTrim = StringManager.trim(sSkill);
				if sTrim ~= "" then
					table.insert(aPickSkills, sTrim);
				end
			end
		elseif sSkills:match("plus your choice of one from among") then
			local sPickSkills = sSkills:match("plus your choice of one from among (.*)");
			sPickSkills = sPickSkills:gsub("and ", "");
			
			sSkills = sSkills:gsub("plus your choice of one from among (.*)", "");
			
			nPicks = 1;
			for sSkill in string.gmatch(sPickSkills, "(%a[%a%s]+)%,?") do
				local sTrim = StringManager.trim(sSkill);
				if sTrim ~= "" then
					table.insert(aPickSkills, sTrim);
				end
			end
		elseif sSkills:match("and one Intelligence, Wisdom, or Charisma skill of your choice, as appropriate to your faction") then
			sSkills = sSkills:gsub("and one Intelligence, Wisdom, or Charisma skill of your choice, as appropriate to your faction", "");
			
			nPicks = 1;
			for k,v in pairs(DataCommon.skilldata) do
				if (v.stat == "intelligence") or (v.stat == "wisdom") or (v.stat == "charisma") then
					table.insert(aPickSkills, k);
				end
			end
			table.sort(aPickSkills);
		end
		
		for sSkill in sSkills:gmatch("(%a[%a%s]+),?") do
			local sTrim = StringManager.trim(sSkill);
			if sTrim ~= "" then
				addSkillDB(nodeChar, sTrim, 1);
			end
		end
		
		if nPicks > 0 then
			pickSkills(nodeChar, aPickSkills, nPicks);
		end
	end

	local sTools = DB.getValue(nodeSource, "tool", "");
	if sTools ~= "" and sTools ~= "None" then
		addProficiencyDB(nodeChar, "tools", sTools);
	end
	
	local sLanguages = DB.getValue(nodeSource, "languages", "");
	if sLanguages ~= "" and sLanguages ~= "None" then
		addLanguageDB(nodeChar, sLanguages);
	end
end

function addRaceRef(nodeChar, sClass, sRecord)
	local nodeSource = resolveRefNode(sRecord);
	if not nodeSource then
		return;
	end
	
	if sClass == "reference_race" then
		local aTable = {};
		aTable["char"] = nodeChar;
		aTable["class"] = sClass;
		aTable["record"] = nodeSource;
		
		local aSelection = {};
		for _,v in pairs(DB.getChildrenGlobal(nodeSource, "subraces")) do
			local sName = DB.getValue(v, "name", "");
			if sName ~= "" then
				table.insert(aSelection, { text = sName, linkclass = "reference_subrace", linkrecord = v.getPath() });
			end
		end
		
		if #aSelection == 0 then
			addRaceSelect(nil, aTable);
		elseif #aSelection == 1 then
			addRaceSelect(aSelection, aTable);
		else
			-- Display dialog to choose subrace
			local wSelect = Interface.openWindow("select_dialog", "");
			local sTitle = Interface.getString("char_build_title_selectsubrace");
			local sMessage = string.format(Interface.getString("char_build_message_selectsubrace"), DB.getValue(nodeSource, "name", ""), 1);
			wSelect.requestSelection (sTitle, sMessage, aSelection, addRaceSelect, aTable);
		end
	else
		local aTable = {};
		aTable["char"] = nodeChar;
		aTable["class"] = "reference_race";
		aTable["record"] = nodeSource.getChild("...");
		
		local aSelection = { DB.getValue(nodeSource, "name", "") };
		
		addRaceSelect(aSelection, aTable);
	end
end

function addRaceSelect(aSelection, aTable)
	-- If subraces available, make sure that exactly one is selected
	if aSelection then
		if #aSelection ~= 1 then
			ChatManager.SystemMessage(Interface.getString("char_error_addsubrace"));
			return;
		end
	end

	local nodeChar = aTable["char"];
	local nodeSource = aTable["record"];
	
	-- Determine race to display on sheet and in notifications
	local sRace = DB.getValue(nodeSource, "name", "");
	local sSubRace = nil;
	if aSelection then
		if type(aSelection[1]) == "table" then
			sSubRace = aSelection[1].text;
		else
			sSubRace = aSelection[1];
		end
		if sSubRace:match(sRace) then
			sRace = sSubRace;
		else
			sRace = sRace .. " (" .. sSubRace .. ")";
		end
	end
	
	-- Notify
	local sFormat = Interface.getString("char_abilities_message_raceadd");
	local sMsg = string.format(sFormat, sRace, DB.getValue(nodeChar, "name", ""));
	ChatManager.SystemMessage(sMsg);
	
	-- Add the name and link to the main character sheet
	DB.setValue(nodeChar, "race", "string", sRace);
	DB.setValue(nodeChar, "racelink", "windowreference", aTable["class"], nodeSource.getNodeName());
		
	for _,v in pairs(DB.getChildren(nodeSource, "traits")) do
		addTraitDB(nodeChar, "reference_racialtrait", v.getPath());
	end
	
	if sSubRace then
		for _,vSubRace in pairs(DB.getChildrenGlobal(nodeSource, "subraces")) do
			if DB.getValue(vSubRace, "name", "") == sSubRace then
				for _,v in pairs(DB.getChildren(vSubRace, "traits")) do
					addTraitDB(nodeChar, "reference_subracialtrait", v.getPath());
				end
				
				break;
			end
		end
	end
end

function addClassRef(nodeChar, sClass, sRecord)
	local nodeSource = resolveRefNode(sRecord)
	if not nodeSource then
		return;
	end

	-- Get the list we are going to add to
	local nodeList = nodeChar.createChild("classes");
	if not nodeList then
		return;
	end
	
	-- Notify
	local sFormat = Interface.getString("char_abilities_message_classadd");
	local sMsg = string.format(sFormat, DB.getValue(nodeSource, "name", ""), DB.getValue(nodeChar, "name", ""));
	ChatManager.SystemMessage(sMsg);
	
	-- Translate Hit Die
	local bHDFound = false;
	local nHDMult = 1;
	local nHDSides = 6;
	local sHD = DB.getText(nodeSource, "hp.hitdice.text");
	if sHD then
		local sMult, sSides = sHD:match("(%d)d(%d+)");
		if sMult and sSides then
			nHDMult = tonumber(sMult);
			nHDSides = tonumber(sSides);
			bHDFound = true;
		end
	end
	if not bHDFound then
		ChatManager.SystemMessage(Interface.getString("char_error_addclasshd"));
	end

	-- Check to see if the character already has this class
	local sRecordSansModule = StringManager.split(sRecord, "@")[1];
	local nodeClass = nil;
	local sClassName = DB.getValue(nodeSource, "name", "");
	local sClassNameLower = StringManager.trim(sClassName):lower();
	for _,v in pairs(nodeList.getChildren()) do
		local _,sExistingClassPath = DB.getValue(v, "shortcut", "", "");
		if sExistingClassPath == "" then
			local sExistingClassName = StringManager.trim(DB.getValue(v, "name", "")):lower();
			if sExistingClassName ~= "" and (sExistingClassName == sClassNameLower) then
				nodeClass = v;
				break;
			end
		else
			local sExistingClassPathSansModule = StringManager.split(sExistingClassPath, "@")[1];
			if sExistingClassPathSansModule == sRecordSansModule then
				nodeClass = v;
				break;
			end
		end
	end
	
	-- Calculate current spell slots before levelling up
	local nCasterLevel = calcSpellcastingLevel(nodeChar);
	local nPactMagicLevel = calcPactMagicLevel(nodeChar);
	
	-- If class already exists, then add a level; otherwise, create a new class entry
	local nLevel = 1;
	local bExistingClass = false;
	if nodeClass then
		bExistingClass = true;
		nLevel = DB.getValue(nodeClass, "level", 1) + 1;
	else
		nodeClass = nodeList.createChild();
	end
	
	-- Any way you get here, overwrite or set the class reference link with the most current
	DB.setValue(nodeClass, "shortcut", "windowreference", sClass, sRecord);
	
	-- Add basic class information
	DB.setValue(nodeClass, "level", "number", nLevel);
	if not bExistingClass then
		DB.setValue(nodeClass, "name", "string", sClassName);

		local aDice = {};
		for i = 1, nHDMult do
			table.insert(aDice, "d" .. nHDSides);
		end
		DB.setValue(nodeClass, "hddie", "dice", aDice);
	end
	
	-- Calculate total level
	local nTotalLevel = 0;
	for _,vClass in pairs(nodeList.getChildren()) do
		nTotalLevel = nTotalLevel + DB.getValue(vClass, "level", 0);
	end
	
	-- Add hit points based on level added
	local nHP = DB.getValue(nodeChar, "hp.total", 0);
	local nConBonus = DB.getValue(nodeChar, "abilities.constitution.bonus", 0);
	if nTotalLevel == 1 then
		local nAddHP = (nHDMult * nHDSides);
		nHP = nHP + nAddHP + nConBonus;

		local sFormat = Interface.getString("char_abilities_message_hpaddmax");
		local sMsg = string.format(sFormat, DB.getValue(nodeSource, "name", ""), DB.getValue(nodeChar, "name", "")) .. " (" .. nAddHP .. "+" .. nConBonus .. ")";
		ChatManager.SystemMessage(sMsg);
	else
		local nAddHP = math.floor(((nHDMult * (nHDSides + 1)) / 2) + 0.5);
		nHP = nHP + nAddHP + nConBonus;

		local sFormat = Interface.getString("char_abilities_message_hpaddavg");
		local sMsg = string.format(sFormat, DB.getValue(nodeSource, "name", ""), DB.getValue(nodeChar, "name", "")) .. " (" .. nAddHP .. "+" .. nConBonus .. ")";
		ChatManager.SystemMessage(sMsg);
	end
	DB.setValue(nodeChar, "hp.total", "number", nHP);

	-- Special hit point level up handling
	if hasTrait(nodeChar, TRAIT_DWARVEN_TOUGHNESS) then
		applyDwarvenToughness(nodeChar);
	end
	if (sClassNameLower == CLASS_SORCERER) and hasFeature(nodeChar, FEATURE_DRACONIC_RESILIENCE) then
		applyDraconicResilience(nodeChar);
	end
	if hasFeat(nodeChar, FEAT_TOUGH) then
		applyTough(nodeChar);
	end
	
	-- Add proficiencies
	if not bExistingClass then
		if nTotalLevel == 1 then
			for _,v in pairs(DB.getChildren(nodeSource, "proficiencies")) do
				addClassProficiencyDB(nodeChar, "reference_classproficiency", v.getPath());
			end
		else
			for _,v in pairs(DB.getChildren(nodeSource, "multiclassproficiencies")) do
				addClassProficiencyDB(nodeChar, "reference_classproficiency", v.getPath());
			end
		end
	end
	
    -- setup/copy the save/fight as cyclers. --celestian
	if not bExistingClass then
        local sSaveAs = DB.getValue(nodeSource,"saveas","warrior");
        local sFightAs = DB.getValue(nodeSource,"fightas","warrior");
        DB.setValue(nodeClass,"saveas","string",sSaveAs);
        DB.setValue(nodeClass,"fightas","string",sFightAs);
    end
    
	-- Determine whether a specialization is added this level
	local nodeSpecializationFeature = nil;
	local aOptions = {};
	for _,v in pairs(DB.getChildren(nodeSource, "features")) do
		if (DB.getValue(v, "level", 0) == nLevel) and (DB.getValue(v, "specializationchoice", 0) == 1) then
			nodeSpecializationFeature = v;
			for _,v in pairs(DB.getChildrenGlobal(nodeSource, "abilities")) do
				table.insert(aOptions, { text = DB.getValue(v, "name", ""), linkclass = "reference_classability", linkrecord = v.getPath() });
			end
			break;
		end
	end
	
	-- Add features, with customization based on whether specialization is added this level
	local rClassAdd = { nodeChar = nodeChar, nodeSource = nodeSource, nLevel = nLevel, nodeClass = nodeClass, nCasterLevel = nCasterLevel, nPactMagicLevel = nPactMagicLevel };
	if #aOptions == 0 then
		addClassFeatureHelper(nil, rClassAdd);
	elseif #aOptions == 1 then
		addClassFeatureHelper( { aOptions[1].text }, rClassAdd);
	else
		-- Display dialog to choose specialization
		local wSelect = Interface.openWindow("select_dialog", "");
		local sTitle = Interface.getString("char_build_title_selectspecialization");
		local sMessage = string.format(Interface.getString("char_build_message_selectspecialization"), DB.getValue(nodeSpecializationFeature, "name", ""), 1);
		wSelect.requestSelection (sTitle, sMessage, aOptions, addClassFeatureHelper, rClassAdd);
	end
end

function addClassFeatureHelper(aSelection, rClassAdd)
	local nodeSource = rClassAdd.nodeSource;
	local nodeChar = rClassAdd.nodeChar;
	
	-- Check to see if we added specialization
	if aSelection then
		if #aSelection ~= 1 then
			ChatManager.SystemMessage(Interface.getString("char_error_addclassspecialization"));
			return;
		end
		
		-- Add specialization
		for _,v in pairs(DB.getChildrenGlobal(nodeSource, "abilities")) do
			if DB.getValue(v, "name", "") == aSelection[1] then
				addClassFeatureDB(nodeChar, "reference_classability", v.getPath(), rClassAdd.nodeClass);
			end
		end
	end
	
	-- Add features
	for _,v in pairs(DB.getChildren(nodeSource, "features")) do
		if (DB.getValue(v, "level", 0) == rClassAdd.nLevel) and (DB.getValue(v, "specializationchoice", 0) == 0) then
			local sFeatureName = DB.getValue(v, "name", "");
			local sFeatureSpec = DB.getValue(v, "specialization", "");
			if sFeatureSpec == "" or hasFeature(nodeChar, sFeatureSpec) then
				addClassFeatureDB(nodeChar, "reference_classfeature", v.getPath(), rClassAdd.nodeClass);
			end
		end
	end
	
	-- Increment spell slots for spellcasting level
	local nNewCasterLevel = calcSpellcastingLevel(nodeChar);
	if nNewCasterLevel > rClassAdd.nCasterLevel then
		for i = rClassAdd.nCasterLevel + 1, nNewCasterLevel do
			if i == 1 then
				DB.setValue(nodeChar, "powermeta.spellslots1.max", "number", DB.getValue(nodeChar, "powermeta.spellslots1.max", 0) + 2);
			elseif i == 2 then
				DB.setValue(nodeChar, "powermeta.spellslots1.max", "number", DB.getValue(nodeChar, "powermeta.spellslots1.max", 0) + 1);
			elseif i == 3 then
				DB.setValue(nodeChar, "powermeta.spellslots1.max", "number", DB.getValue(nodeChar, "powermeta.spellslots1.max", 0) + 1);
				DB.setValue(nodeChar, "powermeta.spellslots2.max", "number", DB.getValue(nodeChar, "powermeta.spellslots2.max", 0) + 2);
			elseif i == 4 then
				DB.setValue(nodeChar, "powermeta.spellslots2.max", "number", DB.getValue(nodeChar, "powermeta.spellslots2.max", 0) + 1);
			elseif i == 5 then
				DB.setValue(nodeChar, "powermeta.spellslots3.max", "number", DB.getValue(nodeChar, "powermeta.spellslots3.max", 0) + 2);
			elseif i == 6 then
				DB.setValue(nodeChar, "powermeta.spellslots3.max", "number", DB.getValue(nodeChar, "powermeta.spellslots3.max", 0) + 1);
			elseif i == 7 then
				DB.setValue(nodeChar, "powermeta.spellslots4.max", "number", DB.getValue(nodeChar, "powermeta.spellslots4.max", 0) + 1);
			elseif i == 8 then
				DB.setValue(nodeChar, "powermeta.spellslots4.max", "number", DB.getValue(nodeChar, "powermeta.spellslots4.max", 0) + 1);
			elseif i == 9 then
				DB.setValue(nodeChar, "powermeta.spellslots4.max", "number", DB.getValue(nodeChar, "powermeta.spellslots4.max", 0) + 1);
				DB.setValue(nodeChar, "powermeta.spellslots5.max", "number", DB.getValue(nodeChar, "powermeta.spellslots5.max", 0) + 1);
			elseif i == 10 then
				DB.setValue(nodeChar, "powermeta.spellslots5.max", "number", DB.getValue(nodeChar, "powermeta.spellslots5.max", 0) + 1);
			elseif i == 11 then
				DB.setValue(nodeChar, "powermeta.spellslots6.max", "number", DB.getValue(nodeChar, "powermeta.spellslots6.max", 0) + 1);
			elseif i == 12 then
				-- No change
			elseif i == 13 then
				DB.setValue(nodeChar, "powermeta.spellslots7.max", "number", DB.getValue(nodeChar, "powermeta.spellslots7.max", 0) + 1);
			elseif i == 14 then
				-- No change
			elseif i == 15 then
				DB.setValue(nodeChar, "powermeta.spellslots8.max", "number", DB.getValue(nodeChar, "powermeta.spellslots8.max", 0) + 1);
			elseif i == 16 then
				-- No change
			elseif i == 17 then
				DB.setValue(nodeChar, "powermeta.spellslots9.max", "number", DB.getValue(nodeChar, "powermeta.spellslots9.max", 0) + 1);
			elseif i == 18 then
				DB.setValue(nodeChar, "powermeta.spellslots5.max", "number", DB.getValue(nodeChar, "powermeta.spellslots5.max", 0) + 1);
			elseif i == 19 then
				DB.setValue(nodeChar, "powermeta.spellslots6.max", "number", DB.getValue(nodeChar, "powermeta.spellslots6.max", 0) + 1);
			elseif i == 20 then
				DB.setValue(nodeChar, "powermeta.spellslots7.max", "number", DB.getValue(nodeChar, "powermeta.spellslots7.max", 0) + 1);
			end
		end
	end
	
	-- Adjust spell slots for pact magic level increase
	local nNewPactMagicLevel = calcPactMagicLevel(nodeChar);
	if nNewPactMagicLevel > rClassAdd.nPactMagicLevel then
		for i = rClassAdd.nPactMagicLevel + 1, nNewPactMagicLevel do
			if i == 1 then
				DB.setValue(nodeChar, "powermeta.pactmagicslots1.max", "number", DB.getValue(nodeChar, "powermeta.pactmagicslots1.max", 0) + 1);
			elseif i == 2 then
				DB.setValue(nodeChar, "powermeta.pactmagicslots1.max", "number", DB.getValue(nodeChar, "powermeta.pactmagicslots1.max", 0) + 1);
			elseif i == 3 then
				DB.setValue(nodeChar, "powermeta.pactmagicslots1.max", "number", math.max(DB.getValue(nodeChar, "powermeta.pactmagicslots1.max", 0) - 2, 0));
				DB.setValue(nodeChar, "powermeta.pactmagicslots2.max", "number", DB.getValue(nodeChar, "powermeta.pactmagicslots2.max", 0) + 2);
			elseif i == 4 then
				-- No change
			elseif i == 5 then
				DB.setValue(nodeChar, "powermeta.pactmagicslots2.max", "number", math.max(DB.getValue(nodeChar, "powermeta.pactmagicslots2.max", 0) - 2, 0));
				DB.setValue(nodeChar, "powermeta.pactmagicslots3.max", "number", DB.getValue(nodeChar, "powermeta.pactmagicslots3.max", 0) + 2);
			elseif i == 6 then
				-- No change
			elseif i == 7 then
				DB.setValue(nodeChar, "powermeta.pactmagicslots3.max", "number", math.max(DB.getValue(nodeChar, "powermeta.pactmagicslots3.max", 0) - 2, 0));
				DB.setValue(nodeChar, "powermeta.pactmagicslots4.max", "number", DB.getValue(nodeChar, "powermeta.pactmagicslots4.max", 0) + 2);
			elseif i == 8 then
				-- No change
			elseif i == 9 then
				DB.setValue(nodeChar, "powermeta.pactmagicslots4.max", "number", math.max(DB.getValue(nodeChar, "powermeta.pactmagicslots4.max", 0) - 2, 0));
				DB.setValue(nodeChar, "powermeta.pactmagicslots5.max", "number", DB.getValue(nodeChar, "powermeta.pactmagicslots5.max", 0) + 2);
			elseif i == 10 then
				-- No change
			elseif i == 11 then
				DB.setValue(nodeChar, "powermeta.pactmagicslots5.max", "number", DB.getValue(nodeChar, "powermeta.pactmagicslots5.max", 0) + 1);
			elseif i == 12 then
				-- No change
			elseif i == 13 then
				-- No change
			elseif i == 14 then
				-- No change
			elseif i == 15 then
				-- No change
			elseif i == 16 then
				-- No change
			elseif i == 17 then
				DB.setValue(nodeChar, "powermeta.pactmagicslots5.max", "number", DB.getValue(nodeChar, "powermeta.pactmagicslots5.max", 0) + 1);
			elseif i == 18 then
				-- No change
			elseif i == 19 then
				-- No change
			elseif i == 20 then
				-- No change
			end
		end
	end
end

function addSkillRef(nodeChar, sClass, sRecord)
	local nodeSource = resolveRefNode(sRecord);
	if not nodeSource then
		return;
	end
	
	-- Add skill entry
	local nodeSkill = addSkillDB(nodeChar, DB.getValue(nodeSource, "name", ""));
	if nodeSkill then
		DB.setValue(nodeSkill, "text", "formattedtext", DB.getValue(nodeSource, "text", ""));
	end
end

function calcSpellcastingLevel(nodeChar)
	local nCurrSpellClass = 0;
	for _,vClass in pairs(DB.getChildren(nodeChar, "classes")) do
		if DB.getValue(vClass, "casterlevelinvmult", 0) > 0 then
			nCurrSpellClass = nCurrSpellClass + 1;
		end
	end
	
	local nCurrSpellCastLevel = 0;
	for _,vClass in pairs(DB.getChildren(nodeChar, "classes")) do
		if DB.getValue(vClass, "casterpactmagic", 0) == 0 then
			local nClassSpellSlotMult = DB.getValue(vClass, "casterlevelinvmult", 0);
			if nClassSpellSlotMult > 0 then
				local nClassSpellCastLevel = DB.getValue(vClass, "level", 0);
				if nCurrSpellClass > 1 then
					nClassSpellCastLevel = math.floor(nClassSpellCastLevel  * (1 / nClassSpellSlotMult));
				else
					nClassSpellCastLevel = math.ceil(nClassSpellCastLevel  * (1 / nClassSpellSlotMult));
				end
				nCurrSpellCastLevel = nCurrSpellCastLevel + nClassSpellCastLevel;
			end
		end
	end
	
	return nCurrSpellCastLevel;
end

function calcPactMagicLevel(nodeChar)
	local nPactMagicLevel = 0;
	for _,vClass in pairs(DB.getChildren(nodeChar, "classes")) do
		if DB.getValue(vClass, "casterpactmagic", 0) > 0 then
			local nClassSpellSlotMult = DB.getValue(vClass, "casterlevelinvmult", 0);
			if nClassSpellSlotMult > 0 then
				local nClassSpellCastLevel = DB.getValue(vClass, "level", 0);
				nClassSpellCastLevel = math.ceil(nClassSpellCastLevel  * (1 / nClassSpellSlotMult));
				nPactMagicLevel = nPactMagicLevel + nClassSpellCastLevel;
			end
		end
	end
	
	return nPactMagicLevel;
end

function addAdventureDB(nodeChar, sClass, sRecord)
	local nodeSource = resolveRefNode(sRecord);
	if not nodeSource then
		return;
	end

	-- Get the list we are going to add to
	local nodeList = nodeChar.createChild("adventurelist");
	if not nodeList then
		return nil;
	end
	
	-- Copy the adventure record data
	local vNew = nodeList.createChild();
	DB.copyNode(nodeSource, vNew);
	DB.setValue(vNew, "locked", "number", 1);
	
	-- Notify
	local sFormat = Interface.getString("char_logs_message_adventureadd");
	local sMsg = string.format(sFormat, DB.getValue(nodeSource, "name", ""), DB.getValue(nodeChar, "name", ""));
	ChatManager.SystemMessage(sMsg);
end

function hasTrait(nodeChar, sTrait)
	local sTraitLower = sTrait:lower();
	for _,v in pairs(DB.getChildren(nodeChar, "traitlist")) do
		if DB.getValue(v, "name", ""):lower() == sTraitLower then
			return true;
		end
	end
	
	return false;
end

function hasFeature(nodeChar, sFeature)
	local sFeatureLower = sFeature:lower();
	for _,v in pairs(DB.getChildren(nodeChar, "featurelist")) do
		if DB.getValue(v, "name", ""):lower() == sFeatureLower then
			return true;
		end
	end
	
	return false;
end

function hasFeat(nodeChar, sFeat)
	local sFeatLower = sFeat:lower();
	for _,v in pairs(DB.getChildren(nodeChar, "featlist")) do
		if DB.getValue(v, "name", ""):lower() == sFeatLower then
			return true;
		end
	end
	
	return false;
end

function applyDwarvenToughness(nodeChar, bInitialAdd)
	-- Add extra hit points
	local nAddHP = 1;
	if bInitialAdd then
		nAddHP = 0;
		for _,nodeChild in pairs(DB.getChildren(nodeChar, "classes")) do
			local nLevel = DB.getValue(nodeChild, "level", 0);
			if nLevel > 0 then
				nAddHP = nAddHP + nLevel;
			end
		end
	end
	
	local nHP = DB.getValue(nodeChar, "hp.total", 0);
	nHP = nHP + nAddHP;
	DB.setValue(nodeChar, "hp.total", "number", nHP);
	
	local sFormat = Interface.getString("char_abilities_message_hpaddtrait");
	local sMsg = string.format(sFormat, StringManager.capitalizeAll(TRAIT_DWARVEN_TOUGHNESS), DB.getValue(nodeChar, "name", "")) .. " (" .. nAddHP .. ")";
	ChatManager.SystemMessage(sMsg);
end

function applyDraconicResilience(nodeChar, bInitialAdd)
	-- Add extra hit points
	local nAddHP = 1;
	local nHP = DB.getValue(nodeChar, "hp.total", 0);
	nHP = nHP + nAddHP;
	DB.setValue(nodeChar, "hp.total", "number", nHP);
	
	local sFormat = Interface.getString("char_abilities_message_hpaddfeature");
	local sMsg = string.format(sFormat, StringManager.capitalizeAll(FEATURE_DRACONIC_RESILIENCE), DB.getValue(nodeChar, "name", "")) .. " (" .. nAddHP .. ")";
	ChatManager.SystemMessage(sMsg);
		
	if bInitialAdd then
		-- Add armor (if wearing none)
		local nArmor = DB.getValue(nodeChar, "defenses.ac.armor", 0);
		if nArmor == 0 then
			DB.setValue(nodeChar, "defenses.ac.armor", "number", 3);
		end
	end
end

function applyUnarmoredDefense(nodeChar, nodeClass)
	local sAbility = "";
	local sClassLower = DB.getValue(nodeClass, "name", ""):lower();
	if sClassLower == CLASS_BARBARIAN then
		sAbility = "constitution";
	elseif sClassLower == CLASS_MONK then
		sAbility = "wisdom";
	end
	
	if (sAbility ~= "") and (DB.getValue(nodeChar,  "defenses.ac.stat2", "") == "") then
		DB.setValue(nodeChar, "defenses.ac.stat2", "string", sAbility);
	end
end

function applyTough(nodeChar, bInitialAdd)
	local nAddHP = 2;
	if bInitialAdd then
		nAddHP = 0;
		for _,nodeChild in pairs(DB.getChildren(nodeChar, "classes")) do
			local nLevel = DB.getValue(nodeChild, "level", 0);
			if nLevel > 0 then
				nAddHP = nAddHP + (2 * nLevel);
			end
		end
	end
	
	local nHP = DB.getValue(nodeChar, "hp.total", 0);
	nHP = nHP + nAddHP;
	DB.setValue(nodeChar, "hp.total", "number", nHP);
	
	local sFormat = Interface.getString("char_abilities_message_hpaddfeat");
	local sMsg = string.format(sFormat, StringManager.capitalizeAll(FEAT_TOUGH), DB.getValue(nodeChar, "name", "")) .. " (" .. nAddHP .. ")";
	ChatManager.SystemMessage(sMsg);
end
