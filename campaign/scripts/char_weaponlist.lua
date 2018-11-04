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
    local bPrepMode = true; -- I wanna have equipped/carried item view always, so set this to always true 
    --celestian
    
    -- if this is a item record, we don't go into prepmode for carried
    if string.match(node.getPath(),"^item") or string.match(node.getPath(),"^class") or string.match(node.getPath(),"^background") then
        bPrepMode = false;
    end
    
  for _,w in ipairs(getWindows()) do
    --w.carried.setVisible(bPrepMode);
    w.carried.setVisible(true);
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
    local nodeWeapon = w.getDatabaseNode();
    DB.setValue(nodeWeapon, "shortcut", "windowreference", "quicknote", nodeWeapon.getPath() .. '.itemnote');
  end
  return w;
end


function onDrop(x, y, draginfo)
--Debug.console("char_weaponslist.lua","onDrop","draginfo",draginfo );
  if draginfo.isType("shortcut") then
    local sClass, sRecord = draginfo.getShortcutData();
    local node = getDatabaseNode().getParent();
--Debug.console("char_weaponslist.lua","onDrop","sClass",sClass );
--Debug.console("char_weaponslist.lua","onDrop","sRecord",sRecord );
--Debug.console("char_weaponslist.lua","onDrop","node",node );
    -- match items dropped into item/class/background fields to populate damage/etc
    if string.match(node.getPath(),"^item") or 
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
          DB.setValue(nodeWeapon, "shortcut", "windowreference", "quicknote", nodeWeapon.getPath() .. '.itemnote');
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
