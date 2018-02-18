-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local rsname = "AD&D Core";
local rsmajorversion = 23;

function onInit()
	if User.isHost() or User.isLocal() then
		updateCampaign();
	end

	DB.onAuxCharLoad = onCharImport;
	DB.onImport = onImport;
	Module.onModuleLoad = onModuleLoad;
end

function onCharImport(nodePC)
	local _, _, aMajor, _ = DB.getImportRulesetVersion();
	updateChar(nodePC, aMajor[rsname]);
end

function onImport(node)
	local aPath = StringManager.split(node.getNodeName(), ".");
	if #aPath == 2 and aPath[1] == "charsheet" then
		local _, _, aMajor, _ = DB.getImportRulesetVersion();
		updateChar(node, aMajor[rsname]);
	end
end

function onModuleLoad(sModule)
	local _, _, aMajor, _ = DB.getRulesetVersion(sModule);
	updateModule(sModule, aMajor[rsname]);
end

function updateChar(nodePC, nVersion)
	if not nVersion then
		nVersion = 0;
	end
	
	if nVersion < rsmajorversion then
		if nVersion < 2 then
			migrateChar2(nodePC);
		end
		if nVersion < 5 then
			migrateChar5(nodePC);
		end
		if nVersion < 7 then
			migrateChar7(nodePC);
		end
	end
end

function updateCampaign()
	local _, _, aMajor, aMinor = DB.getRulesetVersion();
	local major = aMajor[rsname];
	if not major then
		return;
	end
	
	if major > 0 and major < rsmajorversion then
		print("Migrating campaign database to latest data version.");
		DB.backup();
		
		if major < 2 then
			convertCharacters2();
		end
		if major < 4 then
			convertPSEnc4();
		end
		if major < 5 then
			convertCharacters5();
		end
		if major < 6 then
			convertEncounters6();
		end
		if major < 7 then
			convertCharacters7();
		end
        -- migrate spell data 
		if major < 8 then
            --Debug.console("manager_version2.lua","updateCampaign","major",major);
            convertSpellsInitiative();
		end
        -- -- migrate item data 
		-- if major < 10 then
            -- convertItemsType();
		-- end
        -- -- migrate spell data 
		-- if major < 11 then
            -- convertSpellType();
		-- end
        -- -- migrate item data 
		-- if major < 12 then
            -- convertItemsType();
		-- end
		if major < 14 then
           updateNPCs();
		end
		if major < 16 then
           updateNPCs16();
		end
		if major < 18 then
           updateNPCs18();
		end
		if major < 21 then
      updateNPCs21();
		end
		if major < 22 then
      updateNPCs21();
		end
		if major < 23 then
      updateNPCs23();
		end
	end
--Debug.console("manager_version2.lua","updateCampaign","major",major);
end

function updateModule(sModule, nVersion)
	if not nVersion then
		nVersion = 0;
	end
	
	if nVersion < rsmajorversion then
		local nodeRoot = DB.getRoot(sModule);
		
		if nVersion < 5 then
			convertPregenCharacters5(nodeRoot);
		end
		if nVersion < 6 then
			if sModule == "DD MM Monster Manual" then
				Module.revert(sModule);
			end
		end
		if nVersion < 7 then
			convertPregenCharacters7(nodeRoot);
		end
	end
end

function migrateEncounter6(nodeRecord)
	for _,nodeNPC in pairs(DB.getChildren(nodeRecord, "npclist")) do
		local sClass, sRecord = DB.getValue(nodeNPC, "link", "", "");
		local sBadNPCID = sRecord:match ("npc%.(.*)@DD MM Monster Manual");
		if sBadNPCID then
			DB.setValue(nodeNPC, "link", "windowreference", sClass, "reference.npcdata." .. sBadNPCID .. "@DD MM Monster Manual");
		end
	end
end

function convertEncounters6()
	for _,nodeEnc in pairs(DB.getChildren("battle")) do
		migrateEncounter6(nodeEnc);
	end
