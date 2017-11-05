-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Abilities (database names)
abilities = {
	"strength",
	"dexterity",
	"constitution",
	"intelligence",
	"wisdom",
	"charisma"
};

ability_ltos = {
	["strength"] = "STR",
	["dexterity"] = "DEX",
	["constitution"] = "CON",
	["intelligence"] = "INT",
	["wisdom"] = "WIS",
	["charisma"] = "CHA"
};

ability_stol = {
	["STR"] = "strength",
	["DEX"] = "dexterity",
	["CON"] = "constitution",
	["INT"] = "intelligence",
	["WIS"] = "wisdom",
	["CHA"] = "charisma"
};

-- saves (Database names)
-- saves = {
	-- "save_paralyzation_poison_death",
	-- "save_rod_staff_wand",
	-- "save_petrify_polymorph",
	-- "save_breath",
	-- "save_spell"
-- };

    saves = {
        "poison",
        "paralyzation",
        "death",
        "rod",
        "staff",
        "wand",
        "petrification",
        "polymorph",
        "breath",
        "spell"
    };

-- saves_stol = {
	-- ["save_paralyzation_poison_death"] = "Paralyzation, Poison or Death",
	-- ["save_rod_staff_wand"] = "Rod, Staff or Wand",
	-- ["save_petrify_polymorph"] = "Petrification or Polymorph",
	-- ["save_breath"] = "Breath Weapon",
	-- ["save_spell"] = "Spells"
	
-- };
    saves_stol = {
        ["poison"] = "Poison",
        ["paralyzation"] = "Paralyzation",
        ["death"] = "Death",
        ["rod"] = "Rod",
        ["staff"] = "Staff",
        ["wand"] = "Wand",
        ["petrification"] = "Petrification",
        ["polymorph"] = "Polymorph",
        ["breath"] = "Breath",
        ["spell"] = "Spell",
    };

-- saves_multi_name = {
	-- ["poison"] = "save_paralyzation_poison_death",
	-- ["paralyzation"] = "save_paralyzation_poison_death",
	-- ["death"] = "save_paralyzation_poison_death",
	-- ["rod"] = "save_rod_staff_wand",
	-- ["rods"] = "save_rod_staff_wand",
	-- ["staff"] = "save_rod_staff_wand",
	-- ["staves"] = "save_rod_staff_wand",
	-- ["wand"] = "save_rod_staff_wand",
	-- ["wands"] = "save_rod_staff_wand",
	-- ["petrification"] = "save_petrify_polymorph",
	-- ["petrify"] = "save_petrify_polymorph",
	-- ["polymorph"] = "save_petrify_polymorph",
	-- ["breath"] = "save_breath",
	-- ["other"] = "save_spell",
	-- ["spells"] = "save_spell",
	-- ["spell"] = "save_spell"
-- };
saves_multi_name = {
	["poison"] = "poison",
	["paralyzation"] = "paralyzation",
	["death"] = "death",
	["rod"] = "rod",
	["rods"] = "rod",
	["staff"] = "staff",
	["staves"] = "staff",
	["wand"] = "wand",
	["wands"] = "wand",
	["petrification"] = "petrification",
	["petrify"] = "petrification",
	["polymorph"] = "polymorph",
	["breath"] = "breath",
	["other"] = "other",
	["spell"] = "spell",
	["spells"] = "spell"
};

-- saves_index = {
	-- ["save_paralyzation_poison_death"] = 1,
	-- ["save_rod_staff_wand"] = 2,
	-- ["save_petrify_polymorph"] = 3,
	-- ["save_breath"] = 4,
	-- ["save_spell"] = 5
-- };
    -- -- this index points to the location of this save
    -- -- in the aFighterSaves in setNPCSave
    -- saves_fighter_index = {
        -- ["poison"] = 1,
        -- ["paralyzation"] = 1,
        -- ["death"] = 1,
        -- ["rod"] = 2,
        -- ["staff"] = 2,
        -- ["wand"] = 2,
        -- ["petrification"] = 3,
        -- ["polymorph"] = 3,
        -- ["breath"] = 4,
        -- ["spell"] = 5
    -- };

saves_shortnames = {
	"poison",
	"paralyzation",
	"death",
	"rod",
	"staff",
	"wand",
	"petrification",
	"polymorph",
	"breath",
	"spell"
};

-- Basic class values (not display values)
classes = {
	"barbarian",
	"bard",
	"cleric",
	"druid",
	"fighter",
	"monk",
	"paladin",
	"ranger",
	"rogue",
	"sorcerer",
	"warlock",
	"wizard",
};

-- Values for wound comparison
healthstatushalf = "bloodied";
healthstatuswounded = "wounded";

-- Values for alignment comparison
alignment_lawchaos = {
	["lawful"] = 1,
	["chaotic"] = 3,
	["lg"] = 1,
	["ln"] = 1,
	["le"] = 1,
	["cg"] = 3,
	["cn"] = 3,
	["ce"] = 3,
};
alignment_goodevil = {
	["good"] = 1,
	["evil"] = 3,
	["lg"] = 1,
	["le"] = 3,
	["ng"] = 1,
	["ne"] = 3,
	["cg"] = 1,
	["ce"] = 3,
};

