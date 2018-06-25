-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
  updateDisplay();
end

function onCasterTypeChanged()
  updateDisplay();
end

function updateDisplay()
  local sCasterType = castertype.getStringValue();
  local bSpells = (sCasterType == "memorization");
  
  groupuses_label.setVisible(not bSpells);
  uses.setVisible(not bSpells);
  usesperiod.setVisible(not bSpells);
  
  groupprepared_label.setVisible(bSpells);
  prepared.setVisible(bSpells);
end
