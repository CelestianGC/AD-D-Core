-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local aGroups = {};
local aCharSlots = {};

local bCheckingUsage = false;
local bUpdatingGroups = false;

function onInit()
	updatePowerGroups();

	local node = getDatabaseNode();
	
	DB.addHandler(DB.getPath(node, "level"), "onUpdate", onAbilityChanged);
	DB.addHandler(DB.getPath(node, "abilities.*.score"), "onUpdate", onAbilityChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.stat"), "onUpdate", onAbilityChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.atkstat"), "onUpdate", onAbilityChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.atkprof"), "onUpdate", onAbilityChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.atkmod"), "onUpdate", onAbilityChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.savestat"), "onUpdate", onAbilityChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.saveprof"), "onUpdate", onAbilityChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.savemod"), "onUpdate", onAbilityChanged);

	DB.addHandler(DB.getPath(node, "powergroup"), "onChildAdded", onGroupListChanged);
	DB.addHandler(DB.getPath(node, "powergroup"), "onChildDeleted", onGroupListChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.name"), "onUpdate", onGroupNameChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.castertype"), "onUpdate", onGroupTypeChanged);

	DB.addHandler(DB.getPath(node, "powergroup.*.uses"), "onUpdate", onUsesChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.usesperiod"), "onUpdate", onUsesChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.slots1"), "onUpdate", onUsesChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.slots2"), "onUpdate", onUsesChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.slots3"), "onUpdate", onUsesChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.slots4"), "onUpdate", onUsesChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.slots5"), "onUpdate", onUsesChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.slots6"), "onUpdate", onUsesChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.slots7"), "onUpdate", onUsesChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.slots8"), "onUpdate", onUsesChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.slots9"), "onUpdate", onUsesChanged);
	DB.addHandler(DB.getPath(node, "powers.*.cast"), "onUpdate", onUsesChanged);
	DB.addHandler(DB.getPath(node, "powers.*.prepared"), "onUpdate", onUsesChanged);
	DB.addHandler(DB.getPath(node, "powermeta.*.max"), "onUpdate", onUsesChanged);
	DB.addHandler(DB.getPath(node, "powermeta.*.used"), "onUpdate", onUsesChanged);

	DB.addHandler(DB.getPath(node, "powers.*.group"), "onUpdate", onPowerGroupChanged);
	DB.addHandler(DB.getPath(node, "powers.*.level"), "onUpdate", onPowerGroupChanged);
	DB.addHandler(DB.getPath(node, "powers.*.memorized"), "onUpdate", onPowerGroupChanged);
	DB.addHandler(DB.getPath(node, "powers.*.wasmemorized"), "onUpdate", onPowerGroupChanged);
end

function onClose()
	local node = getDatabaseNode();
	
	DB.removeHandler(DB.getPath(node, "level"), "onUpdate", onAbilityChanged);
	DB.removeHandler(DB.getPath(node, "abilities.*.score"), "onUpdate", onAbilityChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.stat"), "onUpdate", onAbilityChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.atkstat"), "onUpdate", onAbilityChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.atkprof"), "onUpdate", onAbilityChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.atkmod"), "onUpdate", onAbilityChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.savestat"), "onUpdate", onAbilityChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.saveprof"), "onUpdate", onAbilityChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.savemod"), "onUpdate", onAbilityChanged);

	DB.removeHandler(DB.getPath(node, "powergroup"), "onChildAdded", onGroupListChanged);
	DB.removeHandler(DB.getPath(node, "powergroup"), "onChildDeleted", onGroupListChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.name"), "onUpdate", onGroupNameChanged);
	
	DB.removeHandler(DB.getPath(node, "powergroup.*.castertype"), "onUpdate", onGroupTypeChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.uses"), "onUpdate", onUsesChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.usesperiod"), "onUpdate", onUsesChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.slots1"), "onUpdate", onUsesChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.slots2"), "onUpdate", onUsesChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.slots3"), "onUpdate", onUsesChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.slots4"), "onUpdate", onUsesChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.slots5"), "onUpdate", onUsesChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.slots6"), "onUpdate", onUsesChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.slots7"), "onUpdate", onUsesChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.slots8"), "onUpdate", onUsesChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.slots9"), "onUpdate", onUsesChanged);
	DB.removeHandler(DB.getPath(node, "powers.*.cast"), "onUpdate", onUsesChanged);
	DB.removeHandler(DB.getPath(node, "powers.*.prepared"), "onUpdate", onUsesChanged);
	DB.removeHandler(DB.getPath(node, "powermeta.*.max"), "onUpdate", onUsesChanged);
	DB.removeHandler(DB.getPath(node, "powermeta.*.used"), "onUpdate", onUsesChanged);

	DB.removeHandler(DB.getPath(node, "powers.*.group"), "onUpdate", onPowerGroupChanged);
	DB.removeHandler(DB.getPath(node, "powers.*.level"), "onUpdate", onPowerGroupChanged);
	DB.removeHandler(DB.getPath(node, "powers.*.memorized"), "onUpdate", onPowerGroupChanged);
	DB.removeHandler(DB.getPath(node, "powers.*.wasmemorized"), "onUpdate", onPowerGroupChanged);
