-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bFilter = true;
function setFilter(bNewFilter)
	bFilter = bNewFilter;
end
--function getFilter()
--	return bFilter;
--end

function onInit()
-- Debug.console("power_item.lua","onInit","nodeTest",nodeTest);
-- Debug.console("power_item.lua","onInit","window",window);
-- Debug.console("power_item.lua","onInit","windowlist",windowlist);

    local node = getDatabaseNode();
    -- these are so memorization sections show up properly if level/type/group are updated
    DB.addHandler(DB.getPath(node, "level"), "onUpdate", toggleDetail);
    DB.addHandler(DB.getPath(node, "group"), "onUpdate", toggleDetail);
    DB.addHandler(DB.getPath(node, "type"), "onUpdate", toggleDetail);
    
-- tweak here for testing --celestian
    if windowlist == nil or not windowlist.isReadOnly() then
--    if not windowlist.isReadOnly() then
		registerMenuItem(Interface.getString("list_menu_deleteitem"), "delete", 6);
		registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 6, 7);

		registerMenuItem(Interface.getString("power_menu_addaction"), "pointer", 3);
		registerMenuItem(Interface.getString("power_menu_addcast"), "radial_sword", 3, 2);
		registerMenuItem(Interface.getString("power_menu_adddamage"), "radial_damage", 3, 3);
		registerMenuItem(Interface.getString("power_menu_addheal"), "radial_heal", 3, 4);
		registerMenuItem(Interface.getString("power_menu_addeffect"), "radial_effect", 3, 5);
		
		-- disabled, we don't reparse in AD&D Core right now --celestian
        --registerMenuItem(Interface.getString("power_menu_reparse"), "textlist", 4);
	end

	--Check to see if we should automatically parse attack description
	local nodeAttack = getDatabaseNode();
	local nParse = DB.getValue(nodeAttack, "parse", 0);
	if nParse ~= 0 then
		DB.setValue(nodeAttack, "parse", "number", 0);
		PowerManager.parsePCPower(nodeAttack);
	end
	
	onDisplayChanged();
	-- window list can be nil when using this for spell records (not PC/NPCs) --celestian
    if windowlist ~= nil then 
        windowlist.onChildWindowAdded(self);
    else
    -- windowlist == nil then we're in a spell record and do
    -- not need to see these
        header.subwindow.group.setVisible(false);
        header.subwindow.shortdescription.setVisible(false);
        header.subwindow.name.setVisible(false);
    end

    
        toggleDetail();
        -- this should default to invis but it's not so this will check and 
        -- make sure it's set properly --celestian
        -- local status = (activatedetail.getValue() == 1);   
        -- initiative.setVisible(status);
        -- local node = getDatabaseNode();
-- Debug.console("power_item.lua","onInit","node",node);
        -- if PowerManager.canMemorizeSpell(node) then
-- Debug.console("power_item.lua","onInit","status1",status);
            -- memorization.setVisible(status);
        -- else
-- Debug.console("power_item.lua","onInit","status2",status);
            -- memorization.setVisible(false);
        -- end
    -- item record first time tweaks
    -- give it a name of the item
    -- set group start to whatever item type is
    -- set usesperiod to "once", default to charged item
    -- set default charges to 25
    if string.match(nodeAttack.getPath(),"^item") then
        local nodeItem = DB.getChild(nodeAttack, "...");
        if (name.getValue() == "") then
            name.setValue(DB.getValue(nodeItem,"name",""));
            group.setValue(DB.getValue(nodeItem,"type","Item"));
            usesperiod.setValue("once");
            prepared.setValue(25);
        end
    end
end

function onClose()
	local node = getDatabaseNode();
	DB.removeHandler(DB.getPath(node, "level"), "onUpdate", toggleDetail);
	DB.removeHandler(DB.getPath(node, "group"), "onUpdate", toggleDetail);
	DB.removeHandler(DB.getPath(node, "type"), "onUpdate", toggleDetail);
end
-- filters out non-memorized spells when in "combat" mode.
function getFilter()
    local bShow = bFilter;
    local node = getDatabaseNode();
    local nodeChar = node.getChild("...");
    local bisNPC = (not ActorManager.isPC(nodeChar));    
--    Debug.console("power_item.lua","getFilter","node",node);
--    Debug.console("power_item.lua","getFilter","nodeChar",nodeChar);

    local bMemorized = ((DB.getValue(node,"memorized",0) > 0) or (bisNPC));
    local sMode = DB.getValue(nodeChar, "powermode", "");
    local nLevel = DB.getValue(node, "level",0);
    local sGroup = DB.getValue(node, "group",""):lower();
    -- make sure it's in group "Spells" and has level > 0
    local bisCastSpell = ( (nLevel > 0) and (sGroup == "spells") );

    -- this is so when they cast a spell it doesn't go away instantly
    -- otherwise they can't use save/damage/heal/etc
    -- it's reset when they toggle mode to standard/preparation mode
    local bWasMemorized = (DB.getValue(node,"wasmemorized",0) > 0);
    
    if bisCastSpell then
        if sMode == "combat" then
            if (bMemorized) then
                DB.setValue(node,"wasmemorized","number",1);
            end
            bShow = (bMemorized or bWasMemorized);
        else
            DB.setValue(node,"wasmemorized","number",0);
            bShow = true;
        end
    end
    
    return bShow;
end