end

function migrateChar5(nodeChar)
	-- Feature list can either be set up by source and level or by link, depending usually on whether they are pregens
	local aSpellCastFeatureBySource = {};
	local aSpellCastFeatureByPath = {};
	for _,nodeFeature in pairs(DB.getChildren(nodeChar, "featurelist")) do
		local sFeature = DB.getValue(nodeFeature, "name", "");
		if sFeature:lower():sub(1, 12) == "spellcasting" then
			local sSource = DB.getValue(nodeFeature, "source", "");
			if sSource ~= "" then
				aSpellCastFeatureBySource[sSource] = DB.getValue(nodeFeature, "level", 1);
			else
				local sPath;
				_, sPath = DB.getValue(nodeFeature, "link", "", "");
				local sPathSansModule = StringManager.split(sPath, "@")[1];
				if sPathSansModule then
					local aSplit = StringManager.split(sPathSansModule, ".");
					if #aSplit == 5 then
						aSpellCastFeatureByPath[aSplit[1] .. "." .. aSplit[2] .. "." .. aSplit[3]] = tonumber(aSplit[5]:match("%d$")) or 1;
					end
				end
			end
		end
	end
	
	-- If spellcasting feature added with source and level, then match the class name
	for kClass, vSpellCastMult in pairs(aSpellCastFeatureBySource) do
		for _,nodeClass in pairs(DB.getChildren(nodeChar, "classes")) do
			local sName = DB.getValue(nodeClass, "name", "");
			if kClass == sName then
				DB.setValue(nodeClass, "casterlevelinvmult", "number", vSpellCastMult);
			end
		end
	end

	-- If spellcasting feature added without source and level, then use link to match
	for kClassPath, vSpellCastMult in pairs(aSpellCastFeatureByPath) do
		for _,nodeClass in pairs(DB.getChildren(nodeChar, "classes")) do
			local sPath;
			_, sPath = DB.getValue(nodeClass, "shortcut", "", "");
			local sPathSansModule = StringManager.split(sPath, "@")[1];
			if sPathSansModule == kClassPath then
				DB.setValue(nodeClass, "casterlevelinvmult", "number", vSpellCastMult);
			end
		end
	end
end

function migrateChar7(nodeChar)
	-- Migrate warlock spell slots from standard spell slots
	-- NOTE: Don't do anything if multiclass with both pact magic and spellcasting
	local bPactMagicOnly = false;
	for _,nodeClass in pairs(DB.getChildren(nodeChar, "classes")) do
		local nCastLevelInvMult = DB.getValue(nodeClass, "casterlevelinvmult", 0);
		if nCastLevelInvMult > 0 then
			local nPactMagic = DB.getValue(nodeClass, "casterpactmagic", 0);
			if nPactMagic == 1 then
				bPactMagicOnly = true;
			else
				bPactMagicOnly = false;
				break;
			end
		end
	end
	if bPactMagicOnly then
		for i = 1, PowerManager.SPELL_LEVELS do
			local nSlotsMax = DB.getValue(nodeChar, "powermeta.spellslots" .. i .. ".max", 0);
			local nSlotsUsed = DB.getValue(nodeChar, "powermeta.spellslots" .. i .. ".used", 0);
			DB.setValue(nodeChar, "powermeta.pactmagicslots" .. i .. ".max", "number", nSlotsMax);
			DB.setValue(nodeChar, "powermeta.pactmagicslots" .. i .. ".used", "number", nSlotsUsed);
			DB.setValue(nodeChar, "powermeta.spellslots" .. i .. ".max", "number", 0);
			DB.setValue(nodeChar, "powermeta.spellslots" .. i .. ".used", "number", 0);
		end
	end
end

function convertPregenCharacters5(nodeRoot)
	for _,nodeChar in pairs(DB.getChildren(nodeRoot, "pregencharsheet")) do
		migrateChar5(nodeChar);
	end
