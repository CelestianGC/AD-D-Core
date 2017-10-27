-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

--
-- Original CoreRPG manager_effect.lua
--
--

-- Standard effect fields
--		sName
--		nGMOnly
--		sSource

OOB_MSGTYPE_APPLYEFF = "applyeff";
OOB_MSGTYPE_EXPIREEFF = "expireeff";

EFFECT_TAG = "EFFECT"

local nLocked = 0;
local aExpireOnLockRelease = {};

local aEffectVarMap = {
	["sName"] = { sDBType = "string", sDBField = "label" },
	["nGMOnly"] = { sDBType = "number", sDBField = "isgmonly" },
	["sSource"] = { sDBType = "string", sDBField = "source_name", bClearOnUntargetedDrop = true },
	["sTarget"] = { sDBType = "string", bClearOnUntargetedDrop = true },
	["nDuration"] = { sDBType = "number", sDBField = "duration", vDBDefault = 1, sDisplay = "[D: %d]" },
	["nInit"] = { sDBType = "number", sDBField = "init", sSourceChangeSet = "initresult", bClearOnUntargetedDrop = true },
};
-- NOTE: isactive is a DB field that is part of all CT effects, but not tracked in the effect record

function onInit()
	CombatManager.setCustomInitChange(manager_effect_processEffects);
	
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYEFF, handleApplyEffect);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_EXPIREEFF, handleExpireEffect);
end

function registerEffectVar(sVar, vData)	
	if vData and (((vData.sDBType or "") ~= "string") and ((vData.sDBType or "") ~= "number")) then
		print("Invalid effect variable type registered. (" .. sVar .. ")");
		return;
	end
	aEffectVarMap[sVar] = vData;
end

--
-- CUSTOM EVENT HANDLING
--

local fCustomOnEffectAddStart = nil;
function setCustomOnEffectAddStart(f)
	fCustomOnEffectAddStart = f;
end

local fCustomOnEffectAddIgnoreCheck = nil;
function setCustomOnEffectAddIgnoreCheck(f)
	fCustomOnEffectAddIgnoreCheck = f;
end

local fCustomOnEffectAddEnd = nil;
function setCustomOnEffectAddEnd(f)
	fCustomOnEffectAddEnd = f;
end

local fCustomOnEffectExpire = nil;
function setCustomOnEffectExpire(f)
	fCustomOnEffectExpire = f;
end

local fCustomOnEffectDragDecode = nil;
function setCustomOnEffectDragDecode(f)
	fCustomOnEffectDragDecode = f;
end

local fCustomOnEffectRollEncode = nil;
function setCustomOnEffectRollEncode(f)
	fCustomOnEffectRollEncode = f;
end

local fCustomOnEffectRollDecode = nil;
function setCustomOnEffectRollDecode(f)
	fCustomOnEffectRollDecode = f;
end

local fCustomOnEffectTextEncode = nil;
function setCustomOnEffectTextEncode(f)
	fCustomOnEffectTextEncode = f;
end

local fCustomOnEffectTextDecode = nil;
function setCustomOnEffectTextDecode(f)
	fCustomOnEffectTextDecode = f;
end

local fCustomOnEffectActorStartTurn = nil;
function setCustomOnEffectActorStartTurn(f)
	fCustomOnEffectActorStartTurn = f;
end

local fCustomOnEffectActorEndTurn = nil;
function setCustomOnEffectActorEndTurn(f)
	fCustomOnEffectActorEndTurn = f;
end

local fCustomOnEffectStartTurn = nil;
function setCustomOnEffectStartTurn(f)
	fCustomOnEffectStartTurn = f;
end

local fCustomOnEffectEndTurn = nil;
function setCustomOnEffectEndTurn(f)
	fCustomOnEffectEndTurn = f;
end

--
-- EFFECT TURN CHANGE HANDLING
--

function processEffects(nodeCurrentActor, nodeNewActor)
Debug.console("manager_effect.lua","processEffects","nodeCurrentActor",nodeCurrentActor);
Debug.console("manager_effect.lua","processEffects","nodeNewActor",nodeNewActor);
        	-- Get sorted combatant list
	local aEntries = CombatManager.getSortedCombatantList();
	if #aEntries == 0 then
		return;
	end
