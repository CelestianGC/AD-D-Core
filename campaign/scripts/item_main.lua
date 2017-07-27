-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
    local nodeRecord = getDatabaseNode();
    DB.addHandler(DB.getPath(nodeRecord, "abilitylist"), "onChildUpdate", update);
    --DB.addHandler(DB.getPath(nodeRecord, "abilitylist"), "onChildAdded", update);
    --DB.addHandler(DB.getPath(nodeRecord, "abilitylist"), "onChildDeleted", update);
	update();
end
function onClose()
    local nodeRecord = getDatabaseNode();
    DB.removeHandler(DB.getPath(nodeRecord, "abilitylist"), "onChildUpdate", update);
    --DB.removeHandler(DB.getPath(nodeRecord, "abilitylist"), "onChildAdded", update);
    --DB.removeHandler(DB.getPath(nodeRecord, "abilitylist"), "onChildDeleted", update);
end

function VisDataCleared()
	update();
end

function InvisDataAdded()
	update();
end

function updateControl(sControl, bReadOnly, bID)
	if not self[sControl] then
		return false;
	end
		
	if not bID then
		return self[sControl].update(bReadOnly, true);
	end
	
	return self[sControl].update(bReadOnly);
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	local bID, bOptionID = LibraryData.getIDState("item", nodeRecord);
	
	local bWeapon, sTypeLower, sSubtypeLower = ItemManager2.isWeapon(nodeRecord);
	local bArmor = ItemManager2.isArmor(nodeRecord);
	local bArcaneFocus = (sTypeLower == "rod") or (sTypeLower == "staff") or (sTypeLower == "wand");
    -- this is so all the options show when 
    -- editing an item. Allows weapons to have AC/etc.
    bWeapon = true;
    bArmor = true;
    bArcaneFocus = true;
	
	local bSection1 = false;
	if bOptionID and User.isHost() then
		if updateControl("nonid_name", bReadOnly, true) then bSection1 = true; end;
	else
		updateControl("nonid_name", false);
	end
	if bOptionID and (User.isHost() or not bID) then
		if updateControl("nonidentified", bReadOnly, true) then bSection1 = true; end;
	else
		updateControl("nonidentified", false);
	end

	local bSection2 = false;
	if updateControl("type", bReadOnly, bID) then bSection2 = true; end
	if User.isHost() then
		istemplate.setVisible(bID);
		istemplate.setReadOnly(bReadOnly);
	end
	if updateControl("subtype", bReadOnly, bID) then bSection2 = true; end
	if updateControl("rarity", bReadOnly, bID) then bSection2 = true; end
	
	local bSection3 = false;
	if updateControl("effect", bReadOnly, bID) then bSection3 = true; end
	if updateControl("cost", bReadOnly, bID) then bSection3 = true; end
	if updateControl("weight", bReadOnly, bID) then bSection3 = true; end
	
	local bSection4 = false;
	if updateControl("bonus", bReadOnly, bID and (bWeapon or bArmor or bArcaneFocus)) then bSection4 = true; end
	--if updateControl("damage", bReadOnly, bID and bWeapon) then bSection4 = true; end
	--if updateControl("speedfactor", bReadOnly, bID and bWeapon) then bSection4 = true; end
	
	if updateControl("ac", bReadOnly, bID and bArmor) then bSection4 = true; end
	--if updateControl("dexbonus", bReadOnly, bID and bArmor) then bSection4 = true; end
	--if updateControl("strength", bReadOnly, bID and bArmor) then bSection4 = true; end
	--if updateControl("stealth", bReadOnly, bID and bArmor) then bSection4 = true; end

	if updateControl("properties", bReadOnly, bID and (bWeapon or bArmor)) then bSection4 = true; end
	
	local bSection5 = bID;
	description.setVisible(bID);
	description.setReadOnly(bReadOnly);
	
	divider.setVisible(bSection1 and bSection2);
	divider2.setVisible((bSection1 or bSection2) and bSection3);
	divider3.setVisible((bSection1 or bSection2 or bSection3) and bSection4);
    
    header_armorclass.setVisible(not bReadOnly);
    armor_base_label.setVisible(not bReadOnly);
    armortype.setVisible(not bReadOnly);
    --armortype_top_label.setVisible(not bReadOnly);
    acbase.setVisible(not bReadOnly);
    --acbase_top_label.setVisible(not bReadOnly);
    label_armorplus.setVisible(not bReadOnly);
    acbonus.setVisible(not bReadOnly);
    --acbonus_top_label.setVisible(not bReadOnly);
    
    header_abilities.setVisible(not bReadOnly);
    item_iedit.setVisible(not bReadOnly);
    ability_list.setVisible(not bReadOnly);

    local bHasAbilityFeatures = (DB.getChildCount(nodeRecord, "abilitylist") > 0);
    if (not bReadOnly) then
        ability_type_label.setVisible(bHasAbilityFeatures);
        ability_ability_label.setVisible(bHasAbilityFeatures);
        ability_value_label.setVisible(bHasAbilityFeatures);
    else
        ability_type_label.setVisible(false);
        ability_ability_label.setVisible(false);
        ability_value_label.setVisible(false);
    end

	divider6.setVisible((bSection1 or bSection2 or bSection3 or bSection4) and bSection5);
    
    updateAbilityEffects();
end

function updateAbilityEffects()
    local nodeRecord = getDatabaseNode();
Debug.console("item_main.lua","updateAbilityEffects","nodeRecord",nodeRecord);

    local sEffectString = "";
    for _,aEffect in pairs(DB.getChildren(nodeRecord, "abilitylist")) do
        local sType = DB.getValue(aEffect,"type","");
        local sAbility = DB.getValue(aEffect,"ability","");
        local nModifier = DB.getValue(aEffect,"value",0);
        local sTypeChar = "";
        
        if (sType == "modifier") then
            sTypeChar = "";
        elseif (sType == "percent_modifier") then
            sTypeChar = "P";
        elseif (sType == "base") then 
            sTypeChar = "B";
        elseif (sType == "base_percent") then
            sTypeChar = "BP";
        end
        
Debug.console("item_main.lua","updateAbilityEffects","sType",sType);
Debug.console("item_main.lua","updateAbilityEffects","sAbility",sAbility);
Debug.console("item_main.lua","updateAbilityEffects","nModifier",nModifier);
        sEffectString = sEffectString .. sTypeChar .. sAbility:upper() .. ": " .. nModifier .. ";";
    end -- end for
    DB.setValue(nodeRecord,"effect","string",sEffectString);
end
