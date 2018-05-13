--
-- This deals with ability scores and their values
--
--

function onInit()
end

--
-- Get current ability properties
--
-- fix scores that go greater than 25 or below one, effects can do this now.
function abilityScoreSanity(nScore)
    if (nScore > 25) then
        nScore = 25;
    end
    if (nScore < 1) then
        nScore = 1;
    end

    return nScore;
end
-- get ability properties adjusted for effects.
function getStrengthProperties(nodeChar)

    local nScore = DB.getValue(nodeChar, "abilities.strength.total", DB.getValue(nodeChar, "abilities.strength.score", 0));
    local nPercent = DB.getValue(nodeChar, "abilities.strength.percenttotal", DB.getValue(nodeChar, "abilities.strength.percenttotal", 0));
    
    local rActor = ActorManager.getActor("", nodeChar);
-- Debug.console("manager_abilityscores.lua","getStrengthProperties","nodeChar",nodeChar);
-- Debug.console("manager_abilityscores.lua","getStrengthProperties","rActor",rActor);
    if rActor then
        -- adjust ability scores from effects!
        local sAbilityEffect = "BSTR";
        local nAbilityMod, nAbilityEffects = EffectManager5E.getEffectsBonus(rActor, sAbilityEffect, true);
        if (nAbilityMod ~= 0) then
         nScore = nAbilityMod;
        end
        
        sAbilityEffect = "BPSTR";
        nAbilityMod, nAbilityEffects = EffectManager5E.getEffectsBonus(rActor, sAbilityEffect, true);
        if (nAbilityMod ~= 0) then
            if (nAbilityMod > 100) then
                nAbilityMod = 100;
            end
            if (nAbilityMod < 1) then
                nAbilityMod = 1;
            end
         nPercent = nAbilityMod;
        end
        
        sAbilityEffect = "STR";
        nAbilityMod, nAbilityEffects = EffectManager5E.getEffectsBonus(rActor, sAbilityEffect, true);
        nScore = nScore + nAbilityMod;
        
        sAbilityEffect = "PSTR";
        nAbilityMod, nAbilityEffects = EffectManager5E.getEffectsBonus(rActor, sAbilityEffect, true);
        nPercent = nPercent + nAbilityMod;
        
        -- adjust ability scores from items!
    end
    nScore = abilityScoreSanity(nScore);
    local nScoreSaved = nScore;
    
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
    dbAbility.score = nScoreSaved;
    dbAbility.scorepercent = nPercent;
    dbAbility.hitadj = DataCommonADND.aStrength[nScore][1];
    dbAbility.dmgadj = DataCommonADND.aStrength[nScore][2];
    dbAbility.weightallow = DataCommonADND.aStrength[nScore][3];
    dbAbility.maxpress = DataCommonADND.aStrength[nScore][4];
    dbAbility.opendoors = DataCommonADND.aStrength[nScore][5];
    dbAbility.bendbars = DataCommonADND.aStrength[nScore][6];

--Debug.console("manager_abilityscores.lua","getStrengthProperties","dbAbility",dbAbility);
    return dbAbility;
end

function getDexterityProperties(nodeChar)
    local nScore = DB.getValue(nodeChar, "abilities.dexterity.total", DB.getValue(nodeChar, "abilities.dexterity.score", 0));
--Debug.console("manager_abilityscores.lua","getDexterityProperties","nodeChar",nodeChar);
--Debug.console("manager_abilityscores.lua","getDexterityProperties","nScore",nScore);

    local rActor = ActorManager.getActor("", nodeChar);
--Debug.console("manager_abilityscores.lua","getDexterityProperties","rActor------>",rActor);
    if rActor then
        -- adjust ability scores from effects!
        local sAbilityEffect = "BDEX";
        local nAbilityMod, nAbilityEffects = EffectManager5E.getEffectsBonus(rActor, sAbilityEffect, true);
        if (nAbilityMod ~= 0) then
         nScore = nAbilityMod;
        end