-- Values for size comparison
creaturesize = {
	["tiny"] = 1,
	["small"] = 2,
	["medium"] = 3,
	["large"] = 4,
	["huge"] = 5,
	["gargantuan"] = 6,
	["T"] = 1,
	["S"] = 2,
	["M"] = 3,
	["L"] = 4,
	["H"] = 5,
	["G"] = 6,
};

-- Values for creature type comparison
creaturedefaulttype = "humanoid";
creaturehalftype = "half-";
creaturehalftypesubrace = "human";
creaturetype = {
	"aberration",
	"beast",
	"celestial",
	"construct",
	"dragon",
	"elemental",
	"fey",
	"fiend",
	"giant",
	"humanoid",
	"monstrosity",
	"ooze",
	"plant",
	"undead",
};
creaturesubtype = {
	"aarakocra",
	"bullywug",
	"demon",
	"devil",
	"dragonborn",
	"dwarf",
	"elf", 
	"gith",
	"gnoll",
	"gnome", 
	"goblinoid",
	"grimlock",
	"halfling",
	"human",
	"kenku",
	"kuo-toa",
	"kobold",
	"lizardfolk",
	"living construct",
	"merfolk",
	"orc",
	"quaggoth",
	"sahuagin",
	"shapechanger",
	"thri-kreen",
	"titan",
	"troglodyte",
	"yuan-ti",
	"yugoloth",
};

-- Values supported in effect conditionals
conditionaltags = {
};

-- Conditions supported in effect conditionals and for token widgets
conditions = {
	"blinded", 
	"charmed",
	"cursed",
	"deafened",
	"encumbered",
	"frightened", 
	"grappled", 
	"incapacitated",
	"incorporeal",
	"intoxicated",
	"invisible", 
	"paralyzed",
	"petrified",
	"poisoned",
	"prone", 
	"restrained",
	"stable", 
	"stunned",
	"turned",
	"unconscious"
};

-- Bonus/penalty effect types for token widgets
bonuscomps = {
	"INIT",
	"CHECK",
	"AC",
	"ATK",
	"DMG",
	"HEAL",
	"SAVE",
	"STR",
	"CON",
	"DEX",
	"INT",
	"WIS",
	"CHA"
};

-- Condition effect types for token widgets
condcomps = {
	["blinded"] = "cond_blinded",
	["charmed"] = "cond_charmed",
	["deafened"] = "cond_deafened",
	["encumbered"] = "cond_encumbered",
	["frightened"] = "cond_frightened",
	["grappled"] = "cond_grappled",
	["incapacitated"] = "cond_paralyzed",
	["incorporeal"] = "cond_incorporeal",
	["invisible"] = "cond_invisible",
	["paralyzed"] = "cond_paralyzed",
	["petrified"] = "cond_paralyzed",
	["prone"] = "cond_prone",
	["restrained"] = "cond_restrained",
	["stunned"] = "cond_stunned",
	["unconscious"] = "cond_unconscious"
};

-- Other visible effect types for token widgets
othercomps = {
	["COVER"] = "cond_cover",
	["SCOVER"] = "cond_cover",
	["IMMUNE"] = "cond_immune",
	["RESIST"] = "cond_resist",
	["VULN"] = "cond_vuln",
	["REGEN"] = "cond_regen",
	["DMGO"] = "cond_ongoing"
};

-- Effect components which can be targeted
targetableeffectcomps = {
	"HIDDEN",
	"COVER",
	"SCOVER",
	"AC",
	"SAVE",
	"ATK",
	"DMG",
	"IMMUNE",
	"VULN",
	"RESIST"
};

connectors = {
	"and",
	"or"
};

-- Range types supported
rangetypes = {
	"melee",
	"ranged"
};

-- Damage types supported
dmgtypes = {
	"acid",		-- ENERGY TYPES
	"cold",
	"fire",
	"force",
	"lightning",
	"necrotic",
	"poison",
	"psychic",
	"radiant",
	"thunder",
	"adamantine", 	-- WEAPON PROPERTY DAMAGE TYPES
	"bludgeoning",
	"cold-forged iron",
	"magic",
	"piercing",
	"silver",
	"slashing",
	"critical", -- SPECIAL DAMAGE TYPES
    "magic +1", --+1 weapons
    "magic +2", --+2 weapons
    "magic +3", --+3 weapons
    "magic +4", --+4 weapons
    "magic +5", --+5 weapons
};

specialdmgtypes = {
	"critical",
};

-- Bonus types supported in power descriptions
bonustypes = {
};
stackablebonustypes = {
};

