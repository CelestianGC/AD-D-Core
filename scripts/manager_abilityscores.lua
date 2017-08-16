--
-- This deals with ability scores and their values
--
--

function onInit()
end

--
-- Get current ability properties
--
function getStrengthProperties(nodeChar)

    local nScore = DB.getValue(nodeChar, "abilities.strength.score", 0);
    local nPercent = DB.getValue(nodeChar, "abilities.strength.percent", 0);
    
    local rActor = ActorManager.getActor("", nodeChar);
    -- adjust ability scores from effects!
	local sAbilityEffect = "BSTR";
	local nAbilityMod, nAbilityEffects = EffectManager.getEffectsBonus(rActor, sAbilityEffect, true);
Debug.console("manager_abilityscores.lua","getStrengthProperties","nAbilityMod",nAbilityMod);
Debug.console("manager_abilityscores.lua","getStrengthProperties","nAbilityEffects",nAbilityEffects);
    
	-- sAbilityEffect = "BPSTR";
	-- nAbilityMod, nAbilityEffects = EffectManager.getEffectsBonus(rActor, sAbilityEffect, true);
    
    sAbilityEffect = "STR";
    nAbilityMod, nAbilityEffects = EffectManager.getEffectsBonus(rActor, sAbilityEffect, true);
Debug.console("manager_abilityscores.lua","getStrengthProperties","nAbilityMod",nAbilityMod);
Debug.console("manager_abilityscores.lua","getStrengthProperties","nAbilityEffects",nAbilityEffects);
    -- nScore = nScore + nAbilityMod;
    
	-- sAbilityEffect = "PSTR";
	-- nAbilityMod, nAbilityEffects = EffectManager.getEffectsBonus(rActor, sAbilityEffect, true);
    
    -- adjust ability scores from items!

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

    local rActor = ActorManager.getActor("", nodeChar);
    -- adjust ability scores from effects!
	local sAbilityEffect = "BDEX";
	local nAbilityMod, nAbilityEffects = EffectManager.getEffectsBonus(rActor, sAbilityEffect, true);
Debug.console("manager_abilityscores.lua","getStrengthProperties","nAbilityMod",nAbilityMod);
Debug.console("manager_abilityscores.lua","getStrengthProperties","nAbilityEffects",nAbilityEffects);
    
    sAbilityEffect = "DEX";
    nAbilityMod, nAbilityEffects = EffectManager.getEffectsBonus(rActor, sAbilityEffect, true);
Debug.console("manager_abilityscores.lua","getStrengthProperties","nAbilityMod",nAbilityMod);
Debug.console("manager_abilityscores.lua","getStrengthProperties","nAbilityEffects",nAbilityEffects);
    -- nScore = nScore + nAbilityMod;

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
    
    local rActor = ActorManager.getActor("", nodeChar);
    -- adjust ability scores from effects!
	local sAbilityEffect = "BWIS";
	local nAbilityMod, nAbilityEffects = EffectManager.getEffectsBonus(rActor, sAbilityEffect, true);
Debug.console("manager_abilityscores.lua","getStrengthProperties","nAbilityMod",nAbilityMod);
Debug.console("manager_abilityscores.lua","getStrengthProperties","nAbilityEffects",nAbilityEffects);
    
    sAbilityEffect = "WIS";
    nAbilityMod, nAbilityEffects = EffectManager.getEffectsBonus(rActor, sAbilityEffect, true);
Debug.console("manager_abilityscores.lua","getStrengthProperties","nAbilityMod",nAbilityMod);
Debug.console("manager_abilityscores.lua","getStrengthProperties","nAbilityEffects",nAbilityEffects);
    -- nScore = nScore + nAbilityMod;
    
    local dbAbility = {};
    dbAbility.score = nScore;
    dbAbility.magicdefenseadj = DataCommonADND.aWisdom[nScore][1];
    dbAbility.spellbonus = DataCommonADND.aWisdom[nScore][2];
    dbAbility.failure = DataCommonADND.aWisdom[nScore][3];
    dbAbility.immunity = DataCommonADND.aWisdom[nScore][4];
    
    local sBonus_TT = "Bonus spells granted by high wisdom. ";
    local sImmunity_TT = "Immunity to spells granted by high wisdom. ";
    if (nScore >= 18) then
        sBonus_TT = sBonus_TT .. DataCommonADND.aWisdom[nScore+100][2];
        sImmunity_TT = sImmunity_TT .. DataCommonADND.aWisdom[nScore+100][4];
    end
    dbAbility.sBonus_TT = sBonus_TT;
    dbAbility.sImmunity_TT = sImmunity_TT;
    