--Debug.console("manager_abilityscores.lua","getDexterityProperties","nAbilityMod1------>",nAbilityMod);
--Debug.console("manager_abilityscores.lua","getDexterityProperties","nAbilityEffects1------->",nAbilityEffects);
        
        sAbilityEffect = "DEX";
        nAbilityMod, nAbilityEffects = EffectManager5E.getEffectsBonus(rActor, sAbilityEffect, true);
        nScore = nScore + nAbilityMod;
--Debug.console("manager_abilityscores.lua","getDexterityProperties","nAbilityMod2------>",nAbilityMod);
--Debug.console("manager_abilityscores.lua","getDexterityProperties","nAbilityEffects2------->",nAbilityEffects);
--Debug.console("manager_abilityscores.lua","getDexterityProperties","ONE",nScore);
    end
--Debug.console("manager_abilityscores.lua","getDexterityProperties","TWO",nScore);
    nScore = abilityScoreSanity(nScore);
    local dbAbility = {};
    dbAbility.score = nScore;
    dbAbility.reactionadj = DataCommonADND.aDexterity[nScore][1];
    dbAbility.hitadj = DataCommonADND.aDexterity[nScore][2];
    dbAbility.defenseadj = DataCommonADND.aDexterity[nScore][3];
    
--Debug.console("manager_abilityscores.lua","getDexterityProperties","dbAbility",dbAbility);
    return dbAbility;
end

function getWisdomProperties(nodeChar)
    local nScore = DB.getValue(nodeChar, "abilities.wisdom.total", DB.getValue(nodeChar, "abilities.wisdom.score", 0));
    
    local rActor = ActorManager.getActor("", nodeChar);
    if rActor then
        -- adjust ability scores from effects!
        local sAbilityEffect = "BWIS";
        local nAbilityMod, nAbilityEffects = EffectManager5E.getEffectsBonus(rActor, sAbilityEffect, true);
        if (nAbilityMod ~= 0) then
         nScore = nAbilityMod;
        end
        
        sAbilityEffect = "WIS";
        nAbilityMod, nAbilityEffects = EffectManager5E.getEffectsBonus(rActor, sAbilityEffect, true);
        nScore = nScore + nAbilityMod;
    end
    nScore = abilityScoreSanity(nScore);
    local dbAbility = {};
    dbAbility.score = nScore;
    dbAbility.magicdefenseadj = DataCommonADND.aWisdom[nScore][1];
    dbAbility.spellbonus = DataCommonADND.aWisdom[nScore][2];
    dbAbility.failure = DataCommonADND.aWisdom[nScore][3];
    dbAbility.immunity = DataCommonADND.aWisdom[nScore][4];
    dbAbility.mac_base = DataCommonADND.aWisdom[nScore][5];
    dbAbility.psp_bonus = DataCommonADND.aWisdom[nScore][6];
    
    local sBonus_TT = "Bonus spells granted by high wisdom. ";
    local sImmunity_TT = "Immunity to spells granted by high wisdom. ";
    if (nScore >= 18) then
        sBonus_TT = sBonus_TT .. DataCommonADND.aWisdom[nScore+100][2];
        sImmunity_TT = sImmunity_TT .. DataCommonADND.aWisdom[nScore+100][4];
    end
    dbAbility.sBonus_TT = sBonus_TT;
    dbAbility.sImmunity_TT = sImmunity_TT;
    
--Debug.console("manager_abilityscores.lua","getWisdomProperties","dbAbility",dbAbility);
    return dbAbility;
end

