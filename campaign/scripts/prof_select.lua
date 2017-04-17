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
    local sFindName = window.profselected.getValue();
    local prof = getProf(nodeChar,sFindName);
    
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
        local svName = DB.getValue(v,"profselected","Unnamed");
        local prof = getProf(nodeChar,svName);
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
    -- sort through player's list of profs and add them
    -- proficiencylist
    local aProfs = {};
    local bNonProf = false;
    for _,v in pairs(DB.getChildren(nodeChar, "proficiencylist")) do
        local sName = DB.getValue(v, "name", "");
        local sNameLower = sName:lower();
        if (sName ~= "") then
            -- at some point this will be a default prof, applies 
            -- the non-proficiency adjustment
            if StringManager.contains({"not-prof", "non-prof","non prof", "not prof"}, sNameLower) then
                bNonProf = true;
            end
            -- add to list of profs
            table.insert(aProfs,sName);
        end
    end
    
    -- if not bNonProf then
            -- table.insert(aProfs,"Not-Proficient");
    -- end
    
    clear(); -- (removed existing items in list)
    addItems(aProfs); -- add prof list to drop down
end

-- get prof hit/dmg adjustments by name of prof
function getProf(nodeChar,sFindName)
    local sFindNameLower = sFindName:lower();
    local prof = {};
    prof.name = sFindName;
    
    local bFoundMatch = false;
    for _,v in pairs(DB.getChildren(nodeChar, "proficiencylist")) do
        local sName = DB.getValue(v, "name", "");
        local sNameLower = sName:lower();
        if (sNameLower == sFindNameLower) then
            bFoundMatch = true;
            prof.hitadj = DB.getValue(v,"hitadj",0);
            prof.dmgadj = DB.getValue(v,"dmgadj",0);
            break;
        end
    end
    
    if bFoundMatch then
        return prof;
    else
        return nil;
    end
end
