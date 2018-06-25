---
--- Code to manage the /readycheck command
---
---
---

OOB_MSGTYPE_READYCHECK = "applyreadycheck";
function onInit()
  OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_READYCHECK, handleReadyCheck);
end

function onClose()
end

-- notify oob
function readyPressed(sUser,nCheck)
  notifyReadyCheck(sUser, nCheck);
  close();
end

-- notify oob to deal with this
function notifyReadyCheck(sUser, nCheck)
  local msgOOB = {};
  msgOOB.type = OOB_MSGTYPE_READYCHECK;
  msgOOB.user_name = sUser;
  msgOOB.ready_check_select = nCheck;
  Comm.deliverOOBMessage(msgOOB, "");
end

-- oob takes control and makes change (sends to apply)
function handleReadyCheck(msgOOB)
  local sUser = msgOOB.user_name;
  local nCheck = msgOOB.ready_check_select;

  -- go through connected list and toggle checked value
  for _,node in pairs(DB.getChildren("connectedlist")) do
    local sName = DB.getValue(node,"name","");
      if (sUser == sName) then
        DB.setValue(node,"ready_check_select","number",nCheck);
        break;
      end
  end
end