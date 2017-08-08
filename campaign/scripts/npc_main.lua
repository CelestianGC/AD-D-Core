-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
    checkNPCForSanity(getDatabaseNode());
    
	onSummaryChanged();
	update();
end

-- check hitdice and saves for sane values.
function checkNPCForSanity(nodeNPC)
    -- this is if someone uses a 5e npc with just "HD" and not "HITDICE" value set. 
    -- we do best guess on what the HD should be....BEST GUESS! --celestian
    local sHitDice = DB.getValue(nodeNPC, "hitDice", "1");
    local sHDother = DB.getValue(nodeNPC, "hd", "");
    if sHitDice == "" and sHDother ~= "" then
        local sRawHD = string.gsub(sHDother,"[Dd]%d+","");
        -- remove spaces and () 
        sRawHD = string.gsub(sRawHD,"%s","");
        sRawHD = string.gsub(sRawHD,"%(","");
        sRawHD = string.gsub(sRawHD,"%)","");
        -- match \d+[+-]\d+
        local sM1, sM2 = sRawHD:match("(%d+)([%-+]%d+)");
        -- just using the first number, 5e has large +/- which scale off the charts for AD&D style
        if sM1 ~= "" then
            sHitDice = sM1;
            local nHD = tonumber(sHitDice) or 0;
            local nTHACO = 21 - nHD;
            thaco.setValue(nTHACO);
        end
        hitDice.setValue(sHitDice);
    end
    -- end kludge around npc hd/hitdice
    
    local nCount = DB.getChildCount(nodeNPC, "saves");
    local nPoison = DB.getValue(nodeNPC, "saves.poison.score",0);
    -- if set to default -20, then we build the saves from 
    -- creatures HDice
    if nPoison == -20 then
        CombatManager2.updateNPCSaves(nodeNPC, nodeNPC, true);
    end
end

function onSummaryChanged()
	local sSize = size.getValue();
	local sType = type.getValue();
	local sAlign = alignment.getValue();
	
	local aText = {};
	if sSize ~= "" then
		table.insert(aText, sSize);
	end
	if sType ~= "" then
		table.insert(aText, sType);
	end
	if sAlign ~= "" then
		table.insert(aText, ", " .. sAlign);
	end
	
	summary_label.setValue(table.concat(aText, " "));
end

function updateControl(sControl, bReadOnly, bForceHide)
	if not self[sControl] then
		return false;
	end
	
	return self[sControl].update(bReadOnly, bForceHide);
end

