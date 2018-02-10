
--
-- Effects on Items, apply to character in CT
--
--
function onInit()
    --CoreRPG replacements
    ActionsManager.decodeActors = decodeActors;

    -- AD&D Core ONLY!!! (need this because we use high to low initiative, not low to high
    EffectManager.setInitAscending(true);
    -- THIS DOESNT WORK, had to just include/replace the entire CoreRPG manager_effect.lua
    --EffectManager.onInit = manager_effect_onInit;
    --EffectManager.processEffects = manager_effect_processEffects;
    --CombatManager.setCustomInitChange(manager_effect_processEffects);
    -- end doesn't work

    -- used for AD&D Core ONLY
    EffectManager5E.evalAbilityHelper = evalAbilityHelper;
    EffectManager5E.checkConditional = checkConditional; -- this is for ARMOR() effect type
    
    -- 5E effects replacements
    EffectManager5E.checkConditionalHelper = checkConditionalHelper;
    EffectManager5E.getEffectsByType = getEffectsByType;
    EffectManager5E.hasEffect = hasEffect;
    
    -- used for 5E extension ONLY
    --ActionAttack.performRoll = manager_action_attack_performRoll;
    --ActionDamage.performRoll = manager_action_damage_performRoll;
    --PowerManager.performAction = manager_power_performAction;
    
    -- option in house rule section, enable/disable allow PCs to edit advanced effects.
	OptionsManager.registerOption2("ADND_AE_EDIT", false, "option_header_houserule", "option_label_ADND_AE_EDIT", "option_entry_cycler", 
			{ labels = "option_label_ADND_AE_enabled" , values = "enabled", baselabel = "option_label_ADND_AE_disabled", baseval = "disabled", default = "disabled" });    
end

-- add the effect if the item is equipped and doesn't exist already
function updateItemEffects(nodeItem)
--Debug.console("manager_effect_adnd.lua","updateItemEffects1","nodeItem",nodeItem);
--Debug.console("manager_effect_adnd.lua","updateItemEffects","User.isHost()",User.isHost());
    local nodeChar = DB.getChild(nodeItem, "...");
    if not nodeChar then
        return;
    end
    local sUser = User.getUsername();
    local sName = DB.getValue(nodeItem, "name", "");
    -- we swap the node to the combat tracker node
    -- so the "effect" is written to the right node
    if not string.match(nodeChar.getPath(),"^combattracker") then
        nodeChar = CharManager.getCTNodeByNodeChar(nodeChar);
    end
--Debug.console("manager_effect_adnd.lua","updateItemEffects","nodeChar3",nodeChar);
    -- if not in the combat tracker bail
    if not nodeChar then
        return;
    end
    
    local nCarried = DB.getValue(nodeItem, "carried", 0);
    local bEquipped = (nCarried == 2);
    local nIdentified = DB.getValue(nodeItem, "isidentified", 0);
    local bOptionID = OptionsManager.isOption("MIID", "on");
    if not bOptionID then 
        nIdentified = 1;
    end
-- Debug.console("manager_effect_adnd.lua","updateItemEffects","sUser",sUser);
-- Debug.console("manager_effect_adnd.lua","updateItemEffects","nodeChar",nodeChar);
-- Debug.console("manager_effect_adnd.lua","updateItemEffects","nodeItem",nodeItem);
-- Debug.console("manager_effect_adnd.lua","updateItemEffects","nCarried",nCarried);
-- Debug.console("manager_effect_adnd.lua","updateItemEffects","bEquipped",bEquipped);
-- Debug.console("manager_effect_adnd.lua","updateItemEffects","nIdentified",nIdentified);

    for _,nodeItemEffect in pairs(DB.getChildren(nodeItem, "effectlist")) do
        updateItemEffect(nodeItem,nodeItemEffect, sName, nodeChar, sUser, bEquipped, nIdentified);
    end -- for item's effects list
end

-- update single effect for item
function updateItemEffect(nodeItem,nodeItemEffect, sName, nodeChar, sUser, bEquipped, nIdentified)
--Debug.console("manager_effect_adnd.lua","updateItemEffect","User.isHost()",User.isHost());
    local sCharacterName = DB.getValue(nodeChar, "name", "");
    local sItemSource = nodeItemEffect.getPath();
--Debug.console("manager_effect_adnd.lua","updateItemEffect","sItemSource",sItemSource);
--Debug.console("manager_effect_adnd.lua","updateItemEffect","itemNode?",nodeItemEffect.getChild("..."));
    -- local bActionOnly = (DB.getValue(nodeItemEffect, "actiononly", 0) ~= 0);
    -- local sActionSource = "";
    -- if (bActionOnly) then
        -- sActionSource =  nodeItem.getPath();
    -- end
    local sLabel = DB.getValue(nodeItemEffect, "effect", "");
-- Debug.console("manager_effect_adnd.lua","updateItemEffect","sName",sName);
-- Debug.console("manager_effect_adnd.lua","updateItemEffect","sLabel",sLabel);
--Debug.console("manager_effect_adnd.lua","updateItemEffect","sItemSource",sItemSource);
    if sLabel and sLabel ~= "" then -- if we have effect string
        local bFound = false;
        for _,nodeEffect in pairs(DB.getChildren(nodeChar, "effects")) do
            local nActive = DB.getValue(nodeEffect, "isactive", 0);
            local nDMOnly = DB.getValue(nodeEffect, "isgmonly", 0);
--Debug.console("manager_effect_adnd.lua","updateItemEffect","nActive",nActive);
            if (nActive ~= 0) then
                local sEffSource = DB.getValue(nodeEffect, "source_name", "");
--Debug.console("manager_effect_adnd.lua","updateItemEffect","sEffSource",sEffSource);
                if (sEffSource == sItemSource) then
                    bFound = true;
--Debug.console("manager_effect_adnd.lua","updateItemEffect","bFound!!!",bFound);
                    if (not bEquipped) then
                        sendEffectRemovedMessage(nodeChar, nodeEffect, sLabel, nDMOnly, sUser)
--Debug.console("manager_effect_adnd.lua","updateItemEffect","!!!bEquipped",bEquipped);
                        nodeEffect.delete();
                        break;
                    end -- not equipped
                end -- effect source == item source
            end -- was active
        end -- nodeEffect for
        
--Debug.console("manager_effect_adnd.lua","updateItemEffect","pre bEquipped",bEquipped);
        if (not bFound and bEquipped) then
--Debug.console("manager_effect_adnd.lua","updateItemEffect","bFound and bEquipped",bEquipped);
--Debug.console("manager_effect_adnd.lua","updateItemEffect","nIdentified",nIdentified);

            local rEffect = {};
            local nRollDuration = 0;
            local dDurationDice = DB.getValue(nodeItemEffect, "durdice");
            local nModDice = DB.getValue(nodeItemEffect, "durmod", 0);
--Debug.console("manager_effect_adnd.lua","updateItemEffect","dDurationDice",dDurationDice);
--Debug.console("manager_effect_adnd.lua","updateItemEffect","nModDice",nModDice);

            if (dDurationDice and dDurationDice ~= "") then
                nRollDuration = StringManager.evalDice(dDurationDice, nModDice);
            else
                nRollDuration = nModDice;
            end
--bug.console("manager_effect_adnd.lua","updateItemEffect","nRollDuration",nRollDuration);
            local nDMOnly = 1;
            local sVisibility = DB.getValue(nodeItemEffect, "visibility", "");
            if sVisibility == "show" then
                nDMOnly = 0;
            elseif sVisibility == "hide" then
                nDMOnly = 1;
            elseif nIdentified > 0 then
                nDMOnly = 0;
            elseif nIdentified == 0 then
                nDMOnly = 1;
            end
            
            rEffect.nDuration = nRollDuration;
            rEffect.sName = sName .. ";" .. sLabel;
            rEffect.sLabel = sLabel; 
            rEffect.sUnits = DB.getValue(nodeItemEffect, "durunit", "");
            rEffect.nInit = 0;
            rEffect.sSource = sItemSource;
            rEffect.nGMOnly = nDMOnly;
            rEffect.sApply = "";
--Debug.console("manager_effect_adnd.lua","updateItemEffect","rEffect",rEffect);
            --EffectManager.addEffect(sUser, "", nodeChar, rEffect, true);
            EffectManager.addEffect("", "", nodeChar, rEffect, false);
            sendEffectAddedMessage(nodeChar, rEffect, sLabel, nDMOnly, sUser)
        end
    end
end

-- flip through all pc/npc effectslist (generally do this in addNPC()/addPC()
-- nodeChar: node of PC/NPC in PC/NPCs record list
-- nodeEntry: node in combat tracker for PC/NPC
function updateCharEffects(nodeChar,nodeEntry)
    for _,nodeCharEffect in pairs(DB.getChildren(nodeChar, "effectlist")) do
        updateCharEffect(nodeCharEffect,nodeEntry);
    end -- for item's effects list 
end
-- apply effect from npc/pc/item to the node
-- nodeCharEffect: node in effectlist on PC/NPC
-- nodeEntry: node in combat tracker for PC/NPC
function updateCharEffect(nodeCharEffect,nodeEntry)
    local sUser = User.getUsername();
    local sName = DB.getValue(nodeEntry, "name", "");
    local sLabel = DB.getValue(nodeCharEffect, "effect", "");
    local bActionOnly = (DB.getValue(nodeCharEffect, "actiononly", 0)==1);
    local nRollDuration = 0;
    local dDurationDice = DB.getValue(nodeCharEffect, "durdice");
    local nModDice = DB.getValue(nodeCharEffect, "durmod", 0);
--Debug.console("manager_effect_adnd.lua","updateCharEffect","dDurationDice",dDurationDice);
--Debug.console("manager_effect_adnd.lua","updateCharEffect","nModDice",nModDice);
    if (dDurationDice and dDurationDice ~= "") then
        nRollDuration = StringManager.evalDice(dDurationDice, nModDice);
    else
        nRollDuration = nModDice;
    end
--Debug.console("manager_effect_adnd.lua","updateCharEffect","nRollDuration",nRollDuration);
    local nDMOnly = 0;
    local sVisibility = DB.getValue(nodeCharEffect, "visibility", "");
    if sVisibility == "show" then
        nDMOnly = 0;
    elseif sVisibility == "hide" then
        nDMOnly = 1;
    end
    local rEffect = {};
    rEffect.nDuration = nRollDuration;
    --rEffect.sName = sName .. ";" .. sLabel;
    rEffect.sName = sLabel;
    rEffect.sLabel = sLabel; 
    rEffect.sUnits = DB.getValue(nodeCharEffect, "durunit", "");
    rEffect.nInit = 0;
    --rEffect.sSource = nodeEntry.getPath();
    rEffect.nGMOnly = nDMOnly;
    rEffect.sApply = "";
    --EffectManager.addEffect("", "", nodeEntry, rEffect, true);
    EffectManager.addEffect("", "", nodeEntry, rEffect, false);
    sendEffectAddedMessage(nodeEntry, rEffect, sLabel, nDMOnly, sUser);
end

-- build message to send that effect removed
function sendEffectRemovedMessage(nodeChar, nodeEffect, sLabel, nDMOnly, sUser)
    local sCharacterName = DB.getValue(nodeChar, "name", "");
	-- Build output message
	local msg = ChatManager.createBaseMessage(ActorManager.getActorFromCT(nodeChar),sUser);
    local msg = {font = "msgfont", icon = "roll_effect"};
    msg.text = "Advanced Effect ['" .. sLabel .. "'] ";
    msg.text = msg.text .. "removed [from " .. sCharacterName .. "]";
    -- HANDLE APPLIED BY SETTING
    local sEffSource = DB.getValue(nodeEffect, "source_name", "");    
    if sEffSource and sEffSource ~= "" then
        msg.text = msg.text .. " [by " .. DB.getValue(DB.findNode(sEffSource), "name", "") .. "]";
    end

    sendRawMessage(nDMOnly,sUser,msg);
end
-- build message to send that effect added
function sendEffectAddedMessage(nodeCT, rNewEffect, sLabel, nDMOnly, sUser)
	-- Build output message
	local msg = ChatManager.createBaseMessage(ActorManager.getActorFromCT(nodeCT),sUser);
	msg.text = "Advanced Effect ['" .. rNewEffect.sName .. "'] ";
	msg.text = msg.text .. "-> [to " .. DB.getValue(nodeCT, "name", "") .. "]";
	if rNewEffect.sSource and rNewEffect.sSource ~= "" then
		msg.text = msg.text .. " [by " .. DB.getValue(DB.findNode(rNewEffect.sSource), "name", "") .. "]";
	end
    sendRawMessage(nDMOnly,sUser,msg);
end
-- send message
function sendRawMessage(nDMOnly,sUser, msg)
-- Debug.console("manager_effect_adnd.lua","sendRawMessage","nDMOnly",nDMOnly);
-- Debug.console("manager_effect_adnd.lua","sendRawMessage","sUser",sUser);
-- Debug.console("manager_effect_adnd.lua","sendRawMessage","msg",msg);
-- Debug.console("manager_effect_adnd.lua","sendRawMessage","User.isHost()",User.isHost());
-- Debug.console("manager_effect_adnd.lua","sendRawMessage","User.getCurrentIdentity()",User.getCurrentIdentity());
-- printstack();
    if nDMOnly == 1 and User.isHost() then
        msg.secret = true;
        Comm.addChatMessage(msg);
    elseif nDMOnly ~= 1 then 
        if sUser ~= "" then
            Comm.addChatMessage(msg);
            --Comm.deliverChatMessage(msg, sUser);
        else
            Comm.deliverChatMessage(msg);
        end
    end
end

-- pass effect to here to see if the effect is being triggered
-- by an item and if so if it's valid
function isValidCheckEffect(rActor,nodeEffect)
    local bResult = false;
    local nActive = DB.getValue(nodeEffect, "isactive", 0);
    local bItem = false;
    local bActionItemUsed = false;
    local bActionOnly = false;
    local nodeItem = nil;

    local sSource = DB.getValue(nodeEffect,"source_name","");
    -- if source is a valid node and we can find "actiononly"
    -- setting then we set it.
    local node = DB.findNode(sSource);
    if (node and node ~= nil) then
        nodeItem = node.getChild("...");
        if nodeItem and nodeItem ~= nil then
            bActionOnly = (DB.getValue(node,"actiononly",0) ~= 0);
        end
    end

    -- if there is a itemPath do some sanity checking
    if (rActor.itemPath and rActor.itemPath ~= "") then 
        -- here is where we get the node path of the item, not the 
        -- effectslist entry
        if ((DB.findNode(rActor.itemPath) ~= nil)) then
            if (node and node ~= nil and nodeItem and nodeItem ) then
                local sNodePath = nodeItem.getPath();
                if bActionOnly and sNodePath ~= "" and (sNodePath == rActor.itemPath) then
                    bActionItemUsed = true;
                    bItem = true;
                else
                    bActionItemUsed = false;
                    bItem = true; -- is item but doesn't match source path for this effect
                end
            end
        end
    end
--Debug.console("manager_effect_adnd.lua","isValidCheckEffect","nActive",nActive);    
--Debug.console("manager_effect_adnd.lua","isValidCheckEffect","bActionOnly",bActionOnly);    
--Debug.console("manager_effect_adnd.lua","isValidCheckEffect","bActionItemUsed",bActionItemUsed);    
    if nActive ~= 0 and bActionOnly and bActionItemUsed then
        bResult = true;
    elseif nActive ~= 0 and not bActionOnly and bActionItemUsed then
        bResult = true;
    elseif nActive ~= 0 and bActionOnly and not bActionItemUsed then
        bResult = false;
    elseif nActive ~= 0 then
        bResult = true;
    end
--Debug.console("manager_effect_adnd.lua","isValidCheckEffect","bResult",bResult);    
	-- if ( nActive ~= 0 and ( not bItem or (bItem and bActionItemUsed) ) ) then
        -- bResult = true;
    -- elseif nActive ~= 0 and bActionOnly and not (bItem or bActionItemUsed) then
        -- bResult = false;
    -- elseif nActive ~= 0 and (not bActionOnly and bItem) then
        -- bResult = true;
    -- end
    return bResult;
end



--
--          REPLACEMENT FUNCTIONS
--



-- CoreRPG EffectManager manager_effect_adnd.lua 
-- AD&D CORE ONLY
local aEffectVarMap = {
	["sName"] = { sDBType = "string", sDBField = "label" },
	["nGMOnly"] = { sDBType = "number", sDBField = "isgmonly" },
	["sSource"] = { sDBType = "string", sDBField = "source_name", bClearOnUntargetedDrop = true },
	["sTarget"] = { sDBType = "string", bClearOnUntargetedDrop = true },
	["nDuration"] = { sDBType = "number", sDBField = "duration", vDBDefault = 1, sDisplay = "[D: %d]" },
	["nInit"] = { sDBType = "number", sDBField = "init", sSourceChangeSet = "initresult", bClearOnUntargetedDrop = true },
};
-- replace CoreRPG EffectManager manager_effect_adnd.lua onInit() with this
-- AD&D CORE ONLY
function manager_effect_onInit()
	--CombatManager.setCustomInitChange(manager_effect_processEffects);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYEFF, handleApplyEffect);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_EXPIREEFF, handleExpireEffect);
