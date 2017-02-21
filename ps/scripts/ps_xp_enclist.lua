-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onListChanged()
	update();
end

function update()
	local bEditMode = (window.enc_iedit.getValue() == 1);
	for _,w in ipairs(getWindows()) do
		w.idelete.setVisibility(bEditMode);
	end
end

function deleteAll()
	for k, v in pairs(getWindows()) do
		v.getDatabaseNode().delete();
	end
end