function getConstitutionProperties(nodeChar)
    local nScore = DB.getValue(nodeChar, "abilities.constitution.total", DB.getValue(nodeChar, "abilities.constitution.score", 0));
    local rActor = ActorManager.getActor("", nodeChar);
    if rActor then
        -- adjust ability scores from effects!
        local sAbilityEffect = "BCON";
        local nAbilityMod, nAbilityEffects = EffectManager5E.getEffectsBonus(rActor, sAbilityEffect, true);
        if (nAbilityMod ~= 0) then
         nScore = nAbilityMod;
        end
        
        sAbilityEffect = "CON";
        nAbilityMod, nAbilityEffects = EffectManager5E.getEffectsBonus(rActor, sAbilityEffect, true);
        nScore = nScore + nAbilityMod;
    end
    
    nScore = abilityScoreSanity(nScore);
    local dbAbility = {};
    dbAbility.score = nScore;
    dbAbility.hitpointadj = DataCommonADND.aConstitution[nScore][1];
    dbAbility.systemshock = DataCommonADND.aConstitution[nScore][2];
    dbAbility.resurrectionsurvival = DataCommonADND.aConstitution[nScore][3];
    dbAbility.poisonadj = DataCommonADND.aConstitution[nScore][4];
    dbAbility.regeneration = DataCommonADND.aConstitution[nScore][5];
    dbAbility.psp_bonus = DataCommonADND.aConstitution[nScore][6];

--Debug.console("manager_abilityscores.lua","getConstitutionProperties","dbAbility",dbAbility);
    return dbAbility;
end

function getCharismaProperties(nodeChar)
    local nScore = DB.getValue(nodeChar, "abilities.charisma.total", DB.getValue(nodeChar, "abilities.charisma.score", 0));
    local rActor = ActorManager.getActor("", nodeChar);
    if rActor then
        -- adjust ability scores from effects!
        local sAbilityEffect = "BCHA";
        local nAbilityMod, nAbilityEffects = EffectManager5E.getEffectsBonus(rActor, sAbilityEffect, true);
        if (nAbilityMod ~= 0) then
         nScore = nAbilityMod;
        end
        
        sAbilityEffect = "CHA";
        nAbilityMod, nAbilityEffects = EffectManager5E.getEffectsBonus(rActor, sAbilityEffect, true);
        nScore = nScore + nAbilityMod;
    end
    nScore = abilityScoreSanity(nScore);
    local dbAbility = {};
    dbAbility.score = nScore;
    dbAbility.maxhench = DataCommonADND.aCharisma[nScore][1];
    dbAbility.loyalty = DataCommonADND.aCharisma[nScore][2];
    dbAbility.reaction = DataCommonADND.aCharisma[nScore][3];

--Debug.console("manager_abilityscores.lua","getCharismaProperties","dbAbility",dbAbility);
    return dbAbility;
end

function getIntelligenceProperties(nodeChar)
    local nScore = DB.getValue(nodeChar, "abilities.intelligence.total", DB.getValue(nodeChar, "abilities.intelligence.score", 0));
    local rActor = ActorManager.getActor("", nodeChar);
    if rActor then
        -- adjust ability scores from effects!
        local sAbilityEffect = "BINT";
        local nAbilityMod, nAbilityEffects = EffectManager5E.getEffectsBonus(rActor, sAbilityEffect, true);
        if (nAbilityMod ~= 0) then
         nScore = nAbilityMod;
        end
        
        sAbilityEffect = "INT";
        nAbilityMod, nAbilityEffects = EffectManager5E.getEffectsBonus(rActor, sAbilityEffect, true);
        nScore = nScore + nAbilityMod;
    end
    nScore = abilityScoreSanity(nScore);
    local dbAbility = {};
    dbAbility.score = nScore;
    dbAbility.languages = DataCommonADND.aIntelligence[nScore][1];
    dbAbility.spelllevel = DataCommonADND.aIntelligence[nScore][2];
    dbAbility.learn = DataCommonADND.aIntelligence[nScore][3];
    dbAbility.maxlevel = DataCommonADND.aIntelligence[nScore][4];
    dbAbility.illusion = DataCommonADND.aIntelligence[nScore][5];
    dbAbility.mac_adjustment = DataCommonADND.aIntelligence[nScore][6];
    dbAbility.psp_bonus = DataCommonADND.aIntelligence[nScore][7];
    dbAbility.mthaco_bonus = DataCommonADND.aIntelligence[nScore][8];

    local sImmunity_TT = "Immune to these level of Illusion spells. ";
    if (nScore >= 19) then
        sImmunity_TT = sImmunity_TT .. DataCommonADND.aIntelligence[nScore+100][5];
    end
    dbAbility.sImmunity_TT = sImmunity_TT;

