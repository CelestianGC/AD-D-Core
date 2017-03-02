-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function handleDrop(sTarget, draginfo)
	if sTarget == "spell" then
		local bAllowEdit = LibraryData.allowEdit(sTarget);
		if bAllowEdit then
			local sRootMapping = LibraryData.getRootMapping(sTarget);
			local sClass, sRecord = draginfo.getShortcutData();
			if ((sClass == "reference_spell") or (sClass == "power")) and ((sRootMapping or "") ~= "") then
				local nodeSource = DB.findNode(sRecord);
				local nodeTarget = DB.createChild(sRootMapping);
				DB.copyNode(nodeSource, nodeTarget);
				DB.setValue(nodeTarget, "locked", "number", 1);
				return true;
			end
		end
	end
end

function lookupCharData(sRecord, aRefModules)
	local node = nil;
	
	local sPath, sModule = sRecord:match("([^@]*)@(.*)");
	if sModule then
		node = DB.findNode(sRecord);
		if not node and sModule == "*" then
			if sRecord:match("^reference%.equipmentdata%.") then
				node = DB.findNode(sRecord:gsub("^reference%.equipmentdata%.", "item."));
			elseif sRecord:match("^reference%.spelldata%.") then
				node = DB.findNode(sRecord:gsub("^reference%.spelldata%.", "spell."));
			end
		end
	else
		node = DB.findNode(sRecord);
		sPath = sRecord;
	end
	if node then
		return node;
	end
	
	local sModulePath = sPath:gsub("^reference[^.]*%.", "reference.");
	for _,v in ipairs(aRefModules) do
		local node = DB.findNode(string.format("%s@%s", sModulePath, v));
		if node then
			return node;
		end
	end
	
	return node;
end

