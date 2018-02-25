--
--
-- Register bits for connections
--
--
--

function onInit()
  if User.isHost() then
      User.onLogin = onLoginManagement;
      local nodeUsers = DB.createNode("connectedlist");
      -- we're just starting, remove all entries, no one is connected
      nodeUsers.delete();
  end
end

-- onLogin run this function
-- sUser = user
-- bLogin, This value is true if the user is logging on, or false if the user is logging off
function onLoginManagement(sUser,bLogin)
  if bLogin then
    -- user connecting, add to list
    local nodeUser = DB.createChild("connectedlist");
    DB.setValue(nodeUser,"name","string",sUser);
  else
    -- user logged out, remove from connected list
    for _,node in pairs(DB.getChildren("connectedlist")) do
      local sName = DB.getValue(node,"name","");
        if (sUser == sName) then
          DB.deleteNode(node.getPath());
          break;
        end
    end
  end
end

