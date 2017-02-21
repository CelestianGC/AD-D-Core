-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYSAVE = "applysave";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYSAVE, handleApplySave);

	ActionsManager.registerTargetingHandler("cast", onPowerTargeting);
	ActionsManager.registerTargetingHandler("powersave", onPowerTargeting);
	
	ActionsManager.registerModHandler("castsave", modCastSave);
	ActionsManager.registerModHandler("powersave", modCastSave);
	
	ActionsManager.registerResultHandler("cast", onPowerCast);
	ActionsManager.registerResultHandler("castsave", onCastSave);
	ActionsManager.registerResultHandler("powersave", onPowerSave);
end

function handleApplySave(msgOOB)
	local rSource = ActorManager.getActor(msgOOB.sSourceType, msgOOB.sSourceNode);
	local rTarget = ActorManager.getActor(msgOOB.sTargetType, msgOOB.sTargetNode);
	
	local sSaveShort, sSaveDC = string.match(msgOOB.sDesc, "%[(%w+) DC (%d+)%]")
	if sSaveShort then
		local sSave = DataCommon.ability_stol[sSaveShort];
		if sSave then
			ActionSave.performRoll(nil, rTarget, sSave, msgOOB.nDC, (tonumber(msgOOB.nSecret) == 1), rSource, msgOOB.bRemoveOnMiss, msgOOB.sDesc);
		end
	end
end

function notifyApplySave(rSource, rTarget, bSecret, sDesc, nDC, bRemoveOnMiss)
	if not rTarget then
		return;
	end

	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYSAVE;
	
	if bSecret then
		msgOOB.nSecret = 1;
	else
		msgOOB.nSecret = 0;
	end
	msgOOB.sDesc = sDesc;
	msgOOB.nDC = nDC;

	local sSourceType, sSourceNode = ActorManager.getTypeAndNodeName(rSource);
	msgOOB.sSourceType = sSourceType;
	msgOOB.sSourceNode = sSourceNode;

	local sTargetType, sTargetNode = ActorManager.getTypeAndNodeName(rTarget);
	msgOOB.sTargetType = sTargetType;
	msgOOB.sTargetNode = sTargetNode;

	if bRemoveOnMiss then
		msgOOB.bRemoveOnMiss = 1;
	end

	if ActorManager.getType(rTarget) == "pc" then
		local nodePC = ActorManager.getCreatureNode(rTarget);
		if nodePC then
			if User.isHost() then
				local sOwner = DB.getOwner(nodePC);
				if sOwner ~= "" then
					for _,vUser in ipairs(User.getActiveUsers()) do
						if vUser == sOwner then
							for _,vIdentity in ipairs(User.getActiveIdentities(vUser)) do
								if nodePC.getName() == vIdentity then
									Comm.deliverOOBMessage(msgOOB, sOwner);
									return;
								end
							end
						end
					end
				end
			else
				if DB.isOwner(nodePC) then
					handleApplySave(msgOOB);
					return;
				end
			end
		end
	end

	Comm.deliverOOBMessage(msgOOB, "");
end

function onPowerTargeting(rSource, aTargeting, rRolls)
	if OptionsManager.isOption("RMMT", "multi") then
		local aTargets = {};
		for _,vTargetGroup in ipairs(aTargeting) do
			for _,vTarget in ipairs(vTargetGroup) do
				table.insert(aTargets, vTarget);
			end
		end
		if #aTargets > 1 then
			for _,vRoll in ipairs(rRolls) do
				vRoll.bRemoveOnMiss = "true";
			end
		end
	end
	return aTargeting;
end

function getPowerCastRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "cast";
	rRoll.aDice = {};
	rRoll.nMod = 0;
	
	rRoll.sDesc = "[CAST";
	if rAction.order and rAction.order > 1 then
		rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
	end
	rRoll.sDesc = rRoll.sDesc .. "] " .. rAction.label;
	
	return rRoll;
end

function getSaveVsRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "powersave";
	rRoll.aDice = {};
	rRoll.nMod = rAction.savemod or 0;
	
	rRoll.sDesc = "[SAVE VS";
	if rAction.order and rAction.order > 1 then
		rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
	end
	rRoll.sDesc = rRoll.sDesc .. "] " .. rAction.label;
	if DataCommon.ability_ltos[rAction.save] then
		rRoll.sDesc = rRoll.sDesc .. " [" .. DataCommon.ability_ltos[rAction.save] .. " DC " .. rAction.savemod .. "]";
	end
	if rAction.onmissdamage == "half" then
		rRoll.sDesc = rRoll.sDesc .. " [HALF ON SAVE]";
	end

	return rRoll;
end

function performSaveVsRoll(draginfo, rActor, rAction)
	local rRoll = getSaveVsRoll(rActor, rAction);
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modCastSave(rSource, rTarget, rRoll)
	if ModifierStack.getModifierKey("DEF_SCOVER") then
		rRoll.sDesc = rRoll.sDesc .. " [COVER -5]";
	elseif ModifierStack.getModifierKey("DEF_COVER") then
		rRoll.sDesc = rRoll.sDesc .. " [COVER -2]";
	end
end

function onPowerCast(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.dice = nil;
	rMessage.icon = "roll_cast";

	if rTarget then
		rMessage.text = rMessage.text .. " [at " .. rTarget.sName .. "]";
	end
	
	Comm.deliverChatMessage(rMessage);
end

function onCastSave(rSource, rTarget, rRoll)
	if rTarget then
		local sSaveShort, sSaveDC = string.match(rRoll.sDesc, "%[(%w+) DC (%d+)%]")
		if sSaveShort then
			local sSave = DataCommon.ability_stol[sSaveShort];
			if sSave then
				notifyApplySave(rSource, rTarget, rRoll.bSecret, rRoll.sDesc, rRoll.nMod, rRoll.bRemoveOnMiss);
				return true;
			end
		end
	end

	return false;
end

function onPowerSave(rSource, rTarget, rRoll)
	if onCastSave(rSource, rTarget, rRoll) then
		return;
	end

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);
end
