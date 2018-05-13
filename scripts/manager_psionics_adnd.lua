--
--
--
--
--
--

function onInit()
  if User.isHost() then
    -- charsheet updates
    DB.addHandler("charsheet.*.combat.mthaco.base","onUpdate", updateMTHACO);
    DB.addHandler("charsheet.*.combat.mthaco.basemod","onUpdate", updateMTHACO);
    DB.addHandler("charsheet.*.combat.mthaco.mod","onUpdate", updateMTHACO);
    DB.addHandler("charsheet.*.combat.mthaco.tempmod","onUpdate", updateMTHACO);
    DB.addHandler("charsheet.*.combat.psp.base","onUpdate", updatePSP);
    DB.addHandler("charsheet.*.combat.psp.basemod","onUpdate", updatePSP);
    DB.addHandler("charsheet.*.combat.psp.mod","onUpdate", updatePSP);
    DB.addHandler("charsheet.*.combat.psp.tempmod","onUpdate", updatePSP);
    DB.addHandler("charsheet.*.combat.mac.base","onUpdate", updateMAC);
    DB.addHandler("charsheet.*.combat.mac.basemod","onUpdate", updateMAC);
    DB.addHandler("charsheet.*.combat.mac.mod","onUpdate", updateMAC);
    DB.addHandler("charsheet.*.combat.mac.tempmod","onUpdate", updateMAC);
    
    -- combattracker updates
    DB.addHandler("combattracker.list.*.combat.mthaco.base","onUpdate", updateMTHACO);
    DB.addHandler("combattracker.list.*.combat.mthaco.basemod","onUpdate", updateMTHACO);
    DB.addHandler("combattracker.list.*.combat.mthaco.mod","onUpdate", updateMTHACO);
    DB.addHandler("combattracker.list.*.combat.mthaco.tempmod","onUpdate", updateMTHACO);
    DB.addHandler("combattracker.list.*.combat.psp.base","onUpdate", updatePSP);
    DB.addHandler("combattracker.list.*.combat.psp.basemod","onUpdate", updatePSP);
    DB.addHandler("combattracker.list.*.combat.psp.mod","onUpdate", updatePSP);
    DB.addHandler("combattracker.list.*.combat.psp.tempmod","onUpdate", updatePSP);
    DB.addHandler("combattracker.list.*.combat.mac.base","onUpdate", updateMAC);
    DB.addHandler("combattracker.list.*.combat.mac.basemod","onUpdate", updateMAC);
    DB.addHandler("combattracker.list.*.combat.mac.mod","onUpdate", updateMAC);
    DB.addHandler("combattracker.list.*.combat.mac.tempmod","onUpdate", updateMAC);

    -- npc entry updates
    DB.addHandler("npc.*.combat.mthaco.base","onUpdate", updateMTHACO);
    DB.addHandler("npc.*.combat.mthaco.basemod","onUpdate", updateMTHACO);
    DB.addHandler("npc.*.combat.mthaco.mod","onUpdate", updateMTHACO);
    DB.addHandler("npc.*.combat.mthaco.tempmod","onUpdate", updateMTHACO);
    DB.addHandler("npc.*.combat.psp.base","onUpdate", updatePSP);
    DB.addHandler("npc.*.combat.psp.basemod","onUpdate", updatePSP);
    DB.addHandler("npc.*.combat.psp.mod","onUpdate", updatePSP);
    DB.addHandler("npc.*.combat.psp.tempmod","onUpdate", updatePSP);
    DB.addHandler("npc.*.combat.mac.base","onUpdate", updateMAC);
    DB.addHandler("npc.*.combat.mac.basemod","onUpdate", updateMAC);
    DB.addHandler("npc.*.combat.mac.mod","onUpdate", updateMAC);
    DB.addHandler("npc.*.combat.mac.tempmod","onUpdate", updateMAC);
  end
end

function onClose()
end

function updatePsionicStats(nodeChar)
  updateMAC(nodeChar);
  updatePSP(nodeChar);
  updateMTHACO(nodeChar);
end

