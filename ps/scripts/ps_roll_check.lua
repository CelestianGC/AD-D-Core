-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function action(draginfo)
  local aParty = {};
  for _,v in pairs(window.list.getWindows()) do
    local rActor = ActorManager.getActor("pc", v.link.getTargetDatabaseNode());
    if rActor then
      table.insert(aParty, rActor);
    end
  end
  if #aParty == 0 then
    aParty = nil;
  end
  
  local sAbilityStat = DB.getValue("partysheet.checkselected", ""):lower();
  
  local nTargetDC = DB.getValue("partysheet.checkdc", 0);
  if nTargetDC == 0 then
    nTargetDC = nil;
  end
  
  local bSecretRoll = (window.hiderollresults.getValue() == 1);
  
  ModifierStack.lock();
  for _,v in pairs(aParty) do
    local sActorType, nodeActor = ActorManager.getTypeAndNode(v);
    nTargetDC = DB.getValue(nodeActor, "abilities.".. sAbilityStat .. ".score", 0);
    ActionCheck.performRoll(nil, v, sAbilityStat, nTargetDC, bSecretRoll);
  end
  ModifierStack.unlock(true);

  return true;
end

function onButtonPress()
  return action();
end      

