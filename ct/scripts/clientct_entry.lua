-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
  super.onInit();
  onHealthChanged();
end

function onFactionChanged()
  super.onInit();
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
