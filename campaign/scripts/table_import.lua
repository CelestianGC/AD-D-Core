-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
--Debug.console("table_import.lua","onInit","window.getDatabaseNode",window.getDatabaseNode());    
--Debug.console("table_import.lua","onInit","getDatabaseNode",getDatabaseNode());    
end


function createBlankTable()
--	local node = window.getDatabaseNode().createChild();
--	local node = getDatabaseNode().createChild();
    local node = DB.createChild("tables"); 
--Debug.console("table_import.lua","createTable","node",node);    

	if node then
		local w = Interface.openWindow("table", node.getNodeName());
		--TableManager.createRows(node, nRows, nStep, bSpecial);
		if w and w.name then
			w.name.setFocus();
		end
	end
    return node;
end

function importTextAsTable()
    local sText = tableimporttext.getValue() or "";

--Debug.console("table_import.lua","importTextAsTable","sText",sText);    

    if (sText ~= "") then
        local aTableText = {};
        for sLine in string.gmatch(sText, '([^\r\n]+)') do
            table.insert(aTableText, sLine);
        end
        
        local nodeTable = createBlankTable();
        local nNewRow = 0;
        if (nodeTable) then
            local nodeTableRows = nodeTable.createChild("tablerows");
            for _,sTableLines in ipairs(aTableText) do
                nNewRow = nNewRow + 1;
                local nodeRow = nodeTableRows.createChild();
                DB.setValue(nodeRow, "fromrange", "number", nNewRow);
                DB.setValue(nodeRow, "torange", "number", nNewRow);
                local nodeResults = nodeRow.createChild("results");
                local nodeResult = nodeResults.createChild();
                DB.setValue(nodeResult, "result", "string", sTableLines);
            end
        end
    end
end
