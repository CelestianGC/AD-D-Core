-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onListChanged()
	update();
end

function update()
	local bEditMode = (window.quests_iedit.getValue() == 1);
	for _,w in ipairs(getWindows()) do
		w.idelete.setVisibility(bEditMode);
	end
end

function addEntry(bFocus)
	local w = createWindow();
	if w and bFocus then
		w.name.setFocus();
	end
	return w;
end

function deleteAll()
	for _,v in pairs(getWindows()) do
		v.getDatabaseNode().delete();
	end
end
