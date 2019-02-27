---
--- Various utility functions
---
---

function onInit()
end

function onClose()
end

-- replace oldWindow with a new window of sClass type
function replaceWindow(oldWindow, sClass, sNodePath)
--Debug.console("manager_utilities_adnd.lua","replaceWindow","oldWindow",oldWindow);
  local x,y = oldWindow.getPosition();
  local w,h = oldWindow.getSize();
  -- Close here otherwise you just close the one you just made since paths are the same at times (drag/drop inline replace item/npc)
  oldWindow.close(); 
  --
  local wNew = Interface.openWindow(sClass, sNodePath);
  wNew.setPosition(x,y);
  wNew.setSize(w,h);
end 