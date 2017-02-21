-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onToggle()
	windowlist.onHeaderToggle(self);
end

local bFilter = true;
function setFilter(bNewFilter)
	bFilter = bNewFilter;
end
function getFilter()
	return bFilter;
end

local nodeGroup = nil;
function setNode(node)
	nodeGroup = node;
	if nodeGroup then
		link.setVisible(true);
	else
		link.setVisible(false);
	end
end
function getNode()
	return nodeGroup;
end

function deleteGroup()
	if nodeGroup then
		nodeGroup.delete();
	end
end

function setHeaderCategory(rGroup, sGroup, nLevel, bAllowDelete)
	if sGroup == "" then
		name.setValue(Interface.getString("char_label_powers"));
		name.setIcon("char_abilities_orange");
	else
		if rGroup.grouptype ~= "" then
			if not nLevel then
				name.setValue(sGroup);
			elseif nLevel == 0 then
				name.setValue(sGroup .. " (" .. Interface.getString("power_label_groupcantrips") .. ")");
			else
				name.setValue(sGroup .. " (" .. Interface.getString("level") .. " " .. nLevel .. ")");
			end
			name.setIcon("char_powers");
			level.setValue(nLevel);
		else
			name.setValue(sGroup);
			name.setIcon("char_abilities_orange");
		end
		group.setValue(sGroup);
		setNode(rGroup.node);
		if bAllowDelete then
			idelete.setVisibility(true);
		end
	end
end

