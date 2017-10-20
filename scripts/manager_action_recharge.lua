-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerResultHandler("recharge", onRecharge);
end

function performRoll(draginfo, rActor, sRecharge, nRecharge, bGMOnly, nodeEffect)
	local rRoll = {};
	rRoll.sType = "recharge";
	rRoll.aDice = { "d6" };
	rRoll.nMod = 0;
	
	rRoll.sDesc = "[RECHARGE " .. nRecharge .. "+] " .. sRecharge;

	rRoll.bSecret = bGMOnly;
	
	if nodeEffect then
		rRoll.sEffectRecord = nodeEffect.getNodeName();
	end
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function onRecharge(rSource, rTarget, rRoll)
	-- Validate
	if not User.isHost() then
		ChatManager.SystemMessage(Interface.getString("ct_error_rechargeclient"));
		return;
	end
	
	-- Create basic message
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	-- Determine target effect
	local nodeTargetEffect = nil;
	if rRoll.sEffectRecord and rRoll.sEffectRecord ~= "" then
		nodeTargetEffect = DB.findNode(rRoll.sEffectRecord);
	end
	
	-- If target effect found, then check for recharge
	if nodeTargetEffect then
		-- Check the effect components
		local sEffectName = DB.getValue(nodeTargetEffect, "label", "");
		local aEffectComps = EffectManager.parseEffect(sEffectName);
		local nRecharge = nil;
		local sRecharge = "";
		for i = 1, #aEffectComps do
			local rEffectComp = EffectManager5E.parseEffectComp(aEffectComps[i]);
			if rEffectComp.type == "RCHG" then
				nRecharge = rEffectComp.mod;
				sRecharge = table.concat(rEffectComp.remainder, " ");
				break;
			end
		end
		
		-- Check for successful recharge
		local nTotal = ActionsManager.total(rRoll);
		if nRecharge and nTotal >= nRecharge then
			-- Add notification
			rMessage.text = rMessage.text .. " [RECHARGED]";
			
			-- Delete effect
			local nodeEffectsList = nodeTargetEffect.getParent();
			nodeTargetEffect.delete();

			-- Remove the [USED] marker from attack line
			for _, nodeAttack in pairs(DB.getChildren(nodeEffectsList, "..actions")) do
				local sAttack = DB.getValue(nodeAttack, "value", "");
				local rPower = CombatManager2.parseAttackLine(sAttack);
				if rPower and rPower.sUsage and rPower.name == sRecharge then
					local sNew = string.sub(sAttack, 1, rPower.nUsageStart - 2) .. string.sub(sAttack, rPower.nUsageEnd + 1);
					DB.setValue(nodeAttack, "value", "string", sNew);
				end
			end
		end
	end

	-- Deliver message
	Comm.deliverChatMessage(rMessage);
end
