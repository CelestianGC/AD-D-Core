-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bFilter = true;
function setFilter(bNewFilter)
	bFilter = bNewFilter;
end
function getFilter()
	return bFilter;
end

function onInit()
	if not windowlist.isReadOnly() then
		registerMenuItem(Interface.getString("list_menu_deleteitem"), "delete", 6);
		registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 6, 7);

		registerMenuItem(Interface.getString("power_menu_addaction"), "pointer", 3);
		registerMenuItem(Interface.getString("power_menu_addcast"), "radial_sword", 3, 2);
		registerMenuItem(Interface.getString("power_menu_adddamage"), "radial_damage", 3, 3);
		registerMenuItem(Interface.getString("power_menu_addheal"), "radial_heal", 3, 4);
		registerMenuItem(Interface.getString("power_menu_addeffect"), "radial_effect", 3, 5);
		
		registerMenuItem(Interface.getString("power_menu_reparse"), "textlist", 4);
	end

	--Check to see if we should automatically parse attack description
	local nodeAttack = getDatabaseNode();
	local nParse = DB.getValue(nodeAttack, "parse", 0);
	if nParse ~= 0 then
		DB.setValue(nodeAttack, "parse", "number", 0);
		PowerManager.parsePCPower(nodeAttack);
	end
	
	onDisplayChanged();
	windowlist.onChildWindowAdded(self);
end

function onDisplayChanged()
	sDisplayMode = DB.getValue(getDatabaseNode(), "...powerdisplaymode", "");

	if sDisplayMode == "summary" then
		header.subwindow.group.setVisible(false);
		header.subwindow.shortdescription.setVisible(true);
		header.subwindow.actionsmini.setVisible(false);
	elseif sDisplayMode == "action" then
		header.subwindow.group.setVisible(false);
		header.subwindow.shortdescription.setVisible(false);
		header.subwindow.actionsmini.setVisible(true);
	else
		header.subwindow.group.setVisible(true);
		header.subwindow.shortdescription.setVisible(false);
		header.subwindow.actionsmini.setVisible(false);
	end
end

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
		getDatabaseNode().delete();
	elseif selection == 4 then
		PowerManager.parsePCPower(getDatabaseNode());
		activatedetail.setValue(1);
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

function toggleDetail()
	local status = (activatedetail.getValue() == 1);
	
	actions.setVisible(status);

	for _,v in pairs(actions.getWindows()) do
		v.updateDisplay();
	end
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
