--
--
-- Functions for the character sheet.
--
--

function onInit()
    local nodeChar = getDatabaseNode();
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.percentbase"),      "onUpdate", detailsPercentUpdate);
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.percentbasemod"),   "onUpdate", detailsPercentUpdate);
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.percentadjustment"),"onUpdate", detailsPercentUpdate);
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.percenttempmod"),   "onUpdate", detailsPercentUpdate);

    DB.addHandler(DB.getPath(nodeChar, "abilities.*.base"),       "onUpdate", detailsUpdate);
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.basemod"),    "onUpdate", detailsUpdate);
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.adjustment"), "onUpdate", detailsUpdate);
    DB.addHandler(DB.getPath(nodeChar, "abilities.*.tempmod"),    "onUpdate", detailsUpdate);

    DB.addHandler(DB.getPath(nodeChar, "abilities.strength.total"),    "onUpdate", updateStrength);
    DB.addHandler(DB.getPath(nodeChar, "abilities.strength.percenttotal"),    "onUpdate", updateStrength);
    DB.addHandler(DB.getPath(nodeChar, "abilities.constitution.total"),"onUpdate", updateConstitution);
    DB.addHandler(DB.getPath(nodeChar, "abilities.intelligence.total"),"onUpdate", updateIntelligence);
    DB.addHandler(DB.getPath(nodeChar, "abilities.wisdom.total"),       "onUpdate", updateWisdom);
    DB.addHandler(DB.getPath(nodeChar, "abilities.dexterity.total"),    "onUpdate", updateDexterity);
    DB.addHandler(DB.getPath(nodeChar, "abilities.charisma.total"),     "onUpdate", updateCharisma);
    
    detailsPercentUpdate();
    detailsUpdate();
end

function onClose()
    local nodeChar = getDatabaseNode();
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.percentbase"),       "onUpdate", detailsPercentUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.percentbasemod"),    "onUpdate", detailsPercentUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.percentadjustment"), "onUpdate", detailsPercentUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.percenttempmod"),    "onUpdate", detailsPercentUpdate);

    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.base"),       "onUpdate", detailsUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.basemod"),    "onUpdate", detailsUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.adjustment"), "onUpdate", detailsUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.*.tempmod"),    "onUpdate", detailsUpdate);

    DB.removeHandler(DB.getPath(nodeChar, "abilities.strength.total"),    "onUpdate", updateStrength);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.strength.percenttotal"),    "onUpdate", updateStrength);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.constitution.total"),"onUpdate", updateConstitution);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.intelligence.total"),"onUpdate", updateIntelligence);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.wisdom.total"),       "onUpdate", updateWisdom);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.dexterity.total"),    "onUpdate", updateDexterity);
    DB.removeHandler(DB.getPath(nodeChar, "abilities.charisma.total"),     "onUpdate", updateCharisma);
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
        -- local nBaseItem  =   DB.getValue(nodeChar, "abilities." .. sTarget .. ".baseitem",0);
        -- local nItemMod =    DB.getValue(nodeChar, "abilities." .. sTarget .. ".itemmod",0);
        -- local nEffectMod =  DB.getValue(nodeChar, "abilities." .. sTarget .. ".effectmod",0);
        local nAdjustment = DB.getValue(nodeChar, "abilities." .. sTarget .. ".adjustment",0);
        local nTempMod =    DB.getValue(nodeChar, "abilities." .. sTarget .. ".tempmod",0);
        local nFinalBase = nBase;

        if (nBaseMod ~= 0) then
            nFinalBase = nBaseMod;
        end
        -- if (nBaseItem > nBaseMod) then
            -- nFinalBase = nBaseItem;
        -- end
--        local nTotal = (nFinalBase + nItemMod + nEffectMod + nAdjustment + nTempMod);
        local nTotal = (nFinalBase + nAdjustment + nTempMod);
        if (nTotal < 1) then
            nTotal = 1;
        end
        if (nTotal > 25) then
            nTotal = 25;
        end
        DB.setValue(nodeChar, "abilities." .. sTarget .. ".score","number", nTotal);
        DB.setValue(nodeChar, "abilities." .. sTarget .. ".total","number", nTotal);
        --setValue(nTotal);
    end
end

function detailsPercentUpdate()
    local nodeChar = getDatabaseNode();

    for i = 1,6,1 do
        local sTarget = DataCommon.abilities[i];
        local nBase =       DB.getValue(nodeChar, "abilities." .. sTarget .. ".percentbase",0);
        local nBaseMod =    DB.getValue(nodeChar, "abilities." .. sTarget .. ".percentbasemod",0);
        local nAdjustment = DB.getValue(nodeChar, "abilities." .. sTarget .. ".percentadjustment",0);
        local nTempMod =    DB.getValue(nodeChar, "abilities." .. sTarget .. ".percenttempmod",0);
        local nFinalBase = nBase;

        if (nBaseMod ~= 0) then
            nFinalBase = nBaseMod;
        end
        -- if (nBaseItem > nBaseMod) then
            -- nFinalBase = nBaseItem;
        -- end
        
--        local nTotal = (nFinalBase + nItemMod + nEffectMod + nAdjustment + nTempMod);
        local nTotal = (nFinalBase + nAdjustment + nTempMod);
        if (nTotal < 1) then
            nTotal = 0;
        end
        if (nTotal > 100) then
            nTotal = 100;
        end
        DB.setValue(nodeChar, "abilities." .. sTarget .. ".percent","number", nTotal);
        DB.setValue(nodeChar, "abilities." .. sTarget .. ".percenttotal","number", nTotal);
        --setValue(nTotal);
    end
end

-- allow drag/drop of class/race/backgrounds onto main sheet
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

---
--- Update ability score total
---
---
function updateStrength(node)
    local nodeChar = node.getChild("....");
    AbilityScoreADND.updateStrength(nodeChar);
end
function updateDexterity(node)
    local nodeChar = node.getChild("....");
    AbilityScoreADND.updateDexterity(nodeChar);
end
function updateConstitution(node)
    local nodeChar = node.getChild("....");
    AbilityScoreADND.updateConstitution(nodeChar);
end
function updateIntelligence(node)
    local nodeChar = node.getChild("....");
    AbilityScoreADND.updateIntelligence(nodeChar);
end
function updateWisdom(node)
    local nodeChar = node.getChild("....");
    AbilityScoreADND.updateWisdom(nodeChar);
end
function updateCharisma(node)
    local nodeChar = node.getChild("....");
    AbilityScoreADND.updateCharisma(nodeChar);
end
