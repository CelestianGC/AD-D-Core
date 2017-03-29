-- 
-- 
-- 
--

    -- this index points to the location of this save
    -- in the aWarriorSaves
    saves_warrior_index = {
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

    -- Death, Rod, Poly, Breath, Spell

    -- Death, Rod, Poly, Breath, Spell

    -- Death, Rod, Poly, Breath, Spell
    
end