Debug.console("manager_effect.lua","processEffects","aEntries",aEntries);
		
	-- Set up current and new initiative values for effect processing
	local nCurrentInit = -10000;
	if nodeCurrentActor then
		nCurrentInit = DB.getValue(nodeCurrentActor, "initresult", 0); 
	end
	local nNewInit = 10000;
	if nodeNewActor then
		nNewInit = DB.getValue(nodeNewActor, "initresult", 0);
	end
Debug.console("manager_effect.lua","processEffects","nCurrentInit",nCurrentInit);
	
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
Debug.console("manager_effect.lua","processEffects","----------nActive1",nActive);
				if bProcessSpecialStart then
Debug.console("manager_effect.lua","processEffects","bProcessSpecialStart",bProcessSpecialStart);
					if fCustomOnEffectActorStartTurn then
Debug.console("manager_effect.lua","processEffects","fCustomOnEffectActorStartTurn1",fCustomOnEffectActorStartTurn);
						fCustomOnEffectActorStartTurn(nodeActor, nodeEffect);
Debug.console("manager_effect.lua","processEffects","fCustomOnEffectActorStartTurn2",fCustomOnEffectActorStartTurn);
					end
Debug.console("manager_effect.lua","processEffects","1");
				end
Debug.console("manager_effect.lua","processEffects","2");

				if aEffectVarMap["nInit"] then
Debug.console("manager_effect.lua","processEffects","3");
					local nEffInit = DB.getValue(nodeEffect, aEffectVarMap["nInit"].sDBField, aEffectVarMap["nInit"].vDBDefault or 0);

Debug.console("manager_effect.lua","processEffects","nEffInit",nEffInit);
Debug.console("manager_effect.lua","processEffects","nCurrentInit",nCurrentInit);
Debug.console("manager_effect.lua","processEffects","nNewInit",nNewInit);
				
					-- Apply start of effect initiative changes
					if nEffInit < nCurrentInit and nEffInit >= nNewInit then
Debug.console("manager_effect.lua","processEffects","4");
						-- Start turn
						local bHandled = false;
Debug.console("manager_effect.lua","processEffects","5");
						if fCustomOnEffectStartTurn then
Debug.console("manager_effect.lua","processEffects","6");
							bHandled = fCustomOnEffectStartTurn(nodeActor, nodeEffect, nCurrentInit, nNewInit);
						end
Debug.console("manager_effect.lua","processEffects","7");
						if not bHandled and aEffectVarMap["nDuration"] then
Debug.console("manager_effect.lua","processEffects","8");
							local nDuration = DB.getValue(nodeEffect, aEffectVarMap["nDuration"].sDBField, 0);
							if nDuration > 0 then
Debug.console("manager_effect.lua","processEffects","9");
								nDuration = nDuration - 1;
								if nDuration <= 0 then
Debug.console("manager_effect.lua","processEffects","10");
									expireEffect(nodeActor, nodeEffect, 0);
								else
Debug.console("manager_effect.lua","processEffects","11");
									DB.setValue(nodeEffect, "duration", "number", nDuration);
								end
Debug.console("manager_effect.lua","processEffects","12");
							end
Debug.console("manager_effect.lua","processEffects","13");
						end
Debug.console("manager_effect.lua","processEffects","14");
						
					-- Apply end of effect initiative changes
					elseif nEffInit <= nCurrentInit and nEffInit > nNewInit then
Debug.console("manager_effect.lua","processEffects","fCustomOnEffectActorStartTurn",nEffInit);
						if fCustomOnEffectEndTurn then
Debug.console("manager_effect.lua","processEffects","fCustomOnEffectEndTurn",fCustomOnEffectEndTurn);
							bHandled = fCustomOnEffectEndTurn(nodeActor, nodeEffect, nCurrentInit, nNewInit);
Debug.console("manager_effect.lua","processEffects","15");
						end
					end
				end
				
				if bProcessSpecialEnd then
Debug.console("manager_effect.lua","processEffects","bProcessSpecialEnd",bProcessSpecialEnd);
					if fCustomOnEffectActorEndTurn then
Debug.console("manager_effect.lua","processEffects","fCustomOnEffectActorEndTurn",fCustomOnEffectActorEndTurn);
						fCustomOnEffectActorEndTurn(nodeActor, nodeEffect);
Debug.console("manager_effect.lua","processEffects","16");
					end
				end
			end -- END ACTIVE EFFECT CHECK