end

function convertPregenCharacters7(nodeRoot)
	for _,nodeChar in pairs(DB.getChildren(nodeRoot, "pregencharsheet")) do
		migrateChar7(nodeChar);
	end
end

function convertCharacters5()
	for _,nodeChar in pairs(DB.getChildren("charsheet")) do
		migrateChar5(nodeChar);
	end
end

function convertCharacters7()
	for _,nodeChar in pairs(DB.getChildren("charsheet")) do
		migrateChar7(nodeChar);
	end
end

function convertPSEnc4()
	for _,vEnc in pairs(DB.getChildren("partysheet.encounters")) do
		DB.setValue(vEnc, "exp", "number", DB.getValue(vEnc, "xp", "number"));
	end
end

function migrateChar2(nodeChar)
	for _,nodeAbility in pairs(DB.getChildren(nodeChar, "abilitylist")) do
		local nodeFeatureList = nodeChar.createChild("featurelist");
		local nodeNewFeature = nodeFeatureList.createChild();
		DB.copyNode(nodeAbility, nodeNewFeature);
	end
	DB.deleteChild(nodeChar, "abilitylist");
	
	for _,nodeWeapon in pairs(DB.getChildren(nodeChar, "weaponlist")) do
		if not DB.getChild(nodeWeapon, "damagelist") then
			local nodeDmgList = DB.createChild(nodeWeapon, "damagelist");
			if nodeDmgList then
				local nodeDmg = DB.createChild(nodeDmgList);
				if nodeDmg then
					DB.setValue(nodeDmg, "dice", "dice", DB.getValue(nodeWeapon, "damagedice", {}));
					DB.setValue(nodeDmg, "stat", "string", DB.getValue(nodeWeapon, "damagestat", ""));
					DB.setValue(nodeDmg, "bonus", "number", DB.getValue(nodeWeapon, "damagebonus", 0));
					DB.setValue(nodeDmg, "type", "string", DB.getValue(nodeWeapon, "damagetype", ""));
					
					DB.deleteChild(nodeWeapon, "damagedice");
					DB.deleteChild(nodeWeapon, "damagestat");
					DB.deleteChild(nodeWeapon, "damagebonus");
					DB.deleteChild(nodeWeapon, "damagetype");
				end
			end
		end
	end
	
	for _,nodePower in pairs(DB.getChildren(nodeChar, "powers")) do
		for _,nodeAction in pairs(DB.getChildren(nodePower, "actions")) do
			local sType = DB.getValue(nodeAction, "type", "");
			if sType == "damage" then
				if not DB.getChild(nodeAction, "damagelist") then
					local nodeDmgList = DB.createChild(nodeAction, "damagelist");
					if nodeDmgList then
						local nodeDmg = DB.createChild(nodeDmgList);
						if nodeDmg then
							local sDmgType = DB.getValue(nodeAction, "dmgtype", "");
							
							DB.setValue(nodeDmg, "dice", "dice", DB.getValue(nodeAction, "dmgdice", {}));
							DB.setValue(nodeDmg, "stat", "string", DB.getValue(nodeAction, "dmgstat", ""));
							DB.setValue(nodeDmg, "bonus", "number", DB.getValue(nodeAction, "dmgmod", 0));
							DB.setValue(nodeDmg, "type", "string", sDmgType);
							
							local sDmgStat2 = DB.getValue(nodeAction, "dmgstat2", "");
							if sDmgStat2 ~= "" then
								local nodeDmg2 = DB.createChild(nodeDmgList);
								DB.setValue(nodeDmg2, "stat", "string", sDmgStat2);
								DB.setValue(nodeDmg2, "type", "string", sDmgType);
							end
							
							DB.deleteChild(nodeAction, "dmgdice");
							DB.deleteChild(nodeAction, "dmgstat");
							DB.deleteChild(nodeAction, "dmgstat2");
							DB.deleteChild(nodeAction, "dmgmod");
							DB.deleteChild(nodeAction, "dmgtype");
						end
					end
				end
			elseif sType == "heal" then
				if not DB.getChild(nodeAction, "heallist") then
					local nodeDmgList = DB.createChild(nodeAction, "heallist");
					if nodeDmgList then
						local nodeHeal = DB.createChild(nodeDmgList);
						if nodeHeal then
							DB.setValue(nodeHeal, "dice", "dice", DB.getValue(nodeAction, "hdice", {}));
							DB.setValue(nodeHeal, "stat", "string", DB.getValue(nodeAction, "hstat", ""));
							DB.setValue(nodeHeal, "bonus", "number", DB.getValue(nodeAction, "hmod", 0));
							
							local sStat2 = DB.getValue(nodeAction, "hstat2", "");
							if sStat2 ~= "" then
								local nodeHeal2 = DB.createChild(nodeDmgList);
								DB.setValue(nodeHeal2, "stat", "string", sStat2);
							end
							
							DB.deleteChild(nodeAction, "hdice");
							DB.deleteChild(nodeAction, "hstat");
							DB.deleteChild(nodeAction, "hstat2");
							DB.deleteChild(nodeAction, "hmod");
						end
					end
				end
			end
		end
	end
