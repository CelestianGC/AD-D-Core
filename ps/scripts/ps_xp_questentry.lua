-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if User.isHost() then
		registerMenuItem(Interface.getString("ps_menu_awardxp"), "deletealltokens", 3);
	end
end

function onMenuSelection(selection, subselection)
	if selection == 3 then
		PartyManager2.awardQuestsToParty(getDatabaseNode());
	end
end
