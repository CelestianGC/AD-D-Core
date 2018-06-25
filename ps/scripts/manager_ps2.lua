-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local aFieldMap = {};

function onInit()
  if User.isHost() then
    DB.addHandler("charsheet.*.classes", "onChildUpdate", linkPCClasses);
  end
end

function linkPCClasses(nodeClass)
  if not nodeClass then
    return;
  end
  local nodeChar = nodeClass.getParent();
  
  local nodePS = PartyManager.mapChartoPS(nodeChar);
  if not nodePS then
    return;
  end
  
  DB.setValue(nodePS, "classlevel", "string", CharManager.getClassLevelSummary(nodeChar));
  
  local nHDUsed, nHDTotal = CharManager.getClassHDUsage(nodeChar);
  DB.setValue(nodePS, "hd", "number", nHDTotal);
  DB.setValue(nodePS, "hdused", "number", nHDUsed);
end

function linkPCFields(nodePS)
  local sClass, sRecord = DB.getValue(nodePS, "link", "", "");
  if sRecord == "" then
    return;
  end
  local nodeChar = DB.findNode(sRecord);
  if not nodeChar then
    return;
  end
  
  PartyManager.linkRecordField(nodeChar, nodePS, "name", "string");
  PartyManager.linkRecordField(nodeChar, nodePS, "token", "token", "token");

  PartyManager.linkRecordField(nodeChar, nodePS, "race", "string");
  PartyManager.linkRecordField(nodeChar, nodePS, "exp", "number");
  PartyManager.linkRecordField(nodeChar, nodePS, "expneeded", "number");

  PartyManager.linkRecordField(nodeChar, nodePS, "hp.total", "number", "hptotal");
  PartyManager.linkRecordField(nodeChar, nodePS, "hp.temporary", "number", "hptemp");
  PartyManager.linkRecordField(nodeChar, nodePS, "hp.wounds", "number", "wounds");
  
  PartyManager.linkRecordField(nodeChar, nodePS, "abilities.strength.score", "number", "strength");
  PartyManager.linkRecordField(nodeChar, nodePS, "abilities.constitution.score", "number", "constitution");
  PartyManager.linkRecordField(nodeChar, nodePS, "abilities.dexterity.score", "number", "dexterity");
  PartyManager.linkRecordField(nodeChar, nodePS, "abilities.intelligence.score", "number", "intelligence");
  PartyManager.linkRecordField(nodeChar, nodePS, "abilities.wisdom.score", "number", "wisdom");
  PartyManager.linkRecordField(nodeChar, nodePS, "abilities.charisma.score", "number", "charisma");

  PartyManager.linkRecordField(nodeChar, nodePS, "abilities.strength.bonus", "number", "strbonus");
  PartyManager.linkRecordField(nodeChar, nodePS, "abilities.constitution.bonus", "number", "conbonus");
  PartyManager.linkRecordField(nodeChar, nodePS, "abilities.dexterity.bonus", "number", "dexbonus");
  PartyManager.linkRecordField(nodeChar, nodePS, "abilities.intelligence.bonus", "number", "intbonus");
  PartyManager.linkRecordField(nodeChar, nodePS, "abilities.wisdom.bonus", "number", "wisbonus");
  PartyManager.linkRecordField(nodeChar, nodePS, "abilities.charisma.bonus", "number", "chabonus");

  PartyManager.linkRecordField(nodeChar, nodePS, "defenses.ac.total", "number", "ac");
  PartyManager.linkRecordField(nodeChar, nodePS, "defenses.special", "string", "specialdefense");
  PartyManager.linkRecordField(nodeChar, nodePS, "perception", "number");
  PartyManager.linkRecordField(nodeChar, nodePS, "senses", "string");
  
  linkPCClasses(nodeChar.getChild("classes"));
end

--
-- DROP HANDLING
--

function addEncounter(nodeEnc)
  if not nodeEnc then
    return;
  end
  
  local nodePSEnc = DB.createChild("partysheet.encounters");
  DB.copyNode(nodeEnc, nodePSEnc);
end