end

function convertCharacters2()
	for _,nodeChar in pairs(DB.getChildren("charsheet")) do
		migrateChar2(nodeChar);
	end
end


-- move initiative from spell->action->cast to spell --celestian
function convertSpellsInitiative()
    -- fix all spell records
	for _,nodeSpell in pairs(DB.getChildren("spell")) do
        for _,nodeAction in pairs(DB.getChildren(nodeSpell, "actions")) do
            migrateSpellInitiative(nodeSpell,nodeAction);
        end
	end
    -- fix all combat tracker records
	for _,nodeCharacters in pairs(DB.getChildren("combattracker.list")) do
        for _,nodePowers in pairs(DB.getChildren(nodeCharacters, "powers")) do
            for _,nodeAction in pairs(DB.getChildren(nodePowers, "actions")) do
                migrateSpellInitiative(nodePowers,nodeAction);
            end
        end
	end
    -- fix all npc records
	for _,nodeCharacters in pairs(DB.getChildren("npc")) do
        for _,nodePowers in pairs(DB.getChildren(nodeCharacters, "powers")) do
            for _,nodeAction in pairs(DB.getChildren(nodePowers, "actions")) do
                migrateSpellInitiative(nodePowers,nodeAction);
            end
        end
	end
    -- fix all pc records
	for _,nodeCharacters in pairs(DB.getChildren("charsheet")) do
        for _,nodePowers in pairs(DB.getChildren(nodeCharacters, "powers")) do
            for _,nodeAction in pairs(DB.getChildren(nodePowers, "actions")) do
                migrateSpellInitiative(nodePowers,nodeAction);
            end
        end
	end
    
end
-- tweak actions/spell
function migrateSpellInitiative(nodeSpell,nodeAction)
    local sName =  DB.getValue(nodeSpell,"name","");
    local sType =  DB.getValue(nodeAction,"type","");
    local nOrder = DB.getValue(nodeAction,"order",0);
    local nInit =  DB.getValue(nodeAction,"castinitiative",0);
-- Debug.console("manager_version2.lua","migrateSpellInitiative","nodeSpell",nodeSpell);        
-- Debug.console("manager_version2.lua","migrateSpellInitiative","nodeAction",nodeAction);        
-- Debug.console("manager_version2.lua","migrateSpellInitiative","sName",sName);        
-- Debug.console("manager_version2.lua","migrateSpellInitiative","sType",sType);        
-- Debug.console("manager_version2.lua","migrateSpellInitiative","nOrder",nOrder);        
-- Debug.console("manager_version2.lua","migrateSpellInitiative","nInit",nInit);        
    if (sType == "cast") then
        DB.deleteChild(nodeAction, "castinitiative");
        if (nInit ~= 0) then
            DB.setValue(nodeSpell,"castinitiative","number",nInit);
        end
        -- Move memorizedcount also?
        local nMemCount = DB.getValue(nodeAction,"memorizedcount",0);
        DB.deleteChild(nodeAction, "memorizedcount");
        if (nMemCount > 0) then
            DB.setValue(nodeSpell,"memorizedcount","number",nMemCount);                
        end
    end