Debug.console("manager_effect.lua","processEffects","----------nActive2",nActive);

         end -- END EFFECT LOOP
		
		if nodeActor == nodeCurrentActor then
			bProcessSpecialStart = true;
		elseif nodeActor == nodeNewActor then
			bProcessSpecialStart = false;
		end
	end -- END ACTOR LOOP
end

--
-- EFFECT APPLICATION AND EXPIRATION HANDLING
--

function handleApplyEffect(msgOOB)
	-- Get the target combat tracker node
	local nodeCTEntry = DB.findNode(msgOOB.sTargetNode);
	if not nodeCTEntry then
		ChatManager.SystemMessage(Interface.getString("ct_error_effectapplyfail") .. " (" .. msgOOB.sTargetNode .. ")");
		return;
	end
	
	-- Reconstitute the effect details
	local rEffect = {};
	for k,v in pairs(msgOOB) do
		if aEffectVarMap[k] then
			if aEffectVarMap[k].sDBType == "number" then
				rEffect[k] = tonumber(msgOOB[k]) or 0;
			else
				rEffect[k] = msgOOB[k];
			end
		end
	end
	
	-- Apply the effect
	addEffect(msgOOB.user, msgOOB.identity, nodeCTEntry, rEffect, true);
end

function notifyApply(rEffect, vTargets)
	-- Build OOB message to pass effect to host
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYEFF;
	for k,v in pairs(rEffect) do
		if aEffectVarMap[k] then
			if aEffectVarMap[k].sDBType == "number" then
				msgOOB[k] = rEffect[k] or aEffectVarMap[k].vDBDefault or 0;
			else
				msgOOB[k] = rEffect[k] or aEffectVarMap[k].vDBDefault or "";
			end
		end
	end
	if User.isHost() then
		msgOOB.user = "";
	else
		msgOOB.user = User.getUsername();
	end
	msgOOB.identity = User.getIdentityLabel();

	-- Send one message for each target
	if type(vTargets) == "table" then
		for _, v in pairs(vTargets) do
			msgOOB.sTargetNode = v;
			Comm.deliverOOBMessage(msgOOB, "");
		end
	else
		msgOOB.sTargetNode = vTargets;
		Comm.deliverOOBMessage(msgOOB, "");
	end
end

function handleExpireEffect(msgOOB)
	local nodeEffect = DB.findNode(msgOOB.sEffectNode);
	if not nodeEffect then
		ChatManager.SystemMessage(Interface.getString("ct_error_effectdeletefail") .. " (" .. msgOOB.sEffectNode .. ")");
		return;
	end
	local nodeActor = nodeEffect.getChild("...");
	if not nodeActor then
		ChatManager.SystemMessage(Interface.getString("ct_error_effectmissingactor") .. " (" .. msgOOB.sEffectNode .. ")");
		return;
	end
	
	expireEffect(nodeActor, nodeEffect, tonumber(msgOOB.nExpireClause) or 0);
end

function notifyExpire(varEffect, nMatch, bImmediate)
	if type(varEffect) == "databasenode" then
		varEffect = varEffect.getNodeName();
	elseif type(varEffect) ~= "string" then
		return;
	end
	
	if (nLocked > 0) and not bImmediate then
		table.insert(aExpireOnLockRelease, varEffect);
		return;
	end
	
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_EXPIREEFF;
	msgOOB.sEffectNode = varEffect;
	msgOOB.nExpireClause = nMatch;
	
	Comm.deliverOOBMessage(msgOOB, "");
end

function setEffect(nodeEffect, rEffect)
	for k, v in pairs(aEffectVarMap) do
		if v.sDBField then
			local nodeEffectChild = nodeEffect.getChild(v.sDBField);
			if nodeEffectChild then
				nodeEffectChild.setValue(rEffect[k]);
			end
		end
	end
end

function getEffect(nodeEffect)
	local rEffect = {};
	for k, v in pairs(aEffectVarMap) do
		if v.sDBField then
			rEffect[k] = DB.getValue(nodeEffect, v.sDBField, v.vDBDefault);
		end
	end
	return rEffect;
end

function onUntargetedDrop(rEffect)
	for k,v in pairs(rEffect) do
		if aEffectVarMap[k] and aEffectVarMap[k].bClearOnUntargetedDrop then
			rEffect[k] = nil;
		end
	end
end

