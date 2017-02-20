-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if User.isHost() then
		registerMenuItem(Interface.getString("menu_rest"), "lockvisibilityon", 8);
		registerMenuItem(Interface.getString("menu_restshort"), "pointer_cone", 8, 8);
		registerMenuItem(Interface.getString("menu_restlong"), "pointer_circle", 8, 6);
	end

	if User.isLocal() then
		portrait.setVisible(false);
		localportrait.setVisible(true);
	end

	OptionsManager.registerCallback("HRIS", onHRISOptionChanged);
	onHRISOptionChanged();
end

function onClose()
	OptionsManager.unregisterCallback("HRIS", onHRISOptionChanged);
end

function onHRISOptionChanged()
	local sOptHRIS = OptionsManager.getOption("HRIS");
	local nOptHRIS = math.min(math.max(tonumber(sOptHRIS) or 1, 1), 3);
	
	if inspiration.getMaxValue() ~= nOptHRIS then
		inspiration.setMaxValue(nOptHRIS);
		inspiration.updateSlots();
	end
	inspiration.setAnchor("left", "inspirationtitle", "center", "absolute", -5 * nOptHRIS);
end

function onMenuSelection(selection, subselection)
	if selection == 8 then
		local nodeChar = getDatabaseNode();
		
		if subselection == 8 then
			ChatManager.Message(Interface.getString("message_restshort"), true, ActorManager.getActor("pc", nodeChar));
			CharManager.rest(nodeChar, false);
		elseif subselection == 6 then
			ChatManager.Message(Interface.getString("message_restlong"), true, ActorManager.getActor("pc", nodeChar));
			CharManager.rest(nodeChar, true);
		end
	end
end
