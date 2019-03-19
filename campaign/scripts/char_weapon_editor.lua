--
--
--
--

-- allows drag/drop of dice to damage and profs to apply
function onDrop(x, y, draginfo)
  local sDragType = draginfo.getType();
  local sClass = draginfo.getShortcutData();
  if sDragType == "dice" then
    local w = list.addEntry(true);
    for _, vDie in ipairs(draginfo.getDieList()) do
      w.dice.addDie(vDie.type);
    end
    return true;
  elseif sDragType == "number" then
    local w = list.addEntry(true);
    w.bonus.setValue(draginfo.getNumberData());
    return true;
  -- add prof to weapon
  elseif sDragType == "shortcut" and draginfo.getShortcutData() == "ref_proficiency_item" then
    local nodeWeapon = getDatabaseNode();
    local nodeProfDragged = draginfo.getDatabaseNode();
    local sProfSelected = nodeProfDragged.getPath();
    if not profExists(nodeWeapon,sProfSelected) then
      local nodeProfList = DB.createChild(nodeWeapon,"proflist");
      local nodeProf = nodeProfList.createChild();
      DB.setValue(nodeProf,"prof","string",DB.getValue(nodeProfDragged,"name"));
      DB.setValue(nodeProf,"dmgadj","number",DB.getValue(nodeProfDragged,"dmgadj"));
      DB.setValue(nodeProf,"hitadj","number",DB.getValue(nodeProfDragged,"hitadj"));
      DB.setValue(nodeProf,"prof_selected","string",sProfSelected);
      return true;
    end
  end
end

-- make sure that we do not already have a prof selected for this 
function profExists(nodeWeapon,sProf)
  local bExists = false;
  
  for _,nodeProfs in pairs(DB.getChildren(nodeWeapon, "proflist")) do
    local sProfSelected = DB.getValue(nodeProfs,"prof_selected","");
    if (sProf == sProfSelected) then
      bExists = true;
      break;
    end
  end
  
  return bExists;
end    