function onEffectSourceChanged(rEffect, nodeSource)
	for k, v in pairs(aEffectVarMap) do
		if v.sSourceChangeSet then
			if v.sDBType == "number" then
				rEffect[k] = DB.getValue(nodeSource, v.sSourceChangeSet, v.vDBDefault or 0);
			else
				rEffect[k] = DB.getValue(nodeSource, v.sSourceChangeSet, v.vDBDefault or "");
			end
		end
	end
end

function onCTEffectSourceChanged(nodeEffect, nodeSource)
	for k, v in pairs(aEffectVarMap) do
		if v.sSourceChangeSet and v.sDBType and v.sDBField then
			if v.sDBType == "number" then
				DB.setValue(nodeEffect, v.sDBField, v.sDBType, DB.getValue(nodeSource, v.sSourceChangeSet, v.vDBDefault or 0));
			else
				DB.setValue(nodeEffect, v.sDBField, v.sDBType, DB.getValue(nodeSource, v.sSourceChangeSet, v.vDBDefault or ""));
			end
		end
	end
end

--
-- EFFECTS
--

function message(sMsg, nodeCTEntry, bGMOnly, sUser)
	local msg = {font = "msgfont", icon = "roll_effect", text = sMsg};
	if nodeCTEntry then
		msg.text = msg.text .. " [on " .. DB.getValue(nodeCTEntry, "name", "") .. "]";
	end
	
	if sUser then
		if sUser == "" then
			Comm.addChatMessage(msg);
		else
			Comm.deliverChatMessage(msg, sUser);
		end
	elseif bGMOnly then
		msg.secret = true;
		if User.isHost() then
			Comm.addChatMessage(msg);
		else
			Comm.deliverChatMessage(msg, User.getUsername());
		end
	else
		Comm.deliverChatMessage(msg);
	end
end

function getEffectString(nodeEffect, bPublicOnly)
	if DB.getValue(nodeEffect, "isactive", 0) ~= 1 then
		return "";
	end
	
	local sLabel = DB.getValue(nodeEffect, "label", "");

	local bAddEffect = true;
	local bGMOnly = false;
	if sLabel == "" then
		bAddEffect = false;
	elseif DB.getValue(nodeEffect, "isgmonly", 0) == 1 then
		if User.isHost() and not bPublicOnly then
			bGMOnly = true;
		else
			bAddEffect = false;
		end
	end

	if not bAddEffect then
		return "";
	end
	
	local aEffectComps = parseEffect(sLabel);

	if isTargetedEffect(nodeEffect) then
		local sTargets = table.concat(getEffectTargets(nodeEffect, true), ",");
		table.insert(aEffectComps, 1, "[TRGT: " .. sTargets .. "]");
	end
	
	for k,v in pairs(aEffectVarMap) do
		if v.fDisplay then
			local vValue = v.fDisplay(nodeEffect);
			if vValue then
				table.insert(aEffectComps, vValue);
			end
		elseif v.sDisplay and v.sDBField then
			local vDBValue;
			if v.sDBType == "number" then
				vDBValue = DB.getValue(nodeEffect, v.sDBField, v.vDBDefault or 0);
				if vDBValue == 0 then
					vDBValue = nil;
				end
			else
				vDBValue = DB.getValue(nodeEffect, v.sDBField, v.vDBDefault or "");
				if vDBValue == "" then
					vDBValue = nil;
				end
			end
			if vDBValue then
				table.insert(aEffectComps, string.format(v.sDisplay, tostring(vDBValue):upper()));
			end
		end
	end

	local sOutputLabel = rebuildParsedEffect(aEffectComps);
	if bGMOnly then
		sOutputLabel = "(" .. sOutputLabel .. ")";
	end

	return sOutputLabel;
end

function getEffectsString(nodeCTEntry, bPublicOnly)
	local aOutputEffects = {};
	
	-- Iterate through each effect
	local aSorted = {};
	for _,nodeChild in pairs(DB.getChildren(nodeCTEntry, "effects")) do
		table.insert(aSorted, nodeChild);
	end
	table.sort(aSorted, function (a, b) return a.getName() < b.getName() end);
	for _,v in pairs(aSorted) do
		local sEffect = getEffectString(v, bPublicOnly);
		if sEffect ~= "" then
			table.insert(aOutputEffects, sEffect);
		end
	end
	
	return table.concat(aOutputEffects, " | ");
