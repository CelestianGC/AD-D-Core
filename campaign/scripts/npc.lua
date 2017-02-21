-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	CampaignDataManager2.updateNPCSpells(getDatabaseNode());
end

function onLockChanged()
	StateChanged();
end

function StateChanged()
	if header.subwindow then
		header.subwindow.update();
	end
	if main_creature.subwindow then
		main_creature.subwindow.update();
	end

	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
	text.setReadOnly(bReadOnly);
end
