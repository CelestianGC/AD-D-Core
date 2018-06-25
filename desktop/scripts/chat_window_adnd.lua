-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
  deliverLaunchMessage()
end

function deliverLaunchMessage()
    local launchmsg = ChatManager.retrieveLaunchMessages();
    for keyMessage, rMessage in ipairs(launchmsg) do
      Comm.addChatMessage(rMessage);
    end
end

function onDiceLanded(draginfo)
   return ActionsManager.onDiceLanded(draginfo);
end

function onDragStart(button, x, y, draginfo)
  return ActionsManager.onChatDragStart(draginfo);
end

function onDrop(x, y, draginfo)
  local bReturn = ActionsManager.actionDrop(draginfo, nil);
  
  if bReturn then
    local aDice = draginfo.getDieList();
    if aDice and #aDice > 0 and (not OptionsManager.isOption("MANUALROLL", "on") and (not Input.isControlPressed() and User.isHost() ) ) then
      return;
    end
    return true;
  end
  
  if draginfo.getType() == "language" then
    LanguageManager.setCurrentLanguage(draginfo.getStringData());
    return true;
  end
end
