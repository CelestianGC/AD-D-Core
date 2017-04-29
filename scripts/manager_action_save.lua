-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYSAVE = "applysave";
function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYSAVE, handleApplySave);
	ActionsManager.registerModHandler("save", modSave);
	ActionsManager.registerResultHandler("save", onSave);
end

function setNPCSave(nodeEntry, sSave, nodeNPC)
    
    --Debug.console("manager_action_save.lua", "setNPCSave", sSave);

    local nSaveIndex = DataCommonADND.saves_table_index[sSave];

    --Debug.console("manager_action_save.lua", "setNPCSave", "DataCommonADND.saves_table_index[sSave]", DataCommonADND.saves_table_index[sSave]);
    
    --Debug.console("manager_action_save.lua", "setNPCSave", "nSaveIndex", nSaveIndex);
    
    local nSaveScore = 20;
    local nLevel = CombatManager2.getNPCLevelFromHitDice(nodeEntry, nodeNPC);

    -- store it incase we wanna look at it later
    DB.setValue(nodeEntry, "level", "number", nLevel);
    
    --Debug.console("manager_action_save.lua", "setNPCSave", "nLevel", nLevel);
    
    if (nLevel > 17) then
        nSaveScore = DataCommonADND.aWarriorSaves[17][nSaveIndex];
    elseif (nLevel < 1) then
        nSaveScore = DataCommonADND.aWarriorSaves[0][nSaveIndex];
    else
        nSaveScore = DataCommonADND.aWarriorSaves[nLevel][nSaveIndex];
    --Debug.console("manager_action_save.lua", "setNPCSave", "DataCommonADND.aWarriorSaves[nLevel][nSaveIndex]", DataCommonADND.aWarriorSaves[nLevel][nSaveIndex]);
    end

    --Debug.console("manager_action_save.lua", "setNPCSave", "nSaveScore", nSaveScore);
    
    DB.setValue(nodeEntry, "saves." .. sSave .. ".score", "number", nSaveScore);

    --Debug.console("manager_action_save.lua", "setNPCSave", "setValue Done");

    return nSaveScore;
end

function handleApplySave(msgOOB)
    --Debug.console("manager_action_Save.lua","handleApplySave","msgOOB",msgOOB);
	local rSource = ActorManager.getActor(msgOOB.sSourceType, msgOOB.sSourceNode);
	local rOrigin = ActorManager.getActor(msgOOB.sTargetType, msgOOB.sTargetNode);
	
	local rAction = {};
	rAction.bSecret = (tonumber(msgOOB.nSecret) == 1);
	rAction.sDesc = msgOOB.sDesc;
	rAction.nTotal = tonumber(msgOOB.nTotal) or 0;
	rAction.sSaveDesc = msgOOB.sSaveDesc;
	rAction.nTarget = tonumber(msgOOB.nTarget) or 0;
--	rAction.nTarget = tonumber(msgOOB.nDC) or 0;
	rAction.sResult = msgOOB.sResult;
	rAction.bRemoveOnMiss = (tonumber(msgOOB.nRemoveOnMiss) == 1);
	
--    Debug.console("manager_action_Save.lua","handleApplySave","rSource",rSource);
--    Debug.console("manager_action_Save.lua","handleApplySave","rOrigin",rOrigin);
--    Debug.console("manager_action_Save.lua","handleApplySave","rAction",rAction);
	applySave(rSource, rOrigin, rAction);
end

function notifyApplySave(rSource, bSecret, rRoll)
--    Debug.console("manager_action_Save.lua","notifyApplySave","rSource",rSource);
--    Debug.console("manager_action_Save.lua","notifyApplySave","bSecret",bSecret);
--    Debug.console("manager_action_Save.lua","notifyApplySave","rRoll",rRoll);
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYSAVE;
	
	if bSecret then
		msgOOB.nSecret = 1;
	else
		msgOOB.nSecret = 0;
	end
	msgOOB.sDesc = rRoll.sDesc;
	msgOOB.nTotal = ActionsManager.total(rRoll);
	msgOOB.sSaveDesc = rRoll.sSaveDesc;
	msgOOB.nTarget = rRoll.nTarget;
	msgOOB.sResult = rRoll.sResult;
	if rRoll.bRemoveOnMiss then msgOOB.nRemoveOnMiss = 1; end

	local sSourceType, sSourceNode = ActorManager.getTypeAndNodeName(rSource);
	msgOOB.sSourceType = sSourceType;
	msgOOB.sSourceNode = sSourceNode;

	if rRoll.sSource ~= "" then
		msgOOB.sTargetType = "ct";
		msgOOB.sTargetNode = rRoll.sSource;
	else
		msgOOB.sTargetType = "";
		msgOOB.sTargetNode = "";
	end

