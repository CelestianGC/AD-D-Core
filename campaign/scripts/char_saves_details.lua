--
-- for AD&D Core, abilities menu
--
--

function detailsUpdate()
    local node = getDatabaseNode();
    local nodeChar = node.getChild("..");
    local sTarget = string.lower(self.target[1]);
    
    --Debug.console("char_abilities_details.lua","detailsUpdate","sTarget",sTarget);
    
    local nBase =       DB.getValue(nodeChar, "saves." .. sTarget .. ".base",20);
    local nBaseMod =    DB.getValue(nodeChar, "saves." .. sTarget .. ".basemod",0);
    local nItemMod =    DB.getValue(nodeChar, "saves." .. sTarget .. ".itemmod",0);
    local nEffectMod =  DB.getValue(nodeChar, "saves." .. sTarget .. ".effectmod",0);
    local nAdjustment = DB.getValue(nodeChar, "saves." .. sTarget .. ".adjustment",0);
    local nTempMod =    DB.getValue(nodeChar, "saves." .. sTarget .. ".tempmod",0);
    local nFinalBase = nBase;

    if (nBaseMod ~= 0) then
        nFinalBase = nBaseMod;
    end
    
    -- flip negative to positive, since we expect +2 to be better and -2 to be worse
    -- here.
    local nFlipMods = ( (nItemMod + nEffectMod + nAdjustment + nTempMod) * -1);
    local nTotal = (nFinalBase + nFlipMods);
    if (nTotal < 1) then
        nTotal = 1;
    end
    if (nTotal > 50) then
        nTotal = 50;
    end
    DB.setValue(nodeChar, "saves." .. sTarget .. ".score","number", nTotal);
    setValue(nTotal);
end