end

function isGMEffect(nodeActor, nodeEffect)
	if nodeEffect and (DB.getValue(nodeEffect, "isgmonly", 0) == 1) then
		return true;
	end
	if nodeActor and CombatManager.isCTHidden(nodeActor) then
		return true;
	end
	return false;
end

function removeEffect(nodeCTEntry, sEffPatternToRemove)
	if not sEffPatternToRemove then
		return;
	end
	for _,nodeEffect in pairs(DB.getChildren(nodeCTEntry, "effects")) do
		if DB.getValue(nodeEffect, "label", ""):match(sEffPatternToRemove) then
			nodeEffect.delete();
			return;
		end
	end
end

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
	DB.setValue(nodeEffect, "isactive", "number", 1);

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

function parseEffect(sEffect)
	local aEffectComps = {};
	for s in sEffect:gmatch("([^;]*);?") do
		local sTrim = StringManager.trim(s);
		if sTrim ~= "" then
			table.insert(aEffectComps, sTrim);
		end
	end
	return aEffectComps;
end

function rebuildParsedEffect(aEffectComps)
	return table.concat(aEffectComps, "; ");
end

function expireEffect(nodeActor, nodeEffect, nExpireComp)
--Debug.console("manager_effect.lua","expireEffect","expireEffect");
	if not nodeEffect then
		return false;
	end
	
	local bGMOnly = isGMEffect(nodeActor, nodeEffect);

	if fCustomOnEffectExpire then
		local sExpirationMsg = fCustomOnEffectExpire(nodeEffect, nExpireComp or 0);
		if sExpirationMsg then
			message(sExpirationMsg, nodeActor, bGMOnly);
			return true;
		end
	end

	local sEffect = DB.getValue(nodeEffect, "label", "");

	-- Check for partial expiration
	if (nExpireComp or 0) > 0 then
		local aEffectComps = parseEffect(sEffect);
		if #aEffectComps > 1 then
			table.remove(aEffectComps, nExpireComp);
			DB.setValue(nodeEffect, "label", "string", rebuildParsedEffect(aEffectComps));
			message("Effect ['" .. sEffect .. "'] -> [SINGLE MOD USED]", nodeActor, bGMOnly);
			return true;
		end
	end
	
	-- Process full expiration
	nodeEffect.delete();
	message("Effect ['" .. sEffect .. "'] -> [EXPIRED]", nodeActor, bGMOnly);
	return true;
end

function disableEffect(nodeActor, nodeEffect)
	if not nodeEffect then
		return false;
	end

	local sEffect = DB.getValue(nodeEffect, "label", "");
	local bGMOnly = isGMEffect(nodeActor, nodeEffect);
	
	DB.setValue(nodeEffect, "isactive", "number", 2);
	message("Effect ['" .. sEffect .. "'] -> [DISABLED]", nodeActor, bGMOnly);
end

--
--  HANDLE EFFECT LOCKING
--

function lock()
	nLocked = nLocked + 1;
end

function unlock()
	nLocked = nLocked - 1;
	if nLocked < 0 then
		nLocked = 0;
	end

	if nLocked == 0 then
		local aExpired = {};
		for _,v in ipairs(aExpireOnLockRelease) do
			if not aExpired[v] then
				EffectManager.notifyExpire(v, 0, true);
				aExpired[v] = true;
			end
		end
		aExpireOnLockRelease = {};
	end
end

--
-- EFFECT TARGETING
--

function setEffectSource(nodeEffect, nodeCT)
	if not nodeCT then
		return;
	end
	local nodeEffectActor = DB.getChild(nodeEffect, "...");
	if not nodeEffectActor then
		return;
	end
	
	local sSourcePath = nodeCT.getPath();
	if nodeEffectActor.getPath() == sSourcePath then
		DB.setValue(nodeEffect, "source_name", "string", "");
		nodeCT = nil;
	else
		DB.setValue(nodeEffect, "source_name", "string", sSourcePath);
	end
	
	onCTEffectSourceChanged(nodeEffect, nodeCT);
end

function isTargetedEffect(nodeEffect)
	return (DB.getChildCount(nodeEffect, "targets") > 0);
end

