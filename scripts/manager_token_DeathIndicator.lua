function onInit()
	OptionsManager.registerOption2("COMBAT_SHOW_RIP", false, "option_header_combat", "option_label_RIP", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("COMBAT_SHOW_RIP_DM", false, "option_header_combat", "option_label_RIP_DM", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
  
  CombatManager.addCombatantFieldChangeHandler("wounds", "onUpdate", updateHealth);
	DB.addHandler("options.COMBAT_SHOW_RIP", "onUpdate", TokenManager.onOptionChanged);
	DB.addHandler("options.COMBAT_SHOW_RIP_DM", "onUpdate", TokenManager.onOptionChanged);  
end

-- various updates thanks to suggestions from Andraax
function updateHealth(nodeField)
	local nodeCT = nodeField.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	-- Percent Damage, Status String, Wound Color
	local pDmg, pStatus, sColor = TokenManager2.getHealthInfo(nodeCT);
	-- show rip on tokens
	local bOptionShowRIP = OptionsManager.isOption("COMBAT_SHOW_RIP", "on");
	local bOptionShowRIP_DM = OptionsManager.isOption("COMBAT_SHOW_RIP_DM", "on");
	-- new stuff, adds indicator for "DEAD" on the token. -celestian
	local widgetDeathIndicator = tokenCT.findWidget("deathindicator");
	local nWidth, nHeight = tokenCT.getSize();
	local sName = DB.getValue(nodeCT,"name","Unknown");
	local sDeathTokenName = "token_dead";
  -- sDeathTokenName = sDeathTokenName .. tostring(math.random(5)); -- creates token_dead0,token_dead1,token_dead2,token_dead3,token_dead4,token_dead5 string
  -- figure out if this is a pc token
  local rActor = ActorManager.getActorFromCT(nodeCT);
  local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);    
  if sActorType == "pc" then
    sDeathTokenName = "token_dead_pc";
  end
	-- display if health 0 or lower and option on
	local bPlayDead = ((pDmg >= 1) and (bOptionShowRIP));
	if User.isHost() then
		bPlayDead = ((pDmg >= 1) and (bOptionShowRIP_DM));
	end
  
	if not widgetDeathIndicator then
		widgetDeathIndicator = tokenCT.addBitmapWidget(sDeathTokenName);
		widgetDeathIndicator.setBitmap(sDeathTokenName);
		widgetDeathIndicator.setName("deathindicator");
		widgetDeathIndicator.setTooltipText(sName .. " has fallen, as if dead.");
		widgetDeathIndicator.setSize(nWidth-20, nHeight-20);
	end
	widgetDeathIndicator.setVisible(bPlayDead);
end