function onDisplayChanged()
    local sDisplayMode = DB.getValue(getDatabaseNode(), "...powerdisplaymode", "");

    -- header nil when we're using this for spell records --celestian
    --if header ~= nil then
        if sDisplayMode == "summary" then
            header.subwindow.group.setVisible(false);
            header.subwindow.shortdescription.setVisible(true);
            --header.subwindow.actionsmini_pre.setVisible(false);
            header.subwindow.actionsmini.setVisible(false);
            header.subwindow.castinitiative.setVisible(false);
            header.subwindow.memorizedcount.setVisible(false);
        elseif sDisplayMode == "action" then
            header.subwindow.group.setVisible(false);
            header.subwindow.shortdescription.setVisible(false);
            --header.subwindow.actionsmini_pre.setVisible(true);
            header.subwindow.actionsmini.setVisible(true);
            header.subwindow.castinitiative.setVisible(true);
            header.subwindow.memorizedcount.setVisible(true);
        else
            header.subwindow.group.setVisible(true);
            header.subwindow.shortdescription.setVisible(false);
            --header.subwindow.actionsmini_pre.setVisible(false);
            header.subwindow.actionsmini.setVisible(false);
            header.subwindow.castinitiative.setVisible(false);
            header.subwindow.memorizedcount.setVisible(false);
        end

        -- if the spell can not be memorized, hide it
        if not PowerManager.canMemorizeSpell(getDatabaseNode()) then
            header.subwindow.memorizedcount.setVisible(false);
        end
        
        -- if init value is < 0 then just keep it hidden.
        -- might want to enable this so things other than spells can have
        -- a initiative, like potion, scroll and wand use? --celelstian
        -- local nInitMod = header.subwindow.castinitiative.getValue();
        -- if (nInitMod <= 0) then
            -- header.subwindow.castinitiative.setVisible(false);
        -- end
        
    --end
end

-- add action for spell/item
function createAction(sType)
	local nodeAttack = getDatabaseNode();
	if nodeAttack then
		local nodeActions = nodeAttack.createChild("actions");
		if nodeActions then
			local nodeAction = nodeActions.createChild();
			if nodeAction then
				DB.setValue(nodeAction, "type", "string", sType);
			end
		end
	end
end

function onMenuSelection(selection, subselection)
	if selection == 6 and subselection == 7 then
        cleanUpMemorization(getDatabaseNode());
		getDatabaseNode().delete();

	elseif selection == 4 then
		-- disabled reparse here also --celestian
        --PowerManager.parsePCPower(getDatabaseNode());
		--activatedetail.setValue(1);
	elseif selection == 3 then
		if subselection == 2 then
			createAction("cast");
			activatedetail.setValue(1);
		elseif subselection == 3 then
			createAction("damage");
			activatedetail.setValue(1);
		elseif subselection == 4 then
			createAction("heal");
			activatedetail.setValue(1);
		elseif subselection == 5 then
			createAction("effect");
			activatedetail.setValue(1);
		end
	end
end

-- this is to clean up and dangling memorized spells (since we disabled player
-- edit options on the tics) when a player decides to delete a memorized spell
-- AD&D, -celestian
function cleanUpMemorization(nodeSpell)
    local nodeChar = nodeSpell.getChild("...");

    local sSpellType = DB.getValue(nodeSpell, "type", ""):lower();
    local nLevel = DB.getValue(nodeSpell, "level", 0);
    local nMemorized = DB.getValue(nodeSpell, "memorized", 0);
    local nUsedArcane = DB.getValue(nodeChar, "powermeta.spellslots" .. nLevel .. ".used", 0);
    local nLeftOver = nUsedArcane - nMemorized;

    if (nMemorized > 0) then
        if (sSpellType == "arcane") then
            DB.setValue(nodeChar,"powermeta.spellslots" .. nLevel .. ".used","number",nLeftOver);
        elseif (sSpellType == "divine") then
            DB.setValue(nodeChar,"powermeta.pactmagicslots" .. nLevel .. ".used","number",nLeftOver);
        else
            DB.setValue(nodeChar,"powermeta.spellslots" .. nLevel .. ".used","number",nLeftOver);
        end
    end
end

-- create a cast action
function createActionCast() 
	createAction("cast");
	activatedetail.setValue(1);
end

function toggleDetail()
	local status = (activatedetail.getValue() == 1);
--Debug.console("power_item.lua","toggleDetail","status",status);    
	
    -- actions can be nil when using this in spell records --celestian
	--if actions ~= nil then 
        actions.setVisible(status);
        initiative.setVisible(status);
        local node = getDatabaseNode();
--Debug.console("power_item.lua","toggleDetail","node1",node);    
        if PowerManager.canMemorizeSpell(node) then
--Debug.console("power_item.lua","toggleDetail","node2",node);    
            memorization.setVisible(status);
        else
--Debug.console("power_item.lua","toggleDetail","node3",node);    
            memorization.setVisible(false);
        end
        
        for _,v in pairs(actions.getWindows()) do
            v.updateDisplay();
        end
    --end
--Debug.console("power_item.lua","toggleDetail","END");    
end

function getDescription(bShowFull)
	local node = getDatabaseNode();
	
	local s = DB.getValue(node, "name", "");
	
	if bShowFull then
		local sShort = DB.getValue(node, "shortdescription", "");
		if sShort ~= "" then
			s = s .. " - " .. sShort;
		end
	end

	return s;
end

function usePower(bShowFull)
	local node = getDatabaseNode();
	ChatManager.Message(getDescription(bShowFull), true, ActorManager.getActor("pc", node.getChild("...")));
end
