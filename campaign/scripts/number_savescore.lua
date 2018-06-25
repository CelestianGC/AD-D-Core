--
--
--
--
--

function onInit()
    if super then
        super.onInit();
    end
  --onValueChanged();
end

function update(bReadOnly)
  setReadOnly(bReadOnly);
end

function action(draginfo)
    local nTargetDC = 20;
    local rActor = ActorManager.getActor("", window.getDatabaseNode());
    local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);
    nTargetDC = DB.getValue(nodeActor, "saves." .. self.target[1] .. ".score", 0);
    ActionSave.performRoll(draginfo, rActor, self.target[1],nTargetDC);

  return true;
end

function onDragStart(button, x, y, draginfo)
  if rollable then
    return action(draginfo);
  end
end
  
function onDoubleClick(x, y)
  if rollable then
    return action();
  end
end

