function onInit()
    local nodeChar = getDatabaseNode();
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.percentbase"),      "onUpdate", detailsPercentUpdate);
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.percentbasemod"),   "onUpdate", detailsPercentUpdate);
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.percentitemmod"),   "onUpdate", detailsPercentUpdate);
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.percenteffectmod"), "onUpdate", detailsPercentUpdate);
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.percentadjustment"),"onUpdate", detailsPercentUpdate);
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.percenttempmod"),   "onUpdate", detailsPercentUpdate);

    DB.addHandler(DB.getPath(nodeChar, "abilities.*.base"),       "onUpdate", detailsUpdate);
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.basemod"),    "onUpdate", detailsUpdate);
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.itemmod"),    "onUpdate", detailsUpdate);
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.effectmod"),  "onUpdate", detailsUpdate);
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.adjustment"), "onUpdate", detailsUpdate);
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.tempmod"),    "onUpdate", detailsUpdate);

    detailsPercentUpdate();
    detailsUpdate();
end

function onClose()
    local nodeChar = getDatabaseNode();
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.percentbase"),       "onUpdate", detailsPercentUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.percentbasemod"),    "onUpdate", detailsPercentUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.percentitemmod"),    "onUpdate", detailsPercentUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.percenteffectmod"),  "onUpdate", detailsPercentUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.percentadjustment"), "onUpdate", detailsPercentUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.percenttempmod"),    "onUpdate", detailsPercentUpdate);

    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.base"),       "onUpdate", detailsUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.basemod"),    "onUpdate", detailsUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.itemmod"),    "onUpdate", detailsUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.effectmod"),  "onUpdate", detailsUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.adjustment"), "onUpdate", detailsUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.tempmod"),    "onUpdate", detailsUpdate);

end


--
-- for AD&D Core, abilities menu
--
--

function detailsUpdate()
    local nodeChar = getDatabaseNode();
    
    --Debug.console("char_abilities_details.lua","detailsUpdate","sTarget",sTarget);
    for i = 1,6,1 do
        local sTarget = DataCommon.abilities[i];
        local nBase =       DB.getValue(nodeChar, "abilities." .. sTarget .. ".base",9);
        local nBaseMod =    DB.getValue(nodeChar, "abilities." .. sTarget .. ".basemod",0);
        local nItemMod =    DB.getValue(nodeChar, "abilities." .. sTarget .. ".itemmod",0);
        local nEffectMod =  DB.getValue(nodeChar, "abilities." .. sTarget .. ".effectmod",0);
        local nAdjustment = DB.getValue(nodeChar, "abilities." .. sTarget .. ".adjustment",0);
        local nTempMod =    DB.getValue(nodeChar, "abilities." .. sTarget .. ".tempmod",0);
        local nFinalBase = nBase;

        if (nBaseMod ~= 0) then
            nFinalBase = nBaseMod;
        end
        
        local nTotal = (nFinalBase + nItemMod + nEffectMod + nAdjustment + nTempMod);
        if (nTotal < 1) then
            nTotal = 1;
        end
        if (nTotal > 25) then
            nTotal = 25;
        end
        DB.setValue(nodeChar, "abilities." .. sTarget .. ".score","number", nTotal);
        --setValue(nTotal);
    end
end

function detailsPercentUpdate()
    local nodeChar = getDatabaseNode();

    for i = 1,6,1 do
        local sTarget = DataCommon.abilities[i];
        local nBase =       DB.getValue(nodeChar, "abilities." .. sTarget .. ".percentbase",0);
        local nBaseMod =    DB.getValue(nodeChar, "abilities." .. sTarget .. ".percentbasemod",0);
        local nItemMod =    DB.getValue(nodeChar, "abilities." .. sTarget .. ".percentitemmod",0);
        local nEffectMod =  DB.getValue(nodeChar, "abilities." .. sTarget .. ".percenteffectmod",0);
        local nAdjustment = DB.getValue(nodeChar, "abilities." .. sTarget .. ".percentadjustment",0);
        local nTempMod =    DB.getValue(nodeChar, "abilities." .. sTarget .. ".percenttempmod",0);
        local nFinalBase = nBase;

        if (nBaseMod ~= 0) then
            nFinalBase = nBaseMod;
        end
        
        local nTotal = (nFinalBase + nItemMod + nEffectMod + nAdjustment + nTempMod);
        if (nTotal < 1) then
            nTotal = 0;
        end
        if (nTotal > 100) then
            nTotal = 100;
        end
        DB.setValue(nodeChar, "abilities." .. sTarget .. ".percent","number", nTotal);
        --setValue(nTotal);
    end
end

function onDrop(x, y, draginfo)
    if draginfo.isType("shortcut") then
        local sClass, sRecord = draginfo.getShortcutData();

        if StringManager.contains({"reference_class", "reference_race", "reference_subrace", "reference_background"}, sClass) then
            CharManager.addInfoDB(getDatabaseNode(), sClass, sRecord);
            if StringManager.contains({"reference_class"}, sClass) then
                Interface.openWindow("charsheet_classes", getDatabaseNode());
            end
            return true;
        end
    end
end

function onHealthChanged()
    local sColor = ActorManager2.getWoundColor("pc", getDatabaseNode());
    wounds.setColor(sColor);
end