--    Debug.console("manager_action_Save.lua","notifyApplySave2","rSource",rSource);
--    Debug.console("manager_action_Save.lua","notifyApplySave2","bSecret",bSecret);
--    Debug.console("manager_action_Save.lua","notifyApplySave2","rRoll",rRoll);
--    Debug.console("manager_action_Save.lua","notifyApplySave2","msgOOB",msgOOB);
	Comm.deliverOOBMessage(msgOOB, "");
end

function performRoll(draginfo, rActor, sSave, nTargetDC, bSecretRoll, rSource, bRemoveOnMiss, sSaveDesc)
    local rRoll = {};
	rRoll.sType = "save";
	rRoll.aDice = { "d20" };
	local nMod, bADV, bDIS, sAddText = ActorManager2.getSave(rActor, sSave);
	rRoll.nMod = nMod;
	
    -- Debug.console("manager_action_Save.lua","performRoll","draginfo",draginfo);
    -- Debug.console("manager_action_Save.lua","performRoll","rActor",rActor);
    -- Debug.console("manager_action_Save.lua","performRoll","sSave",sSave);
    -- Debug.console("manager_action_Save.lua","performRoll","nTargetDC",nTargetDC);
    -- Debug.console("manager_action_Save.lua","performRoll","bSecretRoll",bSecretRoll);
    -- Debug.console("manager_action_Save.lua","performRoll","rSource",rSource);
    -- Debug.console("manager_action_Save.lua","performRoll","bRemoveOnMiss",bRemoveOnMiss);

	-- sPrettySaveText = aSave[string.lower(sSave)];
    local sPrettySaveText = DataCommon.saves_stol[sSave];

	rRoll.sDesc = "[SAVE] vs. " .. StringManager.capitalize(sPrettySaveText);

	if sAddText and sAddText ~= "" then
		rRoll.sDesc = rRoll.sDesc .. " " .. sAddText;
	end
	if bADV then
		rRoll.sDesc = rRoll.sDesc .. " [ADV]";
	end
	if bDIS then
		rRoll.sDesc = rRoll.sDesc .. " [DIS]";
	end
	rRoll.bSecret = bSecretRoll;
	
	rRoll.nTarget = nTargetDC;

	if bRemoveOnMiss then
		rRoll.bRemoveOnMiss = "true";
	end
	if sSaveDesc then
		rRoll.sSaveDesc = sSaveDesc;
	end
	if rSource then
		rRoll.sSource = ActorManager.getCTNodeName(rSource);
	end

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modSave(rSource, rTarget, rRoll)
    -- Debug.console("manager_action_Save.lua","modSave","rSource",rSource);
    -- Debug.console("manager_action_Save.lua","modSave","rTarget",rTarget);
    -- Debug.console("manager_action_Save.lua","modSave","rRoll",rRoll);
	local bAutoFail = false;

	local sSave = string.match(rRoll.sDesc, "%[SAVE%] (%w+)");
	if sSave then
		sSave = sSave:lower();
	end

	local bADV = false;
	local bDIS = false;
	if rRoll.sDesc:match(" %[ADV%]") then
		bADV = true;
		rRoll.sDesc = rRoll.sDesc:gsub(" %[ADV%]", "");
	end
	if rRoll.sDesc:match(" %[DIS%]") then
		bDIS = true;
		rRoll.sDesc = rRoll.sDesc:gsub(" %[DIS%]", "");
	end

	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;
	
	local nCover = 0;
	if sSave == "dexterity" then
		if rRoll.sSaveDesc then
			nCover = tonumber(rRoll.sSaveDesc:match("%[COVER %-(%d)%]")) or 0;
		else
			if ModifierStack.getModifierKey("DEF_SCOVER") then
				nCover = 5;
			elseif ModifierStack.getModifierKey("DEF_COVER") then
				nCover = 2;
			end
		end
	end
	
	if rSource then
		local bEffects = false;

		-- Build filter
		local aSaveFilter = {};
		if sSave then
			table.insert(aSaveFilter, sSave);
		end

		-- Get effect modifiers
		local rSaveSource = nil;
		if rRoll.sSource then
			rSaveSource = ActorManager.getActor("ct", rRoll.sSource);
		end
		local aAddDice, nAddMod, nEffectCount = EffectManager.getEffectsBonus(rSource, {"SAVE"}, false, aSaveFilter, rSaveSource);
		if nEffectCount > 0 then
			bEffects = true;
		end
		
		-- Get condition modifiers
		if EffectManager.hasEffect(rSource, "ADVSAV", rTarget) then
			bADV = true;
			bEffects = true;
		elseif #(EffectManager.getEffectsByType(rSource, "ADVSAV", aSaveFilter, rTarget)) > 0 then
			bADV = true;
			bEffects = true;
		end
		if EffectManager.hasEffect(rSource, "DISSAV", rTarget) then
			bDIS = true;
			bEffects = true;
		elseif #(EffectManager.getEffectsByType(rSource, "DISSAV", aSaveFilter, rTarget)) > 0 then
			bDIS = true;
			bEffects = true;
		end
		if sSave == "dexterity" then
			if EffectManager.hasEffectCondition(rSource, "Restrained") then
				bDIS = true;
				bEffects = true;
			end
			if nCover < 5 then
				if EffectManager.hasEffect(rSource, "SCOVER", rTarget) then
					nCover = 5;
					bEffects = true;
				elseif nCover < 2 then
					if EffectManager.hasEffect(rSource, "COVER", rTarget) then
						nCover = 2;
						bEffects = true;
					end
				end
			end
		end
		if StringManager.contains({ "strength", "dexterity" }, sSave) then
			if EffectManager.hasEffectCondition(rSource, "Paralyzed") then
				bAutoFail = true;
				bEffects = true;
			end
			if EffectManager.hasEffectCondition(rSource, "Stunned") then
				bAutoFail = true;
				bEffects = true;
			end
			if EffectManager.hasEffectCondition(rSource, "Unconscious") then
				bAutoFail = true;
				bEffects = true;
			end
		end
		if StringManager.contains({ "strength", "dexterity", "constitution" }, sSave) then
			if EffectManager.hasEffectCondition(rSource, "Encumbered") then
				bEffects = true;
				bDIS = true;
			end
		end
		if sSave == "dexterity" and EffectManager.hasEffectCondition(rSource, "Dodge") and 
				not (EffectManager.hasEffectCondition(rSource, "Paralyzed") or
				EffectManager.hasEffectCondition(rSource, "Stunned") or
				EffectManager.hasEffectCondition(rSource, "Unconscious") or
				EffectManager.hasEffectCondition(rSource, "Incapacitated") or
				EffectManager.hasEffectCondition(rSource, "Grappled") or
				EffectManager.hasEffectCondition(rSource, "Restrained")) then
			bEffects = true;
			bADV = true;
		end

		-- Get ability modifiers
		local nBonusStat, nBonusEffects = ActorManager2.getAbilityEffectsBonus(rSource, sSave);
		if nBonusEffects > 0 then
			bEffects = true;
			nAddMod = nAddMod + nBonusStat;
		end
		
		-- Get exhaustion modifiers
		local nExhaustMod, nExhaustCount = EffectManager.getEffectsBonus(rSource, {"EXHAUSTION"}, true);
		if nExhaustCount > 0 then
			bEffects = true;
			if nExhaustMod >= 3 then
				bDIS = true;
			end
		end
		
		-- If effects apply, then add note
		if bEffects then
			for _, vDie in ipairs(aAddDice) do
				if vDie:sub(1,1) == "-" then
					table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
				else
					table.insert(rRoll.aDice, "p" .. vDie:sub(2));
				end
			end
			rRoll.nMod = rRoll.nMod + nAddMod;
			
			local sEffects = "";
			local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
			if sMod ~= "" then
				sEffects = "[" .. Interface.getString("effects_tag") .. " " .. sMod .. "]";
			else
				sEffects = "[" .. Interface.getString("effects_tag") .. "]";
			end
			rRoll.sDesc = rRoll.sDesc .. " " .. sEffects;
		end
	end
	
	if nCover > 0 then
		rRoll.nMod = rRoll.nMod + nCover;
		rRoll.sDesc = rRoll.sDesc .. string.format(" [COVER +%d]", nCover);
	end
	
	ActionsManager2.encodeDesktopMods(rRoll);

    -- don't use advantage/disadvantage in AD&D --celestian
    bADV = false;
    bDIS = false;
	ActionsManager2.encodeAdvantage(rRoll, bADV, bDIS);
	
	if bAutoFail then
		rRoll.sDesc = rRoll.sDesc .. " [AUTOFAIL]";
	end
