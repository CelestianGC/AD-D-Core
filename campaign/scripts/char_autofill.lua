--
-- Functions used to set base THACO/Save values for each class
--
--

function onInit()
end

-- returns the number of classes the character has
function getClassCount(nodeChar)
	local nClassCount = 0;
    
	for _,nodeClass in pairs(DB.getChildren(nodeChar, "classes")) do
        nClassCount = nClassCount + 1;
    end
    
    return nClassCount;
end

-- flip through all classes
-- and set saves/thaco
function updateAutoFills(nodeChar)

    -- start clean, set values to 20
    DB.setValue(nodeChar, "combat.thaco.score", "number", 20);
    setDefaultSaves(nodeChar);
    
	for _,nodeClass in pairs(DB.getChildren(nodeChar, "classes")) do
        local nClassActive = DB.getValue(nodeClass, "classactive", 0);
        local sFightAs = DB.getValue(nodeClass, "fightas", "warrior"):lower();
        local sSaveAs = DB.getValue(nodeClass, "saveas", "warrior"):lower();
        local nLevel = DB.getValue(nodeClass, "level", 0);

--Debug.console("char_autofill.lua", "updateAutoFills", "nodeClass", nodeClass);
        
        -- ignoring nClassActive for now
        -- THACO
        if (sFightAs == "warrior") then
            setTHACO(nodeChar,nLevel,DataCommonADND.thaco_warrior_rate, DataCommonADND.thaco_warrior_advancement);
        end
        if (sFightAs == "priest") then
            setTHACO(nodeChar, nLevel, DataCommonADND.thaco_priest_rate, DataCommonADND.thaco_priest_advancement);
        end
        if (sFightAs == "wizard") then
            setTHACO(nodeChar,nLevel,DataCommonADND.thaco_wizard_rate, DataCommonADND.thaco_wizard_advancement);
        end
        if (sFightAs == "rogue") then
            setTHACO(nodeChar,nLevel,DataCommonADND.thaco_rogue_rate, DataCommonADND.thaco_rogue_advancement);
        end

        -- SAVES
        if (sSaveAs == "warrior") then
            setWarriorSaves(nodeChar,nLevel);
        end
        if (sSaveAs == "priest") then
            setPriestSaves(nodeChar,nLevel);
        end
        if (sSaveAs == "wizard") then
            setWizardSaves(nodeChar,nLevel);
        end
        if (sSaveAs == "rogue") then
            setRogueSaves(nodeChar,nLevel);
        end

    end -- for classes

end

function setTHACO(nodeChar, nLevel, nThacoRate, nThacoAdvancement)
    local nTHACO = 20;
    local nLastLevel = nLevel -1;

    while ((nLastLevel > 0) and (nTHACO == 20)) do
        local nTestLeftover = (nLastLevel % nThacoRate);
        if (nTestLeftover == 0) then
            local nLastRate = nLastLevel/nThacoRate;
            local nAdvancement = nLastRate * nThacoAdvancement;
            nTHACO = 20 - nAdvancement;
        else
            -- backup till we have a whole number
            nLastLevel = nLastLevel - 1;
        end
    end
    
    local nCurrentTHACO = DB.getValue(nodeChar,"combat.thaco.score",20);

--Debug.console("char_autofill.lua", "setTHACO", "ClassCount", getClassCount(nodeChar));
    
    -- only apply THACO if new score is better
    if (nCurrentTHACO > nTHACO) then
        DB.setValue(nodeChar, "combat.thaco.score", "number", nTHACO);
    end
end

-- this would be awesome but I can't get an array passed as function for some reason --celestian
function setSaves(nodeChar, nLevel, aSavesTable)
    if nodeChar then
        for i=1,10,1 do
          local sSave = DataCommon.saves[i];
          local nSaveIndex = DataCommonADND.saves_table_index[sSave];
            if (nLevel > 21) then
                nSaveScore = DataCommonADND.aSavesTable[21][nSaveIndex];
            elseif (nLevel < 1) then
                nSaveScore = DataCommonADND.aSavesTable[0][nSaveIndex];
            else
                nSaveScore = DataCommonADND.aSavesTable[nLevel][nSaveIndex];
--                Debug.console("char_autofill.lua", "setSaves", "DataCommonADND.aSavesTable[nLevel][nSaveIndex]", DataCommonADND.aSavesTable[nLevel][nSaveIndex]);
            end
            local nCurrentSave = DB.getValue(nodeChar,"saves." .. sSave .. ".base",20);
            -- only apply save if new score is better
            if (nCurrentSave > nSaveScore) then
                DB.setValue(nodeChar, "saves." .. sSave .. ".base", "number", nSaveScore);
            end
        end -- fore
    end -- nodeChar
end

function setWarriorSaves(nodeChar, nLevel)
    if nodeChar then
        for i=1,10,1 do
          local sSave = DataCommon.saves[i];
