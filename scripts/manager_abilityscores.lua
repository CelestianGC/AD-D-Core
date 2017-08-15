--
-- This deals with ability scores and their values
--
--

function onInit()
end

function getStrengthProperties(nodeChar)

    local nScore = DB.getValue(nodeChar, "abilities.strength.score", 0);
    local nPercent = DB.getValue(nodeChar, "abilities.strength.percent", 0);

    -- adjust ability scores from effects!
    --local nScoreEff = something.getStrength();
    -- adjust ability scores from items!
    --local nScoreItem = something.getStrength();
    
    -- Deal with 18 01-100 strength
    if ((nScore == 18) and (nPercent > 0)) then
        local nPercentRank = 50;
        if (nPercent == 100) then 
            nPercentRank = 100
        elseif (nPercent >= 91 and nPercent <= 99) then
            nPercentRank = 99
        elseif (nPercent >= 76 and nPercent <= 90) then
            nPercentRank = 90
        elseif (nPercent >= 51 and nPercent <= 75) then
            nPercentRank = 75
        elseif (nPercent >= 1 and nPercent <= 50) then
            nPercentRank = 50
        end
        nScore = nPercentRank;
    end
    
    local dbAbility = {};
    dbAbility.score = nScore;
    dbAbility.scorepercent = nPercent;
    dbAbility.hitadj = DataCommonADND.aStrength[nScore][1];
    dbAbility.dmgadj = DataCommonADND.aStrength[nScore][2];
    dbAbility.weightallow = DataCommonADND.aStrength[nScore][3];
    dbAbility.maxpress = DataCommonADND.aStrength[nScore][4];
    dbAbility.opendoors = DataCommonADND.aStrength[nScore][5];
    dbAbility.bendbars = DataCommonADND.aStrength[nScore][6];

Debug.console("manager_abilityscores.lua","getStrengthProperties","dbAbility",dbAbility);
    return dbAbility;
end

function getDexterityProperties(nodeChar)
    local nScore = DB.getValue(nodeChar, "abilities.dexterity.score", 0);
    local dbAbility = {};
    dbAbility.score = nScore;
    dbAbility.reactionadj = DataCommonADND.aDexterity[nScore][1];
    dbAbility.hitadj = DataCommonADND.aDexterity[nScore][2];
    dbAbility.defenseadj = DataCommonADND.aDexterity[nScore][3];
    
Debug.console("manager_abilityscores.lua","getDexterityProperties","dbAbility",dbAbility);
    return dbAbility;
end

function getWisdomProperties(nodeChar)
    local nScore = DB.getValue(nodeChar, "abilities.wisdom.score", 0);
    local dbAbility = {};
    dbAbility.score = nScore;
    dbAbility.magicdefenseadj = DataCommonADND.aWisdom[nScore][1];
    dbAbility.spellbonus = DataCommonADND.aWisdom[nScore][2];
    dbAbility.failure = DataCommonADND.aWisdom[nScore][3];
    dbAbility.immunity = DataCommonADND.aWisdom[nScore][4];
    
Debug.console("manager_abilityscores.lua","getWisdomProperties","dbAbility",dbAbility);
    return dbAbility;
end

function getConstitutionProperties(nodeChar)
    local nScore = DB.getValue(nodeChar, "abilities.constitution.score", 0);
    local dbAbility = {};
    dbAbility.score = nScore;
    dbAbility.hitpointadj = DataCommonADND.aConstitution[nScore][1];
    dbAbility.systemshock = DataCommonADND.aConstitution[nScore][2];
    dbAbility.resurrectionsurvival = DataCommonADND.aConstitution[nScore][3];
    dbAbility.poisonadj = DataCommonADND.aConstitution[nScore][4];
    dbAbility.regeneration = DataCommonADND.aConstitution[nScore][5];

Debug.console("manager_abilityscores.lua","getConstitutionProperties","dbAbility",dbAbility);
    return dbAbility;
end

function getCharismaProperties(nodeChar)
    local nScore = DB.getValue(nodeChar, "abilities.charisma.score", 0);
    local dbAbility = {};
    dbAbility.score = nScore;
    dbAbility.reactionadj = DataCommonADND.aCharisma[nScore][1];
    dbAbility.loyalty = DataCommonADND.aCharisma[nScore][2];
    dbAbility.reaction = DataCommonADND.aCharisma[nScore][3];

Debug.console("manager_abilityscores.lua","getCharismaProperties","dbAbility",dbAbility);
    return dbAbility;
end

function getIntelligenceProperties(nodeChar)
    local nScore = DB.getValue(nodeChar, "abilities.intelligence.score", 0);
    local dbAbility = {};
    dbAbility.score = nScore;
    dbAbility.languages = DataCommonADND.aIntelligence[nScore][1];
    dbAbility.spelllevel = DataCommonADND.aIntelligence[nScore][2];
    dbAbility.learn = DataCommonADND.aIntelligence[nScore][3];
    dbAbility.maxlevel = DataCommonADND.aIntelligence[nScore][4];
    dbAbility.illusion = DataCommonADND.aIntelligence[nScore][5];

Debug.console("manager_abilityscores.lua","getIntelligenceProperties","dbAbility",dbAbility);
    return dbAbility;
end