end

function onAbilityChanged()
	for _,v in pairs(powers.getWindows()) do
		if v.getClass() ~= "power_group_header" then
			if v.header.subwindow then
				for _,v2 in pairs(v.header.subwindow.actionsmini.getWindows()) do
					v2.updateViews();
				end
			end
			for _,v2 in pairs(v.actions.getWindows()) do
				v2.updateViews();
			end
		end
	end
end

function onModeChanged()
	rebuildGroups();
	updateUses();
end

function onDisplayChanged()
	for _,v in pairs(powers.getWindows()) do
		if v.getClass() ~= "power_group_header" then
			v.onDisplayChanged(v);
		end
	end
end

function onUsesChanged()
	rebuildGroups();
	updateUses();
end

function onGroupListChanged()
	updatePowerGroups();
end

function onGroupTypeChanged()
	updatePowerGroups();
end

function onGroupNameChanged(nodeGroupName)
	if bUpdatingGroups then
		return;
	end
	bUpdatingGroups = true;

	local nodeParent = nodeGroupName.getParent();
	local sNode = nodeParent.getNodeName();
	
	local nodeGroup = nil;
	local sOldValue = "";
	for sGroup, vGroup in pairs(aGroups) do
		if vGroup.nodename == sNode then
			nodeGroup = vGroup.node;
			sOldValue = sGroup;
			break;
		end
	end
	if not nodeGroup or sGroup == "" then
		return;
	end

	local sNewValue = DB.getValue(nodeParent, "name", "");
	for _,v in pairs(powers.getWindows()) do
		if v.group.getValue() == sOldValue then
			v.group.setValue(sNewValue);
		end
	end

	bUpdatingGroups = false;
	
	updatePowerGroups();
end

function onPowerListChanged()
	updatePowerGroups();
	updateDisplay();
end

function onPowerGroupChanged(node)
	updatePowerGroups();
end

function addPower(bFocus)
	local w = powers.createWindow();
	if bFocus then
		w.name.setFocus();
	end
	return w;
end

function addGroupPower(sGroup, nLevel)
	local w = powers.createWindow();
	w.level.setValue(nLevel);
	w.group.setValue(sGroup);
	w.name.setFocus();
	return w;
end

function updateDisplay()
	if parentcontrol.window.parentcontrol.window.actions_iedit then
		local bEditMode = (parentcontrol.window.parentcontrol.window.actions_iedit.getValue() == 1);
		for _,w in ipairs(powers.getWindows()) do
			if w.getClass() == "power_group_header" then
				w.iadd.setVisible(bEditMode);
			else
				w.idelete.setVisibility(bEditMode);
			end
		end
	end
end

