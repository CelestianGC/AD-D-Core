

function detailsUpdate()
    local node = getDatabaseNode();
    local nodeChar = node.getChild("..");
    local sTarget = string.lower(self.target[1]);
    
    --Debug.console("char_abilities_details.lua","detailsUpdate","sTarget",sTarget);
    
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
    setValue(nTotal);
end

function detailsPercentUpdate()
    local node = getDatabaseNode();
    local nodeChar = node.getChild("..");
    local sTarget = string.lower(self.target[1]);


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
    setValue(nTotal);
end

