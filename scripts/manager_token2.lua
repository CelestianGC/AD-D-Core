-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local TOKEN_MAX_EFFECTS = 6;
local TOKEN_EFFECT_WIDTH = 12;
local TOKEN_EFFECT_MARGIN = 2;
local TOKEN_EFFECT_OFFSETX = 6;
local TOKEN_EFFECT_OFFSETY = -6;
local TOKEN_HEALTH_MINBAR = 14;
local TOKEN_HEALTH_WIDTH = 20;

function onInit()
	DB.addHandler("combattracker.list.*.hp", "onUpdate", updateHealth);
	DB.addHandler("combattracker.list.*.hptemp", "onUpdate", updateHealth);
	DB.addHandler("combattracker.list.*.wounds", "onUpdate", updateHealth);

	DB.addHandler("combattracker.list.*.effects", "onChildUpdate", updateEffectsList);
	DB.addHandler("combattracker.list.*.effects.*.isactive", "onAdd", updateEffects);
	DB.addHandler("combattracker.list.*.effects.*.isactive", "onUpdate", updateEffects);
	DB.addHandler("combattracker.list.*.effects.*.isgmonly", "onAdd", updateEffects);
	DB.addHandler("combattracker.list.*.effects.*.isgmonly", "onUpdate", updateEffects);
	DB.addHandler("combattracker.list.*.effects.*.label", "onAdd", updateEffects);
	DB.addHandler("combattracker.list.*.effects.*.label", "onUpdate", updateEffects);

	DB.addHandler("options.TNPCE", "onUpdate", TokenManager.onOptionChanged);
	DB.addHandler("options.TNPCH", "onUpdate", TokenManager.onOptionChanged);
	DB.addHandler("options.TPCE", "onUpdate", TokenManager.onOptionChanged);
	DB.addHandler("options.TPCH", "onUpdate", TokenManager.onOptionChanged);
	DB.addHandler("options.WNDC", "onUpdate", TokenManager.onOptionChanged);
end

function onScaleChanged(tokenCT, nodeCT)
	updateHealthBarScale(tokenCT, nodeCT);
	updateEffectsHelper(tokenCT, nodeCT);
end

function onHover(tokenCT, nodeCT, bOver)
	local sFaction = DB.getValue(nodeCT, "friendfoe", "");

	local sOptEffects, sOptHealth;
	if sFaction == "friend" then
		sOptEffects = OptionsManager.getOption("TPCE");
		sOptHealth = OptionsManager.getOption("TPCH");
	else
		sOptEffects = OptionsManager.getOption("TNPCE");
		sOptHealth = OptionsManager.getOption("TNPCH");
	end
		
	local aWidgets = {};
	if sOptHealth == "barhover" then
		aWidgets["healthbar"] = tokenCT.findWidget("healthbar");
	elseif sOptHealth == "dothover" then
		aWidgets["healthdot"] = tokenCT.findWidget("healthdot");
	end
	if sOptEffects == "hover" or sOptEffects == "markhover" then
		for i = 1, TOKEN_MAX_EFFECTS do
			aWidgets["effect" .. i] = tokenCT.findWidget("effect" .. i);
		end
	end

	for _, vWidget in pairs(aWidgets) do
		vWidget.setVisible(bOver);
	end
end

function updateAttributesHelper(tokenCT, nodeCT)
	updateHealthHelper(tokenCT, nodeCT);
	updateEffectsHelper(tokenCT, nodeCT);
end

function updateTooltip(tokenCT, nodeCT)
	local sOptTNAM = OptionsManager.getOption("TNAM");
	local sOptTH, sOptTE;
	if DB.getValue(nodeCT, "friendfoe", "") == "friend" then
		sOptTE = OptionsManager.getOption("TPCE");
		sOptTH = OptionsManager.getOption("TPCH");
	else
		sOptTE = OptionsManager.getOption("TNPCE");
		sOptTH = OptionsManager.getOption("TNPCH");
	end
		
	local aTooltip = {};
	if sOptTNAM == "tooltip" then
		table.insert(aTooltip, DB.getValue(nodeCT, "name", ""));
	end
	if sOptTH == "tooltip" then
		local sStatus;
		_, sStatus = ActorManager2.getPercentWounded2("ct", nodeCT);
		table.insert(aTooltip, sStatus);
	end
	if sOptTE == "tooltip" then
		local aCondList = getConditionIconList(nodeCT);
		for _,v in ipairs(aCondList) do
			table.insert(aTooltip, v.sLabel);
		end
	end
	
	tokenCT.setName(table.concat(aTooltip, "\r"));
