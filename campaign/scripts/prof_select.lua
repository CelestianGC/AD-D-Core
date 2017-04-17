--
-- Code to manage combox box selection in record_char_weapon.xml
--
--
--
function onInit()
Debug.console("prof_select.lua","onInit","RAN");
    super.onInit();
    local node = getDatabaseNode();
    local nodeChar = node.getChild("......");
    -- this should cause the values to update should the player tweak their profs.
    DB.addHandler(DB.getPath(nodeChar, "proficiencylist"),"onChildUpdate", updateAllAdjustments);
    
    updateAllAdjustments();
    
    Debug.console("prof_select.lua","onInit","getItems",getItems());
end

function onClose()
    local node = getDatabaseNode();
    local nodeChar = node.getChild("......");
    DB.removeHandler(DB.getPath(nodeChar,"proficiencylist"),"onChildUpdate", updateAllAdjustments);
end

function onValueChanged()
Debug.console("prof_select.lua","onValueChanged","RAN");
    local node = getDatabaseNode();
    updateAdjustments(node);
end

function updateAdjustments(node)
    -- update hit/dmg modifiers
    -- flip through proflist
    local nodeChar = node.getChild("......");
    local sFindName = window.profselected.getValue();
Debug.console("prof_select.lua","updateAdjustments","sFindName",sFindName);
    local prof = getProf(nodeChar,sFindName);
    
    if prof then
Debug.console("prof_select.lua","updateAdjustments","prof",prof);
        local nHitAdj = prof.hitadj;
        local nDMGAdj = prof.dmgadj;
        window.hitadj.setValue(nHitAdj);
        window.dmgadj.setValue(nDMGAdj);
    else
Debug.console("prof_select.lua","updateAdjustments","!prof");
    end
    
Debug.console("prof_select.lua","updateAdjustments","nodeWeapon",nodeWeapon);
    
Debug.console("prof_select.lua","updateAdjustments","RAN");
end

-- update all adjustments for this weapon
function updateAllAdjustments()
    -- update hit/dmg modifiers
    -- flip through proflist
    local node = getDatabaseNode();
    local nodeWeapon = node.getChild("....");
    local nodeChar = node.getChild("......");
    setProfList(nodeChar);
    
    for _,v in pairs(DB.getChildren(nodeWeapon, "proflist")) do
        local svName = DB.getValue(v,"profselected","Unnamed");
        local prof = getProf(nodeChar,svName);
        if prof then 
            local nHitAdj = prof.hitadj;
            local nDMGAdj = prof.dmgadj;
            DB.setValue(v,"hitadj","number",nHitAdj);
            DB.setValue(v,"dmgadj","number",nDMGAdj);
        end
    end
Debug.console("prof_select.lua","updateAllAdjustments","nodeWeapon",nodeWeapon);
    
Debug.console("prof_select.lua","updateAllAdjustments","RAN");
end

-- fill in the drop down list values
function setProfList(nodeChar)
    Debug.console("prof_select.lua","setProfList","RAN");
    -- sort through player's list of profs and add them
    Debug.console("prof_select.lua","setProfList","nodeChar",nodeChar);
    -- proficiencylist
    local aProfs = {};
    local bNonProf = false;
    for _,v in pairs(DB.getChildren(nodeChar, "proficiencylist")) do
        local sName = DB.getValue(v, "name", "");
        local sNameLower = sName:lower();
    Debug.console("prof_select.lua","setProfList","sName",sName);
        if (sName ~= "") then
            if StringManager.contains({"not-prof", "non-prof","non prof", "not prof"}, sNameLower) then
    Debug.console("prof_select.lua","setProfList","sNameLower",sNameLower);
                bNonProf = true;
            end
            table.insert(aProfs,sName);
        end
    end
    if not bNonProf then
            table.insert(aProfs,"Not-Proficient");
    end
    clear(); -- (removed existing items in list)
    addItems(aProfs);
    
    -- add("Not-Proficient");
    -- add("Longsword");
    -- add("Dagger");
    -- add("Short bow");
    -- add("Racial: Elf Bow");
    -- add("Racial: Elf Sword");
end

function getProf(nodeChar,sFindName)
    local sFindNameLower = sFindName:lower();
    local prof = {};
    prof.name = sFindName;
    
    local bFoundMatch = false;
    for _,v in pairs(DB.getChildren(nodeChar, "proficiencylist")) do
        local sName = DB.getValue(v, "name", "");
    Debug.console("prof_select.lua","getProf","sName",sName);
        local sNameLower = sName:lower();
        if (sNameLower == sFindNameLower) then
    Debug.console("prof_select.lua","getProf","sNameLower FOUND",sNameLower);
            bFoundMatch = true;
            prof.hitadj = DB.getValue(v,"hitadj",0);
            prof.dmgadj = DB.getValue(v,"dmgadj",0);
            break;
        end
    end
    
    if bFoundMatch then
    Debug.console("prof_select.lua","getProf","bFoundMatch",bFoundMatch);
        return prof;
    else
    Debug.console("prof_select.lua","getProf","bFoundMatch",bFoundMatch);
        return nil;
    end
end
