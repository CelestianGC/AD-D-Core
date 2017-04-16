-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
    if super then
        super.onInit();
    end
	onValueChanged();
end

function update(bReadOnly)
	setReadOnly(bReadOnly);
end

function onValueChanged()
    if self then
        local sTarget = string.lower(self.target[1]);
        local nChanged = getValue();
            
        local rActor = ActorManager.getActor("pc", window.getDatabaseNode());
        local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);
        if sActorType == "pc" and (nChanged >= 1) and (nChanged <= 25) then
            if (sTarget == "strength") then
                updateStrength(nodeActor,nChanged);
            elseif (sTarget == "dexterity") then
                updateDexterity(nodeActor,nChanged);
            elseif (sTarget == "wisdom") then
                updateWisdom(nodeActor,nChanged);
            elseif (sTarget == "constitution") then
                updateConstitution(nodeActor,nChanged);
            elseif (sTarget == "charisma") then
                updateCharisma(nodeActor,nChanged);
            elseif (sTarget == "intelligence") then
                updateIntelligence(nodeActor,nChanged);
            end
        end -- was PC
    end
end

function action(draginfo)
	local rActor = ActorManager.getActor("", window.getDatabaseNode());
	
	local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);
    local nTargetDC = DB.getValue(nodeActor, "abilities.".. self.target[1] .. ".score", 0);

	ActionCheck.performRoll(draginfo, rActor, self.target[1], nTargetDC);
	return true;
end

function onDragStart(button, x, y, draginfo)
	if rollable then
		return action(draginfo);
	end
end
	
function onDoubleClick(x, y)
	if rollable then
		return action();
	end
end

function updateStrength(nodeActor,nChanged)
    -- aStrength[abilityScore]={hit prob, dam adj, weight allow, max press, open doors, bend bars}
    local aStrength = {};
    aStrength[1]  = {-5,-4,1,3,"1(0)",0};
    aStrength[2]  = {-3,-2,1,5,"1(0)",0};
    aStrength[3]  = {-3,-1,5,10,"2(0)",0};
    aStrength[4]  = {-2,-1,10,25,"3(0)",0};
    aStrength[5]  = {-2,-1,10,25,"3(0)",0};
    aStrength[6]  = {-1,0,20,55,"4(0)",0};
    aStrength[7]  = {-1,0,20,55,"4(0)",0};
    aStrength[8]  = {0,0,35,90,"5(0)",1};
    aStrength[9]  = {0,0,35,90,"5(0)",1};
    aStrength[10] = {0,0,40,115,"6(0)",2};
    aStrength[11] = {0,0,40,115,"6(0)",2};
    aStrength[12] = {0,0,45,140,"7(0)",4};
    aStrength[13] = {0,0,45,140,"7(0)",4};
    aStrength[14] = {0,0,55,170,"8(0)",7};
    aStrength[15] = {0,0,55,170,"8(0)",7};
    aStrength[16] = {0,1,70,195,"9(0)",10};
    aStrength[17] = {1,1,85,220,"10(0)",13};
    aStrength[18] = {1,2,110,255,"11(0)",16};
    aStrength[19] = {3,7,485,640,"16(8)",50};
    aStrength[20] = {3,8,535,700,"17(10)",60};
    aStrength[21] = {4,9,635,810,"17(12)",70};
    aStrength[22] = {4,10,785,970,"18(14)",80};
    aStrength[23] = {5,11,935,1130,"18(16)",90};
    aStrength[24] = {6,12,1235,1440,"19(17)",95};
    aStrength[25] = {7,14,1535,1750,"19(18)",99};

    -- Deal with 18 01-100 strength
    aStrength[50] = {1,3,135,280,"12(0)",20};
    aStrength[75] = {2,3,160,305,"13(0)",25};
    aStrength[90] = {2,4,185,330,"14(0)",30};
    aStrength[99] = {2,5,235,380,"15(3)",35};
    aStrength[100] ={3,6,335,480,"16(6)",40};

    nPercent = DB.getValue(nodeActor, "abilities.strength.percent", 0);

    -- Deal with 18 01-100 strength
    if ((nChanged == 18) and (nPercent > 0)) then
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
        nChanged = nPercentRank;
    end
    
    DB.setValue(nodeActor, "abilities.strength.hitadj", "number", aStrength[nChanged][1]);
    DB.setValue(nodeActor, "abilities.strength.dmgadj", "number", aStrength[nChanged][2]);
    DB.setValue(nodeActor, "abilities.strength.weightallow", "number", aStrength[nChanged][3]);
    DB.setValue(nodeActor, "abilities.strength.maxpress", "number", aStrength[nChanged][4]);
    DB.setValue(nodeActor, "abilities.strength.opendoors", "string", aStrength[nChanged][5]);
    DB.setValue(nodeActor, "abilities.strength.bendbars", "number", aStrength[nChanged][6]);