function update()
	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());

	updateControl("size", bReadOnly, bReadOnly);
	updateControl("type", bReadOnly, bReadOnly);
	updateControl("alignment", bReadOnly, bReadOnly);
	summary_label.setVisible(bReadOnly);
	
	ac.setReadOnly(bReadOnly);
	actext.setReadOnly(bReadOnly);
	hp.setReadOnly(bReadOnly);
	hd.setReadOnly(bReadOnly);
	speed.setReadOnly(bReadOnly);
	
	updateControl("strength", bReadOnly);
	updateControl("constitution", bReadOnly);
	updateControl("dexterity", bReadOnly);
	updateControl("intelligence", bReadOnly);
	updateControl("wisdom", bReadOnly);
	updateControl("charisma", bReadOnly);

	updateControl("savingthrows", bReadOnly);
	updateControl("skills", bReadOnly);
	updateControl("damagevulnerabilities", bReadOnly);
	updateControl("damageresistances", bReadOnly);
	updateControl("damageimmunities", bReadOnly);
	updateControl("conditionimmunities", bReadOnly);
	updateControl("senses", bReadOnly);
	updateControl("languages", bReadOnly);
	updateControl("challengerating", bReadOnly);
	updateControl("effect_combat", bReadOnly);
	
	cr.setReadOnly(bReadOnly);
	xp.setReadOnly(bReadOnly);
	
	-- if bReadOnly then
		-- if traits_iedit then
			-- traits_iedit.setValue(0);
			-- traits_iedit.setVisible(false);
		-- end
		
		-- local bShow = (traits.getWindowCount() ~= 0);
		-- header_traits.setVisible(bShow);
		-- traits.setVisible(bShow);
	-- else
		-- if traits_iedit then
			-- traits_iedit.setVisible(true);
		-- end
		-- header_traits.setVisible(true);
		-- traits.setVisible(true);
	-- end
	-- for _,w in ipairs(traits.getWindows()) do
		-- w.name.setReadOnly(bReadOnly);
		-- w.desc.setReadOnly(bReadOnly);
	-- end

	-- if bReadOnly then
		-- if actions_iedit then
			-- actions_iedit.setValue(0);
			-- actions_iedit.setVisible(false);
		-- end
		
		-- local bShow = (actions.getWindowCount() ~= 0);
		-- header_actions.setVisible(bShow);
		-- actions.setVisible(bShow);
	-- else
		-- if actions_iedit then
			-- actions_iedit.setVisible(true);
		-- end
		-- header_actions.setVisible(true);
		-- actions.setVisible(true);
	-- end
	-- for _,w in ipairs(actions.getWindows()) do
		-- w.name.setReadOnly(bReadOnly);
		-- w.desc.setReadOnly(bReadOnly);
	-- end
	
	-- if bReadOnly then
		-- if reactions_iedit then
			-- reactions_iedit.setValue(0);
			-- reactions_iedit.setVisible(false);
		-- end
		
		-- local bShow = (reactions.getWindowCount() ~= 0);
		-- header_reactions.setVisible(bShow);
		-- reactions.setVisible(bShow);
	-- else
		-- if reactions_iedit then
			-- reactions_iedit.setVisible(true);
		-- end
		-- header_reactions.setVisible(true);
		-- reactions.setVisible(true);
	-- end
	-- for _,w in ipairs(reactions.getWindows()) do
		-- w.name.setReadOnly(bReadOnly);
		-- w.desc.setReadOnly(bReadOnly);
	-- end
	
	-- if bReadOnly then
		-- if legendaryactions_iedit then
			-- legendaryactions_iedit.setValue(0);
			-- legendaryactions_iedit.setVisible(false);
		-- end
		
		-- local bShow = (legendaryactions.getWindowCount() ~= 0);
		-- header_legendaryactions.setVisible(bShow);
		-- legendaryactions.setVisible(bShow);
	-- else
		-- if legendaryactions_iedit then
			-- legendaryactions_iedit.setVisible(true);
		-- end
		-- header_legendaryactions.setVisible(true);
		-- legendaryactions.setVisible(true);
	-- end
	-- for _,w in ipairs(legendaryactions.getWindows()) do
		-- w.name.setReadOnly(bReadOnly);
		-- w.desc.setReadOnly(bReadOnly);
	-- end
	
	-- if bReadOnly then
		-- if lairactions_iedit then
			-- lairactions_iedit.setValue(0);
			-- lairactions_iedit.setVisible(false);
		-- end
		
		-- local bShow = (lairactions.getWindowCount() ~= 0);
		-- header_lairactions.setVisible(bShow);
		-- lairactions.setVisible(bShow);
	-- else
		-- if lairactions_iedit then
			-- lairactions_iedit.setVisible(true);
		-- end
		-- header_lairactions.setVisible(true);
		-- lairactions.setVisible(true);
	-- end
	-- for _,w in ipairs(lairactions.getWindows()) do
		-- w.name.setReadOnly(bReadOnly);
		-- w.desc.setReadOnly(bReadOnly);
	-- end
	
	-- if bReadOnly then
		-- if innatespells_iedit then
			-- innatespells_iedit.setValue(0);
			-- innatespells_iedit.setVisible(false);
		-- end
		
		-- local bShow = (innatespells.getWindowCount() ~= 0);
		-- header_innatespells.setVisible(bShow);
		-- innatespells.setVisible(bShow);
	-- else
		-- if innatespells_iedit then
			-- innatespells_iedit.setVisible(true);
		-- end
		-- header_innatespells.setVisible(true);
		-- innatespells.setVisible(true);
	-- end
	-- for _,w in ipairs(innatespells.getWindows()) do
		-- w.name.setReadOnly(bReadOnly);
		-- w.desc.setReadOnly(bReadOnly);
	-- end
	
	-- if bReadOnly then
		-- if spells_iedit then
			-- spells_iedit.setValue(0);
			-- spells_iedit.setVisible(false);
		-- end
		
		-- local bShow = (spells.getWindowCount() ~= 0);
		-- header_spells.setVisible(bShow);
		-- spells.setVisible(bShow);
	-- else
		-- if spells_iedit then
			-- spells_iedit.setVisible(true);
		-- end
		-- header_spells.setVisible(true);
		-- spells.setVisible(true);
	-- end
	-- for _,w in ipairs(spells.getWindows()) do
		-- w.name.setReadOnly(bReadOnly);
		-- w.desc.setReadOnly(bReadOnly);
	-- end