Debug.console("manager_abilityscores.lua","getWisdomProperties","dbAbility",dbAbility);
    return dbAbility;
end

function getConstitutionProperties(nodeChar)
    local nScore = DB.getValue(nodeChar, "abilities.constitution.score", 0);
    local rActor = ActorManager.getActor("", nodeChar);
    -- adjust ability scores from effects!
	local sAbilityEffect = "BCON";
	local nAbilityMod, nAbilityEffects = EffectManager.getEffectsBonus(rActor, sAbilityEffect, true);
Debug.console("manager_abilityscores.lua","getStrengthProperties","nAbilityMod",nAbilityMod);
Debug.console("manager_abilityscores.lua","getStrengthProperties","nAbilityEffects",nAbilityEffects);
    
    sAbilityEffect = "CON";
    nAbilityMod, nAbilityEffects = EffectManager.getEffectsBonus(rActor, sAbilityEffect, true);
Debug.console("manager_abilityscores.lua","getStrengthProperties","nAbilityMod",nAbilityMod);
Debug.console("manager_abilityscores.lua","getStrengthProperties","nAbilityEffects",nAbilityEffects);
    -- nScore = nScore + nAbilityMod;

    
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
    local rActor = ActorManager.getActor("", nodeChar);
    -- adjust ability scores from effects!
	local sAbilityEffect = "BCHA";
	local nAbilityMod, nAbilityEffects = EffectManager.getEffectsBonus(rActor, sAbilityEffect, true);
Debug.console("manager_abilityscores.lua","getStrengthProperties","nAbilityMod",nAbilityMod);
Debug.console("manager_abilityscores.lua","getStrengthProperties","nAbilityEffects",nAbilityEffects);
    
    sAbilityEffect = "CHA";
    nAbilityMod, nAbilityEffects = EffectManager.getEffectsBonus(rActor, sAbilityEffect, true);
Debug.console("manager_abilityscores.lua","getStrengthProperties","nAbilityMod",nAbilityMod);
Debug.console("manager_abilityscores.lua","getStrengthProperties","nAbilityEffects",nAbilityEffects);
    -- nScore = nScore + nAbilityMod;
    
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
    local rActor = ActorManager.getActor("", nodeChar);
    -- adjust ability scores from effects!
	local sAbilityEffect = "BINT";
	local nAbilityMod, nAbilityEffects = EffectManager.getEffectsBonus(rActor, sAbilityEffect, true);
Debug.console("manager_abilityscores.lua","getStrengthProperties","nAbilityMod",nAbilityMod);
Debug.console("manager_abilityscores.lua","getStrengthProperties","nAbilityEffects",nAbilityEffects);
    
    sAbilityEffect = "INT";
    nAbilityMod, nAbilityEffects = EffectManager.getEffectsBonus(rActor, sAbilityEffect, true);
Debug.console("manager_abilityscores.lua","getStrengthProperties","nAbilityMod",nAbilityMod);
Debug.console("manager_abilityscores.lua","getStrengthProperties","nAbilityEffects",nAbilityEffects);
    -- nScore = nScore + nAbilityMod;
    local dbAbility = {};
    dbAbility.score = nScore;
    dbAbility.languages = DataCommonADND.aIntelligence[nScore][1];
    dbAbility.spelllevel = DataCommonADND.aIntelligence[nScore][2];
    dbAbility.learn = DataCommonADND.aIntelligence[nScore][3];
    dbAbility.maxlevel = DataCommonADND.aIntelligence[nScore][4];
    dbAbility.illusion = DataCommonADND.aIntelligence[nScore][5];

    local sImmunity_TT = "Immune to these level of Illusion spells. ";
    if (nScore >= 19) then
        sImmunity_TT = sImmunity_TT .. DataCommonADND.aIntelligence[nScore+100][5];
    end
    dbAbility.sImmunity_TT = sImmunity_TT;

