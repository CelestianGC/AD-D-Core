-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()

  DB.addHandler(DB.getPath(getDatabaseNode()), "onChildAdded", onChildAdded);
  DB.addHandler(DB.getPath(window.getDatabaseNode(), "profbonus"), "onUpdate", onProfChanged);
  
  onModeChanged();
end

function onClose()
  DB.removeHandler(DB.getPath(getDatabaseNode()), "onChildAdded", onChildAdded);
  DB.removeHandler(DB.getPath(window.getDatabaseNode(), "profbonus"), "onUpdate", onProfChanged);
end

function onChildAdded()
  onModeChanged();
  update();
end

function onProfChanged()
  for _,w in pairs(getWindows()) do
    w.onAttackChanged();
  end
end

function onListChanged()
  update();
end

function onModeChanged()
    local node = window.getDatabaseNode();
  --local bPrepMode = (DB.getValue(node, "powermode", "") == "preparation");
    local bPrepMode = false; -- dont show prep unless in npc/char/combat tracker sheets
    --celestian
--Debug.console("char_weaponslist.lua","onModeChanged","node",node);    
   -- dont show prep unless in npc/char/combat tracker sheets
    if string.match(node.getPath(),"^npc") or string.match(node.getPath(),"^charsheet") or string.match(node.getPath(),"^combattracker") then
      bPrepMode = true;
    end
    
  for _,w in ipairs(getWindows()) do
    --w.carried.setVisible(bPrepMode);
    w.carried.setVisible(bPrepMode);
  end
  
  applyFilter();
end

function update()
  if window.parentcontrol.window.actions_iedit then
    local bEditMode = (window.parentcontrol.window.actions_iedit.getValue() == 1);
    for _,w in pairs(getWindows()) do
      w.idelete.setVisibility(bEditMode);
    end
  end
end

function addEntry(bFocus)
  local w = createWindow();
  if bFocus and w then
    w.name.setFocus();
  end
  -- this will add a story entry to the manually created attack so that
  -- we can add notes there for npc info/shortcut buttons
  if (w) then
    local node = getDatabaseNode();
--Debug.console("char_weaponslist.lua","addEntry","node",node );  
    local nodeItem = node.getParent();
    if string.match(nodeItem.getPath(),"^item") ~= nil then
--Debug.console("char_weaponslist.lua","addEntry","nodeItem",nodeItem);  
      local nodeWeapon = w.getDatabaseNode();
--Debug.console("char_weaponslist.lua","addEntry","nodeWeapon",nodeWeapon);  
      local sItemName = DB.getValue(nodeItem,"name","");
      local sItemText = DB.getValue(nodeItem,"description","");
      DB.setValue(nodeWeapon,"name","string", sItemName);
      DB.setValue(nodeWeapon,"itemnote.name","string",sItemName);
      DB.setValue(nodeWeapon,"itemnote.text","formattedtext",sItemText);
      DB.setValue(nodeWeapon,"itemnote.locked","number",1);
      --DB.setValue(nodeWeapon, "shortcut", "windowreference", "quicknote", nodeWeapon.getPath() .. '.itemnote');
    elseif string.match(nodeItem.getPath(),"^npc") ~= nil then
      local nodeWeapon = w.getDatabaseNode();
      DB.setValue(nodeWeapon,"itemnote.name","string",'Attack');
      DB.setValue(nodeWeapon,"itemnote.text","formattedtext",'');
      DB.setValue(nodeWeapon,"itemnote.locked","number",1);
    end
  end
  return w;
end


function onDrop(x, y, draginfo)
--Debug.console("char_weaponslist.lua","onDrop","draginfo",draginfo );
  if draginfo.isType("shortcut") then
    local sClass, sRecord = draginfo.getShortcutData();
    local node = getDatabaseNode().getParent();

    -- match items dropped into item/class/background fields to populate damage/etc but not add to inventory
    if ((string.match(node.getPath(),"^npc") or string.match(node.getPath(),"^combattracker%.")) and not Input.isControlPressed()) or
        string.match(node.getPath(),"^item") or 
        string.match(node.getPath(),"^treasureparcels") or 
        string.match(node.getPath(),"^class") or 
        string.match(node.getPath(),"^background") then
      -- load item
      local nodeItem = DB.findNode(sRecord);
      if nodeItem then
        local sItemName = DB.getValue(nodeItem,"name","UNKNOWN");
        local sDesc = DB.getValue(nodeItem,"description","");
        local nodeWeapons = node.createChild("weaponlist");
        for _,v in pairs(DB.getChildren(nodeItem, "weaponlist")) do
          local nodeWeapon = nodeWeapons.createChild();
          DB.copyNode(v,nodeWeapon);
          DB.setValue(nodeWeapon,"name","string",sItemName);
          DB.setValue(nodeWeapon,"itemnote.name","string",sItemName);
          DB.setValue(nodeWeapon,"itemnote.text","formattedtext",sDesc);
          DB.setValue(nodeWeapon,"itemnote.locked","number",1);
          local sThisID = nodeWeapon.getPath():match("(%.weaponlist%.id%-%d+)$");
          local sNotePath = nodeWeapon.getPath();
          if (sThisID and sThisID ~= "") then
            sNotePath = "..." .. sThisID;
          end
          --DB.setValue(nodeWeapon, "shortcut", "windowreference", "quicknote", nodeWeapon.getPath() .. '.itemnote');
          DB.setValue(nodeWeapon, "shortcut", "windowreference", "quicknote", sNotePath .. '.itemnote');
        end
        -- add powers
        local nodePowers = node.createChild("powers");
        for _,nodePowerSource in pairs(DB.getChildren(nodeItem, "powers")) do
          local nodePower = nodePowers.createChild();
          DB.copyNode(nodePowerSource,nodePower);
          -- DB.setValue(nodePower,"name","string",sItemName);
          -- this overwrites spell descriptions, I don't think we need this? --celestian
          -- only set the description if the description doesn't exist.
          if (not DB.getValue(nodePower,"description")) then 
            DB.setValue(nodePower,"description","formattedtext",sDesc);
          end
          DB.setValue(nodePower,"locked","number",1);
        end
        return true;
      end
    -- otherwise it's a item on a npc/character and we need to deal with inventory/etc
    elseif LibraryData.isRecordDisplayClass("item", sClass) and ItemManager2.isWeapon(sRecord) then
      return ItemManager.handleAnyDrop(window.getDatabaseNode(), draginfo);
    end
  end
end

function onFilter(w)
    -- this hides custom entries that are not actual items. I like to have them visible everywhere because
    -- of things like adding "weapons" for unarmed combat or something similar.
    -- because of that I've commented it out so that they are never hidden   --celestian
  -- if (DB.getValue(window.getDatabaseNode(), "powermode", "") == "combat") and (w.carried.getValue() < 2) then
    -- return false;
  -- end
  return true;
end
