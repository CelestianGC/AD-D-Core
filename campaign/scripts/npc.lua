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
  onIDChanged();
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

function onIDChanged()
  onNameUpdated();
  if header.subwindow then
    header.subwindow.updateIDState();
  end
  if User.isHost() then
    if main_creature.subwindow then
      main_creature.subwindow.update();
    end
  else
    local bID = LibraryData.getIDState("npc", getDatabaseNode(), true);
    tabs.setVisibility(bID);
  end
end

function onNameUpdated()
  local nodeRecord = getDatabaseNode();
  local bID = LibraryData.getIDState("npc", nodeRecord, true);
  
  local sTooltip = "";
  if bID then
    sTooltip = DB.getValue(nodeRecord, "name", "");
    if sTooltip == "" then
      sTooltip = Interface.getString("library_recordtype_empty_npc")
    end
  else
    sTooltip = DB.getValue(nodeRecord, "nonid_name", "");
    if sTooltip == "" then
      sTooltip = Interface.getString("library_recordtype_empty_nonid_npc")
    end
  end
  setTooltipText(sTooltip);
end
