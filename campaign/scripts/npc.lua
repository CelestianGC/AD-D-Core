-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
  CampaignDataManager2.updateNPCSpells(getDatabaseNode());
  local sPowerMode = DB.getValue(getDatabaseNode(),"powermode","");
  if (sPowerMode and sPowerMode == "") then 
    DB.setValue(getDatabaseNode(),"powermode","string","standard");
  end
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
