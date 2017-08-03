-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
end

-- createTable(1, 1);
function createTable(nRows, nStep, bSpecial)
	local node = window.getDatabaseNode().createChild();
	if node then
		local w = Interface.openWindow("table", node.getNodeName());
		TableManager.createRows(node, nRows, nStep, bSpecial);
		if w and w.name then
			w.name.setFocus();
		end
	end
end

function importTextAsTable()
    local sText = tableimporttext.getValue() or "";

Debug.console("table_import.lua","importTextAsTable","sText",sText);    

    if (sText ~= "") then
    end
    
end
