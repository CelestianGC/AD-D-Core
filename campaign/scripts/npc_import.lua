-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
--Debug.console("npc_import.lua","onInit","getDatabaseNode",getDatabaseNode());
end


function createBlankNPC()
--	local node = window.getDatabaseNode().createChild();
--	local node = getDatabaseNode().createChild();
    local node = DB.createChild("npc"); 
Debug.console("npc_import.lua","createTable","node",node);    

	if node then
		local w = Interface.openWindow("npc", node.getNodeName());
		if w and w.header and w.header.subwindow and w.header.subwindow.name then
			w.header.subwindow.name.setFocus();
		end
	end
    return node;
end

function importTextAsNPC()
    local sText = npcimporttext.getValue() or "";
Debug.console("npc_import.lua","importTextAsNPC","sText",sText);    
    if (sText ~= "") then
      local aNPCText = {};
      for sLine in string.gmatch(sText, '([^\r\n]+)') do
          table.insert(aNPCText, sLine);
      end
      local nodeNPC = createBlankNPC();

      -- flip through the text, each entry is a line
      for _,sLine in ipairs(aNPCText) do
        -- each line is flipped through
      end
    end
end
