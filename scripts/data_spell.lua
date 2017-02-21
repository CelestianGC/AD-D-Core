-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Examples:
-- { type = "attack", range = "[M|R]", [modifier = #] }
--		If modifier defined, then attack bonus will be this fixed value
--		Otherwise, the attack bonus will be the ability bonus defined for the spell group
--
-- { type = "damage", clauses = { { dice = { "d#", ... }, bonus = #, type = "", [stat = ""] }, ... } }
--		Each damage action can have multiple clauses which can do different damage types
--
-- { type = "heal", [subtype = "temp", ][sTargeting = "self", ] clauses = { { dice = { "d#", ... }, bonus = #, [stat = ""] }, ... } }
--		Each heal action can have multiple clauses 
--		Heal actions are either direct healing or granting temporary hit points (if subtype = "temp" set)
--		If sTargeting = "self" set, then the heal will always be applied to self instead of target.
--
-- { type = "save", save = "<ability>", [savemod = #, ][savestat = "<ability>", ][onmissdamage = "half"] }
--		If savemod defined, then the DC will be this fixed value.
--		If savestat defined, then the DC will be calculated as 8 + specified ability bonus + proficiency bonus
--		Otherwise, the save DC will be the same as the spell group
--
-- { type = "effect", sName = "<effect text>", [sTargeting = "self", ][nDuration = #, ][sUnits = "[<empty>|minute|hour|day]", ][sApply = "[<empty>|action|roll|single]"] }
--		If sTargeting = "self" set, then the effect will always be applied to self instead of target.
--		If nDuration not set or is equal to zero, then the effect will not expire.


-- Spell lookup data
parsedata = {
	["aid"] = {
		{ type = "heal", subtype = "temp", clauses = { { bonus = 5 } } },
	},
	["bane"] = {
		{ type = "save", save = "charisma" },
		{ type = "effect", sName = "ATK: -1d4; SAVE: -1d4; (C)", nDuration = 1, sUnits = "minute" },
	},
	["beacon of hope"] = {
		{ type = "effect", sName = "ADVSAV: wisdom; ADVDEATH; NOTE: Receive Max Healing; (C)", nDuration = 1, sUnits = "minute" },
	},
	["bestow curse"] = {
		{ type = "save", save = "wisdom" },
		{ type = "effect", sName = "DISCHK: strength; DISSAV: strength; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "DISCHK: dexterity; DISSAV: dexterity; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "DISCHK: constitution; DISSAV: constitution; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "DISCHK: intelligence; DISSAV: intelligence; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "DISCHK: wisdom; DISSAV: wisdom; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "DISCHK: charisma; DISSAV: charisma; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "[TRGT]; GRANTDISATK; (C)", sTargeting = "self", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "NOTE: Wisdom save or lose action; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "[TRGT]; DMG: 1d8 necrotic; (C)", sTargeting = "self", nDuration = 1, sUnits = "minute" },
	},
	["blade barrier"] = {
		{ type = "save", save = "dexterity", onmissdamage = "half" },
		{ type = "damage", clauses = { { dice = { "d10", "d10", "d10", "d10", "d10", "d10" }, type = "slashing,magic" } } },
	},
	["blade ward"] = {
		{ type = "effect", sName = "RESIST: bludgeoning,piercing,slashing", nDuration = 1 },
	},
	["bless"] = {
		{ type = "effect", sName = "ATK: 1d4; SAVE: 1d4; (C)", nDuration = 1, sUnits = "minute" },
	},
	["blindness/deafness"] = {
		{ type = "save", save = "constitution" },
		{ type = "effect", sName = "Blinded; NOTE: End of Round Save", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "Deafened; NOTE: End of Round Save", nDuration = 1, sUnits = "minute" },
	},
	["blur"] = {
		{ type = "effect", sName = "GRANTDISATK; (C)", sTargeting = "self", nDuration = 1, sUnits = "minute" },
	},
	["chill touch"] = {
		{ type = "attack", range = "R" },
		{ type = "damage", clauses = { { dice = { "d8" }, type = "necrotic" } } },
		{ type = "effect", sName = "NOTE: Can't regain hit points", nDuration = 1 },
		{ type = "effect", sName = "[TRGT]; GRANTDISATK", sTargeting = "self", nDuration = 1 },
	},
	["chromatic orb"] = {
		{ type = "attack", range = "R" },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8" }, type = "acid" } } },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8" }, type = "cold" } } },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8" }, type = "fire" } } },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8" }, type = "lightning" } } },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8" }, type = "poison" } } },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8" }, type = "thunder" } } },
	},
	["color spray"] = {
		{ type = "effect", sName = "Blinded", nDuration = 1 },
	},
	["contagion"] = {
		{ type = "attack", range = "M" },
		{ type = "effect", sName = "NOTE: Contagion", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "NOTE: Blinding Sickness; DISCHK: wisdom; DISSAV: wisdom; Blinded", nDuration = 7, sUnits = "day" },
		{ type = "effect", sName = "NOTE: Filth Fever; DISCHK: strength; DISSAV: strength; NOTE: DIS on strength attacks", nDuration = 7, sUnits = "day" },
		{ type = "effect", sName = "NOTE: Flesh Rot; DISCHK: charisma; VULN: all", nDuration = 7, sUnits = "day" },
		{ type = "effect", sName = "NOTE: Mindfire; DISCHK: intelligence; NOTE: Confused", nDuration = 7, sUnits = "day" },
		{ type = "effect", sName = "NOTE: Seizure; DISCHK: dexterity; DISSAV: dexterity; NOTE: DIS on dexterity attacks", nDuration = 7, sUnits = "day" },
		{ type = "effect", sName = "NOTE: Slimy Doom; DISCHK: constitution; DISSAV: constitution; NOTE: Stunned when damaged", nDuration = 7, sUnits = "day" },
	},
	["crown of madness"] = {
		{ type = "save", save = "wisdom" },
		{ type = "effect", sName = "Charmed; NOTE: Save on end of round; (C)", nDuration = 1, sUnits = "minute" },
	},
	["death ward"] = {
		{ type = "effect", sName = "NOTE: Death Ward", nDuration = 8, sUnits = "hour" },
	},
	["dispel evil and good"] = {
		{ type = "attack", range = "M" },
		{ type = "save", save = "charisma" },
		{ type = "effect", sName = "IFT: (aberration, celestial, elemental, fey, fiend, undead); GRANTDISATK; IMMUNE: charmed,frightened,possessed; (C)", nDuration = 1, sUnits = "minute" },
	},
	["divine word"] = {
		{ type = "save", save = "charisma" },
		{ type = "effect", sName = "Deafened", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "Deafened; Blinded", nDuration = 10, sUnits = "minute" },
		{ type = "effect", sName = "Blinded; Deafened; Stunned", nDuration = 1, sUnits = "hour" },
	},
	["enhance ability"] = {
		{ type = "effect", sName = "ADVCHK: constitution; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "heal", subtype = "temp", clauses = { { dice = { "d6", "d6" } } } },
		{ type = "effect", sName = "ADVCHK: strength; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "ADVCHK: dexterity; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "ADVCHK: charisma; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "ADVCHK: intelligence; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "ADVCHK: wisdom; (C)", nDuration = 1, sUnits = "hour" },
	},
	["enlarge/reduce"] = {
		{ type = "save", save = "constitution" },
		{ type = "effect", sName = "NOTE: Enlarged; ADVCHK: strength; ADVSAV: strength; DMG: 1d4; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "NOTE: Enlarged; DISCHK: strength; DISSAV: strength; DMG: -1d4; (C)", nDuration = 1, sUnits = "minute" },
	},
	["feign death"] = {
		{ type = "effect", sName = "Blinded; Incapacitated; RESIST: all, !psychic", nDuration = 1, sUnits = "hour" },
	},
	["forbiddance"] = {
		{ type = "damage", clauses = { { dice = { "d10", "d10", "d10", "d10", "d10" }, type = "radiant" } } },
		{ type = "damage", clauses = { { dice = { "d10", "d10", "d10", "d10", "d10" }, type = "necrotic" } } },
	},
	["friends"] = {
		{ type = "effect", sName = "ADVCHK: charisma; (C)", nDuration = 1, sUnits = "minute" },
	},
	["gaseous form"] = {
		{ type = "effect", sName = "NOTE: Gaseous Form; RESIST: all, !magic; ADVSAV: strength; ADVSAV: dexterity; ADVSAV: constitution", nDuration = 1, sUnits = "hour" },
	},
	["geas"] = {
		{ type = "save", save = "wisdom" },
		{ type = "effect", sName = "Charmed" },
		{ type = "damage", clauses = { { dice = { "d10", "d10", "d10", "d10", "d10" }, type = "psychic" } } },
	},
	["glyph of warding"] = {
		{ type = "save", save = "dexterity", onmissdamage = "half" },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8", "d8", "d8" }, type = "acid" } } },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8", "d8", "d8" }, type = "cold" } } },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8", "d8", "d8" }, type = "fire" } } },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8", "d8", "d8" }, type = "lightning" } } },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8", "d8", "d8" }, type = "thunder" } } },
	},
	["grease"] = {
		{ type = "save", save = "dexterity" },
		{ type = "effect", sName = "Prone" },
	},
	["guardian of faith"] = {
		{ type = "effect", sName = "NOTE: Guardian of Faith", sTargeting = "self", nDuration = 8, sUnits = "hour" },
		{ type = "save", save = "dexterity", onmissdamage = "half" },
		{ type = "damage", clauses = { { bonus = 20, type = "radiant" } } },
	},
	["guiding bolt"] = {
		{ type = "attack", range = "R" },
		{ type = "damage", clauses = { { dice = { "d6", "d6", "d6", "d6" }, type = "radiant" } } },
		{ type = "effect", sName = "GRANTADVATK", nDuration = 1, sApply = "roll" },
	},
	["hallow"] = {
		{ type = "save", save = "charisma" },
		{ type = "effect", sName = "IMMUNE: frightened; [FIXED]" },
		{ type = "effect", sName = "RESIST: acid; [FIXED]" },
		{ type = "effect", sName = "RESIST: cold; [FIXED]" },
		{ type = "effect", sName = "RESIST: fire; [FIXED]" },
		{ type = "effect", sName = "RESIST: lightning; [FIXED]" },
		{ type = "effect", sName = "RESIST: necrotic; [FIXED]" },
		{ type = "effect", sName = "RESIST: poison; [FIXED]" },
		{ type = "effect", sName = "RESIST: psychic; [FIXED]" },
		{ type = "effect", sName = "RESIST: radiant; [FIXED]" },
		{ type = "effect", sName = "RESIST: thunder; [FIXED]" },
		{ type = "effect", sName = "VULN: acid; [FIXED]" },
		{ type = "effect", sName = "VULN: cold; [FIXED]" },
		{ type = "effect", sName = "VULN: fire; [FIXED]" },
		{ type = "effect", sName = "VULN: lightning; [FIXED]" },
		{ type = "effect", sName = "VULN: necrotic; [FIXED]" },
		{ type = "effect", sName = "VULN: poison; [FIXED]" },
		{ type = "effect", sName = "VULN: psychic; [FIXED]" },
		{ type = "effect", sName = "VULN: radiant; [FIXED]" },
		{ type = "effect", sName = "VULN: thunder; [FIXED]" },
		{ type = "effect", sName = "Frightened; [FIXED]" },
		{ type = "effect", sName = "NOTE: Silenced; [FIXED]" },
		{ type = "effect", sName = "NOTE: Tongues; [FIXED]" },
	},
	["haste"] = {
		{ type = "effect", sName = "NOTE: Hasted; AC: 2; ADVSAV: dexterity; (C)", nDuration = 1, sUnits = "minute" },
	},
	["heroes' feast"] = {
		{ type = "effect", sName = "IMMUNE: poison,poisoned,frightened; ADVSAV: wisdom", nDuration = 1, sUnits = "day" },
		{ type = "heal", subtype = "temp", clauses = { { dice = { "d10", "d10" } } } },
	},
	["holy aura"] = {
		{ type = "effect", sName = "ADVSAV; GRANTDISATK; NOTE: Extra effect on fiend/undead melee attack; (C)", nDuration = 1, sUnits = "minute" },
	},
	["insect plague"] = {
		{ type = "save", save = "constitution", onmissdamage = "half" },
		{ type = "damage", clauses = { { dice = { "d10", "d10", "d10", "d10" }, type = "piercing,magic" } } },
	},
	["mage armor"] = {
		{ type = "effect", sName = "AC: 3", nDuration = 8, sUnits = "hour" },
	},
	["magic circle"] = {
		{ type = "save", save = "charisma" },
		{ type = "effect", sName = "IFT: (aberration, celestial, elemental, fey, fiend, undead); GRANTDISATK; IMMUNE: charmed,frightened,possessed; [FIXED]", nDuration = 1, sUnits = "hour" },
	},
	["magic weapon"] = {
		{ type = "effect", sName = "ATK: 1; DMG: 1; DMGTYPE: magic; (C)", nDuration = 1, sUnits = "hour" },
	},
	["protection from energy"] = {
		{ type = "effect", sName = "RESIST: acid; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "RESIST: cold; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "RESIST: fire; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "RESIST: lightning; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "RESIST: thunder; (C)", nDuration = 1, sUnits = "hour" },
	},
	["protection from evil and good"] = {
		{ type = "effect", sName = "IFT: (aberration, celestial, elemental, fey, fiend, undead); GRANTDISATK; IMMUNE: charmed,frightened,possessed; (C)", nDuration = 10, sUnits = "minute" },
	},
	["protection from poison"] = {
		{ type = "effect", sName = "ADVSAV: poisoned; RESIST: poison", nDuration = 1, sUnits = "hour" },
	},
	["ray of enfeeblement"] = {
		{ type = "attack", range = "R" },
		{ type = "effect", sName = "NOTE: Deals half damage with Strength attacks; NOTE: Save on end of round; (C)", nDuration = 1, sUnits = "minute" },
	},
	["sanctuary"] = {
		{ type = "effect", sName = "NOTE: Sanctuary", nDuration = 1, sUnits = "minute" },
	},
	["shield"] = {
		{ type = "effect", sName = "AC: 5", sTargeting = "self", nDuration = 1 },
	},
	["shield of faith"] = {
		{ type = "effect", sName = "AC: 2; (C)", nDuration = 10, sUnits = "minute" },
	},
	["slow"] = {
		{ type = "save", save = "wisdom" },
		{ type = "effect", sName = "NOTE: Slowed; AC: -2; DISSAV: dexterity; NOTE: Save on end of round; (C)", nDuration = 1, sUnits = "minute" },
	},
	["symbol"] = {
		{ type = "save", save = "constitution", onmissdamage = "half" },
		{ type = "damage", clauses = { { dice = { "d10", "d10", "d10", "d10", "d10", "d10", "d10", "d10", "d10", "d10" }, type = "necrotic" } } },
		{ type = "effect", sName = "NOTE: Symbol of Discord", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "NOTE: Symbol of FEar; Frightened", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "NOTE: Symbol of Hopelessness", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "NOTE: Symbol of Insanity", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "NOTE: Symbol of Pain; Incapacitated", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "NOTE: Symbol of Sleep; Unconscious", nDuration = 10, sUnits = "minute" },
		{ type = "effect", sName = "NOTE: Symbol of Stunning; Stunned", nDuration = 1, sUnits = "minute" },
	},
	["tasha's hideous laughter"] = {
		{ type = "save", save = "wisdom" },
		{ type = "effect", sName = "Prone; Incapacitated; NOTE: Unable to stand up; NOTE: Save on end of round and damage; (C)", nDuration = 1, sUnits = "minute" },
	},
	["true strike"] = {
		{ type = "effect", sName = "[TRGT]; ADVATK; (C)", sTargeting = "self", nDuration = 2, sApply = "roll" },
	},
	["warding bond"] = {
		{ type = "effect", sName = "AC: 1; SAVE: 1; RESIST: all", nDuration = 1, sUnits = "hour" },
	},
};