--Debug.console("char_autofill.lua", "setWarriorSaves", "sSave", sSave);
          local nSaveIndex = DataCommonADND.saves_table_index[sSave];
            if (nLevel > 21) then
                nSaveScore = DataCommonADND.aWarriorSaves[21][nSaveIndex];
            elseif (nLevel < 1) then
                nSaveScore = DataCommonADND.aWarriorSaves[0][nSaveIndex];
            else
                nSaveScore = DataCommonADND.aWarriorSaves[nLevel][nSaveIndex];
--                Debug.console("char_autofill.lua", "setWarriorSaves", "DataCommonADND.aWarriorSaves[nLevel][nSaveIndex]", DataCommonADND.aWarriorSaves[nLevel][nSaveIndex]);
            end
            local nCurrentSave = DB.getValue(nodeChar,"saves." .. sSave .. ".base",20);
            -- only apply save if new score is better
            if (nCurrentSave > nSaveScore) then
                DB.setValue(nodeChar, "saves." .. sSave .. ".base", "number", nSaveScore);
--                Debug.console("char_autofill.lua", "setWarriorSaves", "SET nSaveScore", nSaveScore);
            end
        end -- fore
    end -- nodeChar
end
function setPriestSaves(nodeChar, nLevel)
    if nodeChar then
        for i=1,10,1 do
          local sSave = DataCommon.saves[i];
          local nSaveIndex = DataCommonADND.saves_table_index[sSave];
            if (nLevel > 21) then
                nSaveScore = DataCommonADND.aPriestSaves[21][nSaveIndex];
            elseif (nLevel < 1) then
                nSaveScore = DataCommonADND.aPriestSaves[0][nSaveIndex];
            else
                nSaveScore = DataCommonADND.aPriestSaves[nLevel][nSaveIndex];
--                Debug.console("char_autofill.lua", "setWarriorSaves", "DataCommonADND.aPriestSaves[nLevel][nSaveIndex]", DataCommonADND.aPriestSaves[nLevel][nSaveIndex]);
            end
            local nCurrentSave = DB.getValue(nodeChar,"saves." .. sSave .. ".base",20);
            -- only apply save if new score is better
            if (nCurrentSave > nSaveScore) then
                DB.setValue(nodeChar, "saves." .. sSave .. ".base", "number", nSaveScore);
--                Debug.console("char_autofill.lua", "setWarriorSaves", "SET nSaveScore", nSaveScore);
            end
        end -- fore
    end -- nodeChar
end
function setRogueSaves(nodeChar, nLevel)
    if nodeChar then
        for i=1,10,1 do
          local sSave = DataCommon.saves[i];
          local nSaveIndex = DataCommonADND.saves_table_index[sSave];
            if (nLevel > 21) then
                nSaveScore = DataCommonADND.aRogueSaves[21][nSaveIndex];
            elseif (nLevel < 1) then
                nSaveScore = DataCommonADND.aRogueSaves[0][nSaveIndex];
            else
                nSaveScore = DataCommonADND.aRogueSaves[nLevel][nSaveIndex];
--                Debug.console("char_autofill.lua", "setWarriorSaves", "DataCommonADND.aRogueSaves[nLevel][nSaveIndex]", DataCommonADND.aRogueSaves[nLevel][nSaveIndex]);
            end
            local nCurrentSave = DB.getValue(nodeChar,"saves." .. sSave .. ".base",20);
            -- only apply save if new score is better
            if (nCurrentSave > nSaveScore) then
                DB.setValue(nodeChar, "saves." .. sSave .. ".base", "number", nSaveScore);
            end
        end -- fore
    end -- nodeChar
end
function setWizardSaves(nodeChar, nLevel)
    if nodeChar then
        for i=1,10,1 do
          local sSave = DataCommon.saves[i];
          local nSaveIndex = DataCommonADND.saves_table_index[sSave];
            if (nLevel > 21) then
                nSaveScore = DataCommonADND.aWizardSaves[21][nSaveIndex];
            elseif (nLevel < 1) then
                nSaveScore = DataCommonADND.aWizardSaves[0][nSaveIndex];
            else
                nSaveScore = DataCommonADND.aWizardSaves[nLevel][nSaveIndex];
--                Debug.console("char_autofill.lua", "setWarriorSaves", "DataCommonADND.aWizardSaves[nLevel][nSaveIndex]", DataCommonADND.aWizardSaves[nLevel][nSaveIndex]);
            end
            local nCurrentSave = DB.getValue(nodeChar,"saves." .. sSave .. ".base",20);
            -- only apply save if new score is better
            if (nCurrentSave > nSaveScore) then
                DB.setValue(nodeChar, "saves." .. sSave .. ".base", "number", nSaveScore);
            end
        end -- fore
    end -- nodeChar
end

-- set all saves to base 20 for clear start
function setDefaultSaves(nodeChar)
    if nodeChar then
        for i=1,10,1 do
          local sSave = DataCommon.saves[i];
          DB.setValue(nodeChar, "saves." .. sSave .. ".base", "number", 20);
        end -- for
    end -- nodeChar
end