end

function updateDexterity(nodeActor,nChanged)
    -- aDexterity[abilityScore]={reaction, missile, defensive}
    local aDexterity = {};
    aDexterity[1]  =  {-6,-6,5};
    aDexterity[2]  =  {-4,-4,5};
    aDexterity[3]  =  {-3,-3,4};
    aDexterity[4]  =  {-2,-2,3};
    aDexterity[5]  =  {-1,-1,2};
    aDexterity[6]  =  {0,0,1};
    aDexterity[7]  =  {0,0,0};
    aDexterity[8]  =  {0,0,0};
    aDexterity[9]  =  {0,0,0};
    aDexterity[10]  = {0,0,0};
    aDexterity[11]  = {0,0,0};
    aDexterity[12]  = {0,0,0};
    aDexterity[13]  = {0,0,0};
    aDexterity[14]  = {0,0,0};
    aDexterity[15]  = {0,0,-1};
    aDexterity[16]  = {1,1,-2};
    aDexterity[17]  = {2,2,-3};
    aDexterity[18]  = {2,2,-4};
    aDexterity[19]  = {3,3,-4};
    aDexterity[20]  = {3,3,-4};
    aDexterity[21]  = {4,4,-5};
    aDexterity[22]  = {4,4,-5};
    aDexterity[23]  = {4,4,-5};
    aDexterity[24]  = {5,5,-6};
    aDexterity[25]  = {5,5,-6};
    
    DB.setValue(nodeActor, "abilities.dexterity.reactionadj", "number", aDexterity[nChanged][1]);
    DB.setValue(nodeActor, "abilities.dexterity.hitadj", "number", aDexterity[nChanged][2]);
    DB.setValue(nodeActor, "abilities.dexterity.defenseadj", "number", aDexterity[nChanged][3]);
end

