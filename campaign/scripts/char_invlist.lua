-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sortLocked = false;

function setSortLock(isLocked)
  sortLocked = isLocked;
end

function onInit()
--Debug.console("char_invlist.lua","onInit","getDatabaseNode()",getDatabaseNode());
  onEncumbranceChanged();

  registerMenuItem(Interface.getString("list_menu_createitem"), "insert", 5);

  local node = getDatabaseNode();
  DB.addHandler(DB.getPath(node, "*.isidentified"), "onUpdate", onIDChanged);
  DB.addHandler(DB.getPath(node, "*.bonus"), "onUpdate", onBonusChanged);
  DB.addHandler(DB.getPath(node, "*.ac"), "onUpdate", onArmorChanged);
  DB.addHandler(DB.getPath(node, "*.dexbonus"), "onUpdate", onArmorChanged);
  DB.addHandler(DB.getPath(node, "*.stealth"), "onUpdate", onArmorChanged);
  DB.addHandler(DB.getPath(node, "*.strength"), "onUpdate", onArmorChanged);
  DB.addHandler(DB.getPath(node, "*.carried"), "onUpdate", onCarriedChanged);
  DB.addHandler(DB.getPath(node, "*.weight"), "onUpdate", onEncumbranceChanged);
  DB.addHandler(DB.getPath(node, "*.count"), "onUpdate", onEncumbranceChanged);
end

function onClose()
  -- OptionsManager.unregisterCallback("MIID", StateChanged); -- removed 3.3.6

  local node = getDatabaseNode();
  DB.removeHandler(DB.getPath(node, "*.isidentified"), "onUpdate", onIDChanged);
  DB.removeHandler(DB.getPath(node, "*.bonus"), "onUpdate", onBonusChanged);
  DB.removeHandler(DB.getPath(node, "*.ac"), "onUpdate", onArmorChanged);
  DB.removeHandler(DB.getPath(node, "*.dexbonus"), "onUpdate", onArmorChanged);
  DB.removeHandler(DB.getPath(node, "*.stealth"), "onUpdate", onArmorChanged);
  DB.removeHandler(DB.getPath(node, "*.strength"), "onUpdate", onArmorChanged);
  DB.removeHandler(DB.getPath(node, "*.carried"), "onUpdate", onCarriedChanged);
  DB.removeHandler(DB.getPath(node, "*.weight"), "onUpdate", onEncumbranceChanged);
  DB.removeHandler(DB.getPath(node, "*.count"), "onUpdate", onEncumbranceChanged);
end

function onMenuSelection(selection)
  if selection == 5 then
    addEntry(true);
  end
end

function onIDChanged(nodeField)
  local nodeItem = DB.getChild(nodeField, "..");
  if (DB.getValue(nodeItem, "carried", 0) == 2) and ItemManager2.isArmor(nodeItem) then
    CharManager.calcItemArmorClass(DB.getChild(nodeItem, "..."));
  end
  local bItemIdentified = (DB.getValue(nodeItem, "isidentified",1) == 1); 
  if bItemIdentified then
    CharManager.addToPowerDB(nodeItem);
  else
    CharManager.removeFromPowerDB(nodeItem);
  end
end

function onBonusChanged(nodeField)
  local nodeItem = DB.getChild(nodeField, "..");
  if (DB.getValue(nodeItem, "carried", 0) == 2) and ItemManager2.isArmor(nodeItem) then
    CharManager.calcItemArmorClass(DB.getChild(nodeItem, "..."));
  end
end

-- update armor based on new item in inventory -celestian
function onArmorChanged(nodeField)
  local nodeItem = DB.getChild(nodeField, "..");
  if (DB.getValue(nodeItem, "carried", 0) == 2) and ItemManager2.isArmor(nodeItem) then
    CharManager.calcItemArmorClass(DB.getChild(nodeItem, "..."));
  end
end

function onCarriedChanged(nodeField)
--Debug.console("char_invlist.lua","onCarriedChanged","nodeField",nodeField);
  local nodeChar = DB.getChild(nodeField, "....");
  if nodeChar then
    local nodeItem = DB.getChild(nodeField, "..");

		local nCarried = nodeField.getValue();

		local sCarriedItem = StringManager.trim(ItemManager.getDisplayName(nodeItem)):lower();
		if sCarriedItem ~= "" then
			for _,vNode in pairs(DB.getChildren(nodeChar, "inventorylist")) do
				if vNode ~= nodeItem then
					local sLoc = StringManager.trim(DB.getValue(vNode, "location", "")):lower();
					if sLoc == sCarriedItem then
						DB.setValue(vNode, "carried", "number", nCarried);
					end
				end
			end
		end
		
		if ItemManager2.isArmor(nodeItem) then
			CharManager.calcItemArmorClass(nodeChar);
		end
	end
	
	onEncumbranceChanged();
end

function onEncumbranceChanged()
  if CharManager.updateEncumbrance then
    CharManager.updateEncumbrance(window.getDatabaseNode());
  end
end

function onListChanged()
  update();
  updateContainers();
end

function update()
  local bEditMode = (window.parentcontrol.window.inventory_iedit.getValue() == 1);
  for _,w in ipairs(getWindows()) do
    w.idelete.setVisibility(bEditMode);
  end
end

function addEntry(bFocus)
  local w = createWindow();
  if w then
    if bFocus then
      w.name.setFocus();
    end
  end
  return w;
end

function onClickDown(button, x, y)
  return true;
end

function onClickRelease(button, x, y)
  if not getNextWindow(nil) then
    addEntry(true);
  end
  return true;
end

function onSortCompare(w1, w2)
  if sortLocked then
    return false;
  end
  return ItemManager.onInventorySortCompare(w1, w2);
end

function updateContainers()
  ItemManager.onInventorySortUpdate(self);
end
function onDrop(x, y, draginfo)
  return ItemManager.handleAnyDrop(window.getDatabaseNode(), draginfo);
end