function updateMAC(node)
  local nodeChar = nil;
  if (node.getPath():match("%d+$")) then
      nodeChar = node;
  else
    nodeChar = node.getChild("....");
  end
  local nMAC         = DB.getValue(nodeChar,"combat.mac.base",10);
  local nMAC_BaseMod = DB.getValue(nodeChar,"combat.mac.basemod",99);
  local nMAC_Mod     = DB.getValue(nodeChar,"combat.mac.mod",0);
  local nMAC_TempMod = DB.getValue(nodeChar,"combat.mac.tempmod",0);
  if (nMAC > nMAC_BaseMod) then 
    nMAC = nMAC_BaseMod;
  end
  nMAC_Mod     = -(nMAC_Mod); -- flip values, +1 ac is improvement
  nMAC_TempMod = -(nMAC_TempMod);
  
  local nMAC_SCORE = nMAC + nMAC_Mod + nMAC_TempMod;
  DB.setValue(nodeChar,"combat.mac.score","number",nMAC_SCORE);
end

function updatePSP(node)
  local nodeChar = nil;
  if (node.getPath():match("%d+$")) then
      nodeChar = node;
  else
    nodeChar = node.getChild("....");
  end
  local nPSP         = DB.getValue(nodeChar,"combat.psp.base",0);
  local nPSP_BaseMod = DB.getValue(nodeChar,"combat.psp.basemod",0);
  local nPSP_Mod     = DB.getValue(nodeChar,"combat.psp.mod",0);
  local nPSP_TempMod = DB.getValue(nodeChar,"combat.psp.tempmod",0);
  if (nPSP < nPSP_BaseMod and nPSP_BaseMod ~= 0) then 
    nPSP = nPSP_BaseMod;
  end
  local nPSP_SCORE = nPSP + nPSP_Mod + nPSP_TempMod;
  DB.setValue(nodeChar,"combat.psp.score","number",nPSP_SCORE);
end

function updateMTHACO(node)
  local nodeChar = nil;
  if (node.getPath():match("%d+$")) then
      nodeChar = node;
  else
    nodeChar = node.getChild("....");
  end
  local nMTHACO         = DB.getValue(nodeChar,"combat.mthaco.base",20);
  local nMTHACO_BaseMod = DB.getValue(nodeChar,"combat.mthaco.basemod",99);
  local nMTHACO_Mod     = DB.getValue(nodeChar,"combat.mthaco.mod",0);
  local nMTHACO_TempMod = DB.getValue(nodeChar,"combat.mthaco.tempmod",0);
  if (nMTHACO > nMTHACO_BaseMod) then 
    nMTHACO = nMTHACO_BaseMod;
  end
  local nMTHACO_SCORE = nMTHACO + nMTHACO_Mod + nMTHACO_TempMod;

  DB.setValue(nodeChar,"combat.mthaco.score","number",nMTHACO_SCORE);
end

function getPSPMax(node)
  local nPSPMax = DB.getValue(node,"combat.psp.score",0);
  return nPSPMax;
end

function getPSPExpended(node)
  local nPSPExpended = DB.getValue(node,"combat.psp.expended",0);
  return nPSPExpended;
end
function getPSPUsed(node)
  return getPSPExpended(node);
end

function getPSPRemaining(node)
  local nPSPMax = getPSPMax(node);
  local nPSPUsed = getPSPExpended(node);
  
  return nPSPMax - nPSPUsed;
end

-- use some PSPs, return false if not enough
function removePSP(node,nAmount)
  local nCurrent = getPSPRemaining(node);
  if (nCurrent >= nAmount) then
    local nUsed = getPSPUsed(node);
    nUsed = nUsed + nAmount;
    DB.setValue(node,"combat.psp.expended","number",nUsed);
  else
    -- not enough, set used to max and call it done
    DB.setValue(node,"combat.psp.expended","number",getPSPMax(node));
    return false;
  end
  return true;
end
-- grant some PSPs
function addPSP(node,nAmount)
  local nUsed = getPSPExpended(node);
  nUsed = nUsed - nAmount;
  if (nUsed < 0) then
    nUsed = 0;
  end
  DB.setValue(node,"combat.psp.expended","number",nUsed);
end
