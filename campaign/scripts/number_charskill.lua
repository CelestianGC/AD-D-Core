


function onInit()
    local nodeChar = window.getDatabaseNode().getChild("...");
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.score"), "onUpdate", onSourceUpdate);
    DB.addHandler(DB.getPath(nodeChar, "profbonus"), "onUpdate", onSourceUpdate);

    addSource("adj_class");
    addSource("adj_armor");
    addSource("adj_mod");
    addSource("adj_stat");
    addSource("base_check");

    addSource("stat", "string");
    addSource("prof");
    addSourceWithOp("misc", "+");

    super.onInit();
end

function onClose()
    local nodeChar = window.getDatabaseNode().getChild("...");
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.score"), "onUpdate", onSourceUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "profbonus"), "onUpdate", onSourceUpdate);

end

function onSourceUpdate(node)
    local nValue = 0;

    local nodeSkill = window.getDatabaseNode();
    local nodeChar = nodeSkill.getChild("...");

    local sAbility = DB.getValue(nodeSkill, "stat", "");


    --
    local nBaseCheck = DB.getValue(nodeSkill, "base_check", 0);
    local nClassADJ = DB.getValue(nodeSkill, "adj_class", 0);
    local nArmorADJ = DB.getValue(nodeSkill, "adj_armor", 0);
    local nStatADJ = DB.getValue(nodeSkill, "adj_stat", 0);
    local nModADJ = DB.getValue(nodeSkill, "adj_mod", 0);
    local nMisc = DB.getValue(nodeSkill, "misc", 0);
    -- -msw 
    if sAbility == "percent" then
        --DB.getPath(nodeChar, "base_check").show(true);
        -- add stuff to deal with percentile checks
        nValue = nValue + nBaseCheck;
    elseif sAbility ~= "" then
        --DB.getPath(nodeChar, "base_check").show(false);
        -- local nScore = DB.getValue(nodeChar, "abilities." .. sAbility .. ".score", 0)
        -- AD&D doesn't do this -msw
        -- nValue = nValue + math.floor((nScore - 10) / 2);

        local nAbilityScore = DB.getValue(nodeChar, "abilities." .. sAbility .. ".score", 0);
        --DB.setValue(nodeSkill, "base_check","number", nAbilityScore);
        nValue = nValue + nAbilityScore;
    else
        --DB.setValue(nodeSkill, "base_check","number", 0);
    end
    
        -- not sure what I'm going to do with this. Perhaps will use it for weapon profs? -msw
--    local nProf = DB.getValue(nodeSkill, "prof", 0);
--    if nProf == 1 then
--        nValue = nValue + DB.getValue(nodeChar, "profbonus", 0);
--    elseif nProf == 2 then
--        nValue = nValue + (2 * DB.getValue(nodeChar, "profbonus", 0));
--    elseif nProf == 3 then
--        nValue = nValue + math.floor(DB.getValue(nodeChar, "profbonus", 0) / 2);
--    end
    

    nValue = nValue + nClassADJ + nModADJ + nStatADJ + nArmorADJ +  nMisc;
    --DB.setValue(nodeSkill, "total","number", nValue);
    setValue(nValue);
end

function action(draginfo)
    local nodeSkill = window.getDatabaseNode();
    local nodeChar = nodeSkill.getChild("...");
    local rActor = ActorManager.getActor("pc", nodeChar);
    local sAbility = DB.getValue(nodeSkill, "stat", "");
    local nTargetDC = DB.getValue(nodeSkill, "total", 20);
    
    -- if sAbility == "percent" then
        -- -- add stuff to deal with percentile checks
        -- nTargetDC = DB.getValue(nodeSkill, "base_check", 0);
        -- Debug.console("number_charskill.lua","action","nTargetDC", nTargetDC);
    -- elseif sAbility ~= "" then
        -- nTargetDC = DB.getValue(nodeChar, "abilities." .. sAbility .. ".score", 0)
        -- Debug.console("number_charskill.lua","action","sAbility", nTargetDC);
    -- end
    
    ActionSkill.performRoll(draginfo, rActor, nodeSkill, nTargetDC);

    return true;
end

function onDragStart(button, x, y, draginfo)
    return action(draginfo);
end
    
function onDoubleClick(x,y)
    return action();
end