end

-- replace CoreRPG EffectManager manager_effect_adnd.lua processEffects() with this
-- AD&D CORE ONLY
-- we use this because we use initiative low to high. Lowest goes first... 
-- because of that we have to manage effects differently 
-- if we do not do this effects with "action" will not expire on that players turn as it should
-- Specifically
-- if nEffInit >= nCurrentInit and nEffInit <= nNewInit then
-- where 5E and others use
-- if nEffInit < nCurrentInit and nEffInit >= nNewInit then
function manager_effect_processEffects(nodeCurrentActor, nodeNewActor)
--Debug.console("manager_effect_adnd.lua","manager_effect_processEffects","nodeCurrentActor",nodeCurrentActor);
--Debug.console("manager_effect_adnd.lua","manager_effect_processEffects","nodeNewActor",nodeNewActor);
        	-- Get sorted combatant list
	local aEntries = CombatManager.getSortedCombatantList();
	if #aEntries == 0 then
		return;
	end
		
	-- Set up current and new initiative values for effect processing
	local nCurrentInit = -10000;
	if nodeCurrentActor then
		nCurrentInit = DB.getValue(nodeCurrentActor, "initresult", 0); 
	end
	local nNewInit = 10000;
	if nodeNewActor then
		nNewInit = DB.getValue(nodeNewActor, "initresult", 0);
	end
	
	-- For each actor, advance durations, and process start of turn special effects
	local bProcessSpecialStart = (nodeCurrentActor == nil);
	local bProcessSpecialEnd = (nodeCurrentActor == nil);
	for i = 1,#aEntries do
		local nodeActor = aEntries[i];
		
		if nodeActor == nodeCurrentActor then
			bProcessSpecialEnd = true;
		elseif nodeActor == nodeNewActor then
			bProcessSpecialEnd = false;
		end

		-- Check each effect
		for _,nodeEffect in pairs(DB.getChildren(nodeActor, "effects")) do
			-- Make sure effect is active
			local nActive = DB.getValue(nodeEffect, "isactive", 0);
			if (nActive ~= 0) then
				if bProcessSpecialStart then
					if EffectManager.fCustomOnEffectActorStartTurn then
						EffectManager.fCustomOnEffectActorStartTurn(nodeActor, nodeEffect);
					end
				end

				if aEffectVarMap["nInit"] then
                    -- change init to match current init of player, this changes each round
                    -- this only matches when the actor and new actor are the same (meaning it's their turn
                    if (nodeActor == nodeNewActor) then
                        DB.setValue(nodeEffect,aEffectVarMap["nInit"].sDBField,"number",nNewInit);
                    end
                    --
					local nEffInit = DB.getValue(nodeEffect, aEffectVarMap["nInit"].sDBField, aEffectVarMap["nInit"].vDBDefault or 0);

-- Debug.console("manager_effect_adnd.lua","manager_effect_processEffects","nEffInit",nEffInit);
-- Debug.console("manager_effect_adnd.lua","manager_effect_processEffects","nCurrentInit",nCurrentInit);
-- Debug.console("manager_effect_adnd.lua","manager_effect_processEffects","nNewInit",nNewInit);
				
					-- Apply start of effect initiative changes
					if nEffInit > nCurrentInit and nEffInit <= nNewInit then
--Debug.console("manager_effect_adnd.lua","manager_effect_processEffects","Apply start of effect initiative changes");
						-- Start turn
						local bHandled = false;
						if fCustomOnEffectStartTurn then
							bHandled = EffectManager.fCustomOnEffectStartTurn(nodeActor, nodeEffect, nCurrentInit, nNewInit);
						end
						if not bHandled and aEffectVarMap["nDuration"] then
							local nDuration = DB.getValue(nodeEffect, aEffectVarMap["nDuration"].sDBField, 0);
							if nDuration > 0 then
								nDuration = nDuration - 1;
--Debug.console("manager_effect_adnd.lua","manager_effect_processEffects","nDuration",nDuration);
								if nDuration <= 0 then
									EffectManager.expireEffect(nodeActor, nodeEffect, 0);
								else
									DB.setValue(nodeEffect, "duration", "number", nDuration);
								end
							end
						end
						
					-- Apply end of effect initiative changes
					elseif nEffInit <= nCurrentInit and nEffInit > nNewInit then
						if EffectManager.fCustomOnEffectEndTurn then
							bHandled = EffectManager.fCustomOnEffectEndTurn(nodeActor, nodeEffect, nCurrentInit, nNewInit);
						end
					end
				end
				
				if bProcessSpecialEnd then
					if EffectManager.fCustomOnEffectActorEndTurn then
						EffectManager.fCustomOnEffectActorEndTurn(nodeActor, nodeEffect);
					end
				end
			end -- END ACTIVE EFFECT CHECK
         end -- END EFFECT LOOP
		
		if nodeActor == nodeCurrentActor then
			bProcessSpecialStart = true;
		elseif nodeActor == nodeNewActor then
			bProcessSpecialStart = false;
		end
	end -- END ACTOR LOOP
end

-- replace 5E EffectManager5E manager_effect_5E.lua evalAbilityHelper() with this
-- AD&D CORE ONLY
function evalAbilityHelper(rActor, sEffectAbility)
	-- local sSign, sModifier, sShortAbility = sEffectAbility:match("^%[([%+%-]?)([H2]?)([A-Z][A-Z][A-Z])%]$");
	
	-- local nAbility = nil;
	-- if sShortAbility == "STR" then
		-- nAbility = ActorManager2.getAbilityBonus(rActor, "strength");
	-- elseif sShortAbility == "DEX" then
		-- nAbility = ActorManager2.getAbilityBonus(rActor, "dexterity");
	-- elseif sShortAbility == "CON" then
		-- nAbility = ActorManager2.getAbilityBonus(rActor, "constitution");
	-- elseif sShortAbility == "INT" then
		-- nAbility = ActorManager2.getAbilityBonus(rActor, "intelligence");
	-- elseif sShortAbility == "WIS" then
		-- nAbility = ActorManager2.getAbilityBonus(rActor, "wisdom");
	-- elseif sShortAbility == "CHA" then
		-- nAbility = ActorManager2.getAbilityBonus(rActor, "charisma");
	-- elseif sShortAbility == "LVL" then
		-- nAbility = ActorManager2.getAbilityBonus(rActor, "level");
	-- elseif sShortAbility == "PRF" then
		-- nAbility = ActorManager2.getAbilityBonus(rActor, "prf");
	-- end
	
	-- if nAbility then
		-- if sSign == "-" then
			-- nAbility = 0 - nAbility;
		-- end
		-- if sModifier == "H" then
			-- if nAbility > 0 then
				-- nAbility = math.floor(nAbility / 2);
			-- else
				-- nAbility = math.ceil(nAbility / 2);
			-- end
		-- elseif sModifier == "2" then
			-- nAbility = nAbility * 2;
		-- end
	-- end
	
	-- return nAbility;
    return 0;
end

-- replace CoreRPG ActionsManager manager_actions.lua decodeActors() with this
function decodeActors(draginfo)
--Debug.console("manager_effect_Adnd.lua","decodeActors","draginfo",draginfo);
--printstack();
	local rSource = nil;
	local aTargets = {};
    
	
	for k,v in ipairs(draginfo.getShortcutList()) do
		if k == 1 then
			rSource = ActorManager.getActor(v.class, v.recordname);
		else
			local rTarget = ActorManager.getActor(v.class, v.recordname);
			if rTarget then
				table.insert(aTargets, rTarget);
			end
		end
	end

    -- itemPath data filled if itemPath if exists
    local sItemPath = draginfo.getMetaData("itemPath");
    local sSpellPath = draginfo.getMetaData("spellPath");
--Debug.console("manager_effect_Adnd.lua","decodeActors","sItemPath",sItemPath);
    if (sItemPath and sItemPath ~= "") then
        rSource.itemPath = sItemPath;
    end
    if (sSpellPath and sSpellPath ~= "") then
        rSource.spellPath = sSpellPath;
    end
    --
    
	return rSource, aTargets;
end

-- replace 5E EffectManager5E manager_effect_5E.lua getEffectsByType() with this
function getEffectsByType(rActor, sEffectType, aFilter, rFilterActor, bTargetedOnly)
-- Debug.console("manager_effect_adnd.lua","getEffectsByType","==rActor",rActor);    
-- Debug.console("manager_effect_adnd.lua","getEffectsByType","==sEffectType",sEffectType);    
	if not rActor then
		return {};
	end
	local results = {};
--Debug.console("manager_effect_adnd.lua","getEffectsByType","------------>rActor",rActor);    
	
	-- Set up filters
	local aRangeFilter = {};
	local aOtherFilter = {};
	if aFilter then
		for _,v in pairs(aFilter) do
			if type(v) ~= "string" then
				table.insert(aOtherFilter, v);
			elseif StringManager.contains(DataCommon.rangetypes, v) then
				table.insert(aRangeFilter, v);
			else
				table.insert(aOtherFilter, v);
			end
		end
	end
	
	-- Determine effect type targeting
	local bTargetSupport = StringManager.isWord(sEffectType, DataCommon.targetableeffectcomps);
	
--Debug.console("manager_effect_adnd.lua","getEffectsByType","rActor",rActor);    
--Debug.console("manager_effect_adnd.lua","getEffectsByType","sEffectType",sEffectType);    
-- Debug.console("manager_effect_adnd.lua","getEffectsByType","aFilter",aFilter);    
-- Debug.console("manager_effect_adnd.lua","getEffectsByType","rFilterActor",rFilterActor);    
-- Debug.console("manager_effect_adnd.lua","getEffectsByType","bTargetedOnly",bTargetedOnly);    

	-- Iterate through effects
	for _,v in pairs(DB.getChildren(ActorManager.getCTNode(rActor), "effects")) do
		-- Check active
		local nActive = DB.getValue(v, "isactive", 0);
		--if ( nActive ~= 0 and ( not bItemTriggered or (bItemTriggered and bItemSource) ) ) then
        if (EffectManagerADND.isValidCheckEffect(rActor,v)) then
			local sLabel = DB.getValue(v, "label", "");
			local sApply = DB.getValue(v, "apply", "");

			-- IF COMPONENT WE ARE LOOKING FOR SUPPORTS TARGETS, THEN CHECK AGAINST OUR TARGET
			local bTargeted = EffectManager.isTargetedEffect(v);
			if not bTargeted or EffectManager.isEffectTarget(v, rFilterActor) then
				local aEffectComps = EffectManager.parseEffect(sLabel);

				-- Look for type/subtype match
				local nMatch = 0;
				for kEffectComp,sEffectComp in ipairs(aEffectComps) do
					local rEffectComp = EffectManager5E.parseEffectComp(sEffectComp);
					-- Handle conditionals
					if rEffectComp.type == "IF" then
						if not EffectManager5E.checkConditional(rActor, v, rEffectComp.remainder) then
							break;
						end
					elseif rEffectComp.type == "IFT" then
						if not rFilterActor then
							break;
						end
						if not EffectManager5E.checkConditional(rFilterActor, v, rEffectComp.remainder, rActor) then
							break;
						end
						bTargeted = true;
					
					-- Compare other attributes
					else
						-- Strip energy/bonus types for subtype comparison
						local aEffectRangeFilter = {};
						local aEffectOtherFilter = {};
						local j = 1;
						while rEffectComp.remainder[j] do
							local s = rEffectComp.remainder[j];
							if #s > 0 and ((s:sub(1,1) == "!") or (s:sub(1,1) == "~")) then
								s = s:sub(2);
							end
							if StringManager.contains(DataCommon.dmgtypes, s) or s == "all" or 
									StringManager.contains(DataCommon.bonustypes, s) or
									StringManager.contains(DataCommon.conditions, s) or
									StringManager.contains(DataCommon.connectors, s) then
								-- SKIP
							elseif StringManager.contains(DataCommon.rangetypes, s) then
								table.insert(aEffectRangeFilter, s);
							else
								table.insert(aEffectOtherFilter, s);
							end
							
							j = j + 1;
						end
					
						-- Check for match
						local comp_match = false;
						if rEffectComp.type == sEffectType then

							-- Check effect targeting
							if bTargetedOnly and not bTargeted then
								comp_match = false;
							else
								comp_match = true;
							end
						
							-- Check filters
							if #aEffectRangeFilter > 0 then
								local bRangeMatch = false;
								for _,v2 in pairs(aRangeFilter) do
									if StringManager.contains(aEffectRangeFilter, v2) then
										bRangeMatch = true;
										break;
									end
								end
								if not bRangeMatch then
									comp_match = false;
								end
							end
							if #aEffectOtherFilter > 0 then
								local bOtherMatch = false;
								for _,v2 in pairs(aOtherFilter) do
									if type(v2) == "table" then
										local bOtherTableMatch = true;
										for k3, v3 in pairs(v2) do
											if not StringManager.contains(aEffectOtherFilter, v3) then
												bOtherTableMatch = false;
												break;
											end
										end
										if bOtherTableMatch then
											bOtherMatch = true;
											break;
										end
									elseif StringManager.contains(aEffectOtherFilter, v2) then
										bOtherMatch = true;
										break;
									end
								end
								if not bOtherMatch then
									comp_match = false;
								end
							end
						end

						-- Match!
						if comp_match then
							nMatch = kEffectComp;
							if nActive == 1 then
								table.insert(results, rEffectComp);
							end
						end
					end
				end -- END EFFECT COMPONENT LOOP

-- Debug.console("manager_effect_adnd.lua","getEffectsByType","END EFFECT COMPONENT LOOP");    
-- Debug.console("manager_effect_adnd.lua","getEffectsByType","nMatch",nMatch);    
-- Debug.console("manager_effect_adnd.lua","getEffectsByType","sApply",sApply);    
-- Debug.console("manager_effect_adnd.lua","getEffectsByType","v",v);    

				-- Remove one shot effects
				if nMatch > 0 then
					if nActive == 2 then
						DB.setValue(v, "isactive", "number", 1);
					else
						if sApply == "action" then
							EffectManager.notifyExpire(v, 0);
						elseif sApply == "roll" then
							EffectManager.notifyExpire(v, 0, true);
						elseif sApply == "single" then
							EffectManager.notifyExpire(v, nMatch, true);
						end
					end
				end
			end -- END TARGET CHECK
		end  -- END ACTIVE CHECK
	end  -- END EFFECT LOOP
	
	-- RESULTS
	return results;
end

-- replace 5E EffectManager5E manager_effect_5E.lua hasEffect() with this
function hasEffect(rActor, sEffect, rTarget, bTargetedOnly, bIgnoreEffectTargets)
	if not sEffect or not rActor then
		return false;
	end
	local sLowerEffect = sEffect:lower();
	
	-- Iterate through each effect
	local aMatch = {};
--Debug.console("manager_effect_adnd.lua","hasEffect","rActor",rActor);    
--Debug.console("manager_effect_adnd.lua","hasEffect","sEffect",sEffect);    
--Debug.console("manager_effect_adnd.lua","hasEffect","rTarget",rTarget);    
--Debug.console("manager_effect_adnd.lua","hasEffect","bIgnoreEffectTargets",bIgnoreEffectTargets);    
--Debug.console("manager_effect_adnd.lua","hasEffect","bTargetedOnly",bTargetedOnly);    
	for _,v in pairs(DB.getChildren(ActorManager.getCTNode(rActor), "effects")) do
		local nActive = DB.getValue(v, "isactive", 0);
        if (EffectManagerADND.isValidCheckEffect(rActor,v)) then
			-- Parse each effect label
			local sLabel = DB.getValue(v, "label", "");
			local bTargeted = EffectManager.isTargetedEffect(v);
			local aEffectComps = EffectManager.parseEffect(sLabel);

			-- Iterate through each effect component looking for a type match
			local nMatch = 0;
			for kEffectComp,sEffectComp in ipairs(aEffectComps) do
				local rEffectComp = EffectManager5E.parseEffectComp(sEffectComp);
				-- Handle conditionals
				if rEffectComp.type == "IF" then
					if not EffectManager5E.checkConditional(rActor, v, rEffectComp.remainder) then
						break;
					end
				elseif rEffectComp.type == "IFT" then
					if not rTarget then
						break;
					end
					if not EffectManager5E.checkConditional(rTarget, v, rEffectComp.remainder, rActor) then
						break;
					end
				
				-- Check for match
				elseif rEffectComp.original:lower() == sLowerEffect then
					if bTargeted and not bIgnoreEffectTargets then
						if EffectManager.isEffectTarget(v, rTarget) then
							nMatch = kEffectComp;
						end
					elseif not bTargetedOnly then
						nMatch = kEffectComp;
					end
				end
				
			end

-- Debug.console("manager_effect_adnd.lua","hasEffect","nMatch",nMatch);    
-- Debug.console("manager_effect_adnd.lua","hasEffect","sApply",sApply);    
			-- If matched, then remove one-off effects
			if nMatch > 0 then
				if nActive == 2 then
					DB.setValue(v, "isactive", "number", 1);
				else
					table.insert(aMatch, v);
					local sApply = DB.getValue(v, "apply", "");
					if sApply == "action" then
						EffectManager.notifyExpire(v, 0);
					elseif sApply == "roll" then
						EffectManager.notifyExpire(v, 0, true);
					elseif sApply == "single" then
						EffectManager.notifyExpire(v, nMatch, true);
					end
				end
			end
		end
	end
	
	if #aMatch > 0 then
		return true;
	end
	return false;
end

-- replace 5E EffectManager5E manager_effect_5E.lua checkConditional() with this
function checkConditional(rActor, nodeEffect, aConditions, rTarget, aIgnore)
	local bReturn = true;
	
	if not aIgnore then
		aIgnore = {};
	end
	table.insert(aIgnore, nodeEffect.getNodeName());
	
	for _,v in ipairs(aConditions) do
		local sLower = v:lower();
		if sLower == DataCommon.healthstatusfull then
			local nPercentWounded = ActorManager2.getPercentWounded(rActor);
			if nPercentWounded > 0 then
				bReturn = false;
			end
		elseif sLower == DataCommon.healthstatushalf then
			local nPercentWounded = ActorManager2.getPercentWounded(rActor);
			if nPercentWounded < .5 then
				bReturn = false;
			end
		elseif sLower == DataCommon.healthstatuswounded then
			local nPercentWounded = ActorManager2.getPercentWounded(rActor);
			if nPercentWounded == 0 then
				bReturn = false;
			end
		elseif StringManager.contains(DataCommon.conditions, sLower) then
			if not EffectManager5E.checkConditionalHelper(rActor, sLower, rTarget, aIgnore) then
				bReturn = false;
			end
		elseif StringManager.contains(DataCommon.conditionaltags, sLower) then
			if not EffectManager5E.checkConditionalHelper(rActor, sLower, rTarget, aIgnore) then
				bReturn = false;
			end
		else
			local sAlignCheck = sLower:match("^align%s*%(([^)]+)%)$");
			local sSizeCheck = sLower:match("^size%s*%(([^)]+)%)$");
			local sTypeCheck = sLower:match("^type%s*%(([^)]+)%)$");
			local sCustomCheck = sLower:match("^custom%s*%(([^)]+)%)$");
            local sArmorCheck = sLower:match("^armor%s*%(([^)]+)%)$");
			if sAlignCheck then
				if not ActorManager2.isAlignment(rActor, sAlignCheck) then
					bReturn = false;
				end
			elseif sSizeCheck then
				if not ActorManager2.isSize(rActor, sSizeCheck) then
					bReturn = false;
				end
			elseif sTypeCheck then
				if not ActorManager2.isCreatureType(rActor, sTypeCheck) then
					bReturn = false;
				end
			elseif sCustomCheck then
				if not EffectManager5E.checkConditionalHelper(rActor, sCustomCheck, rTarget, aIgnore) then
					bReturn = false;
				end
			elseif sArmorCheck then
				if not ActorManagerADND.isArmorType(rActor, sArmorCheck) then
					bReturn = false;
				end
			end
		end
	end
	
	table.remove(aIgnore);
	
	return bReturn;
end

-- replace 5E EffectManager5E manager_effect_5E.lua checkConditionalHelper() with this
function checkConditionalHelper(rActor, sEffect, rTarget, aIgnore)
	if not rActor then
		return false;
	end
	
	local bReturn = false;
	
	for _,v in pairs(DB.getChildren(ActorManager.getCTNode(rActor), "effects")) do
		local nActive = DB.getValue(v, "isactive", 0);
        if (EffectManagerADND.isValidCheckEffect(rActor,v) and not StringManager.contains(aIgnore, v.getNodeName())) then
		--if nActive ~= 0 and not StringManager.contains(aIgnore, v.getNodeName()) then
			-- Parse each effect label
			local sLabel = DB.getValue(v, "label", "");
			local bTargeted = EffectManager.isTargetedEffect(v);
			local aEffectComps = EffectManager.parseEffect(sLabel);

			-- Iterate through each effect component looking for a type match
			local nMatch = 0;
			for kEffectComp, sEffectComp in ipairs(aEffectComps) do
				local rEffectComp = EffectManager5E.parseEffectComp(sEffectComp);
				-- CHECK FOR FOLLOWON EFFECT TAGS, AND IGNORE THE REST
				if rEffectComp.type == "AFTER" or rEffectComp.type == "FAIL" then
					break;
				
				-- CHECK CONDITIONALS
				elseif rEffectComp.type == "IF" then
					if not EffectManager5E.checkConditional(rActor, v, rEffectComp.remainder, nil, aIgnore) then
						break;
					end
				elseif rEffectComp.type == "IFT" then
					if not rTarget then
						break;
					end
					if not EffectManager5E.checkConditional(rTarget, v, rEffectComp.remainder, rActor, aIgnore) then
						break;
					end
				
				-- CHECK FOR AN ACTUAL EFFECT MATCH
				elseif rEffectComp.original:lower() == sEffect then
					if bTargeted then
						if EffectManager.isEffectTarget(v, rTarget) then
							bReturn = true;
						end
					else
						bReturn = true;
					end
				end
			end
		end
	end
	
	return bReturn;
end

-- replace 5E ActionDamage manager_action_damage.lua performRoll() with this
-- extension only
function manager_action_damage_performRoll(draginfo, rActor, rAction)
	local rRoll = ActionDamage.getRoll(rActor, rAction);

    if (draginfo and rActor.itemPath and rActor.itemPath ~= "") then
        draginfo.setMetaData("itemPath",rActor.itemPath);
--Debug.console("manager_effect_adnd.lua","manager_action_damage_performRoll","rActor.itemPath",rActor.itemPath);    
    end
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

-- replace 5E ActionAttack manager_action_attack.lua performRoll() with this
-- extension only
function manager_action_attack_performRoll(draginfo, rActor, rAction)
	local rRoll = ActionAttack.getRoll(rActor, rAction);

    if (draginfo and rActor.itemPath and rActor.itemPath ~= "") then
        draginfo.setMetaData("itemPath",rActor.itemPath);
--Debug.console("manager_effect_adnd.lua","manager_action_attack_performRoll","rActor.itemPath",rActor.itemPath);    
    end
    
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

-- replace 5E PowerManager manager_power.lua performAction() with this
-- extension only
function manager_power_performAction(draginfo, rActor, rAction, nodePower)
	if not rActor or not rAction then
		return false;
	end
	
    -- add itemPath to rActor so that when effects are checked we can 
    -- make compare against action only effects
    local nodeWeapon = nodeAction.getChild("...");
    local _, sRecord = DB.getValue(nodeWeapon, "shortcut", "", "");
	rActor.itemPath = sRecord;
    if (draginfo and rActor.itemPath and rActor.itemPath ~= "") then
        draginfo.setMetaData("itemPath",rActor.itemPath);
    end
    --

	evalAction(rActor, nodePower, rAction);

	local rRolls = {};
	if rAction.type == "cast" then
		rAction.subtype = (rAction.subtype or "");
		if rAction.subtype == "" then
			table.insert(rRolls, ActionPower.getPowerCastRoll(rActor, rAction));
		end
		if ((rAction.subtype == "") or (rAction.subtype == "atk")) and rAction.range then
			table.insert(rRolls, ActionAttack.getRoll(rActor, rAction));
		end
		if ((rAction.subtype == "") or (rAction.subtype == "save")) and ((rAction.save or "") ~= "") then
			table.insert(rRolls, ActionPower.getSaveVsRoll(rActor, rAction));
		end
	
	elseif rAction.type == "attack" then
		table.insert(rRolls, ActionAttack.getRoll(rActor, rAction));
		
	elseif rAction.type == "powersave" then
		table.insert(rRolls, ActionPower.getSaveVsRoll(rActor, rAction));

	elseif rAction.type == "damage" then
		table.insert(rRolls, ActionDamage.getRoll(rActor, rAction));
		
	elseif rAction.type == "heal" then
		table.insert(rRolls, ActionHeal.getRoll(rActor, rAction));
		
	elseif rAction.type == "effect" then
		local rRoll = ActionEffect.getRoll(draginfo, rActor, rAction);
		if rRoll then
			table.insert(rRolls, rRoll);
		end
	end
	
	if #rRolls > 0 then
		ActionsManager.performMultiAction(draginfo, rActor, rRolls[1].sType, rRolls);
	end
	return true;
end
