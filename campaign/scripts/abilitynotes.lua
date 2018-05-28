--
--
--
--

-- drag/drop encounter/notes entry onto a abilitynotes and create
function onDrop(x, y, draginfo)
  if draginfo.isType("shortcut") then
    local node = getDatabaseNode();
    local sClass, sRecord = draginfo.getShortcutData();
    if (sClass == "encounter") then
      local nodeEncounter = DB.findNode(sRecord);
      if (nodeEncounter) then
        local nodeNotes = node.createChild("abilitynoteslist");
        local nodeNote = nodeNotes.createChild();
        local sName = DB.getValue(nodeEncounter,"name","");
        local sText = DB.getValue(nodeEncounter,"text","");
        local nLocked = DB.getValue(nodeEncounter,"locked",0);
        DB.setValue(nodeNote,"name","string",sName);
        DB.setValue(nodeNote,"text","formattedtext",sText);
        DB.setValue(nodeNote,"locked","number",nLocked);
      end
    end
    return true;
  end
end

