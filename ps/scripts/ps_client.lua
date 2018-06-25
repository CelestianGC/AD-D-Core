-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
  OptionsManager.registerCallback("PSMN", onOptionChanged);
  onOptionChanged();
end

function onClose()
  OptionsManager.unregisterCallback("PSMN", onOptionChanged);
end

function onOptionChanged()
  local aTabs = {};
  if OptionsManager.isOption("PSMN", "on") then
    table.insert(aTabs, { sub = "main", graphic = "tab_main" });
  end
  table.insert(aTabs, { sub = "inventory", graphic = "tab_inventory" });
  table.insert(aTabs, { sub = "order", graphic = "tab_order" });
  
  for i = 1, 4 do
    if aTabs[i] then
      tabs.setTab(i, aTabs[i].sub, aTabs[i].graphic);
    else
      tabs.setTab(i);
    end
  end
end
