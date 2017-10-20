
--
-- Effects on Items, apply to character in CT
--
--

function onInit()
    --CoreRPG replacements
    ActionsManager.decodeActors = decodeActors;
    -- 3.3.3 version is bugged, this fixes it
    -- (isactive is not set properly)
    EffectManager.addEffect = addEffect;    
    
    -- 5E effects replacements
    EffectManager5E.checkConditionalHelper = checkConditionalHelper;
    EffectManager5E.getEffectsByType = getEffectsByType;
    EffectManager5E.hasEffect = hasEffect;

    -- used for AD&D Core ONLY
    EffectManager5E.evalAbilityHelper = evalAbilityHelper;
    
    -- used for 5E extension ONLY
    --ActionAttack.performRoll = manager_action_attack_performRoll;
    --ActionDamage.performRoll = manager_action_damage_performRoll;
    --PowerManager.performAction = manager_power_performAction;
    
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
--Debug.console("manager_effect.lua","updateItemEffect","nActive",nActive);
            if (nActive ~= 0) then
                local sEffSource = DB.getValue(nodeEffect, "source_name", "");
--Debug.console("manager_effect.lua","updateItemEffect","sEffSource",sEffSource);
                if (sEffSource == sItemSource) then
                    bFound = true;
--Debug.console("manager_effect.lua","updateItemEffect","bFound!!!",bFound);
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
            if (dDurationDice and dDurationDice ~= "") then
                nRollDuration = StringManager.evalDice(dDurationDice, nModDice);
            else
                nRollDuration = nModDice;
            end
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
            rEffect.sUnits = DB.getValue(nodeItemEffect, "durunit", "day");
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
    if (dDurationDice and dDurationDice ~= "") then
        nRollDuration = StringManager.evalDice(dDurationDice, nModDice);
    else
        nRollDuration = nModDice;
    end
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
    rEffect.sUnits = DB.getValue(nodeCharEffect, "durunit", "day");
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
--Debug.console("manager_effect_Adnd.lua","isValidCheckEffect","nodeEffect",nodeEffect);    
    local bResult = false;
    local nActive = DB.getValue(nodeEffect, "isactive", 0);
    local bItem = false;
    local bValidItemTriggered = false;
    local bActionOnly = false;
    local nodeItem = nil;

    local sSource = DB.getValue(nodeEffect,"source_name","");
    -- if source is a valid node and we can find "actiononly"
    -- setting then we set it.
    local node = DB.findNode(sSource);
--Debug.console("manager_effect_Adnd.lua","isValidCheckEffect","node",node);    
    if (node and node ~= nil) then
        nodeItem = node.getChild("...");
--Debug.console("manager_effect_Adnd.lua","isValidCheckEffect","nodeItem",nodeItem);    
        if nodeItem and nodeItem ~= nil then
            bActionOnly = (DB.getValue(node,"actiononly",0) ~= 0);
--Debug.console("manager_effect_Adnd.lua","isValidCheckEffect","bActionOnly",bActionOnly);    
        end
    end

    -- if there is a itemPath do some sanity checking
    if (rActor.itemPath and rActor.itemPath ~= "") then 
--Debug.console("manager_effect_Adnd.lua","isValidCheckEffect","rActor.itemPath",rActor.itemPath);    
        -- here is where we get the node path of the item, not the 
        -- effectslist entry
        if ((DB.findNode(rActor.itemPath) ~= nil)) then
            if (node and node ~= nil and nodeItem and nodeItem ) then
                local sNodePath = nodeItem.getPath();
--Debug.console("manager_effect_Adnd.lua","isValidCheckEffect","sNodePath",sNodePath);    
                if bActionOnly and sNodePath ~= "" and (sNodePath == rActor.itemPath) then
                    bValidItemTriggered = true;
                    bItem = true;
--Debug.console("manager_effect_Adnd.lua","isValidCheckEffect","bValidItemTriggered1",bValidItemTriggered);    
--Debug.console("manager_effect_Adnd.lua","isValidCheckEffect","bItem1",bItem);    
                else
                    bValidItemTriggered = false;
                    bItem = true; -- is item but doesn't match source path for this effect
--Debug.console("manager_effect_Adnd.lua","isValidCheckEffect","bValidItemTriggered2",bValidItemTriggered);    
--Debug.console("manager_effect_Adnd.lua","isValidCheckEffect","bItem2",bItem);    
                end
            end
        end
    end
	if ( nActive ~= 0 and ( not bItem or (bItem and bValidItemTriggered) ) ) then
        bResult = true;
    end
--Debug.console("manager_effect_Adnd.lua","isValidCheckEffect","bResult",bResult);    
    if bActionOnly and not (bItem or bValidItemTriggered) then
        bResult = false;
    end
