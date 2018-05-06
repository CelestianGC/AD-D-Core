--
--
--
--
--
--

function onInit()
  DB.addHandler("charsheet.*.combat.mthaco.base","onUpdate", updateMTHACO);
  DB.addHandler("charsheet.*.combat.mthaco.basemod","onUpdate", updateMTHACO);
  DB.addHandler("charsheet.*.combat.mthaco.mod","onUpdate", updateMTHACO);
  DB.addHandler("charsheet.*.combat.mthaco.tempmod","onUpdate", updateMTHACO);
  
  DB.addHandler("combattracker.list.*.combat.mthaco.base","onUpdate", updateMTHACO);
  DB.addHandler("combattracker.list.*.combat.mthaco.basemod","onUpdate", updateMTHACO);
  DB.addHandler("combattracker.list.*.combat.mthaco.mod","onUpdate", updateMTHACO);
  DB.addHandler("combattracker.list.*.combat.mthaco.tempmod","onUpdate", updateMTHACO);

  DB.addHandler("npc.*.combat.mthaco.base","onUpdate", updateMTHACO);
  DB.addHandler("npc.*.combat.mthaco.basemod","onUpdate", updateMTHACO);
  DB.addHandler("npc.*.combat.mthaco.mod","onUpdate", updateMTHACO);
  DB.addHandler("npc.*.combat.mthaco.tempmod","onUpdate", updateMTHACO);
end

function onClose()
end

function updateMTHACO(node)
Debug.console("manager_mthaco_adnd.lua","updateMTHACO","node",node);
  local nodeChar = node.getChild("....");
Debug.console("manager_mthaco_adnd.lua","updateMTHACO","nodeChar",nodeChar);  
  local nMTHACO         = DB.getValue(nodeChar,"combat.mthaco.base",20);
  local nMTHACO_BaseMod = DB.getValue(nodeChar,"combat.mthaco.basemod",20);
  local nMTHACO_Mod     = DB.getValue(nodeChar,"combat.mthaco.mod",0);
  local nMTHACO_TempMod = DB.getValue(nodeChar,"combat.mthaco.tempmod",0);
  if (nMTHACO > nMTHACO_BaseMod and nMTHACO_BaseMod ~= 0) then 
    nMTHACO = nMTHACO_BaseMod;
  end
  local nMTHACO_SCORE = nMTHACO + nMTHACO_Mod + nMTHACO_TempMod;

  DB.setValue(nodeChar,"combat.mthaco.score","number",nMTHACO_SCORE);
end

