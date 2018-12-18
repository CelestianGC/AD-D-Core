---
---
---

aIgnoredWindowClasses = {};

function onInit()
  -- set default window classes we dont only want singles for
  setIgnoredWindowClasses({"imagewindow","charsheet"});
  
  -- uncomment this and everytime a window is opened
  -- the combat tracker will be moved ontop.
  --Interface.onWindowOpened = ctOnTopAlways;
  
  -- assign handlers
  Interface.onWindowOpened = onWindowOpened; 
  Interface.onWindowClosed = onWindowClosed; 
end

-- keep the combat tracker on top all the time
-- this isn't used right now... 
function ctOnTopAlways(window)
  if User.isHost() then
    if Interface.findWindow("combattracker_host", "combattracker") then
      Interface.findWindow("combattracker_host", "combattracker").bringToFront();
    end
  else
    if Interface.findWindow("combattracker_client", "combattracker") then
      Interface.findWindow("combattracker_client", "combattracker").bringToFront();
    end
  end
end

--[[
  datastructure:

  classname  
    -> node path
    -> node path
    -> node path
    -> ...
]]--
local gOpenWindowList = {}; 

-- see if there is a collection of this type of window
function oneWindowGroupExists(sClassName)
  return gOpenWindowList[sClassName];
end

-- let extensions tweak this if they like
function setIgnoredWindowClasses(aList)
  aIgnoredWindowClasses = {"masterindex"}; -- we always ignore this
  for _,sIgnoredClass in pairs(aList) do
    table.insert(aIgnoredWindowClasses,sIgnoredClass);
  end
end
-- any window class in "aIgnoredWindowClasses" array will not be singlewindowed
function ignoredWindowClass(sClassName)
  local bIgnored = false;
  for _,sIgnoredClass in pairs(aIgnoredWindowClasses) do
    if sClassName == sIgnoredClass then
      bIgnored = true;
      break;
    end
  end
  return bIgnored;
end
-- WARNING: Race issue can occur if windows are opened in fast successon (automated opening)
function onWindowOpened(window)
  local dbNode = window.getDatabaseNode(); 
  local sClassName = window.getClass(); 
  local tClassNodes = gOpenWindowList[sClassName]; 
  local sNodePath = nil; 

--Debug.console("windowmanager.lua","onWindowOpened","dbNode",dbNode); 
--Debug.console("windowmanager.lua","onWindowOpened","sClassName",sClassName); 
--Debug.console("windowmanager.lua","onWindowOpened","tClassNodes",tClassNodes); 

  -- if the window had no database node attached, we don't care about it (currently)
--Debug.console("windowmanager.lua","onWindowOpened",'Windowclass opened: ' .. tostring(sClassName)); 
  if dbNode then
    tClassNodes = gOpenWindowList[sClassName]; 
    -- ignore masterindex
    --if sClassName == 'masterindex' then return; end
    if ignoredWindowClass(sClassName) then return; end

    if gOpenWindowList[sClassName] then
      -- find last entry and get the node path, this must exist, if it doesn't then we didn't delete properly
      sNodePath = tClassNodes[#tClassNodes]; 
      local wndOther = Interface.findWindow(sClassName,sNodePath); 
      if wndOther then
        sNodePath = dbNode.getPath(); 
        table.insert(tClassNodes,sNodePath); 
        window.setPosition(wndOther.getPosition());
        window.setSize(wndOther.getSize());
        -- if control down, we don't close current open windows of this class
        -- else we close them
        if not Input.isControlPressed() then
          -- due to async issues, we're going to process the delete immediately
          onWindowClosed(wndOther); 
          wndOther.close(); 
        end
      else
        Debug.console('BAD NODE: node: (' .. sNodePath .. ') class: (' .. sClassName .. ') is not open! purging node!! [PURGING]'); 
        table.remove(tClassNodes,#tClassNodes); 
        if #tClassNodes == 0 then
          -- remove class from open window list (we have none of that window class open)
          Debug.console('removing class index: (' .. sClassName .. ') [PURGING]'); 
          gOpenWindowList[sClassName] = nil; 
        end
      end
    else
      -- create a new classnode list at this key
      sNodePath = dbNode.getPath(); 
--Debug.console("windowmanager.lua","onWindowOpened",'creating new class index (' .. sClassName ..')'); 
      tClassNodes = {}; 
--Debug.console("windowmanager.lua","onWindowOpened",'creating new node (' .. sNodePath .. ') @ ( ' .. sClassName .. ' ) '); 
      table.insert(tClassNodes, sNodePath); 
      gOpenWindowList[sClassName] = tClassNodes; 
    end
  end
end

function onWindowClosed(window)
  local dbNode = window.getDatabaseNode(); 
  local sClassName = window.getClass(); 
  local tClassNodes = gOpenWindowList[sClassName]; 
  local sNodePath = nil; 

--Debug.console("windowmanager.lua","onWindowClosed","dbNode",dbNode); 
--Debug.console("windowmanager.lua","onWindowClosed","sClassName",sClassName); 
--Debug.console("windowmanager.lua","onWindowClosed","tClassNodes",tClassNodes); 

  -- remove from the tClassNodes the current window node, if that leaves the list empty, delete the key to that list
  if dbNode then
    local sNodePath = dbNode.getPath(); 
    if tClassNodes ~= nil then
      for i = #tClassNodes,1,-1 do
        if tClassNodes[i] == sNodePath then
          --Debug.console('removing classnode: (' .. sNodePath .. ') @ (' .. sClassName .. ')'); 
          table.remove(tClassNodes,i); 
          break; 
        end
      end
      if #tClassNodes == 0 then
        -- remove class from open window list (we have none of that window class open)
        --Debug.console('removing class index: (' .. sClassName .. ')'); 
        gOpenWindowList[sClassName] = nil; 
      end
    end
  end
end
