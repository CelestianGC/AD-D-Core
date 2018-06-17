-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerMenuItem(Interface.getString("list_menu_createitem"), "insert", 5);
	
	-- Construct default skills
	constructDefaultSkills();
end

function onAbilityChanged()
	for _,w in ipairs(getWindows()) do
		if w.isCustom() then
			w.idelete.setVisibility(bEditMode);
		else
			w.idelete.setVisibility(false);
		end
	end
end

function onListChanged()
	update();
end

function update()
	local bEditMode = (window.parentcontrol.window.skills_iedit.getValue() == 1);
	for _,w in ipairs(getWindows()) do
		if w.isCustom() then
			w.idelete.setVisibility(bEditMode);
		else
			w.idelete.setVisibility(false);
		end
	end
end

function addEntry(bFocus)
	local w = createWindow();
	w.setCustom(true);
	if bFocus and w then
		w.name.setFocus();
	end
	return w;
end

function onMenuSelection(item)
	if item == 5 then
		addEntry(true);
	end
end

-- Create default skill selection
function constructDefaultSkills()
	-- Collect existing entries
	local entrymap = {};

	for _,w in pairs(getWindows()) do
		local sLabel = w.name.getValue(); 
	
		if DataCommon.skilldata[sLabel] then
			if not entrymap[sLabel] then
				entrymap[sLabel] = { w };
			else
				table.insert(entrymap[sLabel], w);
			end
		else
			w.setCustom(true);
		end
	end

	-- Set properties and create missing entries for all known skills
	for k, t in pairs(DataCommon.skilldata) do
		local matches = entrymap[k];
		
		if not matches then
			local w = createWindow();
			if w then
				w.name.setValue(k);
				if t.stat then
					w.stat.setStringValue(t.stat);
				else
					w.stat.setStringValue("");
				end
				matches = { w };
			end
		end
		
		-- Update properties
		local bCustom = false;
		for _, match in pairs(matches) do
			match.setCustom(bCustom);
			if t.disarmorstealth then
				match.armorwidget.setVisible(true);
			end
			if not bCustom then
				local _, sRecord = match.shortcut.getValue();
				if sRecord == match.getDatabaseNode().getPath() then
					match.shortcut.setValue("ref_ability", "reference.skilldata." .. t.lookup .. "@*");
				end
			end
			bCustom = true;
		end
	end
end

function addSkillReference(nodeSource)
	if not nodeSource then
		return;
	end
	
	local sName = StringManager.trim(DB.getValue(nodeSource, "name", ""));
	if sName == "" then
		return;
	end
	
	local wSkill = nil;
	for _,w in pairs(getWindows()) do
		if StringManager.trim(w.name.getValue()) == sName then
			wSkill = w;
			break;
		end
	end
	if not wSkill then
		wSkill = createWindow();
    local sStat = DB.getValue(nodeSource, "stat", "");
    local nMod = DB.getValue(nodeSource, "adj_mod", 0);
    local nBase = DB.getValue(nodeSource, "base_check", 0);
    -- set values from skill to the one we're adding
		wSkill.name.setValue(sName);
    --wSkill.base_check.setValue(nBase);
		DB.setValue(wSkill.getDatabaseNode(), "base_check", "number", nBase);
    --wSkill.adj_mod.setValue(nMod);
		DB.setValue(wSkill.getDatabaseNode(), "adj_mod", "number", nMod);
    --wSkill.stat.setValue(sStat);
		DB.setValue(wSkill.getDatabaseNode(), "stat", "string", sStat);
  else
		DB.setValue(wSkill.getDatabaseNode(), "text", "formattedtext", DB.getValue(nodeSource, "text", ""));
	end
end