--Debug.console("manager_abilityscores.lua","getIntelligenceProperties","dbAbility",dbAbility);
    return dbAbility;
end

--
-- Update ability values
--
function updateStrength(nodeChar)
--Debug.console("manager_abilityscores.lua","updateStrength","nodeChar",nodeChar);
    local dbAbility = getStrengthProperties(nodeChar);
    local nScore = dbAbility.score;
    local nPercent = dbAbility.scorepercent;
    
    DB.setValue(nodeChar, "abilities.strength.hitadj", "number", dbAbility.hitadj);
    DB.setValue(nodeChar, "abilities.strength.dmgadj", "number", dbAbility.dmgadj);
    DB.setValue(nodeChar, "abilities.strength.weightallow", "number", dbAbility.weightallow);
    DB.setValue(nodeChar, "abilities.strength.maxpress", "number", dbAbility.maxpress);
    DB.setValue(nodeChar, "abilities.strength.opendoors", "string", dbAbility.opendoors);
    DB.setValue(nodeChar, "abilities.strength.bendbars", "number", dbAbility.bendbars);

    DB.setValue(nodeChar, "abilities.strength.score", "number", nScore);
    DB.setValue(nodeChar, "abilities.strength.percent", "number", nPercent);
    return dbAbility;
end

function updateDexterity(nodeChar)
    local dbAbility = getDexterityProperties(nodeChar);
    local nScore = dbAbility.score;
    
    DB.setValue(nodeChar, "abilities.dexterity.reactionadj", "number", dbAbility.reactionadj);
    DB.setValue(nodeChar, "abilities.dexterity.hitadj", "number", dbAbility.hitadj);
    DB.setValue(nodeChar, "abilities.dexterity.defenseadj", "number", dbAbility.defenseadj);
    DB.setValue(nodeChar, "abilities.dexterity.score", "number", nScore);
    return dbAbility;
end

function updateWisdom(nodeChar)
    local dbAbility = getWisdomProperties(nodeChar);
    local nScore = dbAbility.score;
    
    DB.setValue(nodeChar, "abilities.wisdom.magicdefenseadj", "number", dbAbility.magicdefenseadj);
    DB.setValue(nodeChar, "abilities.wisdom.spellbonus", "string", dbAbility.spellbonus);
    DB.setValue(nodeChar, "abilities.wisdom.failure", "number", dbAbility.failure);
    DB.setValue(nodeChar, "abilities.wisdom.immunity", "string", dbAbility.immunity);
    DB.setValue(nodeChar, "combat.mac.base", "number", dbAbility.mac_base);
    DB.setValue(nodeChar, "abilities.wisdom.score", "number", nScore);
    return dbAbility;
end

function updateConstitution(nodeChar)
    local dbAbility = getConstitutionProperties(nodeChar);
    local nScore = dbAbility.score;

    DB.setValue(nodeChar, "abilities.constitution.hitpointadj", "string", dbAbility.hitpointadj);
    DB.setValue(nodeChar, "abilities.constitution.systemshock", "number", dbAbility.systemshock);
    DB.setValue(nodeChar, "abilities.constitution.resurrectionsurvival", "number", dbAbility.resurrectionsurvival);
    DB.setValue(nodeChar, "abilities.constitution.poisonadj", "number", dbAbility.poisonadj);
    DB.setValue(nodeChar, "abilities.constitution.regeneration", "string", dbAbility.regeneration);
    DB.setValue(nodeChar, "abilities.constitution.score", "number", nScore);
    return dbAbility;