end

function updateFaction(tokenCT, nodeCT)
	updateHealthHelper(tokenCT, nodeCT);
	updateEffectsHelper(tokenCT, nodeCT);
end

function updateHealth(nodeField)
	local nodeCT = nodeField.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		updateHealthHelper(tokenCT, nodeCT);
		updateTooltip(tokenCT, nodeCT);
	end
end

function updateHealthHelper(tokenCT, nodeCT)
	local sOptTH;
	if DB.getValue(nodeCT, "friendfoe", "") == "friend" then
		sOptTH = OptionsManager.getOption("TPCH");
	else
		sOptTH = OptionsManager.getOption("TNPCH");
	end
	
	local aWidgets = getWidgetList(tokenCT, "health");
	
	if sOptTH == "off" or sOptTH == "tooltip" then
		for _, vWidget in pairs(aWidgets) do
			vWidget.destroy();
		end
	else
		local sColor, nPercentWounded, sStatus = ActorManager2.getWoundBarColor("ct", nodeCT);
		
		if sOptTH == "bar" or sOptTH == "barhover" then
			local w, h = tokenCT.getSize();
		
			if h >= TOKEN_HEALTH_MINBAR then
				local widgetHealthBar = aWidgets["healthbar"];
				if not widgetHealthBar then
					widgetHealthBar = tokenCT.addBitmapWidget("healthbar");
					widgetHealthBar.sendToBack();
					widgetHealthBar.setName("healthbar");
				end
				if widgetHealthBar then
					widgetHealthBar.setColor(sColor);
					widgetHealthBar.setTooltipText(sStatus);
					widgetHealthBar.setVisible(sOptTH == "bar");
				end
			end
			updateHealthBarScale(tokenCT, nodeCT);
			
			if aWidgets["healthdot"] then
				aWidgets["healthdot"].destroy();
			end
		elseif sOptTH == "dot" or sOptTH == "dothover" then
			local widgetHealthDot = aWidgets["healthdot"];
			if not widgetHealthDot then
				widgetHealthDot = tokenCT.addBitmapWidget("healthdot");
				widgetHealthDot.setPosition("bottomright", -4, -6);
				widgetHealthDot.setName("healthdot");
			end
			if widgetHealthDot then
				widgetHealthDot.setColor(sColor);
				widgetHealthDot.setTooltipText(sStatus);
				widgetHealthDot.setVisible(sOptTH == "dot");
			end

			if aWidgets["healthbar"] then
				aWidgets["healthbar"].destroy();
			end
		end
	end
    -- new stuff, adds indicator for "DEAD" on the token. -msw
	local nPercentHealth = ActorManager2.getPercentWounded2("ct", nodeCT);
    local widgetDeathIndicator = tokenCT.findWidget("deathindicator");
    local nWidth, nHeight = tokenCT.getSize();
    local sName = DB.getValue(nodeCT,"name","Unknown");
    if not widgetDeathIndicator then
        widgetDeathIndicator = tokenCT.addBitmapWidget("token_dead");
        widgetDeathIndicator.setBitmap("token_dead");
        widgetDeathIndicator.setName("deathindicator");
        widgetDeathIndicator.setTooltipText(sName .. " has fallen, as if dead.");
        widgetDeathIndicator.setSize(nWidth-20, nHeight-20);
    end
    -- nPercentHealth is the percent of damage, 1 = 100% or more so dead
    widgetDeathIndicator.setVisible(nPercentHealth>=1);
    -- end new stuff
end

