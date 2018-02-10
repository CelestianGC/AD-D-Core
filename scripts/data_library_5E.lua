-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function sortNPCCRValues(aFilterValues)
	local function fNPCSortValue(a)
		local v;
		if a == "1/2" then
			v = 0.5;
		elseif a == "1/4" then
			v = 0.25;
		elseif a == "1/8" then
			v = 0.125;
		else
			v = tonumber(a) or 0;
		end
		return v;
	end
	table.sort(aFilterValues, function(a,b) return fNPCSortValue(a) < fNPCSortValue(b); end);
	return aFilterValues;
end

-- get hitDice and get just the first number
function getNPCHitDice(vNode)
	local sHitDice = StringManager.trim(DB.getValue(vNode, "hitDice", ""));
	local sHD = sHitDice:match("^%d+");
	if sHD then
		sHitDice = StringManager.trim(sHD);
	end
	return sHitDice;
end

-- see if this will sort HD better
function sortNPCHitDice(aFilterValues)
	local function fNPCSortValue(a)
		local v = tonumber(a) or 0;
		return v;
    end
	table.sort(aFilterValues, function(a,b) return fNPCSortValue(a) < fNPCSortValue(b); end);
	return aFilterValues;
end

function getNPCTypeValue(vNode)
	local v = StringManager.trim(DB.getValue(vNode, "type", ""));
	local sType = v:match("^[^(%s]+");
	if sType then
		v = StringManager.trim(sType);
	end
	v = StringManager.capitalize(v);
	return v;
end


function getItemRecordDisplayClass(vNode)
	local sRecordDisplayClass = "item";
	if vNode then
		local sBasePath, sSecondPath = UtilityManager.getDataBaseNodePathSplit(vNode);
		if sBasePath == "reference" then
			if sSecondPath == "equipmentdata" then
				local sTypeLower = StringManager.trim(DB.getValue(DB.getPath(vNode, "type"), ""):lower());
				if sTypeLower == "weapon" then
					sRecordDisplayClass = "reference_weapon";
				elseif sTypeLower == "armor" then
					sRecordDisplayClass = "reference_armor";
				elseif sTypeLower == "mounts and other animals" then
					sRecordDisplayClass = "reference_mountsandotheranimals";
				elseif sTypeLower == "waterborne vehicles" then
					sRecordDisplayClass = "reference_waterbornevehicles";
				elseif sTypeLower == "vehicle" then
					sRecordDisplayClass = "reference_vehicle";
				else
					sRecordDisplayClass = "reference_equipment";
				end
			else
				sRecordDisplayClass = "reference_magicitem";
			end
		end
	end
	return sRecordDisplayClass;
end

function isItemIdentifiable(vNode)
	return (getItemRecordDisplayClass(vNode) == "item");
end

function getSpellSourceValue(vNode)
	return StringManager.split(DB.getValue(vNode, "source", ""), ",", true);
end
function getSpellSphereValue(vNode)
	return StringManager.split(DB.getValue(vNode, "sphere", ""), ",", true);
end
function getSpellSchoolValue(vNode)
	return StringManager.split(DB.getValue(vNode, "school", ""), ",", true);
end

function getSkillTypeValue(vNode)
	return StringManager.capitalize(DB.getValue(vNode, "stat", ""), ",", true);
end

function getSpellLevelValue(vNode)
	local v = DB.getValue(vNode, "level", 0);
	if (v >= 1) and (v <= 9) then
		v = tostring(v);
	else
		v = Interface.getString("library_recordtype_value_spell_level_0");
	end
	return v;
end

