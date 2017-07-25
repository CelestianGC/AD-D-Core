-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sortLocked = false;

function setSortLock(isLocked)
	sortLocked = isLocked;
end

function onInit()
	OptionsManager.registerCallback("MIID", StateChanged);

	onEncumbranceChanged();

	registerMenuItem(Interface.getString("list_menu_createitem"), "insert", 5);

	local node = getDatabaseNode();
Debug.console("char_invlist.lua","onInit","node",node);    

	DB.addHandler(DB.getPath(node, "*.isidentified"), "onUpdate", onIDChanged);
	DB.addHandler(DB.getPath(node, "*.bonus"), "onUpdate", onBonusChanged);
	DB.addHandler(DB.getPath(node, "*.ac"), "onUpdate", onArmorChanged);
	DB.addHandler(DB.getPath(node, "*.dexbonus"), "onUpdate", onArmorChanged);
	DB.addHandler(DB.getPath(node, "*.stealth"), "onUpdate", onArmorChanged);
	DB.addHandler(DB.getPath(node, "*.strength"), "onUpdate", onArmorChanged);
	DB.addHandler(DB.getPath(node, "*.carried"), "onUpdate", onCarriedChanged);
	DB.addHandler(DB.getPath(node, "*.weight"), "onUpdate", onEncumbranceChanged);
	DB.addHandler(DB.getPath(node, "*.count"), "onUpdate", onEncumbranceChanged);
	DB.addHandler(DB.getPath(node), "onChildDeleted", onEncumbranceChanged);
end

function onClose()
	OptionsManager.unregisterCallback("MIID", StateChanged);

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
	DB.removeHandler(DB.getPath(node), "onChildDeleted", onEncumbranceChanged);
end

function onMenuSelection(selection)
	if selection == 5 then
		addEntry(true);
	end
end

function StateChanged()
	for _,w in ipairs(getWindows()) do
		w.onIDChanged();
	end
	applySort();
end

function onIDChanged(nodeField)
Debug.console("char_invlist.lua","onIDChanged","nodeField",nodeField);    
	local nodeItem = DB.getChild(nodeField, "..");
	if (DB.getValue(nodeItem, "carried", 0) == 2) and ItemManager2.isArmor(nodeItem) then
		CharManager.calcItemArmorClass(DB.getChild(nodeItem, "..."));
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
Debug.console("char_invlist.lua","onCarriedChanged","nodeField",nodeField);    
	local nodeChar = DB.getChild(nodeField, "....");
	if nodeChar then
		local nodeItem = DB.getChild(nodeField, "..");

		local nCarried = nodeField.getValue();
		local sCarriedItem = ItemManager.getDisplayName(nodeItem);
		if sCarriedItem ~= "" then
			for _,vNode in pairs(DB.getChildren(nodeChar, "inventorylist")) do
				if vNode ~= nodeItem then
					local sLoc = DB.getValue(vNode, "location", "");
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
	
    updateItemEffects(nodeField);
	onEncumbranceChanged();
end


function updateItemEffects(nodeField)
Debug.console("char_invlist.lua","updateItemEffects","nodeField",nodeField);    
	if EffectManager.updateItemEffects then
		EffectManager.updateItemEffects(nodeField);
	end
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
		w.isidentified.setValue(1);
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

	local n1 = w1.getDatabaseNode();
	local n2 = w2.getDatabaseNode();
	
	local sName1 = ItemManager.getSortName(n1);
	local sName2 = ItemManager.getSortName(n2);
	local sLoc1 = DB.getValue(n1, "location", ""):lower();
	local sLoc2 = DB.getValue(n2, "location", ""):lower();
	
	-- Check for empty name (sort to end of list)
	if sName1 == "" then
		if sName2 == "" then
			return nil;
		end
		return true;
	elseif sName2 == "" then
		return false;
	end
	
	-- If different containers, then figure out containment
	if sLoc1 ~= sLoc2 then
		-- Check for containment
		if sLoc1 == sName2 then
			return true;
		end
		if sLoc2 == sName1 then
			return false;
		end
	
		if sLoc1 == "" then
			return sName1 > sLoc2;
		elseif sLoc2 == "" then
			return sLoc1 > sName2;
		else
			return sLoc1 > sLoc2;
		end
	end

	-- If same container, then sort by name or node id
	if sName1 ~= sName2 then
		return sName1 > sName2;
	end
end

function updateContainers()
	local containermapping = {};

	for _,w in ipairs(getWindows()) do
		if w.name and w.location then
			local entry = {};
			entry.name = w.name.getValue();
			entry.location = w.location.getValue();
			entry.window = w;
			table.insert(containermapping, entry);
		end
	end
	
	local lastcontainer = 1;
	for n, w in ipairs(containermapping) do
		if n > 1 and string.lower(w.location) == string.lower(containermapping[lastcontainer].name) and w.location ~= "" then
			-- Item in a container
			w.window.name.setAnchor("left", nil, "left", "absolute", 45);
		else
			-- Top level item
			w.window.name.setAnchor("left", nil, "left", "absolute", 35);
			lastcontainer = n;
		end
	end
end

function onDrop(x, y, draginfo)
	return ItemManager.handleAnyDrop(window.getDatabaseNode(), draginfo);
end
