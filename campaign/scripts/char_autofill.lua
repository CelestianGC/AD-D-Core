--
-- Functions used to set base THACO/Save values for each class
--
--

function onInit()
end

-- flip through all classes
-- and set saves/thaco
function updateAutoFills(nodeChar)

	for _,nodeClass in pairs(DB.getChildren(nodeChar, "classes")) do
        local nClassActive = DB.getValue(nodeClass, "classactive", 0);
        local sFightAs = DB.getValue(nodeClass, "fightas", "warrior"):lower();
        local sSaveAs = DB.getValue(nodeClass, "saveas", "warrior"):lower();
        local nLevel = DB.getValue(nodeClass, "level", 0);
        
        -- ignoring nClassActive for now
        -- THACO
        if (sFightAs == "warrior") then
            setTHACO(nodeChar,nLevel,DataCommonADND.thaco_warrior);
        end
        if (sFightAs == "priest") then
            setTHACO(nodeChar,nLevel,DataCommonADND.thaco_priest);
        end
        if (sFightAs == "wizard") then
            setTHACO(nodeChar,nLevel,DataCommonADND.thaco_wizard);
        end
        if (sFightAs == "rogue") then
            setTHACO(nodeChar,nLevel,DataCommonADND.thaco_rogue);
        end

        -- SAVES
        if (sSaveAs == "warrior") then
            setSaves(nodeChar,nLevel,DataCommonADND.aWarriorSaves);
        end
        if (sSaveAs == "priest") then
            setSaves(nodeChar,nLevel,DataCommonADND.aPriestSaves);
        end
        if (sSaveAs == "wizard") then
            setSaves(nodeChar,nLevel,DataCommonADND.aWizardSaves);
        end
        if (sSaveAs == "rogue") then
            setSaves(nodeChar,nLevel,DataCommonADND.aRogueSaves);
        end

    end -- for classes

end

function setTHACO(nodeChar, nLevel, nThacoRate)
    local nTHACO = (nLevel - 1) * nThacoRate;
    nTHACO = math.floor(nTHACO);
    nTHACO = 20 - nTHACO;
    
Debug.console("char_autofill.lua", "setTHACO", "nTHACO", nTHACO);
    local nCurrentTHACO = DB.getValue(nodeChar,"combat.thaco.score",20);
    -- only apply THACO if new score is better
    if (nCurrentTHACO > nTHACO) then
        DB.setValue(nodeChar, "combat.thaco.score", "number", nCurrentTHACO);
    end
end

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
                Debug.console("char_autofill.lua", "setSaves", "DataCommonADND.aSavesTable[nLevel][nSaveIndex]", DataCommonADND.aSavesTable[nLevel][nSaveIndex]);
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
          local nSaveIndex = DataCommonADND.saves_table_index[sSave];
            if (nLevel > 21) then
                nSaveScore = DataCommonADND.aWarriorSaves[21][nSaveIndex];
            elseif (nLevel < 1) then
                nSaveScore = DataCommonADND.aWarriorSaves[0][nSaveIndex];
            else
                nSaveScore = DataCommonADND.aWarriorSaves[nLevel][nSaveIndex];
                Debug.console("char_autofill.lua", "setWarriorSaves", "DataCommonADND.aWarriorSaves[nLevel][nSaveIndex]", DataCommonADND.aWarriorSaves[nLevel][nSaveIndex]);
            end
            local nCurrentSave = DB.getValue(nodeChar,"saves." .. sSave .. ".base",20);
            -- only apply save if new score is better
            if (nCurrentSave > nSaveScore) then
                DB.setValue(nodeChar, "saves." .. sSave .. ".base", "number", nSaveScore);
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
                Debug.console("char_autofill.lua", "setWarriorSaves", "DataCommonADND.aPriestSaves[nLevel][nSaveIndex]", DataCommonADND.aPriestSaves[nLevel][nSaveIndex]);
            end
            local nCurrentSave = DB.getValue(nodeChar,"saves." .. sSave .. ".base",20);
            -- only apply save if new score is better
            if (nCurrentSave > nSaveScore) then
                DB.setValue(nodeChar, "saves." .. sSave .. ".base", "number", nSaveScore);
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
                Debug.console("char_autofill.lua", "setWarriorSaves", "DataCommonADND.aRogueSaves[nLevel][nSaveIndex]", DataCommonADND.aRogueSaves[nLevel][nSaveIndex]);
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
                Debug.console("char_autofill.lua", "setWarriorSaves", "DataCommonADND.aWizardSaves[nLevel][nSaveIndex]", DataCommonADND.aWizardSaves[nLevel][nSaveIndex]);
            end
            local nCurrentSave = DB.getValue(nodeChar,"saves." .. sSave .. ".base",20);
            -- only apply save if new score is better
            if (nCurrentSave > nSaveScore) then
                DB.setValue(nodeChar, "saves." .. sSave .. ".base", "number", nSaveScore);
            end
        end -- fore
    end -- nodeChar
end