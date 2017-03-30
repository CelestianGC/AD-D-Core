--
-- for AD&D Core, abilities menu
--
--

function onInit()
    super.onInit();
    local nodeChar = window.getDatabaseNode();

    --Debug.console("char_abilities_details.lua","onInit","nodeChar",nodeChar);

    local sTarget = string.lower(self.target[1]);
    DB.addHandler(DB.getPath(nodeChar, "saves." .. sTarget .. ".base"),       "onUpdate", detailsUpdate);
    DB.addHandler(DB.getPath(nodeChar, "saves." .. sTarget .. ".basemod"),    "onUpdate", detailsUpdate);
    DB.addHandler(DB.getPath(nodeChar, "saves." .. sTarget .. ".itemmod"),    "onUpdate", detailsUpdate);
    DB.addHandler(DB.getPath(nodeChar, "saves." .. sTarget .. ".effectmod"),  "onUpdate", detailsUpdate);
    DB.addHandler(DB.getPath(nodeChar, "saves." .. sTarget .. ".adjustment"), "onUpdate", detailsUpdate);
    DB.addHandler(DB.getPath(nodeChar, "saves." .. sTarget .. ".tempmod"),    "onUpdate", detailsUpdate);
    detailsUpdate();
end

function action(draginfo)
    local nTargetDC = 20;
    local rActor = ActorManager.getActor("pc", window.getDatabaseNode());
    local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);
    nTargetDC = DB.getValue(nodeActor, "saves." .. self.target[1] .. ".score", 0);
    ActionSave.performRoll(draginfo, rActor, self.target[1],nTargetDC);
    return true;
end

function onDragStart(button, x, y, draginfo)
    return action(draginfo);
end
    
function onDoubleClick(x,y)
    return action();
end


function onClose()
    local nodeChar = window.getDatabaseNode();

    --Debug.console("char_abilities_details.lua","onClose","nodeChar",nodeChar);

    local sTarget = string.lower(self.target[1]);
    DB.removeHandler(DB.getPath(nodeChar, "saves." .. sTarget .. ".base"),       "onUpdate", detailsUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "saves." .. sTarget .. ".basemod"),    "onUpdate", detailsUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "saves." .. sTarget .. ".itemmod"),    "onUpdate", detailsUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "saves." .. sTarget .. ".effectmod"),  "onUpdate", detailsUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "saves." .. sTarget .. ".adjustment"), "onUpdate", detailsUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "saves." .. sTarget .. ".tempmod"),    "onUpdate", detailsUpdate);
end

function detailsUpdate()
    local node = getDatabaseNode();
    local nodeChar = window.getDatabaseNode();
    local sTarget = string.lower(self.target[1]);
    
    --Debug.console("char_abilities_details.lua","detailsUpdate","nodeChar",nodeChar);
    --Debug.console("char_abilities_details.lua","detailsUpdate","sTarget",sTarget);
    
    local nBase =       DB.getValue(nodeChar, "saves." .. sTarget .. ".base",20);
    local nBaseMod =    DB.getValue(nodeChar, "saves." .. sTarget .. ".basemod",0);
    local nItemMod =    DB.getValue(nodeChar, "saves." .. sTarget .. ".itemmod",0);
    local nEffectMod =  DB.getValue(nodeChar, "saves." .. sTarget .. ".effectmod",0);
    local nAdjustment = DB.getValue(nodeChar, "saves." .. sTarget .. ".adjustment",0);
    local nTempMod =    DB.getValue(nodeChar, "saves." .. sTarget .. ".tempmod",0);
    local nFinalBase = nBase;

    if (nBaseMod ~= 0) then
        nFinalBase = nBaseMod;
    end
    
    -- flip negative to positive, since we expect +2 to be better and -2 to be worse
    -- here.
    local nFlipMods = ( (nItemMod + nEffectMod + nAdjustment + nTempMod) * -1);
    local nTotal = (nFinalBase + nFlipMods);
    if (nTotal < 1) then
        nTotal = 1;
    end
    if (nTotal > 50) then
        nTotal = 50;
    end
    DB.setValue(nodeChar, "saves." .. sTarget .. ".score","number", nTotal);
    --Debug.console("char_abilities_details.lua","detailsUpdate","nTotal",nTotal);
    
    --setValue(nTotal);
end


