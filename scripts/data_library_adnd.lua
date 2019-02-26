-- data library for ad&d core ruleset
--
--
--

function onInit()
  DesktopManager.showDockTitleText(true);
  DesktopManager.setDockTitleFont("sidebar");
  DesktopManager.setDockTitleFrame("", 25, 2, 25, 5);
  DesktopManager.setDockTitlePosition("top", 2, 14);
  DesktopManager.setStackIconSizeAndSpacing(54, 29, 3, 3);
  DesktopManager.setDockIconSizeAndSpacing(136, 24, 0, 6);
  DesktopManager.setLowerDockOffset(2, 0, 2, 0);
    
  -- we don't use either of these types of records in AD&D, so hide them
  LibraryData.setRecordTypeInfo("feat", nil);
  LibraryData.setRecordTypeInfo("vehicle", nil);
  --

  if User.isHost()  then
    Comm.registerSlashHandler("readycheck", processReadyCheck);
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