end

-- function onSave(rSource, rTarget, rRoll)
	-- ActionsManager2.decodeAdvantage(rRoll);

	-- local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	-- local bAutoFail = string.match(rRoll.sDesc, "%[AUTOFAIL%]");
	-- if not bAutoFail and rRoll.nTarget then
    -- --
		-- local nTotal = ActionsManager.total(rRoll);
		-- local nTargetDC = tonumber(rRoll.nTarget) or 0;
		
		-- rMessage.text = rMessage.text .. " (Target " .. nTargetDC .. ")";
		-- if nTotal >= nTargetDC then
			-- rMessage.text = rMessage.text .. " [SUCCESS]";

			-- if rSource and rRoll.sSource then
				-- if rRoll.sSaveDesc then
					-- local sAttack = string.match(rRoll.sSaveDesc, "%[SAVE VS[^]]*%] ([^[]+)");
					-- if sAttack then
						-- local rRollSource = ActorManager.getActor("ct", rRoll.sSource);
						-- local bHalfMatch = rRoll.sSaveDesc:match("%[HALF ON SAVE%]");
						
						-- local bHalfDamage = false;
						-- local bAvoidDamage = false;
						-- if bHalfMatch then
							-- bHalfDamage = true;
						-- end
						-- if bHalfDamage then
							-- if EffectManager.hasEffectCondition(rSource, "Avoidance") then
								-- bAvoidDamage = true;
								-- rMessage.text = rMessage.text .. " [AVOIDANCE]";
							-- elseif EffectManager.hasEffectCondition(rSource, "Evasion") then
								-- local sSave = string.match(rRoll.sDesc, "%[SAVE%] (%w+)");
								-- if sSave then
									-- sSave = sSave:lower();
								-- end
								-- if sSave == "dexterity" then
									-- bAvoidDamage = true;
									-- rMessage.text = rMessage.text .. " [EVASION]";
								-- end
							-- end
						-- end
						
						-- if bAvoidDamage then
							-- ActionDamage.setDamageState(rRollSource, rSource, StringManager.trim(sAttack), "none");
							-- rRoll.bRemoveOnMiss = false;
						-- elseif bHalfDamage then
							-- ActionDamage.setDamageState(rRollSource, rSource, StringManager.trim(sAttack), "half");
							-- rRoll.bRemoveOnMiss = false;
						-- else
							-- ActionDamage.setDamageState(rRollSource, rSource, StringManager.trim(sAttack), "");
						-- end
					-- end
				-- end
			
				-- local bRemoveTarget = false;
				-- if OptionsManager.isOption("RMMT", "on") then
					-- bRemoveTarget = true;
				-- elseif rRoll.bRemoveOnMiss then
					-- bRemoveTarget = true;
				-- end
				
				-- if bRemoveTarget then
					-- TargetingManager.removeTarget(rRoll.sSource, ActorManager.getCTNodeName(rSource));
				-- end
			-- end
		-- else
			-- rMessage.text = rMessage.text .. " [FAILURE]";

			-- if rRoll.sSaveDesc then
				-- local sAttack = string.match(rRoll.sSaveDesc, "%[SAVE VS[^]]*%] ([^[]+)");
				-- if sAttack then
					-- local rRollSource = ActorManager.getActor("ct", rRoll.sSource);
					-- local bHalfMatch = rRoll.sSaveDesc:match("%[HALF ON SAVE%]");
					
					-- local bHalfDamage = false;
					-- if bHalfMatch then
						-- if EffectManager.hasEffectCondition(rSource, "Avoidance") then
							-- bHalfDamage = true;
							-- rMessage.text = rMessage.text .. " [AVOIDANCE]";
						-- elseif EffectManager.hasEffectCondition(rSource, "Evasion") then
							-- local sSave = string.match(rRoll.sDesc, "%[SAVE%] (%w+)");
							-- if sSave then
								-- sSave = sSave:lower();
							-- end
							-- if sSave == "dexterity" then
								-- bHalfDamage = true;
								-- rMessage.text = rMessage.text .. " [EVASION]";
							-- end
						-- end
					-- end
					
					-- if bHalfDamage then
						-- ActionDamage.setDamageState(rRollSource, rSource, StringManager.trim(sAttack), "half");
					-- else
						-- ActionDamage.setDamageState(rRollSource, rSource, StringManager.trim(sAttack), "");
					-- end
				-- end
			-- end
		-- end
	-- end

	-- Comm.deliverChatMessage(rMessage);