end

function updateCharisma(nodeChar)
    local dbAbility = getCharismaProperties(nodeChar);
    local nScore = dbAbility.score;

    DB.setValue(nodeChar, "abilities.charisma.maxhench", "number", dbAbility.maxhench);
    DB.setValue(nodeChar, "abilities.charisma.loyalty", "number", dbAbility.loyalty);
    DB.setValue(nodeChar, "abilities.charisma.reaction", "number", dbAbility.reaction);
    DB.setValue(nodeChar, "abilities.charisma.score", "number", nScore);
    return dbAbility;
end

function updateIntelligence(nodeChar)
    local dbAbility = getIntelligenceProperties(nodeChar);
    local nScore = dbAbility.score;

    DB.setValue(nodeChar, "abilities.intelligence.languages", "number", dbAbility.languages);
    DB.setValue(nodeChar, "abilities.intelligence.spelllevel", "number", dbAbility.spelllevel);
    DB.setValue(nodeChar, "abilities.intelligence.learn", "number", dbAbility.learn);
    DB.setValue(nodeChar, "abilities.intelligence.maxlevel", "string", dbAbility.maxlevel);
    DB.setValue(nodeChar, "abilities.intelligence.illusion", "string", dbAbility.illusion);
    DB.setValue(nodeChar, "combat.mac.mod", "number", dbAbility.mac_adjustment);
    DB.setValue(nodeChar, "combat.mthaco.mod", "number", dbAbility.mthaco_bonus);
    DB.setValue(nodeChar, "abilities.intelligence.score", "number", nScore);
    return dbAbility;
end

-- update all ability scores because effects were updated.
function updateForEffects(nodeChar)
--Debug.console("manager_abilityscores.lua","updateForEffects","nodeChar",nodeChar);
    updateCharisma(nodeChar);
    updateConstitution(nodeChar);
    updateDexterity(nodeChar);
    updateIntelligence(nodeChar);
    updateStrength(nodeChar);
    updateWisdom(nodeChar);
end


function detailsUpdate(nodeChar)
    
    ----Debug.console("char_abilities_details.lua","detailsUpdate","sTarget",sTarget);
    for i = 1,6,1 do
        local sTarget = DataCommon.abilities[i];
        local nBase =       DB.getValue(nodeChar, "abilities." .. sTarget .. ".base",9);
        local nBaseMod =    DB.getValue(nodeChar, "abilities." .. sTarget .. ".basemod",0);
        local nAdjustment = DB.getValue(nodeChar, "abilities." .. sTarget .. ".adjustment",0);
        local nTempMod =    DB.getValue(nodeChar, "abilities." .. sTarget .. ".tempmod",0);
        local nFinalBase = nBase;

        if (nBaseMod ~= 0) then
            nFinalBase = nBaseMod;
        end
        local nTotal = (nFinalBase + nAdjustment + nTempMod);
        if (nTotal < 1) then
            nTotal = 1;
        end
        if (nTotal > 25) then
            nTotal = 25;
        end
        DB.setValue(nodeChar, "abilities." .. sTarget .. ".score","number", nTotal);
        DB.setValue(nodeChar, "abilities." .. sTarget .. ".total","number", nTotal);
    end
end

function detailsPercentUpdate(nodeChar)
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
        local nTotal = (nFinalBase + nAdjustment + nTempMod);
        if (nTotal < 1) then
            nTotal = 0;
        end
        if (nTotal > 100) then
            nTotal = 100;
        end
        DB.setValue(nodeChar, "abilities." .. sTarget .. ".percent","number", nTotal);
        DB.setValue(nodeChar, "abilities." .. sTarget .. ".percenttotal","number", nTotal);
    end
end