function updateWisdom(nodeActor,nChanged)
    local aWisdom = {};
    -- aWisdom[abilityScore]={magic adj, spell bonuses, spell failure, spell imm. }
    aWisdom[1]   =    {-6, "None", 80, "None"};
    aWisdom[2]   =    {-4, "None", 60, "None"};
    aWisdom[3]   =    {-3, "None", 50, "None"};
    aWisdom[4]   =    {-2, "None", 45, "None"};
    aWisdom[5]   =    {-1, "None", 40, "None"};
    aWisdom[6]   =    {-1, "None", 35, "None"};
    aWisdom[7]   =    {-1, "None", 30, "None"};
    aWisdom[8]   =    { 0, "None", 25, "None"};
    aWisdom[9]   =    { 0, "None", 20, "None"};
    aWisdom[10]  =    { 0, "None", 15, "None"};
    aWisdom[11]  =    { 0, "None", 10, "None"};
    aWisdom[12]  =    { 0, "None", 5, "None"};
    aWisdom[13]  =    { 0, "None", 0, "None"};
    aWisdom[14]  =    { 0, "1", 0, "None"};
    aWisdom[15]  =    { 1, "2x1", 0, "None"};
    aWisdom[16]  =    { 2, "2x1,2x1", 0, "None"};
    aWisdom[17]  =    { 3, "2x1,2x2", 0, "None"};
    aWisdom[18]  =    { 4, "Various", 0, "None"};
    aWisdom[19]  =    { 4, "Various", 0, "Various"};
    aWisdom[20]  =    { 4, "Various", 0, "Various"};
    aWisdom[21]  =    { 4, "Various", 0, "Various"};
    aWisdom[22]  =    { 4, "Various", 0, "Various"};
    aWisdom[23]  =    { 4, "Various", 0, "Various"};
    aWisdom[24]  =    { 4, "Various", 0, "Various"};
    aWisdom[25]  =    { 4, "Various", 0, "Various"};

    aWisdom[118]  =    { 4, "Bonus Spells: 2x1st, 2x2nd, 1x3rd", 0, "None"};
    aWisdom[119]  =    { 4, "Bonus Spells: 3x1st, 2x2nd, 2x3rd, 1x4th", 0, "Spells: cause fear,charm person, command, friends, hypnotism"};
    aWisdom[120]  =    { 4, "Bonus Spells: 3x1st, 3x2nd, 2x3rd, 2x4th", 0, "Spells: cause fear,charm person, command, friends, hypnotism, forget, hold person, enfeeble, scare"};
    aWisdom[121]  =    { 4, "Bonus Spells: 3x1st, 3x2nd, 3x3rd, 2x4th, 5th", 0, "Spells: cause fear,charm person, command, friends, hypnotism, forget, hold person, enfeeble, scare, fear"};
    aWisdom[122]  =    { 4, "Bonus Spells: 3x1st, 3x2nd, 3x3rd, 3x4th, 2x5th", 0, "Spells: cause fear,charm person, command, friends, hypnotism, forget, hold person, enfeeble, scare, fear, charm monster, confusion, emotion, fumble, suggestion"};
    aWisdom[123]  =    { 4, "Bonus Spells: 4x1st, 3x2nd, 3x3rd, 3x4th, 2x5th, 1x6th", 0, "Spells: cause fear,charm person, command, friends, hypnotism, forget, hold person, enfeeble, scare, fear, charm monster, confusion, emotion, fumble, suggestion, chaos, feeblemind, hold monster,magic jar,quest"};
    aWisdom[124]  =    { 4, "Bonus Spells: 4x1st, 3x2nd, 3x3rd, 3x4th, 3x5th, 2x6th", 0, "Spells: cause fear,charm person, command, friends, hypnotism, forget, hold person, enfeeble, scare, fear, charm monster, confusion, emotion, fumble, suggestion, chaos, feeblemind, hold monster,magic jar,quest, geas, mass suggestion, rod of ruleship"};
    aWisdom[125]  =    { 4, "Bonus Spells: 4x1st, 3x2nd, 3x3rd, 3x4th, 3x5th, 3x6th,1x7th", 0, "Spells: cause fear,charm person, command, friends, hypnotism, forget, hold person, enfeeble, scare, fear, charm monster, confusion, emotion, fumble, suggestion, chaos, feeblemind, hold monster,magic jar,quest, geas, mass suggestion, rod of ruleship, antipathy/sympath, death spell,mass charm"};
    
    DB.setValue(nodeActor, "abilities.wisdom.magicdefenseadj", "number", aWisdom[nChanged][1]);
    DB.setValue(nodeActor, "abilities.wisdom.spellbonus", "string", aWisdom[nChanged][2]);
    DB.setValue(nodeActor, "abilities.wisdom.failure", "number", aWisdom[nChanged][3]);
    DB.setValue(nodeActor, "abilities.wisdom.immunity", "string", aWisdom[nChanged][4]);


    if (window and window.wisdom_immunity and window.wisdom_immunity_label 
        and window.wisdom_spellbonus and window.wisdom_spellbonus_label) then
        -- set tooltip for this because it's just to big for the
        -- abilities pane
        local sBonus_TT = "Bonus spells granted by high wisdom. ";
        local sImmunity_TT = "Immunity to spells granted by high wisdom. ";
        if (nChanged >= 18) then
            sBonus_TT = sBonus_TT .. aWisdom[nChanged+100][2];
            sImmunity_TT = sImmunity_TT .. aWisdom[nChanged+100][4];
            -- set the xml elements tooltip to data to large for display
        end
        window.wisdom_immunity.setTooltipText(sImmunity_TT);
        window.wisdom_immunity_label.setTooltipText(sImmunity_TT);

        window.wisdom_spellbonus.setTooltipText(sBonus_TT);
        window.wisdom_spellbonus_label.setTooltipText(sBonus_TT);
    end

end

