-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerMenuItem(Interface.getString("ct_menu_effectdelete"), "deletepointer", 3);
	registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 3, 3);
end

function onMenuSelection(selection, subselection)
	if selection == 3 and subselection == 3 then
		windowlist.deleteChild(self, true);
	end
end

function onDragStart(button, x, y, draginfo)
	local rEffect = {};
	rEffect.sName = label.getValue();
	rEffect.nDuration = duration.getValue();
	rEffect.nInit = init.getValue();
	rEffect.sSource = source_name.getValue();
	rEffect.nGMOnly = isgmonly.getValue();
	rEffect.sApply = apply.getStringValue();

	return ActionEffect.performRoll(draginfo, nil, rEffect);
end

function onDrop(x, y, draginfo)
	if draginfo.isType("combattrackerentry") then
		local nodeCTSource = draginfo.getCustomData();
		if nodeCTSource then
			local nodeWin = windowlist.window.getDatabaseNode();
			if nodeWin then
				if nodeCTSource.getNodeName() == nodeWin.getNodeName() then
					source.setSource("");
				else
					source.setSource(nodeCTSource.getNodeName());
					init.setValue(DB.getValue(nodeCTSource, "initresult", 0));
				end
			end
		end
		return true;
	end
end