end

-- not needed in the end --celestian
-- -- convert type to weapon_type on items
-- function convertItemsType()
    -- -- -- fix all item records
	-- -- for _,nodeItem in pairs(DB.getChildren("item")) do
        -- -- local sType =  DB.getValue(nodeItem,"type","");
        -- -- DB.setValue(nodeItem,"weapon_type","string",sType);
        -- -- DB.deleteChild(nodeItem, "type");
	-- -- end
-- end

-- -- convert type to spell_type on spells
-- function convertSpellType()
    -- -- -- fix all item records
	-- -- for _,nodeSpell in pairs(DB.getChildren("spell")) do
        -- -- local sType =  DB.getValue(nodeSpell,"type","");
        -- -- DB.setValue(nodeSpell,"type","string",sType);
        -- -- DB.deleteChild(nodeSpell, "type");
	-- -- end
-- end

-- -- convert type to weapon_type on items
-- function convertItemsType()
    -- -- -- fix all item records
	-- -- for _,nodeItem in pairs(DB.getChildren("item")) do
        -- -- local sType =  DB.getValue(nodeItem,"weapon_type","");
        -- -- DB.setValue(nodeItem,"type","string",sType);
        -- -- DB.deleteChild(nodeItem, "weapon_type");
	-- -- end
-- end

-- update NPCs to have saves based on HD and set default ability scores.
function updateNPCs()
	-- for _,nodeNPC in pairs(DB.getChildren("npc")) do
        -- -- set default saves for HDice.
-- --Debug.console("manager_version2.lua","updateNPCs","nodeNPC",nodeNPC);
        -- if (DB.getValue(nodeNPC, "saves.poison.score",0) == 0) then
            -- CombatManager2.updateNPCSaves(nodeNPC, nodeNPC, true);
        -- end
        
        -- if DB.getChildCount(nodeNPC, "abilities") < 6 then
-- --Debug.console("manager_version2.lua","updateNPCs","nodeNPC Add abilities",nodeNPC);
            -- local nodeAbilites = nodeNPC.createChild("abilities");
            -- for _,sAbility in pairs(DataCommon.abilities) do
                -- local nodeAbility = nodeAbilites.createChild(sAbility);
                -- DB.setValue(nodeAbility,"score","number",10);
            -- end
        -- end
        -- AbilityScoreADND.updateStrength(nodeNPC,DB.getValue(nodeNPC,"strength",10));
        -- AbilityScoreADND.updateDexterity(nodeNPC,DB.getValue(nodeNPC,"dexterity",10));
        -- AbilityScoreADND.updateWisdom(nodeNPC,DB.getValue(nodeNPC,"wisdom",10));
        -- AbilityScoreADND.updateConstitution(nodeNPC,DB.getValue(nodeNPC,"constitution",10));
        -- AbilityScoreADND.updateCharisma(nodeNPC,DB.getValue(nodeNPC,"charisma",10));
        -- AbilityScoreADND.updateIntelligence(nodeNPC,DB.getValue(nodeNPC,"intelligence",10));

	-- end
end

function updateNPCs16()
    -- fix all combat tracker records
	for _,nodeNPC in pairs(DB.getChildren("combattracker.list")) do
        local sClass, sRecord = DB.getValue(nodeNPC, "link", "", "");
        if (sClass == "npc") then
            fixNPCAbilities(nodeNPC);
            fixNPCSaves(nodeNPC);
        end
	end
    -- fix all npc records
	for _,nodeNPC in pairs(DB.getChildren("npc")) do
            fixNPCAbilities(nodeNPC);
            fixNPCSaves(nodeNPC);
	end