function updateHealthBarScale(tokenCT, nodeCT)
	local widgetHealthBar = tokenCT.findWidget("healthbar");
	if widgetHealthBar then
		local nPercentWounded = ActorManager2.getPercentWounded2("ct", nodeCT);
		
		local w, h = tokenCT.getSize();
		h = h + 4;

		widgetHealthBar.setSize();
		local barw, barh = widgetHealthBar.getSize();
		
		-- Resize bar to match health percentage, but preserve bulb portion of bar graphic
		if h >= TOKEN_HEALTH_MINBAR then
			barh = (math.max(1.0 - nPercentWounded, 0) * (math.min(h, barh) - TOKEN_HEALTH_MINBAR)) + TOKEN_HEALTH_MINBAR;
		else
			barh = TOKEN_HEALTH_MINBAR;
		end

		widgetHealthBar.setSize(barw, barh, "bottom");
		widgetHealthBar.setPosition("bottomright", -4, -(barh / 2) + 4);
	end
end

function updateEffects(nodeEffectField)
	local nodeEffect = nodeEffectField.getChild("..");
	local nodeCT = nodeEffect.getChild("...");
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		updateEffectsHelper(tokenCT, nodeCT);
		updateTooltip(tokenCT, nodeCT);
	end
end

function updateEffectsList(nodeEffectsList, bListChanged)
	if bListChanged then
		local nodeCT = nodeEffectsList.getParent();
		local tokenCT = CombatManager.getTokenFromCT(nodeCT);
		if tokenCT then
			updateEffectsHelper(tokenCT, nodeCT);
			updateTooltip(tokenCT, nodeCT);
		end
	end
end

function updateEffectsHelper(tokenCT, nodeCT)
	local sOptTE;
	if DB.getValue(nodeCT, "friendfoe", "") == "friend" then
		sOptTE = OptionsManager.getOption("TPCE");
	else
		sOptTE = OptionsManager.getOption("TNPCE");
	end

	local aWidgets = getWidgetList(tokenCT, "effect");
	
	if sOptTE == "off" or sOptTE == "tooltip" then
		for _, vWidget in pairs(aWidgets) do
			vWidget.destroy();
		end
	elseif sOptTE == "mark" or sOptTE == "markhover" then
		local bWidgetsVisible = (sOptTE == "mark");
		
		local aTooltip = {};
		local aCondList = getConditionIconList(nodeCT);
		for _,v in ipairs(aCondList) do
			table.insert(aTooltip, v.sLabel);
		end
		
		if #aTooltip > 0 then
			local w = aWidgets["effect1"];
			if not w then
				w = tokenCT.addBitmapWidget();
				w.setPosition("bottomleft", TOKEN_EFFECT_OFFSETX, TOKEN_EFFECT_OFFSETY);
				w.setName("effect1");
			end
			if w then
				w.setBitmap("cond_generic");
				w.setVisible(bWidgetsVisible);
				w.setTooltipText(table.concat(aTooltip, "\r"));
			end
			for i = 2, TOKEN_MAX_EFFECTS do
				local w = aWidgets["effect" .. i];
				if w then
					w.destroy();
				end
			end
		else
			for i = 1, TOKEN_MAX_EFFECTS do
				local w = aWidgets["effect" .. i];
				if w then
					w.destroy();
				end
			end
		end
	else
		local bWidgetsVisible = (sOptTE == "on");
		
		local aCondList = getConditionIconList(nodeCT);
		local nConds = #aCondList;
		
		local wToken, hToken = tokenCT.getSize();
		local nMaxToken = math.floor(((wToken - TOKEN_HEALTH_WIDTH - TOKEN_EFFECT_MARGIN) / (TOKEN_EFFECT_WIDTH + TOKEN_EFFECT_MARGIN)) + 0.5);
		if nMaxToken < 1 then
			nMaxToken = 1;
		end
		local nMaxShown = math.min(nMaxToken, TOKEN_MAX_EFFECTS);
		
		local i = 1;
		local nMaxLoop = math.min(nConds, nMaxShown);
		while i <= nMaxLoop do
			local w = aWidgets["effect" .. i];
			if not w then
				w = tokenCT.addBitmapWidget();
				w.setPosition("bottomleft", TOKEN_EFFECT_OFFSETX + ((TOKEN_EFFECT_WIDTH + TOKEN_EFFECT_MARGIN) * (i - 1)), TOKEN_EFFECT_OFFSETY);
				w.setName("effect" .. i);
			end
			if w then
				if i == nMaxLoop and nConds > nMaxLoop then
					w.setBitmap("cond_more");
					local aTooltip = {};
					for j = i, nConds do
						table.insert(aTooltip, aCondList[j].sLabel);
					end
					w.setTooltipText(table.concat(aTooltip, "\r"));
				else
					w.setBitmap(aCondList[i].sIcon);
					w.setTooltipText(aCondList[i].sText);
				end
				w.setVisible(bWidgetsVisible);
			end
			i = i + 1;
		end
		while i <= TOKEN_MAX_EFFECTS do
			local w = aWidgets["effect" .. i];
			if w then
				w.destroy();
			end
			i = i + 1;
		end
	end
