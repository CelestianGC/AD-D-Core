--
-- Code to manage combox box selection in record_char_weapon.xml
--
--
--
function onInit()
  super.onInit();
  local node = getDatabaseNode();
  local nodeChar = node.getChild("......");
  -- this should cause the values to update should the player tweak their profs.
  DB.addHandler(DB.getPath(nodeChar, "proficiencylist"),"onChildUpdate", updateAllAdjustments);
  
  updateAllAdjustments();
end

function onClose()
  local node = getDatabaseNode();
  local nodeChar = node.getChild("......");
  DB.removeHandler(DB.getPath(nodeChar,"proficiencylist"),"onChildUpdate", updateAllAdjustments);
end

-- when value changed, update hit/dmg
function onValueChanged()
  local node = getDatabaseNode();
  updateAdjustments(node);
end

-- update hit/damage adjustments from Proficiency in the abilities tab
function updateAdjustments(node)
  -- update hit/dmg modifiers for prof
  -- flip through proflist
  local nodeChar = node.getChild("......");
  local sSource = DB.getValue(node.getParent(),"prof_selected","");
  local prof = getProf(nodeChar,sSource);
  
  if prof then
    local nHitAdj = prof.hitadj;
    local nDMGAdj = prof.dmgadj;
    window.hitadj.setValue(nHitAdj);
    window.dmgadj.setValue(nDMGAdj);
  else
--Debug.console("prof_select.lua","updateAdjustments","!prof");
  end
end


-- update all adjustments for this weapon
-- we do this when a proficiency is updated in the abilities tab
function updateAllAdjustments()
  -- update hit/dmg modifiers
  -- flip through proflist
  local node = getDatabaseNode();
  local nodeWeapon = node.getChild("....");
  local nodeChar = node.getChild("......");
  setProfList(nodeChar);
  
  for _,v in pairs(DB.getChildren(nodeWeapon, "proflist")) do
    --local svName = DB.getValue(v,"prof_selected","Unnamed");
    local sSource = DB.getValue(v,"prof_selected","");
    local prof = getProf(nodeChar,sSource);
    if prof then 
      local nHitAdj = prof.hitadj;
      local nDMGAdj = prof.dmgadj;
      DB.setValue(v,"hitadj","number",nHitAdj);
      DB.setValue(v,"dmgadj","number",nDMGAdj);
    end
  end
end

-- fill in the drop down list values
function setProfList(nodeChar)
  clear(); -- (removed existing items in list)
  -- sort through player's list of profs and add them
  -- proficiencylist
  for _,v in pairs(DB.getChildren(nodeChar, "proficiencylist")) do
    local sName = DB.getValue(v, "name", "");
    add(v.getPath(),sName);
  end
end

-- get prof hit/dmg adjustments by name of prof
function getProf(nodeChar,sSource)
  local nodeProf = DB.findNode(sSource);
  if (nodeProf) then 
    local prof = {};
    prof.name = DB.getValue(nodeProf,"name","");
    prof.hitadj = DB.getValue(nodeProf,"hitadj",0);
    prof.dmgadj = DB.getValue(nodeProf,"dmgadj",0);
    prof.source = sSource;
    return prof;
  else
    return nil;
  end
end