end

function updateNPCs18()
    -- fix all combat tracker records
	for _,nodeNPC in pairs(DB.getChildren("combattracker.list")) do
        local sClass, sRecord = DB.getValue(nodeNPC, "link", "", "");
        if (sClass == "npc") then
            fixNPCAbilities(nodeNPC);
        end
	end
    -- fix all npc records
	for _,nodeNPC in pairs(DB.getChildren("npc")) do
        fixNPCAbilities(nodeNPC);
	end
end

function fixNPCAbilities(nodeNPC)    
    if DB.getChildCount(nodeNPC, "abilities") < 6 then
--Debug.console("manager_version2.lua","updateNPCs","nodeNPC Add abilities",nodeNPC);
        local nodeAbilites = nodeNPC.createChild("abilities");
        for _,sAbility in pairs(DataCommon.abilities) do
            local nodeAbility = nodeAbilites.createChild(sAbility);
            DB.setValue(nodeAbility,"score","number",10);
            DB.setValue(nodeAbility,"base","number",10);
            DB.setValue(nodeAbility,"total","number",10);
        end
    end
    DB.setValue(nodeNPC,"abilities.strength.base","number",DB.getValue(nodeNPC,"abilities.strength.base",10));
    DB.setValue(nodeNPC,"abilities.dexterity.base","number",DB.getValue(nodeNPC,"abilities.dexterity.base",10));
    DB.setValue(nodeNPC,"abilities.wisdom.base","number",DB.getValue(nodeNPC,"abilities.wisdom.base",10));
    DB.setValue(nodeNPC,"abilities.constitution.base","number",DB.getValue(nodeNPC,"abilities.constitution.base",10));
    DB.setValue(nodeNPC,"abilities.charisma.base","number",DB.getValue(nodeNPC,"abilities.charisma.base",10));
    DB.setValue(nodeNPC,"abilities.intelligence.base","number",DB.getValue(nodeNPC,"abilities.intelligence.base",10));

    DB.setValue(nodeNPC,"abilities.strength.total","number",DB.getValue(nodeNPC,"abilities.strength.total",10));
    DB.setValue(nodeNPC,"abilities.dexterity.total","number",DB.getValue(nodeNPC,"abilities.dexterity.total",10));
    DB.setValue(nodeNPC,"abilities.wisdom.total","number",DB.getValue(nodeNPC,"abilities.wisdom.total",10));
    DB.setValue(nodeNPC,"abilities.constitution.total","number",DB.getValue(nodeNPC,"abilities.constitution.total",10));
    DB.setValue(nodeNPC,"abilities.charisma.total","number",DB.getValue(nodeNPC,"abilities.charisma.total",10));
    DB.setValue(nodeNPC,"abilities.intelligence.total","number",DB.getValue(nodeNPC,"abilities.intelligence.total",10));
    AbilityScoreADND.updateStrength(nodeNPC);
    AbilityScoreADND.updateDexterity(nodeNPC);
    AbilityScoreADND.updateWisdom(nodeNPC);
    AbilityScoreADND.updateConstitution(nodeNPC);
    AbilityScoreADND.updateCharisma(nodeNPC);
    AbilityScoreADND.updateIntelligence(nodeNPC);
end

function fixNPCSaves(nodeNPC)    
    -- set default saves for HDice.
--Debug.console("manager_version2.lua","updateNPCs","nodeNPC",nodeNPC);
    if (DB.getValue(nodeNPC, "saves.poison.score",0) == 0) then
        CombatManager2.updateNPCSaves(nodeNPC, nodeNPC, true);
    end
end

