-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
  if User.isHost() then
    registerMenuItem(Interface.getString("menu_rest"), "lockvisibilityon", 8);
    registerMenuItem(Interface.getString("menu_restshort"), "pointer_cone", 8, 8);
    registerMenuItem(Interface.getString("menu_restlong"), "pointer_circle", 8, 6);
  end

  if User.isLocal() then
    portrait.setVisible(false);
    localportrait.setVisible(true);
  end

end

function onClose()
end

function onMenuSelection(selection, subselection)
  if selection == 8 then
    local nodeChar = getDatabaseNode();
    
    if subselection == 8 then
      ChatManager.Message(Interface.getString("message_restshort"), true, ActorManager.getActor("pc", nodeChar));
      CharManager.rest(nodeChar, false);
    elseif subselection == 6 then
      ChatManager.Message(Interface.getString("message_restlong"), true, ActorManager.getActor("pc", nodeChar));
      CharManager.rest(nodeChar, true);
    end
  end
end