Debug.console("manager_abilityscores.lua","getIntelligenceProperties","dbAbility",dbAbility);
    return dbAbility;
end

--
-- Update ability values
--
function updateStrength(nodeChar)
    local dbAbility = AbilityScoreADND.getStrengthProperties(nodeChar);
    local nScore = dbAbility.score;
    local nPercent = dbAbility.scorepercent;
    
    DB.setValue(nodeChar, "abilities.strength.hitadj", "number", dbAbility.hitadj);
    DB.setValue(nodeChar, "abilities.strength.dmgadj", "number", dbAbility.dmgadj);
    DB.setValue(nodeChar, "abilities.strength.weightallow", "number", dbAbility.weightallow);
    DB.setValue(nodeChar, "abilities.strength.maxpress", "number", dbAbility.maxpress);
    DB.setValue(nodeChar, "abilities.strength.opendoors", "string", dbAbility.opendoors);
    DB.setValue(nodeChar, "abilities.strength.bendbars", "number", dbAbility.bendbars);
    -- update encumbrance if we changed strength
    CharManager.updateEncumbrance(nodeChar);
end

function updateDexterity(nodeChar)
    local dbAbility = AbilityScoreADND.getDexterityProperties(nodeChar);
    local nScore = dbAbility.score;
    
    DB.setValue(nodeChar, "abilities.dexterity.reactionadj", "number", dbAbility.reactionadj);
    DB.setValue(nodeChar, "abilities.dexterity.hitadj", "number", dbAbility.hitadj);
    DB.setValue(nodeChar, "abilities.dexterity.defenseadj", "number", dbAbility.defenseadj);

end

function updateWisdom(nodeChar)
    local dbAbility = AbilityScoreADND.getWisdomProperties(nodeChar);
    local nScore = dbAbility.score;
    
    DB.setValue(nodeChar, "abilities.wisdom.magicdefenseadj", "number", dbAbility.magicdefenseadj);
    DB.setValue(nodeChar, "abilities.wisdom.spellbonus", "string", dbAbility.spellbonus);
    DB.setValue(nodeChar, "abilities.wisdom.failure", "number", dbAbility.failure);
    DB.setValue(nodeChar, "abilities.wisdom.immunity", "string", dbAbility.immunity);
end

function updateConstitution(nodeChar)
    local dbAbility = AbilityScoreADND.getConstitutionProperties(nodeChar);
    local nScore = dbAbility.score;

    DB.setValue(nodeChar, "abilities.constitution.hitpointadj", "string", dbAbility.hitpointadj);
    DB.setValue(nodeChar, "abilities.constitution.systemshock", "number", dbAbility.systemshock);
    DB.setValue(nodeChar, "abilities.constitution.resurrectionsurvival", "number", dbAbility.resurrectionsurvival);
    DB.setValue(nodeChar, "abilities.constitution.poisonadj", "number", dbAbility.poisonadj);
    DB.setValue(nodeChar, "abilities.constitution.regeneration", "string", dbAbility.regeneration);
    
end

function updateCharisma(nodeChar)
    local dbAbility = AbilityScoreADND.getCharismaProperties(nodeChar);
    local nScore = dbAbility.score;

    DB.setValue(nodeChar, "abilities.charisma.maxhench", "number", dbAbility.maxhench);
    DB.setValue(nodeChar, "abilities.charisma.loyalty", "number", dbAbility.loyalty);
    DB.setValue(nodeChar, "abilities.charisma.reaction", "number", dbAbility.reaction);
end

function updateIntelligence(nodeChar)
    local dbAbility = AbilityScoreADND.getIntelligenceProperties(nodeChar);
    local nScore = dbAbility.score;

    DB.setValue(nodeChar, "abilities.intelligence.languages", "number", dbAbility.languages);
    DB.setValue(nodeChar, "abilities.intelligence.spelllevel", "number", dbAbility.spelllevel);
    DB.setValue(nodeChar, "abilities.intelligence.learn", "number", dbAbility.learn);
    DB.setValue(nodeChar, "abilities.intelligence.maxlevel", "string", dbAbility.maxlevel);
    DB.setValue(nodeChar, "abilities.intelligence.illusion", "string", dbAbility.illusion);
end