end

function addTrait(sName, sDesc)
	local w = traits.createWindow();
	if w then
		w.name.setValue(sName);
		w.desc.setValue(sDesc);
	end
end

function addAction(sName, sDesc)
	local w = actions.createWindow();
	if w then
		w.name.setValue(sName);
		w.desc.setValue(sDesc);
	end
end

function addSpell(sName, sDesc, bInnate)
	local w = nil;
	if bInnate then
		w = innatespells.createWindow();
	else
		w = spells.createWindow();
	end
	if w then
		w.name.setValue(sName);
		w.desc.setValue(sDesc);
	end
end

function addSpellDrop(nodeSource, bInnate)
	local aDesc = {};
	
	local sSchool = DB.getValue(nodeSource, "school", "");
	local nLevel = DB.getValue(nodeSource, "level", 0);
	if sSchool ~= "" then
		sSchool = sSchool .. " ";
	end
	if nLevel ~= 0 then
		table.insert(aDesc, sSchool .. "L" .. nLevel);
	else
		table.insert(aDesc, sSchool .. "Cantrip");
	end
	
	local sCastTime = DB.getValue(nodeSource, "castingtime", "");
	if sCastTime ~= "" then
		table.insert(aDesc, "Casting Time: " .. sCastTime);
	end
	
	local sRange = DB.getValue(nodeSource, "range", "");
	if sRange ~= "" then
		table.insert(aDesc, "Range: " .. sRange);
	end
	
	local sDuration = DB.getValue(nodeSource, "duration", "");
	if sDuration ~= "" then
		table.insert(aDesc, "Duration: " .. sDuration);
	end

	local sDesc = DB.getText(nodeSource, "description", "");
	if sDesc ~= "" then
		table.insert(aDesc, sDesc);
	end
	
	addSpell(DB.getValue(nodeSource, "name", ""), table.concat(aDesc, "\r"), bInnate);
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local sClass = draginfo.getShortcutData();
		local nodeSource = draginfo.getDatabaseNode();
		
		if sClass == "reference_spell" or sClass == "power" then
			addSpellDrop(nodeSource);
		elseif sClass == "reference_backgroundfeature" then
			addAction(DB.getValue(nodeSource, "name", ""), DB.getText(nodeSource, "text", ""));
		elseif sClass == "reference_classfeature" then
			--addAction(DB.getValue(nodeSource, "name", ""), DB.getText(nodeSource, "text", ""));
		elseif sClass == "reference_feat" then
			--addAction(DB.getValue(nodeSource, "name", ""), DB.getText(nodeSource, "text", ""));
		elseif sClass == "reference_racialtrait" or sClass == "reference_subracialtrait" then
			--addTrait(DB.getValue(nodeSource, "name", ""), DB.getText(nodeSource, "text", ""));
		end
		return true;
	end
end
