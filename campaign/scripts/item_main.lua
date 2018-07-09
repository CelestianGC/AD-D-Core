-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
  update();
end
function onClose()
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

  -- added test because items have attacks now but not other features
  if not self[sControl].update then
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
  local bID = LibraryData.getIDState("item", nodeRecord);
      
  local bWeapon, sTypeLower, sSubtypeLower = ItemManager2.isWeapon(nodeRecord);
  local bArmor = ItemManager2.isArmor(nodeRecord);
  local bArcaneFocus = (sTypeLower == "rod") or (sTypeLower == "staff") or (sTypeLower == "wand");
    -- this is so all the options show when 
    -- editing an item. Allows weapons to have AC/etc.
    bWeapon = true;
    bArmor = true;
    bArcaneFocus = true;
    
    local bPlayer = (not User.isHost());
    local bHost = User.isHost();
    
    -- local sEffectString = DB.getValue(nodeRecord,"abilityeffect","") .. DB.getValue(nodeRecord,"saveeffect","");
    -- effect.setValue(sEffectString);
  
  local bSection1 = false;
  if User.isHost() then
    if updateControl("nonid_name", bReadOnly, true) then bSection1 = true; end;
  else
    updateControl("nonid_name", false);
  end
  if (User.isHost() or not bID) then
    if updateControl("nonidentified", bReadOnly, true) then bSection1 = true; end;
  else
    updateControl("nonidentified", false);
  end

  local bSection2 = false;
  if updateControl("type", bReadOnly, bID) then bSection2 = true; end
    bSection2 = (type.getValue() ~= "");
--Debug.console("item_main.lua","update","bSection2",bSection2);    
--Debug.console("item_main.lua","update","bReadOnly",bReadOnly);    
--Debug.console("item_main.lua","update","bID",bID);    
  if bHost then
    istemplate.setVisible(bID);
    istemplate.setReadOnly(bReadOnly);
        istemplate.setVisible(bSection2 or not bReadOnly);
        template_label.setVisible(bSection2 or not bReadOnly);
        type_label.setVisible(bSection2 or not bReadOnly);
        -- -- show effect features for DM
        -- header_effects.setVisible(true);
        -- effects_iedit.setVisible(true);
        -- effects_list_iadd.setVisible(true);
        -- effects_list.setVisible(true);
  else
        type_label.setVisible(false);
        
        -- -- hide effect features for pcs
        -- header_effects.setVisible(false);
        -- effects_iedit.setVisible(false);
        -- effects_list_iadd.setVisible(false);
        -- effects_list.setVisible(false);
    end
    
  if updateControl("subtype", bReadOnly, bID) then bSection2 = true; end
  if updateControl("rarity", bReadOnly, bID) then bSection2 = true; end
  
  local bSection3 = false;
  if updateControl("cost", bReadOnly, bID) then bSection3 = true; end
  if updateControl("exp", bReadOnly, bID) then bSection3 = true; end
  if updateControl("weight", bReadOnly, bID) then bSection3 = true; end
  
  local bSection4 = false;
  -- if updateControl("effect_combat", bReadOnly, bID) then bSection4 = true; end
  -- if updateControl("effect", bReadOnly, bID) then bSection4 = true; end
    -- if not User.isHost() then
    -- effect.setVisible(bID);
    -- effect_combat.setVisible(bID);
  -- end
  if updateControl("bonus", bReadOnly, bID and (bWeapon or bArmor or bArcaneFocus)) then bSection4 = true; end
  --if updateControl("damage", bReadOnly, bID and bWeapon) then bSection4 = true; end
  --if updateControl("speedfactor", bReadOnly, bID and bWeapon) then bSection4 = true; end
  
  if updateControl("ac", bReadOnly, bID and bArmor) then bSection4 = true; end
  --if updateControl("dexbonus", bReadOnly, bID and bArmor) then bSection4 = true; end
  --if updateControl("strength", bReadOnly, bID and bArmor) then bSection4 = true; end
  --if updateControl("stealth", bReadOnly, bID and bArmor) then bSection4 = true; end
  if updateControl("properties", bReadOnly, bID and (bWeapon or bArmor)) then bSection4 = true; end
  
    local bSection6 = false;
  if updateControl("dmonly", bReadOnly, bID and User.isHost()) then bSection6 = true; end

  local bSection5 = bID;
  description.setVisible(bID);
  description.setReadOnly(bReadOnly);
  
  divider.setVisible(bSection1 and bSection2);
  divider2.setVisible((bSection1 or bSection2) and bSection3);
  divider3.setVisible((bSection1 or bSection2 or bSection3) and bSection4);
    
    header_armorclass.setVisible(bHost and not bReadOnly);
    armor_base_label.setVisible(bHost and not bReadOnly);
    armortype.setVisible(bHost and not bReadOnly);
    armortype_top_label.setVisible(bHost and not bReadOnly);
    acbase.setVisible(bHost and not bReadOnly);
    acbase_top_label.setVisible(bHost and not bReadOnly);
    label_armorplus.setVisible(bHost and not bReadOnly);
    acbonus.setVisible(bHost and not bReadOnly);
    acbonus_top_label.setVisible(bHost and not bReadOnly);
    
    -- header_abilities.setVisible(bHost and not bReadOnly);
    -- item_iedit.setVisible(bHost and not bReadOnly);
    -- ability_list.setVisible(bHost and not bReadOnly);

    -- header_saves.setVisible(bHost and not bReadOnly);
    -- saves_iedit.setVisible(bHost and not bReadOnly);
    -- save_list.setVisible(bHost and not bReadOnly);

    -- local bHasAbilityFeatures = (DB.getChildCount(nodeRecord, "abilitylist") > 0);
    -- local bHasSaveFeatures = (DB.getChildCount(nodeRecord, "savelist") > 0);
    -- if (bHost and not bReadOnly) then
        -- ability_type_label.setVisible(bHasAbilityFeatures);
        -- ability_ability_label.setVisible(bHasAbilityFeatures);
        -- ability_value_label.setVisible(bHasAbilityFeatures);

        -- save_type_label.setVisible(bHasSaveFeatures);
        -- save_save_label.setVisible(bHasSaveFeatures);
        -- save_value_label.setVisible(bHasSaveFeatures);
    -- else
        -- ability_type_label.setVisible(false);
        -- ability_ability_label.setVisible(false);
        -- ability_value_label.setVisible(false);

        -- save_type_label.setVisible(false);
        -- save_save_label.setVisible(false);
        -- save_value_label.setVisible(false);
    -- end

  --divider4.setVisible((bSection1 or bSection2 or bSection3 or bSection4) and bSection5);
  --divider6.setVisible(bSection6);
end