-- end

-- this part of the new save method in the 5e ruleset, need to trace it and see if we need it.
function onSave(rSource, rTarget, rRoll)
    -- Debug.console("manager_action_Save.lua","onSave","rSource",rSource);
    -- Debug.console("manager_action_Save.lua","onSave","rTarget",rTarget);
    -- Debug.console("manager_action_Save.lua","onSave","rRoll",rRoll);
	ActionsManager2.decodeAdvantage(rRoll);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);

	local bAutoFail = rRoll.sDesc:match("%[AUTOFAIL%]");
	if not bAutoFail and rRoll.nTarget then
		notifyApplySave(rSource, rMessage.secret, rRoll);
	end
end

-- this part of the new save method in the 5e ruleset, need to trace it and see if we need it.
function applySave(rSource, rOrigin, rAction, sUser)
    -- Debug.console("manager_action_Save.lua","applySave","rSource",rSource);
    -- Debug.console("manager_action_Save.lua","applySave","rOrigin",rOrigin);
    -- Debug.console("manager_action_Save.lua","applySave","rAction",rAction);
    -- Debug.console("manager_action_Save.lua","applySave","sUser",sUser);
	local msgShort = {font = "msgfont"};
	local msgLong = {font = "msgfont"};
	
	msgShort.text = "Save";
	msgLong.text = "Save [" .. rAction.nTotal ..  "]";
	if rAction.nTarget > 0 then
		msgLong.text = msgLong.text .. " [Target " .. rAction.nTarget .. "]";
	end
	msgShort.text = msgShort.text .. " ->";
	msgLong.text = msgLong.text .. " ->";
	if rSource then
		msgShort.text = msgShort.text .. " [for " .. rSource.sName .. "]";
		msgLong.text = msgLong.text .. " [for " .. rSource.sName .. "]";
	end
	if rOrigin then
		msgShort.text = msgShort.text .. " [vs " .. rOrigin.sName .. "]";
		msgLong.text = msgLong.text .. " [vs " .. rOrigin.sName .. "]";
	end
	
	msgShort.icon = "roll_cast";
		
	local sAttack = "";
	local bHalfMatch = false;
	if rAction.sSaveDesc then
		sAttack = rAction.sSaveDesc:match("%[SAVE VS[^]]*%] ([^[]+)") or "";
		bHalfMatch = (rAction.sSaveDesc:match("%[HALF ON SAVE%]") ~= nil);
	end
	rAction.sResult = "";
	
	if rAction.nTotal >= rAction.nTarget then
		msgLong.text = msgLong.text .. " [SUCCESS]";
		
		if rSource then
			local bHalfDamage = bHalfMatch;
			local bAvoidDamage = false;
			if bHalfDamage then
				if EffectManager.hasEffectCondition(rSource, "Avoidance") then
					bAvoidDamage = true;
					msgLong.text = msgLong.text .. " [AVOIDANCE]";
				elseif EffectManager.hasEffectCondition(rSource, "Evasion") then
					local sSave = rAction.sDesc:match("%[SAVE%] (%w+)");
					if sSave then
						sSave = sSave:lower();
					end
					if sSave == "dexterity" then
						bAvoidDamage = true;
						msgLong.text = msgLong.text .. " [EVASION]";
					end
				end
			end
			
			if bAvoidDamage then
				rAction.sResult = "none";
				rAction.bRemoveOnMiss = false;
			elseif bHalfDamage then
				rAction.sResult = "half";
				rAction.bRemoveOnMiss = false;
			end
			
			if rOrigin and rAction.bRemoveOnMiss then
				TargetingManager.removeTarget(ActorManager.getCTNodeName(rOrigin), ActorManager.getCTNodeName(rSource));
			end
		end
	else
		msgLong.text = msgLong.text .. " [FAILURE]";

		if rSource then
			local bHalfDamage = false;
			if bHalfMatch then
				if EffectManager.hasEffectCondition(rSource, "Avoidance") then
					bHalfDamage = true;
					msgLong.text = msgLong.text .. " [AVOIDANCE]";
				elseif EffectManager.hasEffectCondition(rSource, "Evasion") then
					local sSave = rAction.sDesc:match("%[SAVE%] (%w+)");
					if sSave then
						sSave = sSave:lower();
					end
					if sSave == "dexterity" then
						bHalfDamage = true;
						msgLong.text = msgLong.text .. " [EVASION]";
					end
				end
			end
			
			if bHalfDamage then
				rAction.sResult = "half";
			end
		end
	end
	
	ActionsManager.messageResult(bSecret, rSource, rOrigin, msgLong, msgShort);
	
	if rSource and rOrigin then
		ActionDamage.setDamageState(rOrigin, rSource, StringManager.trim(sAttack), rAction.sResult);
	end
end
