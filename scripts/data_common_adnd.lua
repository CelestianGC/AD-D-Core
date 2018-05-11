-- 
-- 
-- 
--

    -- what version of AD&D is this
    coreVersion = "2e";

    -- this index points to the location of this save
    -- in the aWarriorSaves, aPriestSaves, aWizardSaves, aRogueSaves
    -- We do this so we can split the saves up and give
    -- bonuses for things like just poison or just wands.
    -- 1 = Paralyzation, poison or death
    -- 2 = Rod, Staff or Wand
    -- 3 = Petrification or Polymorph
    -- 4 = Breath
    -- 5 = Spell
    saves_table_index = {
        ["poison"] = 1,
        ["paralyzation"] = 1,
        ["death"] = 1,
        ["rod"] = 2,
        ["staff"] = 2,
        ["wand"] = 2,
        ["petrification"] = 3,
        ["polymorph"] = 3,
        ["breath"] = 4,
        ["spell"] = 5
    };

    aWarriorSaves = {};
    aPriestSaves = {};
    aWizardSaves = {};
    aRogueSaves = {};

    -- every 3 levels get improvement of 2 thaco
    thaco_priest_rate = 3;
    thaco_priest_advancement = 2;
    
    -- every 1 level get improvement of 1 thaco
    thaco_warrior_rate = 1;
    thaco_warrior_advancement = 1;

    -- every 2 levels get improvement of 1 thaco
    thaco_rogue_rate = 2;
    thaco_rogue_advancement = 1;
    
    -- every 3 levels get improvement of 1 thaco
    thaco_wizard_rate = 3;
    thaco_wizard_advancement = 1;

    -- ability scores 
    aStrength = {};
    aDexterity = {};
    aWisdom = {};
    aConstitution = {};
    aCharisma = {};
    aIntelligence = {};
    
    -- turn undead, cleric
    aTurnUndead = {};
    
    -- distance per unit grid, this is for reach? --celestian
    nDefaultDistancePerUnitGrid = 10;
    
    -- used in effects to denote that these types of modifiers are not added up
    -- and to use the "best" (highest) one.
    basetypes = {
      "BSTR",
      "BDEX",
      "BINT",
      "BCHA",
      "BCON",
      "BWIS",
      "BPSTR",
      "BPDEX",
      "BPINT",
      "BPCHA",
      "BPCON",
      "BPWIS",
    };
    
    -- base effect, take LOWEST (low AC is good remember)
    lowtypes = {
      "BAC",      -- base AC
      "BRANGEAC", -- base ranged AC (attack is via range)
      "BMELEEAC", -- base melee AC
      "BMAC",     -- base mental AC
    };
    
    -- also added these effect tags
    --"TURN",
    --"TURNLEVEL",
    --"SURPRISE",
    
    -- these class get con bonus to hp
    fighterTypes = {
        "fighter",
        "ranger",
        "paladin",
        "barbarian",        
    };
    
