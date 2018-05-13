-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local sNode = getDatabaseNode().getNodeName();
	DB.addHandler(sNode, "onChildUpdate", onDataChanged);
	onDataChanged();
end

function onClose()
	local sNode = getDatabaseNode().getNodeName();
	DB.removeHandler(sNode, "onChildUpdate", onDataChanged);
end

function onDataChanged()
	updateDisplay();
	updateViews();
end

function updateDisplay()
	local sType = DB.getValue(getDatabaseNode(), "type", "");
	
	if sType == "cast" then
		button.setIcons("button_roll", "button_roll_down");
	elseif sType == "damage" then
		button.setIcons("button_action_damage", "button_action_damage_down");
	elseif sType == "heal" then
		button.setIcons("button_action_heal", "button_action_heal_down");
	elseif sType == "effect" then
		button.setIcons("button_action_effect", "button_action_effect_down");
	elseif sType == "damage_psp" then
		button.setIcons("button_action_damage_psp", "button_action_damage_down_psp");
	elseif sType == "heal_psp" then
		button.setIcons("button_action_heal_psp", "button_action_heal_down_psp");
	end
end

function updateViews()
	local sType = DB.getValue(getDatabaseNode(), "type", "");
	
	if sType == "cast" then
		onCastChanged();
	elseif sType == "damage" then
		onDamageChanged();
	elseif sType == "heal" then
		onHealChanged();
	elseif sType == "effect" then
		onEffectChanged();
	elseif sType == "damage_psp" then
		onDamagePSPChanged();
	elseif sType == "heal_psp" then
		onHealPSPChanged();
	end
end

function onCastChanged()
	local nodeAction = getDatabaseNode();
	if not nodeAction then
		return;
	end
	local rActor = ActorManager.getActor("", nodeAction.getChild("....."));
	
	local sAttack = "";
	local sAttackType = DB.getValue(nodeAction, "atktype", "");
	if sAttackType == "melee" then
		sAttack = "ATK: Melee";
	elseif sAttackType == "ranged" then
		sAttack = "ATK: Ranged";
	elseif sAttackType == "psionic" then
		sAttack = "ATK: Psionic";
	end

	if sAttack ~= "" then
		local nGroupMod, sGroupStat = PowerManager.getGroupAttackBonus(rActor, nodeAction, "");
		
		local nAttackMod = 0;
		local sAttackBase = DB.getValue(nodeAction, "atkbase", "");
		if sAttackBase == "fixed" then
			nAttackMod = DB.getValue(nodeAction, "atkmod", 0);
		elseif sAttackBase == "ability" then
			local sAbility = DB.getValue(nodeAction, "atkstat", "");
			if sAbility == "base" then
				sAbility = sGroupStat;
			end
			local nAttackProf = DB.getValue(nodeAction, "atkprof", 1);
			
			nAttackMod = ActorManager2.getAbilityBonus(rActor, sAbility, "hitadj") + DB.getValue(nodeAction, "atkmod", 0);
			if nAttackProf == 1 then
				nAttackMod = nAttackMod + DB.getValue(ActorManager.getCreatureNode(rActor), "profbonus", 0);
			end
		else
			nAttackMod = nGroupMod + DB.getValue(nodeAction, "atkmod", 0);
		end

		if nAttackMod ~= 0 then
			sAttack = string.format("%s %+d", sAttack, nAttackMod);
		end
	end

	local sSave = "";
	local sSaveType = DB.getValue(nodeAction, "savetype", "");
	if sSaveType ~= "" then
		local nGroupDC, sGroupStat = PowerManager.getGroupSaveDC(rActor, nodeAction, sSaveType);
		if sSaveType == "base" then
			sSaveType = sGroupStat;
		end
		
		local nDC = 0;
		local sSaveBase = DB.getValue(nodeAction, "savedcbase", "");
		if sSaveBase == "fixed" then
			nDC = DB.getValue(nodeAction, "savedcmod", 0);
		elseif sSaveBase == "ability" then
			local sAbility = DB.getValue(nodeAction, "savedcstat", "");
			if sAbility == "base" then
				sAbility = sGroupStat;
			end
			local nSaveProf = DB.getValue(nodeAction, "savedcprof", 1);
			
			nDC = DB.getValue(nodeAction, "savedcmod", 0);
			--nDC = 8 + ActorManager2.getAbilityBonus(rActor, sAbility) + DB.getValue(nodeAction, "savedcmod", 0);
			--if nSaveProf == 1 then
			--	nDC = nDC + DB.getValue(ActorManager.getCreatureNode(rActor), "profbonus", 0);
			--end
		else
			nDC = nGroupDC + DB.getValue(nodeAction, "savedcmod", 0);
		end

--		sSave = "SAVE: " .. StringManager.capitalize(sSaveType:sub(1,3)) .. " DC " .. nDC;
		sSave = "SAVE: " .. StringManager.capitalize(sSaveType) .. " ADJ " .. nDC;
		
		if DB.getValue(nodeAction, "onmissdamage", "") == "half" then
			sSave = sSave .. " (H)";
		end
	end
	
	local sTooltip = "CAST: ";
	if sAttack ~= "" then
		sTooltip = sTooltip .. "\r" .. sAttack;
	end
	if sSave ~= "" then
		sTooltip = sTooltip .. "\r" .. sSave;
	end

	button.setTooltipText(sTooltip);
end

function onDamageChanged()
	local sDamage = PowerManager.getActionDamageText(getDatabaseNode());
	button.setTooltipText("DMG: " .. sDamage);
end

function onHealChanged()
	local sHeal = PowerManager.getActionHealText(getDatabaseNode());
	button.setTooltipText("HEAL: " .. sHeal);
end

function onDamagePSPChanged()
	local sDamage = PowerManager.getActionDamagePSPText(getDatabaseNode());
	button.setTooltipText("PSP DMG: " .. sDamage);
end

function onHealPSPChanged()
	local sHeal = PowerManager.getActionHealPSPText(getDatabaseNode());
	button.setTooltipText("PSP HEAL: " .. sHeal);
end

function onEffectChanged()
	local node = getDatabaseNode();
	if not node then
		return;
	end
	
	local sTooltip = DB.getValue(node, "label", "");

	local sApply = DB.getValue(node, "apply", "");
	if sApply == "action" then
		sTooltip = sTooltip .. "; [ACTION]";
	elseif sApply == "roll" then
		sTooltip = sTooltip .. "; [ROLL]";
	elseif sApply == "single" then
		sTooltip = sTooltip .. "; [SINGLES]";
	end
	
	local sTargeting = DB.getValue(node, "targeting", "");
	if sTargeting == "self" then
		sTooltip = sTooltip .. "; [SELF]";
	end
	
	sTooltip = "EFFECT: " .. sTooltip;
	
	button.setTooltipText(sTooltip);
end


