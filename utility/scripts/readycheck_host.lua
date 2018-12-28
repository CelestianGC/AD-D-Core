---
--- Code to manage the /readycheck command
---
---
---

function onInit()
  -- make sure all checks are off and ding the users for readycheck!
  for _,node in pairs(DB.getChildren("connectedlist")) do
    DB.setValue(node,"ready_check_select","number",0);
    local sUser = DB.getValue(node,"name","");
    if sUser ~= "" then
      User.ringBell(sUser);
    end
  end
  
  local node = getDatabaseNode();
  DB.addHandler(node.getPath() .. ".name","onUpdate", updateName);
  DB.addHandler(node.getPath() .. ".ready_check_select","onUpdate", updateCheck);
  
  updateName();
  updateCheck();
end

function onClose()
  local node = getDatabaseNode();
  DB.removeHandler(node.getPath() .. ".name","onUpdate", updateName);
  DB.removeHandler(node.getPath() .. ".ready_check_select","onUpdate", updateCheck);
end

function updateName()
  local node = getDatabaseNode();
  local sName = DB.getValue(node,"name","UNKNOWN");
  name_label.setValue(sName);

--Debug.console("readycheck_host.lua","updateName","node",node);
--Debug.console("readycheck_host.lua","updateName","sName",sName);
  
  -- -- set Player portrait
  local sID = User.getCurrentIdentity(sName);
  --local node = DB.findNode("charsheet." .. sID);
  if sID then
    local sCharName = DB.getValue(node,"name","");
--Debug.console("readycheck_host.lua","updateName","sID",sID);
    readycheck_portrait.setIcon("portrait_" .. sID .. "_charlist", true);
  else
    readycheck_portrait.setIcon(nil);
  end
end

function updateCheck()
  local node = getDatabaseNode();
  local nCheck = DB.getValue(node,"ready_check_select",0);
  ready_check_select.setValue(nCheck);
  if (nCheck ~= 0) then
    ready_check_select.setVisible(false);
    ready_check_select_ready.setVisible(true);
  else
    ready_check_select.setVisible(true);
    ready_check_select_ready.setVisible(false);
  end
  seeIfEveryoneIsReady();
end

function seeIfEveryoneIsReady()
  local bEveryoneReady = true;
  for _,node in pairs(DB.getChildren("connectedlist")) do
    local sName = DB.getValue(node,"name","");
    local bReady = (DB.getValue(node,"ready_check_select",0) == 1);
    if (not bReady) then
      Debug.console("ready_check_host.lua","seeIfEveryoneIsReady",sName .. " is NOT READY");
      bEveryoneReady = false;
    end
  end
  -- DING dm that everyone is ready?
  if bEveryoneReady then
    Debug.console("ready_check_host.lua","EVERYONE READY!");
    --User.ringBell(); -- this rings everyone, not just DM/GM/Host ;(
  end
end