function onInit()

    -- default initiative dice size 
	nDefaultInitiativeDice = 10;
    -- default coin weight, 50 coins = 1 pound
    nDefaultCoinWeight = 0.02;
    -- default surprise dice
    aDefaultSurpriseDice = {"d10"};
    
    -- aStrength[abilityScore]={hit adj, dam adj, weight allow, max press, open doors, bend bars, light enc, moderate enc, heavy enc, severe enc, max enc}
    aStrength[1]  = {-5,-4,1,3,"1(0)",0 ,2,3,4,5,7};
    aStrength[2]  = {-3,-2,1,5,"1(0)",0 ,2,3,4,5,7};
    aStrength[3]  = {-3,-1,5,10,"2(0)",0 ,2,3,4,5,7};
    
    aStrength[4]  = {-2,-1,10,25,"3(0)",0 ,11,14,17,20,25};
    aStrength[5]  = {-2,-1,10,25,"3(0)",0 ,11,14,17,20,25};
    
    aStrength[6]  = {-1,0,20,55,"4(0)",0 ,21,30,39,47,55};
    aStrength[7]  = {-1,0,20,55,"4(0)",0 ,21,30,39,47,55};
    
    aStrength[8]  = {0,0,35,90,"5(0)",1 ,36,51,66,81,90};
    aStrength[9]  = {0,0,35,90,"5(0)",1 ,36,51,66,81,90};
    
    aStrength[10] = {0,0,40,115,"6(0)",2 ,41,59,77,97,110};
    aStrength[11] = {0,0,40,115,"6(0)",2 ,41,59,77,97,110};
    
    aStrength[12] = {0,0,45,140,"7(0)",4 ,46,70,94,118,140};
    aStrength[13] = {0,0,45,140,"7(0)",4 ,46,70,94,118,140};
    
    aStrength[14] = {0,0,55,170,"8(0)",7 ,56,86,116,146,170};
    aStrength[15] = {0,0,55,170,"8(0)",7 ,56,86,116,146,170};
    
    aStrength[16] = {0,1,70,195,"9(0)",10 ,71,101,131,161,195};
    
    aStrength[17] = {1,1,85,220,"10(0)",13 ,86,122,158,194,220};
    
    aStrength[18] = {1,2,110,255,"11(0)",16 ,111,150,189,228,255};
    
    aStrength[19] = {3,7,485,640,"16(8)",50 ,486,500,550,600,640};
    aStrength[20] = {3,8,535,700,"17(10)",60 ,536,580,610,670,700};
    aStrength[21] = {4,9,635,810,"17(12)",70 ,636,680,720,790,810};
    aStrength[22] = {4,10,785,970,"18(14)",80 ,786,830,870,900,970};
    aStrength[23] = {5,11,935,1130,"18(16)",90 ,936,960,1000,1090,1130};
    aStrength[24] = {6,12,1235,1440,"19(17)",95 ,1236,1290,1300,1380,1440};
    aStrength[25] = {7,14,1535,1750,"19(18)",99 ,1536,1590,1600,1680,1750};
    -- Deal with 18 01-100 strength
    aStrength[50] = {1,3,135,280,"12(0)",20 ,136,175,214,253,280};
    aStrength[75] = {2,3,160,305,"13(0)",25 ,161,200,239,278,305};
    aStrength[90] = {2,4,185,330,"14(0)",30 ,186,225,264,303,330};
    aStrength[99] = {2,5,235,380,"15(3)",35 ,236,275,314,353,380};
    aStrength[100] ={3,6,335,480,"16(6)",40 ,336,375,414,453,480};

    -- aDexterity[abilityScore]={reaction, missile, defensive}
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
    aWisdom[13]  =    { 0, "1x1", 0, "None"};
    aWisdom[14]  =    { 0, "2x1", 0, "None"};
    aWisdom[15]  =    { 1, "2x1", 0, "None"};
    aWisdom[16]  =    { 2, "2x1,1x2", 0, "None"};
    aWisdom[17]  =    { 3, "2x1,2x2", 0, "None"};
    aWisdom[18]  =    { 4, "Various", 0, "None"};
    aWisdom[19]  =    { 4, "Various", 0, "Various"};
    aWisdom[20]  =    { 4, "Various", 0, "Various"};
    aWisdom[21]  =    { 4, "Various", 0, "Various"};
    aWisdom[22]  =    { 4, "Various", 0, "Various"};
    aWisdom[23]  =    { 4, "Various", 0, "Various"};
    aWisdom[24]  =    { 4, "Various", 0, "Various"};
    aWisdom[25]  =    { 4, "Various", 0, "Various"};
    -- deal with long string bonus for tooltip
    aWisdom[118]  =    { 4, "Bonus Spells: 2x1st, 2x2nd, 1x3rd, 1x4th", 0, "None"};
    aWisdom[119]  =    { 4, "Bonus Spells: 3x1st, 2x2nd, 2x3rd, 1x4th", 0, "Spells: cause fear,charm person, command, friends, hypnotism"};
    aWisdom[120]  =    { 4, "Bonus Spells: 3x1st, 3x2nd, 2x3rd, 2x4th", 0, "Spells: cause fear,charm person, command, friends, hypnotism, forget, hold person, enfeeble, scare"};
    aWisdom[121]  =    { 4, "Bonus Spells: 3x1st, 3x2nd, 3x3rd, 2x4th, 5th", 0, "Spells: cause fear,charm person, command, friends, hypnotism, forget, hold person, enfeeble, scare, fear"};
    aWisdom[122]  =    { 4, "Bonus Spells: 3x1st, 3x2nd, 3x3rd, 3x4th, 2x5th", 0, "Spells: cause fear,charm person, command, friends, hypnotism, forget, hold person, enfeeble, scare, fear, charm monster, confusion, emotion, fumble, suggestion"};
    aWisdom[123]  =    { 4, "Bonus Spells: 4x1st, 3x2nd, 3x3rd, 3x4th, 2x5th, 1x6th", 0, "Spells: cause fear,charm person, command, friends, hypnotism, forget, hold person, enfeeble, scare, fear, charm monster, confusion, emotion, fumble, suggestion, chaos, feeblemind, hold monster,magic jar,quest"};
    aWisdom[124]  =    { 4, "Bonus Spells: 4x1st, 3x2nd, 3x3rd, 3x4th, 3x5th, 2x6th", 0, "Spells: cause fear,charm person, command, friends, hypnotism, forget, hold person, enfeeble, scare, fear, charm monster, confusion, emotion, fumble, suggestion, chaos, feeblemind, hold monster,magic jar,quest, geas, mass suggestion, rod of ruleship"};
    aWisdom[125]  =    { 4, "Bonus Spells: 4x1st, 3x2nd, 3x3rd, 3x4th, 3x5th, 3x6th,1x7th", 0, "Spells: cause fear,charm person, command, friends, hypnotism, forget, hold person, enfeeble, scare, fear, charm monster, confusion, emotion, fumble, suggestion, chaos, feeblemind, hold monster,magic jar,quest, geas, mass suggestion, rod of ruleship, antipathy/sympath, death spell,mass charm"};

    -- aConstitution[abilityScore]={hp, system shock, resurrection survivial, poison save, regeneration}
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
    
    -- aCharisma[abilityScore]={reaction, missile, defensive}
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
    
    -- aIntelligence[abilityScore]={# languages, spelllevel, learn spell, max spells, illusion immunity}
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
    aIntelligence[119]  =   {8, 9,95, "All","Level: 1st"};
    aIntelligence[120]  =   {9, 9,96, "All","Level: 1st, 2nd"};
    aIntelligence[121]  =   {10,9,97, "All","Level: 1st, 2nd, 3rd"};
    aIntelligence[122]  =   {11,9,98, "All","Level: 1st, 2nd, 3rd, 4th"};
    aIntelligence[123]  =   {12,9,99, "All","Level: 1st, 2nd, 3rd, 4th, 5th"};
    aIntelligence[124]  =   {15,9,100,"All","Level: 1st, 2nd, 3rd, 4th, 5th, 6th"};
    aIntelligence[125]  =   {20,9,100,"All","Level: 1st, 2nd, 3rd, 4th, 5th, 6th, 7th"};



                      -- Death, Rod, Poly, Breath, Spell
    aWarriorSaves[0]  = {16,18,17,20,19};
    aWarriorSaves[1]  = {14,16,15,17,17};
    aWarriorSaves[2]  = {14,16,15,17,17};
    aWarriorSaves[3]  = {13,15,14,16,16};
    aWarriorSaves[4]  = {13,15,14,16,16};
    aWarriorSaves[5]  = {11,13,12,13,14};
    aWarriorSaves[6]  = {11,13,12,13,14};
    aWarriorSaves[7]  = {10,12,11,12,13};
    aWarriorSaves[8]  = {10,12,11,12,13};
    aWarriorSaves[9]  = {8,10,9,9,11};
    aWarriorSaves[10] = {8,10,9,9,11};
    aWarriorSaves[11] = {7,9,8,8,10};
    aWarriorSaves[12] = {7,9,8,8,10};
    aWarriorSaves[13] = {5,7,6,5,8};
    aWarriorSaves[14] = {5,7,6,5,8};
    aWarriorSaves[15] = {4,6,5,4,7};
    aWarriorSaves[16] = {4,6,5,4,7};
    aWarriorSaves[17] = {3,5,4,4,6};
    aWarriorSaves[18] = {3,5,4,4,6};
    aWarriorSaves[19] = {3,5,4,4,6};
    aWarriorSaves[20] = {3,5,4,4,6};
    aWarriorSaves[21] = {3,5,4,4,6};

                     -- Death, Rod, Poly, Breath, Spell
    aPriestSaves[0]  = {10,14,13,16,15};
    aPriestSaves[1]  = {10,14,13,16,15};
    aPriestSaves[2]  = {10,14,13,16,15};
    aPriestSaves[3]  = {10,14,13,16,15};
    aPriestSaves[4]  = {9,13,12,15,14};
    aPriestSaves[5]  = {9,13,12,15,14};
    aPriestSaves[6]  = {9,13,12,15,14};
    aPriestSaves[7]  = {7,11,10,13,12};
    aPriestSaves[8]  = {7,11,10,13,12};
    aPriestSaves[9]  = {7,11,10,13,12};
    aPriestSaves[10] = {6,10,9,12,11};
    aPriestSaves[11] = {6,10,9,12,11};
    aPriestSaves[12] = {6,10,9,12,11};
    aPriestSaves[13] = {5,9,8,11,10};
    aPriestSaves[14] = {5,9,8,11,10};
    aPriestSaves[15] = {5,9,8,11,10};
    aPriestSaves[16] = {4,8,7,10,9};
    aPriestSaves[17] = {4,8,7,10,9};
    aPriestSaves[18] = {4,8,7,10,9};
    aPriestSaves[19] = {2,6,5,8,7};
    aPriestSaves[20] = {2,6,5,8,7};
    aPriestSaves[21] = {2,6,5,8,7};

                     -- Death, Rod, Poly, Breath, Spell
    aWizardSaves[0]  = {14,11,13,15,12};
    aWizardSaves[1]  = {14,11,13,15,12};
    aWizardSaves[2]  = {14,11,13,15,12};
    aWizardSaves[3]  = {14,11,13,15,12};
    aWizardSaves[4]  = {14,11,13,15,12};
    aWizardSaves[5]  = {14,11,13,15,12};
    aWizardSaves[6]  = {13,9,11,13,10};
    aWizardSaves[7]  = {13,9,11,13,10};
    aWizardSaves[8]  = {13,9,11,13,10};
    aWizardSaves[9]  = {13,9,11,13,10};
    aWizardSaves[10]  = {13,9,11,13,10};
    aWizardSaves[11] = {11,7,9,11,8};
    aWizardSaves[12] = {11,7,9,11,8};
    aWizardSaves[13] = {11,7,9,11,8};
    aWizardSaves[14] = {11,7,9,11,8};
    aWizardSaves[15] = {11,7,9,11,8};
    aWizardSaves[16] = {10,5,7,9,6};
    aWizardSaves[17] = {10,5,7,9,6};
    aWizardSaves[18] = {10,5,7,9,6};
    aWizardSaves[19] = {10,5,7,9,6};
    aWizardSaves[20] = {10,5,7,9,6};
    aWizardSaves[21] = {8,3,5,7,4};

                    -- Death, Rod, Poly, Breath, Spell
    aRogueSaves[0]  = {13,14,12,16,15};
    aRogueSaves[1]  = {13,14,12,16,15};
    aRogueSaves[2]  = {13,14,12,16,15};
    aRogueSaves[3]  = {13,14,12,16,15};
    aRogueSaves[4]  = {13,14,12,16,15};
    aRogueSaves[5]  = {12,12,11,15,13};
    aRogueSaves[6]  = {12,12,11,15,13};
    aRogueSaves[7]  = {12,12,11,15,13};
    aRogueSaves[8]  = {12,12,11,15,13};
    aRogueSaves[9]  = {11,10,10,14,11};
    aRogueSaves[10]  = {11,10,10,14,11};
    aRogueSaves[11]  = {11,10,10,14,11};
    aRogueSaves[12]  = {11,10,10,14,11};
    aRogueSaves[13] = {10,8,9,13,9};
    aRogueSaves[14] = {10,8,9,13,9};
    aRogueSaves[15] = {10,8,9,13,9};
    aRogueSaves[16] = {10,8,9,13,9};
    aRogueSaves[17] = {9,6,8,12,7};
    aRogueSaves[18] = {9,6,8,12,7};
    aRogueSaves[19] = {9,6,8,12,7};
    aRogueSaves[20] = {9,6,8,12,7};
    aRogueSaves[21] = {8,4,7,11,5};
    
    -- default turn dice size 
	nDefaultTurnDice = {"d20"};
  nDefaultTurnUndeadMaxHD = 13; -- this is actually the number of turn_name_index entries
  -- index of the turns 1-13
  turn_name_index ={      -- make sure the HD listing is XXHD or X-XHD, 
      "Skeleton or 1HD",  -- we need the number it from of HD for the 
      "Zombie or 1-2HD",  -- turn undead automation.
      "Ghoul or 2HD",
      "Shadow or 3-4HD",
      "Wight or 5HD",
      "Ghast or 5-6HD",
      "Wraith or 6HD",
      "Mummy or 7HD",
      "Spectre or 8HD",
      "Vampire or 9HD",
      "Ghost or 10HD",
      "Lich or 11-15HD+", -- 11++ doesn't work so I added 11-15 so the max HD is 15 this will work on
      "Special 20HD++"    -- "special" doesn't translate so added 20+ HD
  };
    
    -- cap of turn improvement
    nDefaultTurnUndeadMaxLevel = 14;

    --  0 = Cannot turn
    -- -1 = Turn
    -- -2 = Disentigrate
    -- -3 = Additional 2d4 creatures effected.
    aTurnUndead[1] =  {10,13,16,19,20,0,0,0,0,0,0,0,0};
    aTurnUndead[2] =  {7,10,13,16,19,20,0,0,0,0,0,0,0};
    aTurnUndead[3] =  {4,7,10,13,16,19,20,0,0,0,0,0,0};
    aTurnUndead[4] =  {-1,4,7,10,13,16,19,20,0,0,0,0,0};
    aTurnUndead[5] =  {-1,-1,4,7,10,13,16,19,20,0,0,0,0};
    aTurnUndead[6] =  {-2,-1,-1,4,7,10,13,16,19,20,0,0,0};
    aTurnUndead[7] =  {-2,-2,-1,-1,4,7,10,13,16,19,20,0,0};
    aTurnUndead[8] =  {-3,-2,-2,-1,-1,4,7,10,13,16,19,20,0};
    aTurnUndead[9] =  {-3,-3,-2,-2,-1,-1,4,7,10,13,16,19,20};
    aTurnUndead[10] = {-3,-3,-3,-2,-2,-1,-1,4,7,10,13,16,19};
    aTurnUndead[11] = {-3,-3,-3,-2,-2,-1,-1,4,7,10,13,16,19};
    aTurnUndead[12] = {-3,-3,-3,-3,-2,-2,-1,-1,4,7,10,13,16};
    aTurnUndead[13] = {-3,-3,-3,-3,-2,-2,-1,-1,4,7,10,13,16};
    aTurnUndead[14] = {-3,-3,-3,-3,-3,-2,-2,-1,-1,4,7,10,13};

end
