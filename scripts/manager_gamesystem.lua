-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Ruleset action types
actions = {
	["dice"] = { bUseModStack = true },
	["table"] = { },
	["cast"] = { sTargeting = "each" },
	["castsave"] = { sTargeting = "each" },
	["death"] = { },
	["powersave"] = { sTargeting = "each" },
	["attack"] = { sIcon = "action_attack", sTargeting = "each", bUseModStack = true },
	["damage"] = { sIcon = "action_damage", sTargeting = "all", bUseModStack = true },
	["heal"] = { sIcon = "action_heal", sTargeting = "all", bUseModStack = true },
	["effect"] = { sIcon = "action_effect", sTargeting = "all" },
	["init"] = { bUseModStack = true },
	["save"] = { bUseModStack = true },
	["check"] = { bUseModStack = true },
	["recharge"] = { },
	["recovery"] = { bUseModStack = true },
	["skill"] = { bUseModStack = true },
};

targetactions = {
	"cast",
	"castsave",
	"powersave",
	"attack",
	"damage",
	"heal",
	"effect"
};

currencies = { "PP", "GP", "EP", "SP", "CP" };
currencyDefault = "GP";

function onInit()	
	-- Languages
	languages = {
		-- Standard languages
		[Interface.getString("language_value_common")] = "",
		[Interface.getString("language_value_dwarvish")] = "Dwarven",
		[Interface.getString("language_value_elvish")] = "Elven",
		[Interface.getString("language_value_giant")] = "Dwarven",
		[Interface.getString("language_value_gnomish")] = "Dwarven",
		[Interface.getString("language_value_goblin")] = "Dwarven",
		[Interface.getString("language_value_halfling")] = "",
		[Interface.getString("language_value_orc")] = "Dwarven",
		-- Exotic languages
		[Interface.getString("language_value_abyssal")] = "Infernal",
		[Interface.getString("language_value_aquan")] = "Elven",
		[Interface.getString("language_value_auran")] = "Draconic",
		[Interface.getString("language_value_celestial")] = "Celestial",
		[Interface.getString("language_value_deepspeech")] = "",
		[Interface.getString("language_value_draconic")] = "Draconic",
		[Interface.getString("language_value_ignan")] = "Draconic",
		[Interface.getString("language_value_infernal")] = "Infernal",
		[Interface.getString("language_value_primordial")] = "Primordial",
		[Interface.getString("language_value_sylvan")] = "Elven",
		[Interface.getString("language_value_terran")] = "Dwarven",
		[Interface.getString("language_value_undercommon")] = "Elven",
	}
	languagefonts = {
		[Interface.getString("language_value_celestial")] = "Celestial",
		[Interface.getString("language_value_draconic")] = "Draconic",
		[Interface.getString("language_value_dwarvish")] = "Dwarven",
		[Interface.getString("language_value_elvish")] = "Elven",
		[Interface.getString("language_value_infernal")] = "Infernal",
		[Interface.getString("language_value_primordial")] = "Primordial",
	}
end

function getCharSelectDetailHost(nodeChar)
	local sValue = "";
	-- local nLevel = DB.getValue(nodeChar, "level", 0);
	-- if nLevel > 0 then
		-- sValue = "Level " .. math.floor(nLevel*100)*0.01;
	-- end
	return sValue;
end

function requestCharSelectDetailClient()
	return "name,#level";
end

function receiveCharSelectDetailClient(vDetails)
--	return vDetails[1], "Level " .. math.floor(vDetails[2]*100)*0.01;
	return vDetails[1];
end

function getCharSelectDetailLocal(nodeLocal)
	local vDetails = {};
	table.insert(vDetails, DB.getValue(nodeLocal, "name", ""));
	--table.insert(vDetails, DB.getValue(nodeLocal, "level", 0));
	return receiveCharSelectDetailClient(vDetails);
end

function getPregenCharSelectDetail(nodePregenChar)
	return CharManager.getClassLevelSummary(nodePregenChar);
end

function getDistanceUnitsPerGrid()
--Debug.console("manager_gamesystem.lua","getDistanceUnitsPerGrid","DataCommonADND.nDefaultDistancePerUnitGrid",DataCommonADND.nDefaultDistancePerUnitGrid);
	return DataCommonADND.nDefaultDistancePerUnitGrid;
--	return 5;
end