-- fix npc levels
function updateNPCs21()
    -- fix all combat tracker records
	for _,nodeNPC in pairs(DB.getChildren("combattracker.list")) do
        local sClass, sRecord = DB.getValue(nodeNPC, "link", "", "");
        if (sClass == "npc") then
          CombatManager2.updateNPCLevels(nodeNPC, true);
        end
	end
    -- fix all npc records
	for _,nodeNPC in pairs(DB.getChildren("npc")) do
  --Debug.console("manager_version2.lua","updateNPCs19","nodeNPC",nodeNPC);
    CombatManager2.updateNPCLevels(nodeNPC, true);
	end
end

-- fix npcs... again
function updateNPCs23()
    -- fix all combat tracker records
	for _,nodeNPC in pairs(DB.getChildren("combattracker.list")) do
        local sClass, sRecord = DB.getValue(nodeNPC, "link", "", "");
        if (sClass == "npc") then
          fixNPCAbilities23(nodeNPC);
          CombatManager2.updateNPCSaves(nodeNPC, nodeNPC, true);
        end
	end
    -- fix all npc records
	for _,nodeNPC in pairs(DB.getChildren("npc")) do
    fixNPCAbilities23(nodeNPC);
    CombatManager2.updateNPCSaves(nodeNPC, nodeNPC, true);
	end
end

function fixNPCAbilities23(nodeNPC)    
    if DB.getChildCount(nodeNPC, "abilities") < 6 then
--Debug.console("manager_version2.lua","updateNPCs","nodeNPC Add abilities",nodeNPC);
        local nodeAbilites = nodeNPC.createChild("abilities");
        for _,sAbility in pairs(DataCommon.abilities) do
            local nodeAbility = nodeAbilites.createChild(sAbility);
            DB.setValue(nodeAbility,"score","number",10);
            DB.setValue(nodeAbility,"base","number",10);
            DB.setValue(nodeAbility,"total","number",10);
        end
    end
    
    DB.setValue(nodeNPC,"abilities.strength.base","number",DB.getValue(nodeNPC,"abilities.strength.base",10));
    DB.setValue(nodeNPC,"abilities.dexterity.base","number",DB.getValue(nodeNPC,"abilities.dexterity.base",10));
    DB.setValue(nodeNPC,"abilities.wisdom.base","number",DB.getValue(nodeNPC,"abilities.wisdom.base",10));
    DB.setValue(nodeNPC,"abilities.constitution.base","number",DB.getValue(nodeNPC,"abilities.constitution.base",10));
    DB.setValue(nodeNPC,"abilities.charisma.base","number",DB.getValue(nodeNPC,"abilities.charisma.base",10));
    DB.setValue(nodeNPC,"abilities.intelligence.base","number",DB.getValue(nodeNPC,"abilities.intelligence.base",10));
    DB.setValue(nodeNPC,"abilities.strength.total","number",DB.getValue(nodeNPC,"abilities.strength.total",10));
    DB.setValue(nodeNPC,"abilities.dexterity.total","number",DB.getValue(nodeNPC,"abilities.dexterity.total",10));
    DB.setValue(nodeNPC,"abilities.wisdom.total","number",DB.getValue(nodeNPC,"abilities.wisdom.total",10));
    DB.setValue(nodeNPC,"abilities.constitution.total","number",DB.getValue(nodeNPC,"abilities.constitution.total",10));
    DB.setValue(nodeNPC,"abilities.charisma.total","number",DB.getValue(nodeNPC,"abilities.charisma.total",10));
    DB.setValue(nodeNPC,"abilities.intelligence.total","number",DB.getValue(nodeNPC,"abilities.intelligence.total",10));
    AbilityScoreADND.updateStrength(nodeNPC);
    AbilityScoreADND.updateDexterity(nodeNPC);
    AbilityScoreADND.updateWisdom(nodeNPC);
    AbilityScoreADND.updateConstitution(nodeNPC);
    AbilityScoreADND.updateCharisma(nodeNPC);
    AbilityScoreADND.updateIntelligence(nodeNPC);
end
