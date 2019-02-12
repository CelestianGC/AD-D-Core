-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- get identified state for sCustom 
function getItemIsIdentified(vRecord, vDefault)
	return LibraryData.getIDState("item", vRecord, true);
end

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

-- search filter by type, split type by commas.
function getNPCTypeValue(vNode)
  local sText = sanitizevNodeText(DB.getValue(vNode, "type", ""));
  return StringManager.split(sText, ",", true);
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

-- remove ()'s and replace / with commas
function sanitizevNodeText(sText)
  sText = sText:gsub(" ","");
  sText = sText:gsub("%(","");
  sText = sText:gsub("%)","");
  sText = sText:gsub("/",",");
  sText = sText:gsub("\\",",");
  return sText;
end
function getSpellSourceValue(vNode)
  local sText = sanitizevNodeText(DB.getValue(vNode, "source", ""));
  
  return StringManager.split(sText, ",", true);
end
function getSpellSphereValue(vNode)
  local sText = sanitizevNodeText(DB.getValue(vNode, "sphere", ""));
  return StringManager.split(sText, ",", true);
end
function getSpellSchoolValue(vNode)
  local sText = sanitizevNodeText(DB.getValue(vNode, "school", ""));
  return StringManager.split(sText, ",", true);
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
    bID = true,
    aDataMap = { "npc", "reference.npcdata" }, 
    aDisplayIcon = { "button_people", "button_people_down" },
    -- sRecordDisplayClass = "npc", 
    aGMEditButtons = { "button_npc_export_file","button_npc_import_file","button_npc_import_text","button_npc_statblock_import_text" };
    aGMListButtons = { "button_npc_letter", "button_npc_hd", "button_npc_type" };
    aCustomFilters = {
      ["Type"] = { sField = "type", fGetValue = getNPCTypeValue },
      ["HitDice"] = { sField = "hitDice", fGetValue = getNPCHitDice,fSort = sortNPCHitDice },
--      ["Type"] = { sField = "type", sType = "string" },
      ["Organization"] = { sField = "organization", sType = "string" },
      ["Activity"] = { sField = "activity", sType = "string" },
      ["Diet"] = { sField = "diet", sType = "string" },
--    ["Frequency"] = { sField = "frequency", sType = "string", fSort = sortNPCCRValues },
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
--    aGMListButtons = { "button_forge_item" },
--    aGMListButtons = { "button_item_armor", "button_item_weapons","button_item_list", "button_item_templates" };
    aGMListButtons = { "button_item_armor", "button_item_weapons" };
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
    aGMEditButtons = { "button_power_import" };
    aGMListButtons = { "button_spells_arcane_player", "button_spells_school_player","button_spells_divine_player","button_spells_sphere_player" };
    aPlayerListButtons = { "button_spells_school_player", "button_spells_sphere_player" };
    aCustomFilters = {
      -- psionic searches hidden for now, till official psionic support --celestian
      --["Discipline"] = { sField = "discipline", sType = "string" },
      --["Discipline Type"] = { sField = "disciplinetype", sType = "string" },
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

aListViews = {
	["npc"] = {
		["byletter"] = {
			sTitleRes = "npc_grouped_title_byletter",
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "npc_grouped_label_name", nWidth=250 },
				{ sName = "cr", sType = "string", sHeadingRes = "npc_grouped_label_cr", sTooltipRe = "npc_grouped_tooltip_cr", bCentered=true },
			},
			aFilters = { },
			aGroups = { { sDBField = "name", nLength = 1 } },
			aGroupValueOrder = { },
		},
		-- ["bycr"] = {
			-- sTitleRes = "npc_grouped_title_bycr",
			-- aColumns = {
				-- { sName = "name", sType = "string", sHeadingRes = "npc_grouped_label_name", nWidth=250 },
				-- { sName = "cr", sType = "string", sHeadingRes = "npc_grouped_label_cr", sTooltipRe = "npc_grouped_tooltip_cr", bCentered=true },
			-- },
			-- aFilters = { },
			-- aGroups = { { sDBField = "cr", sPrefix = "CR" } },
			-- aGroupValueOrder = { "CR", "CR 0", "CR 1/8", "CR 1/4", "CR 1/2", 
								-- "CR 1", "CR 2", "CR 3", "CR 4", "CR 5", "CR 6", "CR 7", "CR 8", "CR 9" },
		-- },
		["bytype"] = {
			sTitleRes = "npc_grouped_title_bytype",
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "npc_grouped_label_name", nWidth=250 },
				{ sName = "cr", sType = "string", sHeadingRes = "npc_grouped_label_cr", sTooltipRe = "npc_grouped_tooltip_cr", bCentered=true },
			},
			aFilters = { },
			aGroups = { { sDBField = "type" } },
			aGroupValueOrder = { },
		},
	},
	-- ["item"] = {
		-- ["armor"] = {
			-- sTitleRes = "item_grouped_title_armor",
			-- aColumns = {
				-- { sName = "name", sType = "string", sHeadingRes = "item_grouped_label_name", nWidth=150 },
				-- { sName = "cost", sType = "string", sHeadingRes = "item_grouped_label_cost", bCentered=true },
				-- { sName = "ac", sType = "number", sHeadingRes = "item_grouped_label_ac", sTooltipRes = "item_grouped_tooltip_ac", nWidth=40, bCentered=true, nSortOrder=1 },
				-- --{ sName = "dexbonus", sType = "string", sHeadingRes = "item_grouped_label_dexbonus", sTooltipRes = "item_grouped_tooltip_dexbonus", nWidth=70, bCentered=true },
				-- --{ sName = "strength", sType = "string", sHeadingRes = "item_grouped_label_strength", sTooltipRes = "item_grouped_tooltip_strength", bCentered=true },
				-- --{ sName = "stealth", sType = "string", sHeadingRes = "item_grouped_label_stealth", sTooltipRes = "item_grouped_tooltip_stealth", nWidth=100, bCentered=true },
				-- { sName = "weight", sType = "number", sHeadingRes = "item_grouped_label_weight", sTooltipRes = "item_grouped_tooltip_weight", nWidth=30, bCentered=true }
			-- },
			-- aFilters = { 
				-- { sDBField = "type", vFilterValue = "Armor" }, 
				-- { sCustom = "item_isidentified" } 
			-- },
			-- aGroups = { { sDBField = "subtype" } },
			-- aGroupValueOrder = { "Light Armor", "Medium Armor", "Heavy Armor", "Shield" },
		-- },
		-- ["weapon"] = {
			-- sTitleRes = "item_grouped_title_weapons",
			-- aColumns = {
				-- { sName = "name", sType = "string", sHeadingRes = "item_grouped_label_name", nWidth=150 },
				-- { sName = "cost", sType = "string", sHeadingRes = "item_grouped_label_cost", bCentered=true },
				-- --{ sName = "damage", sType = "string", sHeadingRes = "item_grouped_label_damage", nWidth=150, bCentered=true },
				-- { sName = "weight", sType = "number", sHeadingRes = "item_grouped_label_weight", sTooltipRes = "item_grouped_tooltip_weight", nWidth=30, bCentered=true },
				-- { sName = "properties", sType = "string", sHeadingRes = "item_grouped_label_properties", nWidth=300, bWrapped=true },
			-- },
			-- aFilters = { 
				-- { sDBField = "type", vFilterValue = "Weapon" }, 
				-- { sCustom = "item_isidentified" } 
			-- },
			-- aGroups = { { sDBField = "subtype" } },
			-- aGroupValueOrder = { "Simple Melee Weapons", "Simple Ranged Weapons", "Martial Weapons", "Martial Melee Weapons", "Martial Ranged Weapons" },
		-- },
		-- ["vehicledrawn"] = {
			-- sTitleRes = "item_grouped_title_vehicledrawn",
			-- aColumns = {
				-- { sName = "name", sType = "string", sHeadingRes = "item_grouped_label_name", nWidth=150 },
				-- { sName = "cost", sType = "string", sHeadingRes = "item_grouped_label_cost", nWidth=70, bCentered=true },
				-- { sName = "speed", sType = "string", sHeadingRes = "item_grouped_label_speed", nWidth=60, bCentered=true },
				-- { sName = "carryingcapacity", sType = "string", sHeadingRes = "item_grouped_label_carryingcapacity", sTooltipRes="item_grouped_tooltip_carryingcapacity", nWidth=70, bCentered=true },
			-- },
			-- aFilters = { { sDBField = "type", vFilterValue = "Mounts And Other Animals" } },
			-- aGroups = { { sDBField = "subtype" } },
			-- aGroupValueOrder = { },
		-- },
		-- ["vehiclemount"] = {
			-- sTitleRes = "item_grouped_title_vehiclemount",
			-- aColumns = {
				-- { sName = "name", sType = "string", sHeadingRes = "item_grouped_label_name", nWidth=150 },
				-- { sName = "cost", sType = "string", sHeadingRes = "item_grouped_label_cost", nWidth=70, bCentered=true },
				-- { sName = "speed", sType = "string", sHeadingRes = "item_grouped_label_speed", nWidth=60, bCentered=true },
				-- { sName = "carryingcapacity", sType = "string", sHeadingRes = "item_grouped_label_carryingcapacity", sTooltipRes="item_grouped_tooltip_carryingcapacity", nWidth=70, bCentered=true },
			-- },
			-- aFilters = { { sDBField = "type", vFilterValue = "Tack, Harness, And Drawn Vehicles" } },
			-- aGroups = { { sDBField = "subtype" } },
			-- aGroupValueOrder = { },
		-- },
		-- ["vehiclewater"] = {
			-- sTitleRes = "item_grouped_title_vehiclewater",
			-- aColumns = {
				-- { sName = "name", sType = "string", sHeadingRes = "item_grouped_label_name", nWidth=150 },
				-- { sName = "cost", sType = "string", sHeadingRes = "item_grouped_label_cost", nWidth=70, bCentered=true },
				-- { sName = "speed", sType = "string", sHeadingRes = "item_grouped_label_speed", nWidth=60, bCentered=true },
				-- { sName = "carryingcapacity", sType = "string", sHeadingRes = "item_grouped_label_carryingcapacity", sTooltipRes="item_grouped_tooltip_carryingcapacity", nWidth=70, bCentered=true },
			-- },
			-- aFilters = { { sDBField = "type", vFilterValue = "Waterborne Vehicles" } },
			-- aGroups = { { sDBField = "subtype" } },
			-- aGroupValueOrder = { },
		-- },
	-- },
};

function onInit()
	LibraryData.setCustomFilterHandler("item_isidentified", getItemIsIdentified);
  for kDefSidebar,vDefSidebar in pairs(aDefaultSidebarState) do
    DesktopManager.setDefaultSidebarState(kDefSidebar, vDefSidebar);
  end
  for kRecordType,vRecordType in pairs(aRecords) do
    LibraryData.setRecordTypeInfo(kRecordType, vRecordType);
  end
	for kRecordType,vRecordListViews in pairs(aListViews) do
		for kListView, vListView in pairs(vRecordListViews) do
			LibraryData.setListView(kRecordType, kListView, vListView);
		end
	end
end