aRecords = {
	-- ["image"] = { 
		-- bExport = true,
		-- bID = true,
		-- sIDOption = "IMID",
		-- aDataMap = { "image", "reference.images" }, 
		-- aDisplayIcon = { "button_maps", "button_maps_down" }, 
		-- sListDisplayClass = "masterindexitem_id",
		-- sRecordDisplayClass = "imagewindow",
		-- aGMListButtons = { "button_folder_image", "button_store_image" },
	-- },
	-- ["image"] = { 
		-- bExport = true,
		-- bID = true,
		-- sIDOption = "IMID",
		-- aDataMap = { "image", "reference.images" }, 
		-- aDisplayIcon = { "button_maps", "button_maps_down" }, 
		-- sListDisplayClass = "imagelist",
		-- sRecordDisplayClass = "image",
		-- aGMListButtons = { "button_folder_image", "button_store_image" },
	-- },
	["npc"] = { 
		bExport = true,
		aDataMap = { "npc", "reference.npcdata" }, 
		aDisplayIcon = { "button_people", "button_people_down" },
		-- sRecordDisplayClass = "npc", 
		aGMListButtons = { "button_npc_letter", "button_npc_hd", "button_npc_type" };
		aCustomFilters = {
--			["Type"] = { sField = "type", fGetValue = getNPCTypeValue },
            ["HitDice"] = { sField = "hitDice", fGetValue = getNPCHitDice,fSort = sortNPCHitDice },
			["Type"] = { sField = "type", sType = "string" },
			["Organization"] = { sField = "organization", sType = "string" },
			["Activity"] = { sField = "activity", sType = "string" },
			["Diet"] = { sField = "diet", sType = "string" },
--			["Frequency"] = { sField = "frequency", sType = "string", fSort = sortNPCCRValues },
			["Frequency"] = { sField = "frequency", sType = "string"},
			["Climate"] = { sField = "climate", sType = "string" },
		},
	},
	["item"] = { 
		bExport = true,
		bID = true,
		sIDOption = "MIID",
		fIsIdentifiable = isItemIdentifiable,
		aDataMap = { "item", "reference.equipmentdata", "reference.magicitemdata", "reference.magicrefitemdata" }, 
		aDisplayIcon = { "button_items", "button_items_down" }, 
		sListDisplayClass = "masterindexitem_id",
--		aGMListButtons = { "button_forge_item" },
--		aGMListButtons = { "button_item_armor", "button_item_weapons","button_item_list", "button_item_templates" };
		aGMListButtons = { "button_item_armor", "button_item_weapons", "button_item_templates" };
        aPlayerListButtons = { "button_item_armor_player", "button_item_weapons_player" };
		fRecordDisplayClass = getItemRecordDisplayClass,
		aRecordDisplayClasses = { "item", "reference_magicitem", "reference_armor", "reference_weapon", "reference_equipment", "reference_mountsandotheranimals", "reference_waterbornevehicles" },
		aCustomFilters = {
			["Cost"] = { sField = "cost", sType = "string" },
			["Type"] = { sField = "type" },
			--["Template"] = { sField = "istemplate", sType = "boolean" },
            --["Text"] = { sField = "text", sType = "formattedtext", bSearchable = true };
		},
	},
	["quest"] = { 
		bExport = true,
		aDataMap = { "quest", "reference.questdata" }, 
		aDisplayIcon = { "button_quests", "button_quests_down" },
		-- sRecordDisplayClass = "quest", 
	},
	
	["background"] = {
		bExport = true, 
		aDataMap = { "background", "reference.backgrounddata" }, 
		aDisplayIcon = { "button_backgrounds", "button_backgrounds_down" },
		sRecordDisplayClass = "reference_background", 
	},
	["class"] = {
		bExport = true, 
		aDataMap = { "class", "reference.classdata" }, 
		aDisplayIcon = { "button_classes", "button_classes_down" },
		sRecordDisplayClass = "reference_class", 
	},
	["feat"] = {
		bExport = true, 
		aDataMap = { "feat", "reference.featdata" }, 
		aDisplayIcon = { "button_feats", "button_feats_down" },
		sRecordDisplayClass = "reference_feat", 
	},
	["race"] = {
		bExport = true, 
		aDataMap = { "race", "reference.racedata" }, 
		aDisplayIcon = { "button_races", "button_races_down" },
		sRecordDisplayClass = "reference_race", 
	},
	["skill"] = {
		bExport = true, 
		aDataMap = { "skill", "reference.skilldata" }, 
		aDisplayIcon = { "button_skills", "button_skills_down" },
		sRecordDisplayClass = "reference_skill", 
        aGMListButtons = { "button_skills_type" };
		aCustomFilters = {
			["Type"] = { sField = "stat", fGetValue = getSkillTypeValue},
		},
        aPlayerListButtons = { "button_skills_type_player" };
	},
	["spell"] = {
		bExport = true, 
		aDataMap = { "spell", "reference.spelldata" }, 
		aDisplayIcon = { "button_spells", "button_spells_down" },
		sRecordDisplayClass = "power", 
		aGMListButtons = { "button_spells_arcane_player", "button_spells_school_player","button_spells_divine_player","button_spells_sphere_player" };
        aPlayerListButtons = { "button_spells_school_player", "button_spells_sphere_player" };
		aCustomFilters = {
			["Sphere"] = { sField = "sphere", fGetValue = getSpellSphereValue },
			["School"] = { sField = "school", fGetValue = getSpellSchoolValue },
			["Type"] = { sField = "type", sType = "string" },
			["Level"] = { sField = "level", sType = "number" };
		},
	},
	["table"] = { 
		bExport = true,
		aDataMap = { "tables", "reference.tables" }, 
		aDisplayIcon = { "button_tables", "button_tables_down" },
		-- sRecordDisplayClass = "table", 
		aGMEditButtons = { "button_add_table_guided" };
	},
    
};

aDefaultSidebarState = {
	["create"] = "charsheet,class,background,item,race,skill,spell",
};

function onInit()
	for kDefSidebar,vDefSidebar in pairs(aDefaultSidebarState) do
		DesktopManager.setDefaultSidebarState(kDefSidebar, vDefSidebar);
	end
	for kRecordType,vRecordType in pairs(aRecords) do
		LibraryData.setRecordTypeInfo(kRecordType, vRecordType);
	end
end