-- this little tweak is to simply allow a single NPC to be added from
-- the NPC window or the shield drag/drop from the combat tracker.
-- celestian
function addEncounterNPC(nodeEnc)
  if not nodeEnc then
    return;
  end

    -- capture XP and to set it in the current default usage 
    -- for partysheet.encounters
    local nXP = DB.getValue(nodeEnc,"xp",0);
    
  local nodePSEnc = DB.createChild("partysheet.encounters");
    -- store xp in "exp" also so we don't have to manipulate 
    -- other code to deal with "xp" also.
    DB.setValue(nodePSEnc,"exp","number",nXP);
  DB.copyNode(nodeEnc, nodePSEnc);
end

function addQuest(nodeQuest)
  if not nodeQuest then
    return;
  end
  
  local nodePSQuest = DB.createChild("partysheet.quests");
  DB.copyNode(nodeQuest, nodePSQuest);
end

--
-- XP DISTRIBUTION
--

function awardQuestsToParty(nodeEntry)
  local nXP = 0;
  if nodeEntry then
    if DB.getValue(nodeEntry, "xpawarded", 0) == 0 then
      nXP = DB.getValue(nodeEntry, "xp", 0);
      DB.setValue(nodeEntry, "xpawarded", "number", 1);
    end
  else
    for _,v in pairs(DB.getChildren("partysheet.quests")) do
      if DB.getValue(v, "xpawarded", 0) == 0 then
        nXP = nXP + DB.getValue(v, "xp", 0);
        DB.setValue(v, "xpawarded", "number", 1);
      end
    end
  end
  if nXP ~= 0 then
    awardXP(nXP);
  end
end

function awardEncountersToParty(nodeEntry)
  local nXP = 0;
  if nodeEntry then
    if DB.getValue(nodeEntry, "xpawarded", 0) == 0 then
      nXP = DB.getValue(nodeEntry, "exp", 0);
      DB.setValue(nodeEntry, "xpawarded", "number", 1);
    end
  else
    for _,v in pairs(DB.getChildren("partysheet.encounters")) do
      if DB.getValue(v, "xpawarded", 0) == 0 then
        nXP = nXP + DB.getValue(v, "exp", 0);
        DB.setValue(v, "xpawarded", "number", 1);
      end
    end
  end
  if nXP ~= 0 then
    awardXP(nXP);
  end
end

function awardXP(nXP) 
  -- Determine members of party
  local aParty = {};
  for _,v in pairs(DB.getChildren("partysheet.partyinformation")) do
    local sClass, sRecord = DB.getValue(v, "link");
    if sClass == "charsheet" and sRecord then
      local nodePC = DB.findNode(sRecord);
      if nodePC then
        local sName = DB.getValue(v, "name", "");
        table.insert(aParty, { name = sName, node = nodePC } );
      end
    end
  end

  -- Determine split
  local nAverageSplit;
  if nXP >= #aParty then
    nAverageSplit = math.floor((nXP / #aParty) + 0.5);
  else
    nAverageSplit = 0;
  end
  local nFinalSplit = math.max((nXP - ((#aParty - 1) * nAverageSplit)), 0);
  
  -- Award XP
  for _,v in ipairs(aParty) do
    local nAmount;
    if k == #aParty then
      nAmount = nFinalSplit;
    else
      nAmount = nAverageSplit;
    end
    
    if nAmount > 0 then
      local nNewAmount = DB.getValue(v.node, "exp", 0) + nAmount;
      DB.setValue(v.node, "exp", "number", nNewAmount);
    end

    v.given = nAmount;
  end
  
  -- Output results
  local msg = {font = "msgfont"};
  msg.icon = "xp";
  for _,v in ipairs(aParty) do
    msg.text = "[" .. v.given .. " XP] -> " .. v.name;
    Comm.deliverChatMessage(msg);
  end

  msg.icon = "portrait_gm_token";
  msg.text = Interface.getString("ps_message_xpaward") .. " (" .. nXP .. ")";
  Comm.deliverChatMessage(msg);
end

function awardXPtoPC(nXP, nodePC)
  local nCharXP = DB.getValue(nodePC, "exp", 0);
  nCharXP = nCharXP + nXP;
  DB.setValue(nodePC, "exp", "number", nCharXP);
              
  local msg = {font = "msgfont"};
  msg.icon = "xp";
  msg.text = "[" .. nXP .. " XP] -> " .. DB.getValue(nodePC, "name");
  Comm.deliverChatMessage(msg, "");

  local sOwner = nodePC.getOwner();
  if (sOwner or "") ~= "" then
    Comm.deliverChatMessage(msg, sOwner);
  end
end