function updatePowerGroups()
	if bUpdatingGroups then
		return;
	end
	bUpdatingGroups = true;
	
	rebuildGroups();

	-- Determine all the groups accounted for by current powers
	local aPowerGroups = {};
	for _,nodePower in pairs(DB.getChildren(getDatabaseNode(), "powers")) do
		local sGroup = DB.getValue(nodePower, "group", "");
		if sGroup ~= "" then
			aPowerGroups[sGroup] = true;
		end
	end
	
	-- Remove the groups that already exist
	for _,vGroup in pairs(aGroups) do
		if aPowerGroups[sGroup] then
			aPowerGroups[sGroup] = nil;
		end
	end
	
	-- For the remaining power groups, that aren't named
	local sLowerSpellsLabel = Interface.getString("power_label_groupspells"):lower();
	for k,_ in pairs(aPowerGroups) do
		if not aGroups[k] then
			local nodeGroups = DB.createChild(getDatabaseNode(), "powergroup");
			local nodeNewGroup = nodeGroups.createChild();
			DB.setValue(nodeNewGroup, "name", "string", k);
			if sLowerSpellsLabel == k:lower() then
				DB.setValue(nodeNewGroup, "castertype", "string", "memorization");
			end
		end
	end
	
	rebuildGroups();

	bUpdatingGroups = false;

	updateHeaders();
	updateUses();
end

function updateHeaders()
	if bUpdatingGroups then
		return;
	end
	bUpdatingGroups = true;
	
	-- Close all category headings
	for _,v in pairs(powers.getWindows()) do
		if v.getClass() == "power_group_header" then
			v.close();
		end
	end

	-- Create new category headings
	local aCategoryWindows = {};
	local aGroupShown = {};
	for _,nodePower in pairs(DB.getChildren(getDatabaseNode(), "powers")) do
		local sCategory, sGroup, nLevel = getWindowSortByNode(nodePower);
		
		if not aCategoryWindows[sCategory] then
			local wh = powers.createWindowWithClass("power_group_header");
			if wh then
				wh.setHeaderCategory(aGroups[sGroup], sGroup, nLevel);
			end
			aCategoryWindows[sCategory] = wh;
			aGroupShown[sGroup] = true;
		end
	end
	
	-- Create empty category headings
	for k,v in pairs(aGroups) do
		if not aGroupShown[k] then
			local wh = powers.createWindowWithClass("power_group_header");
			if wh then
				wh.setHeaderCategory(v, k, nil, true);
			end
		end
	end

	bUpdatingGroups = false;

	powers.applySort();
end

function onPowerWindowAdded(w)
	updatePowerWindowDisplay(w);
	updatePowerWindowUses(getDatabaseNode(), w);
end

function updatePowerWindowDisplay(w)
	if parentcontrol.window.parentcontrol.window.actions_iedit then
		local bEditMode = (parentcontrol.window.parentcontrol.window.actions_iedit.getValue() == 1);
		w.idelete.setVisibility(bEditMode);
	end
end

