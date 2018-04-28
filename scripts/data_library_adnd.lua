-- data library for ad&d core ruleset
--
--
--

function onInit()
  DesktopManager.showDockTitleText(true);
  DesktopManager.setDockTitleFont("sidebar");
  DesktopManager.setDockTitleFrame("", 25, 2, 25, 5);
  DesktopManager.setDockTitlePosition("top", 2, 14);
  DesktopManager.setStackIconSizeAndSpacing(43, 27, 3, 3);
  DesktopManager.setDockIconSizeAndSpacing(100, 24, 0, 6);
  DesktopManager.setLowerDockOffset(2, 0, 2, 0);
    
  -- we don't use either of these types of records in AD&D, so hide them
	LibraryData.setRecordTypeInfo("feat", nil);
	LibraryData.setRecordTypeInfo("vehicle", nil);
  --
  if User.isHost()  then
    Comm.registerSlashHandler("readycheck", processReadyCheck);
    Comm.registerSlashHandler("updateadnd", processUpdateADND);
  end
end

function processReadyCheck(sCommand, sParams)
  if User.isHost() then
    local wWindow = Interface.openWindow("readycheck","");
    if wWindow then
      local aList = ConnectionManagerADND.getUserLoggedInList();
      -- share this window with every person connected.
      for _,name in pairs(aList) do
        wWindow.share(name);
      end
    end
  end
end

-- function that Celestian uses to bulk update things as needed
function processUpdateADND()
  if User.isHost() then
    -- option to flip through spells and add "cast" "initiative" and "duration" effect with name of spell
    
    -- I use this to set default values on spells w/o them
    -- for _,nodeSpell in pairs(DB.getChildren("spell")) do
      -- local sName = DB.getValue(nodeSpell,"name","UNKNOWN");
      -- local sDuration = DB.getValue(nodeSpell,"duration",""):lower();
      -- local bNoDuration = (sDuration:match("instant") ~= nil or sDuration:match("perm") ~= nil or sDuration == "" or sDuration == nil);
      -- local sCastingTime = DB.getValue(nodeSpell,"castingtime","99"):lower();
      -- local bCastingTimeSegment = (sCastingTime:match("^%d+$"));
      -- local nCastinitiative = tonumber(sCastingTime:match("%d+")) or 99;
      -- if not bCastingTimeSegment then -- if round/turn/whatever set to 99
        -- nCastinitiative = 99;
      -- end
      -- local sSave = DB.getValue(nodeSpell,"save","none"):lower();
      -- local bNoSave = (sSave:match("none") ~= nil or sSave == "" or sSave == nil);
      -- if (DB.getChildCount(nodeSpell,"actions") < 1) then
-- Debug.console("data_library_adnd.lua","processUpdateADND","sName",sName);        
-- Debug.console("data_library_adnd.lua","processUpdateADND","sDuration",sDuration);        
-- Debug.console("data_library_adnd.lua","processUpdateADND","bNoDuration",bNoDuration);        
-- Debug.console("data_library_adnd.lua","processUpdateADND","sCastingTime",sCastingTime);        
-- Debug.console("data_library_adnd.lua","processUpdateADND","nCastinitiative",nCastinitiative);        
-- Debug.console("data_library_adnd.lua","processUpdateADND","sSave",sSave);        
-- Debug.console("data_library_adnd.lua","processUpdateADND","bNoSave",bNoSave);        
      -- DB.setValue(nodeSpell,"castinitiative","number",nCastinitiative);
        -- local nodeActions = nodeSpell.createChild("actions");
        -- if nodeActions then
          -- local nodeActionCast = nodeActions.createChild();
          -- if nodeActionCast then
            -- DB.setValue(nodeActionCast, "type", "string", "cast");
            -- if not bNoSave then
              -- DB.setValue(nodeActionCast, "savetype", "string", "spell");
            -- end
          -- end
          -- local nodeActionDuration = nodeActions.createChild();
          -- if nodeActionDuration and (not bNoDuration) then
            -- DB.setValue(nodeActionDuration, "type", "string", "effect");
            -- DB.setValue(nodeActionDuration, "label","string",sName);
          -- end
        -- end
      -- end
    -- end
  
  
  end
end
