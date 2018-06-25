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
  
  local sSave = DB.getValue("partysheet.saveselected", ""):lower();
  
  local nTargetDC = DB.getValue("partysheet.savedc", 0);
  if nTargetDC == 0 then
    nTargetDC = nil;
  end
  
  local bSecretRoll = (window.hiderollresults.getValue() == 1);
  
  ModifierStack.lock();
  for _,v in pairs(aParty) do
    ActionSave.performRoll(nil, v, sSave, nTargetDC, bSecretRoll);
  end
  ModifierStack.unlock(true);

  return true;
end

function onButtonPress()
  return action();
end