function isEffectTarget(nodeEffect, rTarget)
	local bMatch = false;
	
	local sTargetCT = ActorManager.getCTNodeName(rTarget);
	if sTargetCT ~= "" then
		for _,v in pairs(DB.getChildren(nodeEffect, "targets")) do
			if DB.getValue(v, "noderef", "") == sTargetCT then
				bMatch = true;
				break;
			end
		end
	end

	return bMatch;
end

function getEffectTargets(nodeEffect, bUseName)
	local aTargets = {};
	
	for _,nodeTarget in pairs(DB.getChildren(nodeEffect, "targets")) do
		local sNode = DB.getValue(nodeTarget, "noderef", "");
		if bUseName then
			local nodeTargetCT = DB.findNode(sNode);
			table.insert(aTargets, DB.getValue(nodeTargetCT, "name", ""));
		else
			table.insert(aTargets, sNode);
		end
	end

	return aTargets;
end

function addEffectTarget(vEffect, sTargetNode)
	if sTargetNode == "" then
		return;
	end
	
	local nodeTargetList = nil;
	if type(vEffect) == "string" then
		nodeTargetList = DB.createChild(DB.findNode(vEffect), "targets");
	elseif type(vEffect) == "databasenode" then
		nodeTargetList = DB.createChild(vEffect, "targets");
	end
	if not nodeTargetList then
		return;
	end
	
	for _,nodeTarget in pairs(nodeTargetList.getChildren()) do
		if (DB.getValue(nodeTarget, "noderef", "") == sTargetNode) then
			return;
		end
	end

	local nodeNewTarget = nodeTargetList.createChild();
	if nodeNewTarget then
		DB.setValue(nodeNewTarget, "noderef", "string", sTargetNode);
	end
end

function setEffectFactionTargets(nodeEffect, sFaction, bNegated)
	if not nodeEffect then
		return;
	end
	
	clearEffectTargets(nodeEffect);
	
	for _,nodeCT in pairs(DB.getChildren(CombatManager.CT_LIST)) do
		if bNegated then
			if DB.getValue(nodeCT, "friendfoe", "") ~= sFaction then
				addEffectTarget(nodeEffect, nodeCT.getNodeName());
			end
		else
			if DB.getValue(nodeCT, "friendfoe", "") == sFaction then
				addEffectTarget(nodeEffect, nodeCT.getNodeName());
			end
		end
	end
end

function clearEffectTargets(nodeEffect)
	for _,nodeTarget in pairs(DB.getChildren(nodeEffect, "targets")) do
		nodeTarget.delete();
	end
end

--
-- HELPER FUNCTIONS
--

function decodeEffectFromDrag(draginfo, rTarget)
	local rEffect = nil;
	
	local sDragType = draginfo.getType();
	local sDragDesc = "";

	local bEffectDrag = false;
	if sDragType == "effect" then
		bEffectDrag = true;
		sDragDesc = draginfo.getStringData();
	elseif sDragType == "number" then
		if sDragDesc:match("%[" .. EFFECT_TAG) then
			bEffectDrag = true;
			sDragDesc = draginfo.getDescription();
		end
	end
	
	if bEffectDrag then
		rEffect = decodeEffectFromText(sDragDesc, draginfo.getSecret());
		if rEffect then
			if aEffectVarMap["nDuration"] then
				rEffect.nDuration = draginfo.getNumberData();
			end
			if fCustomOnEffectDragDecode then
				fCustomOnEffectDragDecode(draginfo, rEffect);
			end
			if not rTarget then
				onUntargetedDrop(rEffect);
			end
		end
	end
	
	return rEffect;
end

function encodeEffect(rAction)
	local rRoll = {};
	rRoll.sType = "effect";
	rRoll.sDesc = encodeEffectAsText(rAction);
	if rAction.nGMOnly then
		rRoll.bSecret = (rAction.nGMOnly ~= 0);
	end
	if aEffectVarMap["nDuration"] then
		rRoll.aDice = rAction.aDice or {};
		rRoll.nMod = rAction.nDuration or 0;
	end
	if fCustomOnEffectRollEncode then
		fCustomOnEffectRollEncode(rRoll, rAction);
	end
	return rRoll;
end

function decodeEffect(rRoll)
	local rEffect = decodeEffectFromText(rRoll.sDesc, rRoll.bSecret);
	if aEffectVarMap["nDuration"] then
		rEffect.aDice = rRoll.aDice;
		rEffect.nMod = rRoll.nMod;
		rEffect.nDuration = ActionsManager.total(rRoll);
	end
	if rEffect and fCustomOnEffectRollDecode then
		fCustomOnEffectRollDecode(rRoll, rEffect);
	end
	return rEffect;
