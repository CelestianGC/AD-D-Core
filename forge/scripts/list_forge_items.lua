-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onSortCompare(w1, w2)
  local nodeW1 = w1.getDatabaseNode();
  local nodeW2 = w2.getDatabaseNode();
  
  local sRefNode1 = DB.getValue(nodeW1, "refclass", "");
  local sRefNode2 = DB.getValue(nodeW2, "refclass", "");
  if sRefNode1 ~= sRefNode2 then
    return sRefNode1 > sRefNode2;
  end
  local sName1 = DB.getValue(nodeW1, "name", ""):lower();
  local sName2 = DB.getValue(nodeW2, "name", ""):lower();
  if sName1 ~= sName2 then
    return sName1 > sName2;
  end
end

function onDrop(x, y, draginfo)
  if draginfo.getType() == "shortcut" then
    local sClass, sRecord = draginfo.getShortcutData();
    if StringManager.contains({"reference_magicitem", "item"}, sClass) then
      if DB.getValue(DB.findNode(sRecord), "istemplate", 0) == 1 then
        ForgeManagerItem.addTemplate(sClass, sRecord);
        window.templates.updateItemIcons();
      else
        ForgeManagerItem.addBaseItem(sClass, sRecord);
        updateItemIcons();
      end
    elseif ItemManager2.isRefBaseItemClass(sClass) then
      ForgeManagerItem.addBaseItem(sClass, sRecord);
      updateItemIcons();
    elseif sClass == "reference_spell" then
      ForgeManagerItem.addTemplate(sClass, sRecord);
      window.templates.updateItemIcons();
    end
  end
  return true;
end

function onListChanged()
  update();
  window.statusicon.setIndex(0);
  window.status.setValue("");
end

function update()
  local bEditMode = (window.items_iedit.getValue() == 1);
  for _,w in ipairs(getWindows()) do
    w.idelete.setVisibility(bEditMode);
  end
end

function addEntry(bFocus)
  local w = createWindow();
  if bFocus and w then
    w.name.setFocus();
  end
  return w;
end

function updateItemIcons()
  for _,v in pairs(getWindows()) do
    v.itemtype.update();
  end  
end