function addPregenChar(nodeSource)
	-- Standard record copy
	local nodeTarget = DB.createChild("charsheet");
	DB.copyNode(nodeSource, nodeTarget);

	-- Perform 5E specific conversions
	local aRefModules = {};
	local aModules = Module.getModules();
	for _, v in ipairs(aModules) do
		if DB.findNode("reference@" .. v) then
			table.insert(aRefModules, v);
		end
	end
	
	local bMissingData = false;
	
	-- Feature/trait links
	for _,v in pairs(DB.getChildren(nodeTarget, "featurelist")) do
		local sName = DB.getValue(v, "name", "");
		local _, sRecord = DB.getValue(v, "link", "", "");
		local nodeFeatureSource = lookupCharData(sRecord, aRefModules);
		if nodeFeatureSource then
			DB.copyNode(nodeFeatureSource, v);
			
			DB.setValue(v, "name", "string", sName);
			DB.setValue(v, "locked", "number", 1);
		else
			Debug.chat("FEATURE", sRecord);
			bMissingData = true;
		end
	end
	for _,v in pairs(DB.getChildren(nodeTarget, "traitlist")) do
		local sName = DB.getValue(v, "name", "");
		local _, sRecord = DB.getValue(v, "link", "", "");
		local nodeTraitSource = lookupCharData(sRecord, aRefModules);
		if nodeTraitSource then
			DB.copyNode(nodeTraitSource, v);
			
			DB.setValue(v, "name", "string", sName);
			DB.setValue(v, "locked", "number", 1);
		else
			Debug.chat("TRAIT", sRecord);
			bMissingData = true;
		end
	end
	
	-- Inventory processing
	for _,v in pairs(DB.getChildren(nodeTarget, "inventorylist")) do
		local sName = DB.getValue(v, "name", "");
		local _, sRecord = DB.getValue(v, "link", "", "");
		local nodeItemSource = lookupCharData(sRecord, aRefModules);
		if nodeItemSource then
			DB.copyNode(nodeItemSource, v);
			
			DB.setValue(v, "name", "string", sName);
			DB.setValue(v, "isidentified", "number", 1)
			DB.setValue(v, "locked", "number", 1);
			DB.setValue(v, "carried", "number", 1);
			
			CharManager.addToWeaponDB(v);
		else
			Debug.chat("ITEM", sRecord);
			bMissingData = true;
		end
	end
	
	-- Spell processing
	local nodePowers = nodeTarget.createChild("powers");
	local bHasSpells = false;
	
	for _,v in pairs(DB.getChildren(nodeTarget, "cantriplist")) do
		local sName = DB.getValue(v, "name", "");
		local _, sRecord = DB.getValue(v, "link", "", "");
		local nodeSpellSource = lookupCharData(sRecord, aRefModules);
		if nodeSpellSource then
			local nodePower = nodePowers.createChild();
			
			DB.copyNode(nodeSpellSource, nodePower);
			
			DB.setValue(nodePower, "name", "string", sName);
			DB.setValue(nodePower, "group", "string", Interface.getString("power_label_groupspells"));
			DB.setValue(nodePower, "prepared", "number", 1);

			DB.setValue(nodePower, "locked", "number", 1);
			DB.setValue(nodePower, "parse", "number", 1);
			
			bHasSpells = true;
		else
			Debug.chat("POWER", sRecord);
			bMissingData = true;
		end
	end
	for _,v in pairs(DB.getChildren(nodeTarget, "domainspells")) do
		local sName = DB.getValue(v, "name", "");
		local _, sRecord = DB.getValue(v, "link", "", "");
		local nodeSpellSource = lookupCharData(sRecord, aRefModules);
		if nodeSpellSource then
			local nodePower = nodePowers.createChild();
			
			DB.copyNode(nodeSpellSource, nodePower);
			
			DB.setValue(nodePower, "name", "string", sName);
			DB.setValue(nodePower, "group", "string", Interface.getString("power_label_groupspells"));
			DB.setValue(nodePower, "prepared", "number", 1);

			DB.setValue(nodePower, "locked", "number", 1);
			DB.setValue(nodePower, "parse", "number", 1);
			
			bHasSpells = true;
		else
			Debug.chat("SPELL DOMAIN", sRecord);
			bMissingData = true;
		end
	end
	for _,v in pairs(DB.getChildren(nodeTarget, "spellslist")) do
		local sName = DB.getValue(v, "name", "");
		local _, sRecord = DB.getValue(v, "link", "", "");
		local nodeSpellSource = lookupCharData(sRecord, aRefModules);
		if nodeSpellSource then
			local nodePower = nodePowers.createChild();
			
			DB.copyNode(nodeSpellSource, nodePower);
			
			DB.setValue(nodePower, "name", "string", sName);
			DB.setValue(nodePower, "group", "string", Interface.getString("power_label_groupspells"));
			DB.setValue(nodePower, "prepared", "number", 1);

			DB.setValue(nodePower, "locked", "number", 1);
			DB.setValue(nodePower, "parse", "number", 1);
			
			bHasSpells = true;
		else
			Debug.chat("SPELL", sRecord);
			bMissingData = true;
		end
	end
	for _,v in pairs(DB.getChildren(nodeTarget, "spellbook")) do
		local sName = DB.getValue(v, "name", "");
		local _, sRecord = DB.getValue(v, "link", "", "");
		local nodeSpellSource = lookupCharData(sRecord, aRefModules);
		if nodeSpellSource then
			local nodePower = nodePowers.createChild();
			
			DB.copyNode(nodeSpellSource, nodePower);
			
			DB.setValue(nodePower, "name", "string", sName);
			DB.setValue(nodePower, "group", "string", Interface.getString("power_label_groupspells"));

			DB.setValue(nodePower, "locked", "number", 1);
			DB.setValue(nodePower, "parse", "number", 1);
			
			bHasSpells = true;
		else
			Debug.chat("SPELL BOOK", sRecord);
			bMissingData = true;
		end
	end
	if bHasSpells then
		for i = 1,PowerManager.SPELL_LEVELS do
			local nSlots = DB.getValue(nodeTarget, "spellslots.level" .. i, 0);
			DB.setValue(nodeTarget, "powermeta.spellslots" .. i .. ".max", "number", nSlots);
		end

		for i = 1,PowerManager.SPELL_LEVELS do
			local nSlots = DB.getValue(nodeTarget, "pactmagicslots.level" .. i, 0);
			DB.setValue(nodeTarget, "powermeta.pactmagicslots" .. i .. ".max", "number", nSlots);
		end

		local nodeGroups = DB.createChild(nodeTarget, "powergroup");
		local nodeNewGroup = nodeGroups.createChild();
		DB.setValue(nodeNewGroup, "name", "string", Interface.getString("power_label_groupspells"));
		DB.setValue(nodeNewGroup, "castertype", "string", "memorization");

		local nPrepared = DB.getValue(nodeTarget, "preparedspells.level1", 0);
		DB.setValue(nodeNewGroup, "prepared", "number", nPrepared);
	end
	
	-- Spell Data Cleanup
	DB.deleteChild(nodeTarget, "attacklist");
	DB.deleteChild(nodeTarget, "cantriplist");
	DB.deleteChild(nodeTarget, "spellslots");
	DB.deleteChild(nodeTarget, "pactmagicslots");
	DB.deleteChild(nodeTarget, "preparedspells");
	DB.deleteChild(nodeTarget, "spellslist");
	DB.deleteChild(nodeTarget, "spellbook");

	-- Notifications
	ChatManager.SystemMessage(Interface.getString("pregenchar_message_add"));

	if bMissingData then
		ChatManager.SystemMessage(Interface.getString("pregen_error_missingdata"));
	end
