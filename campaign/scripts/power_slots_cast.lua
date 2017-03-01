-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	Debug.console("power_slots_cast.lua","onInit");
	rebuildSlots();
	Debug.console("power_slots_cast.lua","onInit","rebuildSlots");
	DB.addHandler(DB.getPath(getDatabaseNode(), "powermeta.*.max"), "onUpdate", rebuildSlots);
	Debug.console("power_slots_cast.lua","onInit","addHandler");
	onModeChanged();
	Debug.console("power_slots_cast.lua","onInit","onModeChanged");
end

function onClose()
	Debug.console("power_slots_cast.lua","onClose","1");
	DB.removeHandler(DB.getPath(getDatabaseNode(), "powermeta.*.max"), "onUpdate", rebuildSlots);
	Debug.console("power_slots_cast.lua","onClose","2");
end

function onModeChanged()
	Debug.console("power_slots_cast.lua","onModeChanged","1");
	local nodeChar = getDatabaseNode();
	local sMode = DB.getValue(nodeChar, "powermode", "");
	if sMode == "preparation" then
	Debug.console("power_slots_cast.lua","onModeChanged","2");
		parentcontrol.setVisible(false);
	else
	Debug.console("power_slots_cast.lua","onModeChanged","3");
		local bSpellSlotsVisible = false;
		for i = 1, PowerManager.SPELL_LEVELS do
			if DB.getValue(nodeChar, "powermeta.spellslots" .. i .. ".max", 0) > 0 then
				bSpellSlotsVisible = true;
				break;
			end
		end
		local bPactMagicSlotsVisible = false;
		for i = 1, PowerManager.SPELL_LEVELS do
			if DB.getValue(nodeChar, "powermeta.pactmagicslots" .. i .. ".max", 0) > 0 then
				bPactMagicSlotsVisible = true;
				break;
			end
		end
		
		if bSpellSlotsVisible then
			spellslots.setVisible(true);
			spellslots_label.setVisible(bPactMagicSlotsVisible);
		else
			spellslots.setVisible(false);
			spellslots_label.setVisible(false);
		end
		if bPactMagicSlotsVisible then
			pactmagicslots.setVisible(true);
			pactmagicslots_label.setVisible(true);
		else
			pactmagicslots.setVisible(false);
			pactmagicslots_label.setVisible(false);
		end
		parentcontrol.setVisible(bSpellSlotsVisible or bPactMagicSlotsVisible);
	end
	Debug.console("power_slots_cast.lua","onModeChanged","4");
end

function rebuildListSlots(ctrlList, sPrefix)
	Debug.console("power_slots_cast.lua","rebuildListSlots","1");
	ctrlList.closeAll();
	
	local nodeChar = getDatabaseNode();
	for i = 1, PowerManager.SPELL_LEVELS do
		if DB.getValue(nodeChar, "powermeta." .. sPrefix .. i .. ".max", 0) > 0 then
			local w = ctrlList.createWindow();
			if i == 1 then w.label.setValue("1st")
			elseif i == 2 then w.label.setValue("2nd")
			elseif i == 3 then w.label.setValue("3rd")
			else
				w.label.setValue(i .. "th")
			end
			w.counter.setMaxNode(DB.getPath(nodeChar, "powermeta." .. sPrefix .. i .. ".max"));
			w.counter.setCurrNode(DB.getPath(nodeChar, "powermeta." .. sPrefix .. i .. ".used"));
		end
	end
	Debug.console("power_slots_cast.lua","rebuildListSlots","2");
end

function rebuildSlots()
	Debug.console("power_slots_cast.lua","rebuildSlots","1");
	rebuildListSlots(spellslots, "spellslots");
	Debug.console("power_slots_cast.lua","rebuildSlots","2");
	rebuildListSlots(pactmagicslots, "pactmagicslots");
	Debug.console("power_slots_cast.lua","rebuildSlots","3");
end
