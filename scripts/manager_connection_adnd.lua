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

-- get a list of users.
function getUserLoggedInList()
  local aList = {}
    for _,node in pairs(DB.getChildren("connectedlist")) do
      local sName = DB.getValue(node,"name","");
      if sName and sName ~= "" then
        table.insert(aList,sName);
      end
    end
  return aList;
end

-- get a string list of users
function getUserLoggedInAsString()
  local sUsers = "";
  local aList = getUserLoggedInList();
  for _,name in pairs(aList) do
    if sUsers == "" then
      sUsers = name;
    else
      sUsers = sUsers .. "," .. name;
    end
  end
  return sUsers;
end