--Debug.console("manager_effect_Adnd.lua","isValidCheckEffect","bResult",bResult);    
    
    return bResult;
end



--
--          REPLACEMENT FUNCTIONS
--



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
--Debug.console("manager_effect_Adnd.lua","decodeActors","sItemPath",sItemPath);
    if (sItemPath and sItemPath ~= "") then
        rSource.itemPath = sItemPath;
    end
    --
    
	return rSource, aTargets;
end

-- replace 5E EffectManager5E manager_effect_5E.lua getEffectsByType() with this
function getEffectsByType(rActor, sEffectType, aFilter, rFilterActor, bTargetedOnly)
--Debug.console("manager_effect_adnd.lua","getEffectsByType","==rActor",rActor);    
--Debug.console("manager_effect_adnd.lua","getEffectsByType","==sEffectType",sEffectType);    
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

-- replace CoreRPG EffectManager manager_effect.lua addEffect() with this
-- Why? it's got a bug in it and not setting isactive correctly, this does.
function addEffect(sUser, sIdentity, nodeCT, rNewEffect, bShowMsg)
	if not nodeCT or not rNewEffect or not rNewEffect.sName then
		return;
	end
	local nodeEffectsList = nodeCT.createChild("effects");
	if not nodeEffectsList then
		return;
	end
	
	if fCustomOnEffectAddStart then
		fCustomOnEffectAddStart(rNewEffect);
	end
    local aEffectVarMap = {
        ["sName"] = { sDBType = "string", sDBField = "label" },
        ["nGMOnly"] = { sDBType = "number", sDBField = "isgmonly" },
        ["sSource"] = { sDBType = "string", sDBField = "source_name", bClearOnUntargetedDrop = true },
        ["sTarget"] = { sDBType = "string", bClearOnUntargetedDrop = true },
        ["nDuration"] = { sDBType = "number", sDBField = "duration", vDBDefault = 1, sDisplay = "[D: %d]" },
        ["nInit"] = { sDBType = "number", sDBField = "init", sSourceChangeSet = "initresult", bClearOnUntargetedDrop = true },
    };
	
	-- Check whether to ignore new effect (i.e. duplicates)
	local sDuplicateMsg = nil;
	if fCustomOnEffectAddIgnoreCheck then
		sDuplicateMsg = fCustomOnEffectAddIgnoreCheck(nodeCT, rNewEffect);
	else
		for k, v in pairs(nodeEffectsList.getChildren()) do
			if (DB.getValue(v, "label", "") == rNewEffect.sName) and 
					(DB.getValue(v, "init", 0) == rNewEffect.nInit) and
					(DB.getValue(v, "duration", 0) == rNewEffect.nDuration) then
				sDuplicateMsg = "Effect ['" .. rNewEffect.sName .. "'] -> [ALREADY EXISTS]"
				break;
			end
		end
	end
	if sDuplicateMsg then
		message(sDuplicateMsg, nodeCT, false, sUser);
		return;
	end
	
	-- Write effect record
	local nodeTargetEffect = nodeEffectsList.createChild();
	for k,v in pairs(aEffectVarMap) do
		if rNewEffect[k] and v.sDBType and v.sDBField and not v.bSkipAdd then
			DB.setValue(nodeTargetEffect, v.sDBField, v.sDBType, rNewEffect[k]);
		end
	end
	DB.setValue(nodeTargetEffect, "isactive", "number", 1);

	-- Handle effect targeting
	if rNewEffect.sTarget and rNewEffect.sTarget ~= "" then
		addEffectTarget(nodeTargetEffect, rNewEffect.sTarget);
	end
	
	if fCustomOnEffectAddEnd then
		fCustomOnEffectAddEnd(nodeTargetEffect, rNewEffect);
	end

	-- Handle effect ownership
	if sUser ~= "" then
		DB.setOwner(nodeTargetEffect, sUser);
	end

	-- Build output message
	local msg = {font = "msgfont", icon = "roll_effect"};
	msg.text = "Effect ['" .. rNewEffect.sName .. "'] ";
	msg.text = msg.text .. "-> [to " .. DB.getValue(nodeCT, "name", "") .. "]";
	if rNewEffect.sSource and rNewEffect.sSource ~= "" then
		msg.text = msg.text .. " [by " .. DB.getValue(DB.findNode(rNewEffect.sSource), "name", "") .. "]";
	end
	
	-- Output message
	if bShowMsg then
		if isGMEffect(nodeCT, nodeTargetEffect) then
			if sUser == "" then
				msg.secret = true;
				Comm.addChatMessage(msg);
			elseif sUser ~= "" then
				Comm.addChatMessage(msg);
				Comm.deliverChatMessage(msg, sUser);
			end
		else
			Comm.deliverChatMessage(msg);
		end
	end
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