end

-- Check to see if NPC has no spell entries defined, but a spellcasting trait. If so, then attempt to lookup and add spells.
function updateNPCSpells(nodeNPC)
	if not nodeNPC then
		return;
	end
	if nodeNPC.isReadOnly() then
		return;
	end
	
	if (DB.getChildCount(nodeNPC, "spells") > 0) or (DB.getChildCount(nodeNPC, "innatespells") > 0) then
		return;
	end

	for _,v in pairs(DB.getChildren(nodeNPC, "traits")) do
		local sTraitName = StringManager.trim(DB.getValue(v, "name", ""):lower());
		if sTraitName == "spellcasting" then
			updateNPCSpellcasting(nodeNPC, v);
		elseif sTraitName == "innate spellcasting" then
			updateNPCInnateSpellcasting(nodeNPC, v);
		end
	end
end

function updateNPCSpellcasting(nodeNPC, nodeTrait)
	local aError = {};
	local aSpellcasting = {};
	aSpellcasting.bInnate = false; 
	
	local sDesc = DB.getValue(nodeTrait, "desc", ""):lower();
	aSpellcasting.sDC = sDesc:match("spell save dc (%d+)");
	aSpellcasting.sAtk = sDesc:match("([+-]%d+) to hit with spell attacks");
		
    
	local aLines = StringManager.split(DB.getValue(nodeTrait, "desc", ""), "\n");
	for _,sLine in ipairs(aLines) do
		local sLineLower = sLine:lower();
		local nLevel = tonumber(sLineLower:match("^([1-9])[snrt][tdh] level")) or -1;
		if nLevel == -1 and sLineLower:match("^cantrips") then
			nLevel = 0;
		end
		if nLevel >= 0 then
			local aSpells = StringManager.split(sLine:match(":(.*)$"), ",", true);
			if #aSpells > 0 then
				aSpellcasting[nLevel] = aSpells;
			end
		end
	end
	
	for i = 0,9 do
		if aSpellcasting[i] then
			for _,sSpell in ipairs(aSpellcasting[i]) do
				if not updateNPCSpellHelper(sSpell, nodeNPC, aSpellcasting) then
					table.insert(aError, sSpell);
				end
			end
		end
	end
	
	if #aError > 0 then
		ChatManager.SystemMessage("Failed spellcasting lookup on " .. #aError .. " spell(s) for (" .. DB.getValue(nodeNPC, "name", "") .. "). Make sure your spell module(s) are open."); 
		ChatManager.SystemMessage("Spell lookup failures: " .. table.concat(aError, ", ")); 
	end
end

-- review this to deal with AD&D monster/spells -msw
function updateNPCInnateSpellcasting(nodeNPC, nodeTrait)
	local aError = {};
	local aSpellcasting = {};
	aSpellcasting.bInnate = true; 
	
	local sDesc = DB.getValue(nodeTrait, "desc", ""):lower();
	aSpellcasting.sDC = sDesc:match("spell save dc (%d+)");
	aSpellcasting.sAtk = sDesc:match("([+-]%d+) to hit with spell attacks");


	local aLines = StringManager.split(DB.getValue(nodeTrait, "desc", ""), "\n");
	for _,sLine in ipairs(aLines) do
		local sLineLower = sLine:lower();
		local nCastAmount = tonumber(sLineLower:match("^([1-9])/day")) or -1;
		if nCastAmount == -1 and sLineLower:match("^at will") then
			nCastAmount = 0;
		end
		if nCastAmount >= 0 then
			local aSpells = StringManager.split(sLine:match(":(.*)$"), ",", true);
			if #aSpells > 0 then
				aSpellcasting[nCastAmount] = aSpells;
			end
		end
	end
	
	for i = 0,9 do
		if aSpellcasting[i] then
			for _,sSpell in ipairs(aSpellcasting[i]) do
				if not updateNPCSpellHelper(sSpell, nodeNPC, aSpellcasting, i) then
					table.insert(aError, sSpell);
				end
			end
		end
	end
	
	if #aError > 0 then
		ChatManager.SystemMessage("Failed innate spellcasting lookup on " .. #aError .. " spell(s) for (" .. DB.getValue(nodeNPC, "name", "") .. "). Make sure your spell module(s) are open."); 
		ChatManager.SystemMessage("Spell lookup failures: " .. table.concat(aError, ", ")); 
	end
end

function sanitize(s)
	local sSanitized = StringManager.trim(s:gsub("%s%(.*%)$", ""));
	sSanitized = sSanitized:gsub("[.,-():'’/?+–]", "_"):gsub("%s", ""):lower();
	return sSanitized
end

function updateNPCSpellHelper(sSpell, nodeNPC, aSpellcasting, nDaily)
	-- Remove any excess parenthetical text
	-- Then convert spell name using algorithm used by Par5E to create valid XML tags for spells
	-- (Remove all whitespace, converts to lowercase and replaces punctuation with _ char)
	local sSanitized = sanitize(sSpell);
	
	-- See if we can find a matching node in any loaded module. If not, we're done.
	local nodeRefSpell = DB.findNode("reference.spelldata." .. sSanitized .. "@*");
	if not nodeRefSpell then
		local sCleaned = StringManager.trim(sSpell:lower());
		for _,v in pairs(DB.getChildren("spell")) do
			local sCheckCleaned = StringManager.trim(DB.getValue(v, "name", ""):lower());
			if sCleaned == sCheckCleaned then
				nodeRefSpell = v;
				break;
			end
		end
	end
	if not nodeRefSpell then
		for _,v in pairs(DB.getChildrenGlobal("reference.spelldata")) do
			local sCheckCleaned = StringManager.trim(DB.getValue(v, "name", ""):lower());
			if sCleaned == sCheckCleaned then
				nodeRefSpell = v;
				break;
			end
		end
	end
	if not nodeRefSpell then
		return false;
	end
	
	-- Create the new spell node
	local nodeSpell;
	if aSpellcasting.bInnate then
		nodeSpell = DB.createChild(DB.getPath(nodeNPC, "innatespells"));
	else
		nodeSpell = DB.createChild(DB.getPath(nodeNPC, "spells"));
	end
	
	-- Add the daily use or level information to the name field 
	local nLevel = DB.getValue(nodeRefSpell, "level", 0);
	local sSpellName = DB.getValue(nodeRefSpell, "name", "");
	if aSpellcasting.bInnate then
		if nDaily == 0 then
			DB.setValue(nodeSpell, "name", "string", sSpellName .. " (At will)");
		else
			DB.setValue(nodeSpell, "name", "string", sSpellName .. " (" .. nDaily .. "/day)");
		end
	else
		if nLevel == 1 then
			DB.setValue(nodeSpell, "name", "string", sSpellName .. " - 1st level");
		elseif nLevel == 2 then
			DB.setValue(nodeSpell, "name", "string", sSpellName .. " - 2nd level");
		elseif nLevel == 3 then
			DB.setValue(nodeSpell, "name", "string", sSpellName .. " - 3rd level");
		elseif nLevel >= 4 then
			DB.setValue(nodeSpell, "name", "string", sSpellName .. " - " .. nLevel .. "th level");
		else
			DB.setValue(nodeSpell, "name", "string", sSpellName .. " - Cantrip");
		end
	end
	
	-- Convert the multi-field spell data to a single spell description field.
	local sDesc = "Level: " .. nLevel;
	sDesc = sDesc .. "\rCasting Time: " .. DB.getValue(nodeRefSpell, "castingtime", "");
	sDesc = sDesc .. "\rComponents: " .. DB.getValue(nodeRefSpell, "components", "");
	sDesc = sDesc .. "\rDuration: " .. DB.getValue(nodeRefSpell, "duration", "");
	sDesc = sDesc .. "\rRange: " .. DB.getValue(nodeRefSpell, "range", "");
	
	local sRefDesc = DB.getValue(nodeRefSpell, "description", "");
	sRefDesc = sRefDesc:gsub("</?[biu]>", "");
	sRefDesc = sRefDesc:gsub("<p>", "");
	sRefDesc = sRefDesc:gsub("</p>", "\r");
	sRefDesc = sRefDesc:gsub("<list>", "");
	sRefDesc = sRefDesc:gsub("</list>", "\r");
	sRefDesc = sRefDesc:gsub("<li>", "* ");
	sRefDesc = sRefDesc:gsub("</li>", "\r");
	sRefDesc = sRefDesc:gsub("</?table>", "");
	sRefDesc = sRefDesc:gsub("<tr>", "");
	sRefDesc = sRefDesc:gsub("<tr decoration=\"underline\">", "");
	sRefDesc = sRefDesc:gsub("</tr>", "\r");
	sRefDesc = sRefDesc:gsub("<td>", "");
	sRefDesc = sRefDesc:gsub("</td>", " ");
	sRefDesc = sRefDesc:gsub("\r", "");
	sRefDesc = sRefDesc:gsub("\\r$", "");
	
	if aSpellcasting.sAtk then
		sRefDesc = sRefDesc:gsub("ranged spell attack", "ranged spell attack (" .. aSpellcasting.sAtk .. " to hit)");
		sRefDesc = sRefDesc:gsub("melee spell attack", "melee spell attack (" .. aSpellcasting.sAtk .. " to hit)");
	end

	if aSpellcasting.sDC then
		if sRefDesc:match("spell save DC %d+") then
			sRefDesc = sRefDesc:gsub("spell save DC %d+", "spell save DC " .. aSpellcasting.sDC);
		else
			sRefDesc = sRefDesc:gsub("spell save DC", "spell save DC " .. aSpellcasting.sDC);
		end
		sRefDesc = sRefDesc:gsub("Strength saving throw([^s])", "DC " .. aSpellcasting.sDC .. " Strength saving throw%1");
		sRefDesc = sRefDesc:gsub("Dexterity saving throw([^s])", "DC " .. aSpellcasting.sDC .. " Dexterity saving throw%1");
		sRefDesc = sRefDesc:gsub("Constitution saving throw([^s])", "DC " .. aSpellcasting.sDC .. " Constitution saving throw%1");
		sRefDesc = sRefDesc:gsub("Intelligence saving throw([^s])", "DC " .. aSpellcasting.sDC .. " Intelligence saving throw%1");
		sRefDesc = sRefDesc:gsub("Wisdom saving throw([^s])", "DC " .. aSpellcasting.sDC .. " Wisdom saving throw%1");
		sRefDesc = sRefDesc:gsub("Charisma saving throw([^s])", "DC " .. aSpellcasting.sDC .. " Charisma saving throw%1");
	end

	sDesc = sDesc .. "\r" .. sRefDesc;
	DB.setValue(nodeSpell, "desc", "string", sDesc);
	
	return true;
end