function updatePowerWindowUses(nodeChar, w)
	local sMode = DB.getValue(nodeChar, "powermode", "");
	local bShow = true;

    local bisNPC = (not ActorManager.isPC(nodeChar)); 
    
	-- Get power information
	local sGroup = w.group.getValue();
	local nLevel = w.level.getValue();
    
	local nCast = w.cast.getValue();
	local nPrepared = w.prepared.getValue();
	local sUsesPeriod = w.usesperiod.getValue();
    local nodeSpell = w.getDatabaseNode();
    local nMemorizedCount = DB.getValue(nodeSpell,"memorized",0);
	local nWasMemorized = DB.getValue(nodeSpell,"wasmemorized",0);
    
	-- Get the power group, and whether it's a caster group
	local rGroup = aGroups[sGroup];
	local bCaster = (rGroup and rGroup.grouptype ~= "");

	-- Get group meta usage information
	local nAvailable = 0;
	local nTotalCast = 0;
	local nTotalPrepared = 0;
	if bCaster then
		if nLevel >= 1 and nLevel <= PowerManager.SPELL_LEVELS then
			nAvailable = aCharSlots[nLevel].nMax;
			nTotalCast = (aCharSlots[nLevel].nTotalCast or 0);
			nTotalPrepared = (aCharSlots[nLevel].nTotalPrepared or 0);
		end
	elseif rGroup then
		nAvailable = rGroup.nAvailable;
		nTotalCast = rGroup.nTotalCast;
		nTotalPrepared = rGroup.nTotalPrepared;
		sUsesPeriod = rGroup.sUsesPeriod;
	end

	-- SPELL CLASS
	if bCaster then
		if sMode == "combat" then
			if nLevel > 0 then
                if rGroup.nPrepared > 0 and nPrepared <= 0 then
					bShow = false;
				else
                -- we don't want to hide because there are no slots "unused" because
                -- I use the slots as memorization slots now which means they are tic'distribution
                -- if they have one memorized. 
                -- AD&D style, -celestian
					-- local bValidSlot = false;
					-- for i = nLevel, PowerManager.SPELL_LEVELS do
						-- if (aCharSlots[i].nTotalCast or 0) < aCharSlots[i].nMax then
							-- bValidSlot = true;
							-- break;
						-- end
					-- end
					-- if not bValidSlot then
						-- bShow = false;
					-- end
                    if (nMemorizedCount <= 0 and nWasMemorized == 0 and not bisNPC) then
                        bShow = false;
                    end
				end
                
			else
				bShow = true;
			end
		elseif sMode == "preparation" then
			bShow = true;
		else
			bShow = true;
		end
	
	-- ABILITY GROUP
	else
		if sMode == "combat" then
            -- got alert of compare number with nil here... test
            -- there is some edge case where one of these is nil
            -- so this will make sure it doesn't happen.
            if nTotalCast == nil then
                nTotalCast = 0;
            end
            if nAvailable == nil then
                nAvailable = 0;
            end
            -- nil kludge tweak --celestian
			if rGroup and 
                (nTotalCast >= nAvailable) and 
                                (nAvailable > 0) then 
				bShow = false;
			elseif (nCast >= nPrepared) and (nPrepared > 0) then
				bShow = false;
			end
		elseif sMode == "preparation" then
			bShow = true;
		else
			bShow = true;
		end
	end
	w.setFilter(bShow);
	
	if bCaster then
		if w.header.subwindow.prepared.getValue() > 1 then
			w.header.subwindow.prepared.setValue(1);
		end
		w.header.subwindow.prepared.setVisible(false);
		w.header.subwindow.usesperiod.setVisible(false);
		w.header.subwindow.counter.setVisible(false);
		if sMode == "preparation" then
			if nLevel == 0 then
				w.header.subwindow.preparedcheck.setVisible(false);
				w.header.subwindow.usepower.setVisible(false);
				w.header.subwindow.blank.setVisible(true);
			else
				w.header.subwindow.preparedcheck.setVisible(true);
				w.header.subwindow.usepower.setVisible(false);
				w.header.subwindow.blank.setVisible(false);
			end
		else
			w.header.subwindow.preparedcheck.setVisible(false);
			if nLevel == 0 or (w.header.subwindow.preparedcheck.getValue() > 0) then
				w.header.subwindow.usepower.setVisible(true);
				w.header.subwindow.blank.setVisible(false);
			else
				w.header.subwindow.usepower.setVisible(false);
				w.header.subwindow.blank.setVisible(true);
			end
		end
	else
		w.header.subwindow.blank.setVisible(false);
		if sMode == "preparation" then
			w.header.subwindow.prepared.setVisible(true);
			w.header.subwindow.usepower.setVisible(false);
			w.header.subwindow.counter.setVisible(false);
			if rGroup and (nAvailable > 0) then
				w.header.subwindow.usesperiod.setVisible(false);
			else
				w.header.subwindow.usesperiod.setVisible(true);
			end
		else
			w.header.subwindow.prepared.setVisible(false);
			w.header.subwindow.usesperiod.setVisible(false);
			if nAvailable > 0 then
				w.header.subwindow.usepower.setVisible(false);
				w.header.subwindow.counter.setVisible(true);
				if nPrepared > 0 then
					w.header.subwindow.counter.update(sMode, true, math.min(nAvailable, nPrepared), nTotalCast, nTotalPrepared);
				else
					w.header.subwindow.counter.update(sMode, true, nAvailable, nTotalCast, nTotalPrepared);
				end
			elseif nPrepared > 0 then
				w.header.subwindow.usepower.setVisible(false);
				w.header.subwindow.counter.setVisible(true);
				w.header.subwindow.counter.update(sMode, true, nPrepared, nCast, nPrepared);
			else
				w.header.subwindow.usepower.setVisible(true);
				w.header.subwindow.counter.setVisible(false);
			end
		end
	end
    
	return bShow;
