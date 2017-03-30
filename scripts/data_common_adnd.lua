-- 
-- 
-- 
--

    -- this index points to the location of this save
    -- in the aWarriorSaves, aPriestSaves, aWizardSaves, aRogueSaves
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

    -- thaco rates, 2/3 = 0.67 etc..
    thaco_priest = 0.67;
    thaco_warrior = 1;
    thaco_rogue = 0.5;
    thaco_wizard = 0.33;
    
function onInit()

    -- Death, Rod, Poly, Breath, Spell
    aWarriorSaves[0]  = {16,18,17,20,19};
    aWarriorSaves[1]  = {15,16,15,17,17};
    aWarriorSaves[2]  = {15,16,15,17,17};
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
    aRogueSaves[5]  = {12,12,11,15,12};
    aRogueSaves[6]  = {12,12,11,15,12};
    aRogueSaves[7]  = {12,12,11,15,12};
    aRogueSaves[8]  = {12,12,11,15,12};
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
    
end
