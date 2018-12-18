--- 
---
---
---

function onInit()
  local node = getDatabaseNode();
  local nodeItem = node.getParent();
-- Debug.console("ref_itemdamage_adnd.lua","onInit","node",node);          
-- Debug.console("ref_itemdamage_adnd.lua","onInit","nodeItem",nodeItem);  
 DB.addHandler(DB.getPath(nodeItem, "weaponlist.*.damagelist"), "onChildUpdate", update);
 DB.addHandler(DB.getPath(nodeItem, "weaponlist.*.damagelist"), "onChildDeleted", update);
 DB.addHandler(DB.getPath(nodeItem, "weaponlist"), "onChildDeleted", update);
 update(nodeItem); 
end

function onClose()
  local node = getDatabaseNode();
  local nodeItem = node.getParent();
  DB.removeHandler(DB.getPath(nodeItem, "weaponlist.*.damagelist"), "onChildUpdate", update);
  DB.removeHandler(DB.getPath(nodeItem, "weaponlist.*.damagelist"), "onChildDeleted", update);
  DB.removeHandler(DB.getPath(nodeItem, "weaponlist"), "onChildDeleted", update);
end

function update(nodeItem)
 setValue(updateDamageString(nodeItem));
end

-- damage changed on a weapon, bulk update
function updateDamageString(nodeField)
  local sDamageAll = "";
--Debug.console("ref_itemdamage_adnd.lua","updateDamageString","nodeField",nodeField);   
  -- these paths could contain module, save that detail
  local sPath, sModule = nodeField.getPath():match("([^@]*)@(.*)");
  if sPath == nil then 
    sPath = nodeField.getPath();
  end
  -- we get nodeField and nodeItem sent, we need to make sure it's
  -- nodeItem (item.id-000001) type
  local sNodePath = sPath:match("^(item%.id%-%d+)");
-- Debug.console("ref_itemdamage_adnd.lua","updateDamageString","sPath",sPath);   
-- Debug.console("ref_itemdamage_adnd.lua","updateDamageString","sModule",sModule);   
-- Debug.console("ref_itemdamage_adnd.lua","updateDamageString","sNodePath",sNodePath);   
  if sNodePath ~= nil then
    local sFindNodePath = sNodePath;
    if (sModule ~= nil) then
      sFindNodePath = sFindNodePath .. "@" .. sModule;
    end;
--Debug.console("ref_itemdamage_adnd.lua","updateDamageString","sFindNodePath",sFindNodePath);   
    local nodeItem = DB.findNode(sFindNodePath);
    if nodeItem then 
--Debug.console("ref_itemdamage_adnd.lua","updateDamageString","nodeItem",nodeItem);   
      --weaponlist
      local aWeaponNodes = UtilityManager.getSortedTable(DB.getChildren(nodeItem, "weaponlist"));
      for _,nodeWeapon in ipairs(aWeaponNodes) do
        local nType = DB.getValue(nodeWeapon,"type",0);
        local sBaseAbility = "strength";
        if nType == 1 then
          sBaseAbility = "dexterity";
        end
        -- flip through all damage entries and update damage display string
        -- also update the weapons "damage" string field to contain them all so
        -- that they show up decently in the item records "weapons" list.
        local aDamageNodes = UtilityManager.getSortedTable(DB.getChildren(nodeWeapon, "damagelist"));
        for _,nodeDMG in ipairs(aDamageNodes) do
          local nMod = DB.getValue(nodeDMG, "bonus", 0);
          local sAbility = DB.getValue(nodeDMG, "stat", "");
          if sAbility == "base" then
            sAbility = sBaseAbility;
          end
          local aDice = DB.getValue(nodeDMG, "dice", {});
          if #aDice > 0 or nMod ~= 0 then
            local sDamage = StringManager.convertDiceToString(DB.getValue(nodeDMG, "dice", {}), nMod);
            local sType = DB.getValue(nodeDMG, "type", "");
            if sType ~= "" then
              sDamage = sDamage .. " " .. sType;
            end
            sDamageAll = sDamageAll .. sDamage .. ";";
          end
        end
      end -- aWeaponNodes
--Debug.console("ref_itemdamage_adnd.lua","updateDamageString","sDamageAll",sDamageAll);     
    end -- nodeItem
  end -- sPath
  return sDamageAll;
end
