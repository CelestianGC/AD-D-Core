-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	rebuildSlots();
	DB.addHandler(DB.getPath(getDatabaseNode(), "powermeta.*.max"), "onUpdate", rebuildSlots);
	onModeChanged();
end

function onClose()
	DB.removeHandler(DB.getPath(getDatabaseNode(), "powermeta.*.max"), "onUpdate", rebuildSlots);
end

function onModeChanged()
	local nodeChar = getDatabaseNode();

	local sMode = DB.getValue(nodeChar, "powermode", "");
    
	if sMode == "preparation" then
		parentcontrol.setVisible(false);
	else
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
      arcanelevel.setVisible(true)
			spellslots_label.setVisible(true);
		else
			spellslots.setVisible(false);
			spellslots_label.setVisible(false);
      arcanelevel.setVisible(false)
		end
		if bPactMagicSlotsVisible then
			pactmagicslots.setVisible(true);
			pactmagicslots_label.setVisible(true);
      divinelevel.setVisible(true);
		else
			pactmagicslots.setVisible(false);
			pactmagicslots_label.setVisible(false);
      divinelevel.setVisible(false);
		end
		parentcontrol.setVisible(bSpellSlotsVisible or bPactMagicSlotsVisible);
	end
    
end

function rebuildListSlots(ctrlList, sPrefix)
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
end

function rebuildSlots()
	rebuildListSlots(spellslots, "spellslots");
	rebuildListSlots(pactmagicslots, "pactmagicslots");
end