end

function getConditionIconList(nodeCT)
	local aIconList = {};

	local rActor = ActorManager.getActorFromCT(nodeCT);
	
	-- Iterate through effects
	local aSorted = {};
	for _,nodeChild in pairs(DB.getChildren(nodeCT, "effects")) do
		table.insert(aSorted, nodeChild);
	end
	table.sort(aSorted, function (a, b) return a.getName() < b.getName() end);

	for k,v in pairs(aSorted) do
		if DB.getValue(v, "isactive", 0) == 1 then
			if User.isHost() or (DB.getValue(v, "isgmonly", 0) == 0) then
				local sLabel = DB.getValue(v, "label", "");
				
				local sEffect = nil;
				local bSame = true;
				local sLastIcon = nil;

				local aEffectComps = EffectManager.parseEffect(sLabel);
				for kComp,vComp in ipairs(aEffectComps) do
					-- CHECK CONDITIONALS
					if vComp.type == "IF" then
						if not EffectManager.checkConditional(rActor, v, vComp.remainder) then
							break;
						end
					elseif vComp.type == "IFT" then
						-- Do nothing
					
					else
						local sNewIcon = nil;
						
						-- CHECK FOR A BONUS OR PENALTY
						local sComp = vComp.type;
						if StringManager.contains(DataCommon.bonuscomps, sComp) then
							if #(vComp.dice) > 0 or vComp.mod > 0 then
								sNewIcon = "cond_bonus";
							elseif vComp.mod < 0 then
								sNewIcon = "cond_penalty";
							else
								sNewIcon = "cond_generic";
							end
					
						-- CHECK FOR OTHER VISIBLE EFFECT TYPES
						else
							sNewIcon = DataCommon.othercomps[sComp];
						end
					
						-- CHECK FOR A CONDITION
						if not sNewIcon then
							sComp = vComp.original:lower();
							sNewIcon = DataCommon.condcomps[sComp];
						end
						
						if sNewIcon then
							if bSame then
								if sLastIcon and sLastIcon ~= sNewIcon then
									bSame = false;
								end
								sLastIcon = sNewIcon;
							end
						else
							if kComp == 1 then
								sEffect = vComp.original;
							end
						end
					end
				end
				
				if #aEffectComps > 0 then
					local sFinalIcon;
					if bSame and sLastIcon then
						sFinalIcon = sLastIcon;
					else
						sFinalIcon = "cond_generic";
					end
					
					local sFinalLabel;
					if sEffect then
						sFinalLabel = sEffect;
					else
						sFinalLabel = sLabel;
					end
					
					table.insert(aIconList, { sText = sFinalLabel, sIcon = sFinalIcon, sLabel = sLabel } );
				end
			end
		end
	end
	
	return aIconList;
end

function getWidgetList(tokenCT, sSubset)
	local aWidgets = {};

	local w = nil;
	if not sSubset or sSubset == "health" then
		for _, vName in pairs({"healthbar", "healthdot"}) do
			w = tokenCT.findWidget(vName);
			if w then
				aWidgets[vName] = w;
			end
		end
	end
	if not sSubset or sSubset == "effect" then
		for i = 1, TOKEN_MAX_EFFECTS do
			w = tokenCT.findWidget("effect" .. i);
			if w then
				aWidgets["effect" .. i] = w;
			end
		end
	end
	
	return aWidgets;
end