end

function updateUses()
	if bCheckingUsage then
		return;
	end
	bCheckingUsage = true;
	
	-- Prepare for lots of crunching
	local nodeChar = getDatabaseNode();
	local sMode = DB.getValue(nodeChar, "powermode", "");
	
	-- Add power counts, total cast and total prepared per group/slot
	for _,v in pairs(DB.getChildren(nodeChar, "powers")) do
		local sGroup = DB.getValue(v, "group", "");
		local rGroup = aGroups[sGroup];
		if rGroup then
			local nCast = DB.getValue(v, "cast", 0);
			local nPrepared = DB.getValue(v, "prepared", 0);
			if rGroup.grouptype == "" then
				rGroup.nCount = (rGroup.nCount or 0) + 1;
				rGroup.nTotalCast = (rGroup.nTotalCast or 0) + nCast;
				rGroup.nTotalPrepared = (rGroup.nTotalPrepared or 0) + nPrepared;
			else
				local nLevel = DB.getValue(v, "level", 0);
				if nLevel >= 1 and nLevel <= PowerManager.SPELL_LEVELS then
					aCharSlots[nLevel].nCount = (aCharSlots[nLevel].nCount or 0) + 1;
					aCharSlots[nLevel].nTotalPrepared = (aCharSlots[nLevel].nTotalPrepared or 0) + nPrepared;
					aCharSlots[nLevel].nTotalCast = DB.getValue(nodeChar, "powermeta.spellslots" .. nLevel .. ".used", 0) + DB.getValue(nodeChar, "powermeta.pactmagicslots" .. nLevel .. ".used", 0);
				end
			end
		end
	end
	
	local aCasterGroupSpellsShown = {};
	
	-- Show/hide powers based on findings
	for _,v in pairs(powers.getWindows()) do
		if v.getClass() ~= "power_group_header" then
			if updatePowerWindowUses(nodeChar, v) then
				local sGroup = v.group.getValue();
				local rGroup = aGroups[sGroup];
				local bCaster = (rGroup and rGroup.grouptype ~= "");
				
				if bCaster then
					if not aCasterGroupSpellsShown[sGroup] then
						aCasterGroupSpellsShown[sGroup] = {};
					end
					local nLevel = v.level.getValue();
					aCasterGroupSpellsShown[sGroup][nLevel] = (aCasterGroupSpellsShown[sGroup][nLevel] or 0) + 1;
				elseif rGroup then
					rGroup.nShown = (rGroup.nShown or 0) + 1;
				end
			end
		end
	end
	
	-- Hide headers with no spells
	for _,v in pairs(powers.getWindows()) do
		if v.getClass() == "power_group_header" then
			local sGroup = v.group.getValue();
			local rGroup = aGroups[sGroup];
			local bCaster = (rGroup and rGroup.grouptype ~= "");
			
			local bShow = true;

			if sMode == "combat" then
				if bCaster then
					local nLevel = v.level.getValue();
					if not aCasterGroupSpellsShown[sGroup] or (aCasterGroupSpellsShown[sGroup][nLevel] or 0) <= 0 then
						bShow = false;
					end
				elseif rGroup then
					bShow = ((rGroup.nShown or 0) > 0);
				end
			end
			v.setFilter(bShow);
		end
	end
	
	powers.applyFilter();
	
	bCheckingUsage = false;
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local sClass = draginfo.getShortcutData();
		if sClass == "reference_spell" or sClass == "power" then
			bUpdatingGroups = true;
			draginfo.setSlot(2);
			local sGroup = draginfo.getStringData();
			draginfo.setSlot(1);
			if sGroup == "" then
				sGroup = Interface.getString("power_label_groupspells");
			end
			PowerManager.addPower(sClass, draginfo.getDatabaseNode(), getDatabaseNode(), sGroup);
			bUpdatingGroups = false;
			onPowerGroupChanged();
			return true;
		end
		if sClass == "reference_classfeature" then
			bUpdatingGroups = true;
			PowerManager.addPower(sClass, draginfo.getDatabaseNode(), getDatabaseNode());
			bUpdatingGroups = false;
			onPowerGroupChanged();
			return true;
		end
		if sClass == "reference_racialtrait" then
			bUpdatingGroups = true;
			PowerManager.addPower(sClass, draginfo.getDatabaseNode(), getDatabaseNode());
			bUpdatingGroups = false;
			onPowerGroupChanged();
			return true;
		end
		if sClass == "reference_feat" then
			bUpdatingGroups = true;
			PowerManager.addPower(sClass, draginfo.getDatabaseNode(), getDatabaseNode());
			bUpdatingGroups = false;
			onPowerGroupChanged();
			return true;
		end
		if sClass == "ref_ability" then
			bUpdatingGroups = true;
			PowerManager.addPower(sClass, draginfo.getDatabaseNode(), getDatabaseNode());
			bUpdatingGroups = false;
			onPowerGroupChanged();
			return true;
		end
	end
