--
--
--
-- this code is to manage the movement speed for characters
--

function onInit()
    super.onInit();
    local nodeChar = window.getDatabaseNode();
    DB.addHandler(DB.getPath(nodeChar, "speed.base"),"onUpdate", detailsUpdate);
    DB.addHandler(DB.getPath(nodeChar, "speed.basemodenc"),"onUpdate", detailsUpdate);
    DB.addHandler(DB.getPath(nodeChar, "speed.basemoditem"),"onUpdate", detailsUpdate);
    DB.addHandler(DB.getPath(nodeChar, "speed.basemod"),"onUpdate", detailsUpdate);
    DB.addHandler(DB.getPath(nodeChar, "speed.itemmod"),"onUpdate", detailsUpdate);
    DB.addHandler(DB.getPath(nodeChar, "speed.effectmod"),"onUpdate", detailsUpdate);
    DB.addHandler(DB.getPath(nodeChar, "speed.mod"),"onUpdate", detailsUpdate);
    DB.addHandler(DB.getPath(nodeChar, "speed.tempmod"),"onUpdate", detailsUpdate);
    detailsUpdate();
end

function onClose()
    local nodeChar = window.getDatabaseNode();
    DB.removeHandler(DB.getPath(nodeChar, "speed.base"),"onUpdate", detailsUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "speed.basemodenc"),"onUpdate", detailsUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "speed.basemoditem"),"onUpdate", detailsUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "speed.basemod"),"onUpdate", detailsUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "speed.itemmod"),"onUpdate", detailsUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "speed.effectmod"),"onUpdate", detailsUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "speed.mod"),"onUpdate", detailsUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "speed.tempmod"),"onUpdate", detailsUpdate);
end

function detailsUpdate()
    local nodeChar = window.getDatabaseNode();
    local nMoveBase     = DB.getValue(nodeChar,"speed.base",0);
    local nMoveBaseENC  = DB.getValue(nodeChar,"speed.basemodenc",0);
    local nMoveBaseItem = DB.getValue(nodeChar,"speed.basemoditem",0);
    local nMoveBaseMod = DB.getValue(nodeChar,"speed.basemod",0);
    local nTotalBase = nMoveBase;
    if (nMoveBaseENC ~= 0) and (nMoveBaseENC < nTotalBase) then
        nTotalBase = nMoveBaseENC;
    end
    if (nMoveBaseItem ~= 0) and (nMoveBaseItem < nTotalBase) then
        nTotalBase = nMoveBaseItem;
    end
    if (nMoveBaseMod ~= 0) and (nMoveBaseMod < nTotalBase) then
        nTotalBase = nMoveBaseMod;
    end

    local nMoveItem   = DB.getValue(nodeChar,"speed.itemmod",0);
    local nMoveEffect = DB.getValue(nodeChar,"speed.effectmod",0);
    local nMoveMod    = DB.getValue(nodeChar,"speed.mod",0);
    local nMoveTemp   = DB.getValue(nodeChar,"speed.tempmod",0);
    
    local nTotalMods = nMoveItem + nMoveEffect + nMoveMod + nMoveTemp;
    local nTotalMove = nTotalBase + nTotalMods;
    DB.setValue(nodeChar,"speed.total","number",nTotalMove);
end