end

function encodeEffectAsText(rEffect)
	local aMessage = {};
	
	if rEffect then
		table.insert(aMessage, "[" .. EFFECT_TAG .. "] " .. rEffect.sName);

		if fCustomOnEffectTextEncode then
			local sEncode = fCustomOnEffectTextEncode(rEffect);
			if sEncode ~= "" then
				table.insert(aMessage, sEncode);
			end
		end

		if aEffectVarMap["nInit"] and rEffect.nInit and rEffect.nInit ~= 0 then
			table.insert(aMessage, "[INIT " .. rEffect.nInit .. "]");
		end
		
		if rEffect.sSource and rEffect.sSource ~= "" then
			table.insert(aMessage, "[by " .. rEffect.sSource .. "]");
		end
	end
	
	return table.concat(aMessage, " ");
end

function decodeEffectFromText(sEffect, bSecret)
	local rEffect = {};

	local s = sEffect;
	if fCustomOnEffectTextDecode then
		s = fCustomOnEffectTextDecode(s, rEffect);
	end

	rEffect.sSource = sEffect:match("%[by ([^]]+)%]") or "";
	s = s:gsub("%[by ([^]]+)%]", "");
	
	if aEffectVarMap["nInit"] then
		local sEffectInit = sEffect:match("%[INIT (%d+)%]");
		if sEffectInit then
			s = s:gsub("%[INIT (%d+)%]", "");
			rEffect.nInit = tonumber(sEffectInit) or 0;
		end
	end

	s = s:gsub("^%[" .. EFFECT_TAG .. "%] ", "");
	s = StringManager.trim(s);
	
	if s == "" then
		return nil;
	end
		
	rEffect.sName = s;
	if bSecret then
		rEffect.nGMOnly = 1;
	else
		rEffect.nGMOnly = 0;
	end

	return rEffect;
end

function onEffectFilter(w)
	local node = w.getDatabaseNode();
	if DB.getValue(node, "isgmonly", 0) == 1 then
		return false;
	end
	if not DB.isOwner(node) then
		if DB.getValue(node, "isactive", 1) == 0 then
			return false;
		end
	end
	return true;
end

function manager_effect_processEffects(nodeCurrentActor, nodeNewActor)
--Debug.console("manager_effect_CoreRPG.lua","manager_effect_processEffects","nodeCurrentActor",nodeCurrentActor);
--Debug.console("manager_effect_CoreRPG.lua","manager_effect_processEffects","nodeNewActor",nodeNewActor);
        	-- Get sorted combatant list
	local aEntries = CombatManager.getSortedCombatantList();
	if #aEntries == 0 then
		return;
	end
		
	-- Set up current and new initiative values for effect processing
	local nCurrentInit = 10000;
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
					local nEffInit = DB.getValue(nodeEffect, aEffectVarMap["nInit"].sDBField, aEffectVarMap["nInit"].vDBDefault or 0);

--Debug.console("manager_effect_CoreRPG.lua","manager_effect_processEffects","nEffInit",nEffInit);
--Debug.console("manager_effect_CoreRPG.lua","manager_effect_processEffects","nCurrentInit",nCurrentInit);
--Debug.console("manager_effect_CoreRPG.lua","manager_effect_processEffects","nNewInit",nNewInit);
				
					-- Apply start of effect initiative changes
					if nEffInit > nCurrentInit and nEffInit <= nNewInit then
--Debug.console("manager_effect_CoreRPG.lua","manager_effect_processEffects","Apply start of effect initiative changes");
						-- Start turn
						local bHandled = false;
						if fCustomOnEffectStartTurn then
							bHandled = EffectManager.fCustomOnEffectStartTurn(nodeActor, nodeEffect, nCurrentInit, nNewInit);
						end
						if not bHandled and aEffectVarMap["nDuration"] then
							local nDuration = DB.getValue(nodeEffect, aEffectVarMap["nDuration"].sDBField, 0);
							if nDuration > 0 then
								nDuration = nDuration - 1;
--Debug.console("manager_effect_CoreRPG.lua","manager_effect_processEffects","nDuration",nDuration);
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