function onInit()

	-- Classes
	class_nametovalue = {
		[Interface.getString("class_value_barbarian")] = "barbarian",
		[Interface.getString("class_value_bard")] = "bard",
		[Interface.getString("class_value_cleric")] = "cleric",
		[Interface.getString("class_value_druid")] = "druid",
		[Interface.getString("class_value_fighter")] = "fighter",
		[Interface.getString("class_value_monk")] = "monk",
		[Interface.getString("class_value_paladin")] = "paladin",
		[Interface.getString("class_value_ranger")] = "ranger",
		[Interface.getString("class_value_rogue")] = "rogue",
		[Interface.getString("class_value_sorcerer")] = "sorcerer",
		[Interface.getString("class_value_warlock")] = "warlock",
		[Interface.getString("class_value_wizard")] = "wizard",
	};

	class_valuetoname = {
		["barbarian"] = Interface.getString("class_value_barbarian"),
		["bard"] = Interface.getString("class_value_bard"),
		["cleric"] = Interface.getString("class_value_cleric"),
		["druid"] = Interface.getString("class_value_druid"),
		["fighter"] = Interface.getString("class_value_fighter"),
		["monk"] = Interface.getString("class_value_monk"),
		["paladin"] = Interface.getString("class_value_paladin"),
		["ranger"] = Interface.getString("class_value_ranger"),
		["rogue"] = Interface.getString("class_value_rogue"),
		["sorcerer"] = Interface.getString("class_value_sorcerer"),
		["warlock"] = Interface.getString("class_value_warlock"),
		["wizard"] = Interface.getString("class_value_wizard"),
	};

	-- Skills
        skilldata = {};
	-- skilldata = {
		-- [Interface.getString("skill_value_acrobatics")] = { lookup = "acrobatics", stat = 'dexterity' },
		-- [Interface.getString("skill_value_animalhandling")] = { lookup = "animalhandling", stat = 'wisdom' },
		-- [Interface.getString("skill_value_arcana")] = { lookup = "arcana", stat = 'intelligence' },
		-- [Interface.getString("skill_value_athletics")] = { lookup = "athletics", stat = 'strength' },
		-- [Interface.getString("skill_value_deception")] = { lookup = "deception", stat = 'charisma' },
		-- [Interface.getString("skill_value_history")] = { lookup = "history", stat = 'intelligence' },
		-- [Interface.getString("skill_value_insight")] = { lookup = "insight", stat = 'wisdom' },
		-- [Interface.getString("skill_value_intimidation")] = { lookup = "intimidation", stat = 'charisma' },
		-- [Interface.getString("skill_value_investigation")] = { lookup = "investigation", stat = 'intelligence' },
		-- [Interface.getString("skill_value_medicine")] = { lookup = "medicine", stat = 'wisdom' },
		-- [Interface.getString("skill_value_nature")] = { lookup = "nature", stat = 'intelligence' },
		-- [Interface.getString("skill_value_perception")] = { lookup = "perception", stat = 'wisdom' },
		-- [Interface.getString("skill_value_performance")] = { lookup = "performance", stat = 'charisma' },
		-- [Interface.getString("skill_value_persuasion")] = { lookup = "persuasion", stat = 'charisma' },
		-- [Interface.getString("skill_value_religion")] = { lookup = "religion", stat = 'intelligence' },
		-- [Interface.getString("skill_value_sleightofhand")] = { lookup = "sleightofhand", stat = 'dexterity' },
		-- [Interface.getString("skill_value_stealth")] = { lookup = "stealth", stat = 'dexterity', disarmorstealth = 1 },
		-- [Interface.getString("skill_value_survival")] = { lookup = "survival", stat = 'wisdom' },
	-- };

	-- Party sheet drop down list data
	psabilitydata = {
		Interface.getString("strength"),
		Interface.getString("dexterity"),
		Interface.getString("constitution"),
		Interface.getString("intelligence"),
		Interface.getString("wisdom"),
		Interface.getString("charisma"),
	};

	-- Party sheet drop down list data
        psskilldata = {};
	-- psskilldata = {
		-- Interface.getString("skill_value_acrobatics"),
		-- Interface.getString("skill_value_animalhandling"),
		-- Interface.getString("skill_value_arcana"),
		-- Interface.getString("skill_value_athletics"),
		-- Interface.getString("skill_value_deception"),
		-- Interface.getString("skill_value_history"),
		-- Interface.getString("skill_value_insight"),
		-- Interface.getString("skill_value_intimidation"),
		-- Interface.getString("skill_value_investigation"),
		-- Interface.getString("skill_value_medicine"),
		-- Interface.getString("skill_value_nature"),
		-- Interface.getString("skill_value_perception"),
		-- Interface.getString("skill_value_performance"),
		-- Interface.getString("skill_value_persuasion"),
		-- Interface.getString("skill_value_religion"),
		-- Interface.getString("skill_value_sleightofhand"),
		-- Interface.getString("skill_value_stealth"),
		-- Interface.getString("skill_value_survival"),
	-- };
	
	-- partysheet save drop down list
	pssavedata = saves;
	-- pssavedata = {
		-- Interface.getString("save_paralyzation_poison_death"),
		-- Interface.getString("save_rod_staff_wand"),
		-- Interface.getString("save_petrify_polymorph"),
		-- Interface.getString("save_breath"),
		-- Interface.getString("save_spell"),
	-- };

end