end

--------------------------
-- POWER GROUP DISPLAY
--------------------------

function rebuildGroups()
	aGroups = {};
	aCharSlots = {};
	
	local nodeChar = getDatabaseNode();
	
	for _,v in pairs(DB.getChildren(nodeChar, "powergroup")) do
		local sGroup = DB.getValue(v, "name", "");
		local rGroup = {};
		rGroup.node = v;
		rGroup.nodename = v.getNodeName();
		if sGroup == "" then
			rGroup.grouptype = "";
		else
			rGroup.grouptype = DB.getValue(v, "castertype", "");
		end
		
		if rGroup.grouptype == "memorization" then
			rGroup.nPrepared = DB.getValue(v, "prepared", 0);
		else
			rGroup.nAvailable = DB.getValue(v, "uses", 0);
		end
		
		rGroup.sUsesPeriod = DB.getValue(v, "usesperiod", "");
		
		aGroups[sGroup] = rGroup;
	end
	
	for i = 1, PowerManager.SPELL_LEVELS do
		aCharSlots[i] = { nMax = DB.getValue(nodeChar, "powermeta.spellslots" .. i .. ".max", 0) + DB.getValue(nodeChar, "powermeta.pactmagicslots" .. i .. ".max", 0) };
	end
end

function getWindowSortByNode(node)
	local sGroup = DB.getValue(node, "group", "");
	local nLevel = DB.getValue(node, "level", 0);
	
	sCategory = sGroup;
	if aGroups[sGroup] and aGroups[sGroup].grouptype ~= "" then
		sCategory = sCategory .. nLevel;
	else
		nLevel = 0;
	end

	return sCategory, sGroup, nLevel;
end

function getWindowSort(w)
	local sGroup = w.group.getValue();
	local nLevel = w.level.getValue();
	
	sCategory = sGroup;
	if aGroups[sGroup] and aGroups[sGroup].grouptype ~= "" then
		sCategory = sCategory .. nLevel;
	else
		nLevel = 0;
	end

	return sCategory, sGroup, nLevel;
end

function onSortCompare(w1, w2)
	local vCategory1 = getWindowSort(w1);
	local vCategory2 = getWindowSort(w2);
	if vCategory1 ~= vCategory2 then
		return vCategory1 > vCategory2;
	end
	
	local bIsHeader1 = (w1.getClass() == "power_group_header");
	local bIsHeader2 = (w2.getClass() == "power_group_header");
	if bIsHeader1 then
		return false;
	elseif bIsHeader2 then
		return true;
	end
	
	local sValue1 = string.lower(w1.name.getValue());
	local sValue2 = string.lower(w2.name.getValue());
	if sValue1 ~= sValue2 then
		return sValue1 > sValue2;
	end
end