function updateConstitution(nodeActor,nChanged)
    -- aConstitution[abilityScore]={hp, system shock, resurrection survivial, poison save, regeneration}
    local aConstitution = {};
    aConstitution[1]  =   {"-3",25,30,-2,"None"};
    aConstitution[2]  =   {"-2",30,35,-1,"None"};
    aConstitution[3]  =   {"-2",35,40,0,"None"};
    aConstitution[4]  =   {"-1",40,45,0,"None"};
    aConstitution[5]  =   {"-1",45,50,0,"None"};
    aConstitution[6]  =   {"-1",50,55,0,"None"};
    aConstitution[7]  =   {"0",55,60,0,"None"};
    aConstitution[8]  =   {"0",60,65,0,"None"};
    aConstitution[9]  =   {"0",65,70,0,"None"};
    aConstitution[10]  =  {"0",70,75,0,"None"};
    aConstitution[11]  =  {"0",75,80,0,"None"};
    aConstitution[12]  =  {"0",80,85,0,"None"};
    aConstitution[13]  =  {"0",85,90,0,"None"};
    aConstitution[14]  =  {"0",88,92,0,"None"};
    aConstitution[15]  =  {"1",90,94,0,"None"};
    aConstitution[16]  =  {"2",95,96,0,"None"};
    aConstitution[17]  =  {"2/3",97,98,0,"None"};
    aConstitution[18]  =  {"2/4",99,100,0,"None"};
    aConstitution[19]  =  {"2/5",99,100,1,"None"};
    aConstitution[20]  =  {"2/5",99,100,1,"1/6 turns"};
    aConstitution[21]  =  {"2/6",99,100,2,"1/5 turns"};
    aConstitution[22]  =  {"2/6",99,100,2,"1/4 turns"};
    aConstitution[23]  =  {"2/6",99,100,3,"1/3 turns"};
    aConstitution[24]  =  {"2/7",99,100,3,"1/2"};
    aConstitution[25]  =  {"2/7",100,100,4,"1 turn"};
    
    DB.setValue(nodeActor, "abilities.constitution.hitpointadj", "string", aConstitution[nChanged][1]);
    DB.setValue(nodeActor, "abilities.constitution.systemshock", "number", aConstitution[nChanged][2]);
    DB.setValue(nodeActor, "abilities.constitution.resurrectionsurvival", "number", aConstitution[nChanged][3]);
    DB.setValue(nodeActor, "abilities.constitution.poisonadj", "number", aConstitution[nChanged][4]);
    DB.setValue(nodeActor, "abilities.constitution.regeneration", "string", aConstitution[nChanged][5]);
end

function updateCharisma(nodeActor,nChanged)
    -- aCharisma[abilityScore]={reaction, missile, defensive}
    local aCharisma = {};
    aCharisma[1]   =  {0, -8,-7};
    aCharisma[2]   =  {1, -7,-6};
    aCharisma[3]   =  {1, -6,-5};
    aCharisma[4]   =  {1, -5,-4};
    aCharisma[5]   =  {2, -4,-3};
    aCharisma[6]   =  {2, -3,-2};
    aCharisma[7]   =  {3, -2,-1};
    aCharisma[8]   =  {3, -1,0};
    aCharisma[9]   =  {4, 0, 0};
    aCharisma[10]  =  {4, 0, 0};
    aCharisma[11]  =  {4, 0, 0};
    aCharisma[12]  =  {5, 0, 0};
    aCharisma[13]  =  {5, 0, 1};
    aCharisma[14]  =  {6, 1, 2};
    aCharisma[15]  =  {7, 3, 3};
    aCharisma[16]  =  {8, 4, 5};
    aCharisma[17]  =  {10,6, 6};
    aCharisma[18]  =  {15,8, 7};
    aCharisma[19]  =  {20,10,8};
    aCharisma[20]  =  {25,12,9};
    aCharisma[21]  =  {30,14,10};
    aCharisma[22]  =  {35,16,1};
    aCharisma[23]  =  {40,18,12};
    aCharisma[24]  =  {45,20,13};
    aCharisma[25]  =  {50,20,14};
    
    DB.setValue(nodeActor, "abilities.charisma.maxhench", "number", aCharisma[nChanged][1]);
    DB.setValue(nodeActor, "abilities.charisma.loyalty", "number", aCharisma[nChanged][2]);
    DB.setValue(nodeActor, "abilities.charisma.reaction", "number", aCharisma[nChanged][3]);
	
