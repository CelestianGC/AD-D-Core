-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onFactionChanged();
	onHealthChanged();
end

function updateDisplay()
	local sFaction = friendfoe.getStringValue();

	local sOptCTSI = OptionsManager.getOption("CTSI");
	local bShowInit = ((sOptCTSI == "friend") and (sFaction == "friend")) or (sOptCTSI == "on");
	initresult.setVisible(bShowInit);
	
	if active.getValue() == 1 then
		name.setFont("sheetlabel");

		active_spacer_top.setVisible(true);
		active_spacer_bottom.setVisible(true);
		
		if sFaction == "friend" then
			setFrame("ctentrybox_friend_active");
		elseif sFaction == "neutral" then
			setFrame("ctentrybox_neutral_active");
		elseif sFaction == "foe" then
			setFrame("ctentrybox_foe_active");
		else
			setFrame("ctentrybox_active");
		end

		windowlist.scrollToWindow(self);
	else
		name.setFont("sheettext");

		active_spacer_top.setVisible(false);
		active_spacer_bottom.setVisible(false);
		
		if sFaction == "friend" then
			setFrame("ctentrybox_friend");
		elseif sFaction == "neutral" then
			setFrame("ctentrybox_neutral");
		elseif sFaction == "foe" then
			setFrame("ctentrybox_foe");
		else
			setFrame("ctentrybox");
		end
	end
end

function onActiveChanged()
	updateDisplay();
end

function onFactionChanged()
	updateHealthDisplay();
	updateDisplay();
end

function onTypeChanged()
	updateHealthDisplay();
end

function onHealthChanged()
	local sColor = ActorManager2.getWoundColor("ct", getDatabaseNode());
	
	wounds.setColor(sColor);
	status.setColor(sColor);
end

function updateHealthDisplay()
	local sOption;
	if friendfoe.getStringValue() == "friend" then
		sOption = OptionsManager.getOption("SHPC");
	else
		sOption = OptionsManager.getOption("SHNPC");
	end
	
	if sOption == "detailed" then
		hptotal.setVisible(true);
		hptemp.setVisible(true);
		wounds.setVisible(true);

		status.setVisible(false);
	elseif sOption == "status" then
		hptotal.setVisible(false);
		hptemp.setVisible(false);
		wounds.setVisible(false);

		status.setVisible(true);
	else
		hptotal.setVisible(false);
		hptemp.setVisible(false);
		wounds.setVisible(false);

		status.setVisible(false);
	end
end

