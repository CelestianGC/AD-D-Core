--
-- Contains list of various node conversion functions
-- npc to pc
-- pc to npc
--

function onInit()
end

function onClose()
end

-- take a npc node and convert it to a charsheet/PC node
function convertToPC(nodeNPC)
  if not nodeNPC then
    return nil;
  end
 
  -- create pc node
  local nodePC = DB.createChild("charsheet");
  -- copy nodeNPC into PC node
  DB.copyNode(nodeNPC, nodePC);
  
  -- roll hitpoints for the NPC and set on PC node
  local nHP = CombatManager2.rollNPCHitPoints(nodeNPC);
  DB.setValue(nodePC, "hp.total", "number", nHP);
  
  -- set race
  DB.setValue(nodePC, "race", "string", DB.getValue(nodeNPC,"type",""));

  -- set "level"
  DB.setValue(nodePC, "level", "number", DB.getValue(nodeNPC,"level",0));
  
  -- set "personalitytraits" to the npc's description? Need better place because of formatted text.
  local tDescription = DB.getValue(nodeNPC,"text","");
  DB.setValue(nodePC, "personalitytraits", "string", tDescription);
  
  -- set special defense
  DB.setValue(nodePC, "special", "string", DB.getValue(nodeNPC,"specialdefense",""));

  -- set AC
  DB.setValue(nodePC, "defenses.ac.base", "number", DB.getValue(nodeNPC, "ac", 10));
  DB.setValue(nodePC, "defenses.ac.total", "number", DB.getValue(nodeNPC, "ac", 10));
  -- set movebase/speed in proper place
  local sMove = DB.getValue(nodeNPC, "speed","");
  local nMove = sMove:match("%d+"); -- grab first digit we can find, thats the speed!
  DB.setValue(nodePC, "speed.total", "number", nMove);
  DB.setValue(nodePC, "speed.base", "number", nMove);
  
  DB.setValue(nodeNPC, "combat.thaco.score", "number", DB.getValue(nodePC, "thaco", 20));
  --DB.setValue(nodeNPC, "combat.thaco.base", "number", DB.getValue(nodePC, "thaco", 20));
  
  return nodePC;
end

-- take a PC and convert it to a npc/NPC node
function convertToNPC(nodePCIncoming)
  if not nodePCIncoming then
    return nil;
  end
  
  -- we create a local copy of the nodePC because
  -- we need to remove a few bits from it, if we dont
  -- then we end up deleting those nodes from the place
  -- we got it from, WOOPS!
  local nodePC = DB.createChild("charsheet");
  DB.copyNode(nodePCIncoming, nodePC);
  
  -- get HP to set on NPC
  local nHP = DB.getValue(nodePC,"hp.total",0);
  local sSpeed = DB.getValue(nodePC,"speed.total",12);

  -- these are different on npcs, so nuke them before copy
  DB.deleteChild(nodePC,"hp");
  DB.deleteChild(nodePC,"speed");
  
  -- create pc node
  local nodeNPC = DB.createChild("npc");
  -- copy nodeNPC into PC node
  DB.copyNode(nodePC, nodeNPC);
  
  DB.setValue(nodeNPC, "type","string","Humanoid");
  
  -- set nHP to hp value for npc
  DB.setValue(nodeNPC, "hptotal", "number", nHP);
  DB.setValue(nodeNPC, "hp", "number", nHP);
  
  -- set speed
  DB.setValue(nodeNPC, "speed", "string", sSpeed);
  
  -- set thaco
  DB.setValue(nodeNPC, "thaco", "number", DB.getValue(nodePC, "combat.thaco.score", 20));
  
  -- set AC
  DB.setValue(nodeNPC, "ac", "number", DB.getValue(nodePC, "defenses.ac.total", 10));

  -- set special defense
  DB.setValue(nodeNPC, "specialDefense", "string", DB.getValue(nodePC,"special",""));
  
  -- delete temporary copy we made to make the clone
  DB.deleteNode(nodePC.getPath());
  return nodeNPC;
end