end

function updateIntelligence(nodeActor,nChanged)
    -- aIntelligence[abilityScore]={# languages, spelllevel, learn spell, max spells, illusion immunity}
    local aIntelligence = {};
    aIntelligence[1]  =    {0, 0,0,  0,"None"};
    aIntelligence[2]  =    {0, 0,0,  0,"None"};
    aIntelligence[3]  =    {0, 0,0,  0,"None"};
    aIntelligence[4]  =    {0, 0,0,  0,"None"};
    aIntelligence[5]  =    {0, 0,0,  0,"None"};
    aIntelligence[6]  =    {0, 0,0,  0,"None"};
    aIntelligence[7]  =    {0, 0,0,  0,"None"};
    aIntelligence[8]  =    {0, 0,0,  0,"None"};
    aIntelligence[9]  =    {2, 4,35, 6,"None"};
    aIntelligence[10]  =   {2, 5,40, 7,"None"};
    aIntelligence[11]  =   {2, 5,45, 7,"None"};
    aIntelligence[12]  =   {3, 6,50, 7,"None"};
    aIntelligence[13]  =   {3, 6,55, 9,"None"};
    aIntelligence[14]  =   {4, 7,60, 9,"None"};
    aIntelligence[15]  =   {4, 7,65, 11,"None"};
    aIntelligence[16]  =   {5, 8,70, 11,"None"};
    aIntelligence[17]  =   {6, 8,75, 14,"None"};
    aIntelligence[18]  =   {7, 9,85, 18,"None"};
    aIntelligence[19]  =   {8, 9,95, "All","1st"};
    aIntelligence[20]  =   {9, 9,96, "All","1,2"};
    aIntelligence[21]  =   {10,9,97, "All","1,2,3"};
    aIntelligence[22]  =   {11,9,98, "All","1,2,3,4"};
    aIntelligence[23]  =   {12,9,99, "All","1,2,3,4,5"};
    aIntelligence[24]  =   {15,9,100,"All","1,2,3,4,5,6"};
    aIntelligence[25]  =   {20,9,100,"All","1,2,3,4,5,6,7"};
    
    -- these have such long values we stuff them into tooltips instead
    
    aIntelligence[119]  =   {8, 9,95, 0,"Level: 1st"};
    aIntelligence[120]  =   {9, 9,96, 0,"Level: 1st, 2nd"};
    aIntelligence[121]  =   {10,9,97, 0,"Level: 1st, 2nd, 3rd"};
    aIntelligence[122]  =   {11,9,98, 0,"Level: 1st, 2nd, 3rd, 4th"};
    aIntelligence[123]  =   {12,9,99, 0,"Level: 1st, 2nd, 3rd, 4th, 5th"};
    aIntelligence[124]  =   {15,9,100,0,"Level: 1st, 2nd, 3rd, 4th, 5th, 6th"};
    aIntelligence[125]  =   {20,9,100,0,"Level: 1st, 2nd, 3rd, 4th, 5th, 6th, 7th"};

    DB.setValue(nodeActor, "abilities.intelligence.languages", "number", aIntelligence[nChanged][1]);
    DB.setValue(nodeActor, "abilities.intelligence.spelllevel", "number", aIntelligence[nChanged][2]);
    DB.setValue(nodeActor, "abilities.intelligence.learn", "number", aIntelligence[nChanged][3]);
    DB.setValue(nodeActor, "abilities.intelligence.maxlevel", "string", aIntelligence[nChanged][4]);
    DB.setValue(nodeActor, "abilities.intelligence.illusion", "string", aIntelligence[nChanged][5]);

    -- set tooltip for this because it's just to big for the
    -- abilities pane
    if (window and window.intelligence_illusion and window.intelligence_illusion_label) then
        local sImmunity_TT = "Immune these level of Illusion spells. ";
        if (nChanged >= 19) then
            sImmunity_TT = sImmunity_TT .. aIntelligence[nChanged+100][5];
        end
        window.intelligence_illusion.setTooltipText(sImmunity_TT);
        window.intelligence_illusion_label.setTooltipText(sImmunity_TT);
    end
end
