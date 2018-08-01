
--
-- Effects on Items, apply to character in CT
--
--

function onInit()
  if User.isHost() then
    -- watch the combatracker/npc inventory list
    DB.addHandler("combattracker.list.*.inventorylist.*.carried", "onUpdate", inventoryUpdateItemEffects);
    DB.addHandler("combattracker.list.*.inventorylist.*.effectlist.*.effect", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("combattracker.list.*.inventorylist.*.effectlist.*.durdice", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("combattracker.list.*.inventorylist.*.effectlist.*.durmod", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("combattracker.list.*.inventorylist.*.effectlist.*.name", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("combattracker.list.*.inventorylist.*.effectlist.*.durunit", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("combattracker.list.*.inventorylist.*.effectlist.*.visibility", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("combattracker.list.*.inventorylist.*.effectlist.*.actiononly", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("combattracker.list.*.inventorylist.*.isidentified", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("combattracker.list.*.inventorylist", "onChildDeleted", updateFromDeletedInventory);

    -- watch the character/pc inventory list
    DB.addHandler("charsheet.*.inventorylist.*.carried", "onUpdate", inventoryUpdateItemEffects);
    DB.addHandler("charsheet.*.inventorylist.*.effectlist.*.effect", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("charsheet.*.inventorylist.*.effectlist.*.durdice", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("charsheet.*.inventorylist.*.effectlist.*.durmod", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("charsheet.*.inventorylist.*.effectlist.*.name", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("charsheet.*.inventorylist.*.effectlist.*.durunit", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("charsheet.*.inventorylist.*.effectlist.*.visibility", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("charsheet.*.inventorylist.*.effectlist.*.actiononly", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("charsheet.*.inventorylist.*.isidentified", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("charsheet.*.inventorylist", "onChildDeleted", updateFromDeletedInventory);
  end
    --CoreRPG replacements
    ActionsManager.decodeActors = decodeActors;
    -- AD&D Core ONLY!!! (need this because we use Ascending initiative, not high to low
    EffectManager.setInitAscending(true);
    CombatManager.addCombatantFieldChangeHandler("initresult", "onUpdate", updateForInitiative);
    CombatManager.addCombatantFieldChangeHandler("initrolled", "onUpdate", updateForInitiativeRolled);
    
    
    -- used for AD&D Core ONLY
    --ActionsManager.resolveAction = resolveAction;
    EffectManager5E.evalAbilityHelper = evalAbilityHelper;
    EffectManager.setCustomOnEffectActorStartTurn(onEffectActorStartTurn);
    --EffectManager.setCustomOnEffectAddStart(adndOnEffectAddStart);
    EffectManager.setCustomOnEffectAddEnd(adndOnEffectAddEnd);
    EffectManager5E.applyOngoingDamageAdjustment = applyOngoingDamageAdjustment;
    
    -- this is for ARMOR() effect type
    --IFT: ARMOR(plate,platemail);ATK: 2 and it will then give you +2 to hit versus targets that are wearing plate/platemail armor.
    EffectManager5E.checkConditional = checkConditional; 
    
    -- 5E effects replacements
    EffectManager5E.checkConditionalHelper = checkConditionalHelper;
    EffectManager5E.getEffectsByType = getEffectsByType;
    EffectManager5E.hasEffect = hasEffect;
    
    -- used for 5E extension ONLY
    --ActionAttack.performRoll = manager_action_attack_performRoll;
    --ActionDamage.performRoll = manager_action_damage_performRoll;
    --PowerManager.performAction = manager_power_performAction;
    
    -- option in house rule section, enable/disable allow PCs to edit advanced effects.
  OptionsManager.registerOption2("ADND_AE_EDIT", false, "option_header_houserule", "option_label_ADND_AE_EDIT", "option_entry_cycler", 
      { labels = "option_label_ADND_AE_enabled" , values = "enabled", baselabel = "option_label_ADND_AE_disabled", baseval = "disabled", default = "disabled" });    
end

function onClose()
  -- DB.removeHandler("charsheet.*.inventorylist.*.carried", "onUpdate", inventoryUpdateItemEffects);
  -- DB.removeHandler("charsheet.*.inventorylist.*.effectlist.*.effect", "onUpdate", updateItemEffectsForEdit);
  -- DB.removeHandler("charsheet.*.inventorylist.*.effectlist.*.durdice", "onUpdate", updateItemEffectsForEdit);
  -- DB.removeHandler("charsheet.*.inventorylist.*.effectlist.*.durmod", "onUpdate", updateItemEffectsForEdit);
  -- DB.removeHandler("charsheet.*.inventorylist.*.effectlist.*.name", "onUpdate", updateItemEffectsForEdit);
  -- DB.removeHandler("charsheet.*.inventorylist.*.effectlist.*.durunit", "onUpdate", updateItemEffectsForEdit);
  -- DB.removeHandler("charsheet.*.inventorylist.*.effectlist.*.visibility", "onUpdate", updateItemEffectsForEdit);
  -- DB.removeHandler("charsheet.*.inventorylist.*.effectlist.*.actiononly", "onUpdate", updateItemEffectsForEdit);
  -- DB.removeHandler("charsheet.*.inventorylist.*", "onChildDeleted", updateFromDeletedInventory);
end
------------------------------------------------------

-- run from addHandler for updated item effect options
function inventoryUpdateItemEffects(nodeField)
    updateItemEffects(DB.getChild(nodeField, ".."));
end
-- update single item from edit for *.effect handler
function updateItemEffectsForEdit(nodeField)
    checkEffectsAfterEdit(DB.getChild(nodeField, ".."));
end
-- find the effect for this source and delete and re-build
function checkEffectsAfterEdit(itemNode)
  local nodeChar = nil
  local bIDUpdated = false;
  if itemNode.getPath():match("%.effectlist%.") then
    nodeChar = DB.getChild(itemNode, ".....");
  else
    nodeChar = DB.getChild(itemNode, "...");
    bIDUpdated = true;
  end
  local nodeCT = CharManager.getCTNodeByNodeChar(nodeChar);
  if nodeCT then
    for _,nodeEffect in pairs(DB.getChildren(nodeCT, "effects")) do
      local sLabel = DB.getValue(nodeEffect, "label", "");
      local sEffSource = DB.getValue(nodeEffect, "source_name", "");
      -- see if the node exists and if it's in an inventory node
      local nodeEffectFound = DB.findNode(sEffSource);
      if (nodeEffectFound  and string.match(sEffSource,"inventorylist")) then
        local nodeEffectItem = nodeEffectFound.getChild("...");
        if nodeEffectFound == itemNode then -- effect hide/show edit
          nodeEffect.delete();
          updateItemEffects(DB.getChild(itemNode, "..."));
        elseif nodeEffectItem == itemNode then -- id state was changed
          nodeEffect.delete();
          updateItemEffects(nodeEffectItem);
        end
      end
    end
  end
end
-- this checks to see if an effect is missing a associated item that applied the effect 
-- when items are deleted and then clears that effect if it's missing.
function updateFromDeletedInventory(node)
    local nodeChar = DB.getChild(node, "..");
    local bisNPC = (not ActorManager.isPC(nodeChar));
    local nodeTarget = nodeChar;
    local nodeCT = CharManager.getCTNodeByNodeChar(nodeChar);
    -- if we're already in a combattracker situation (npcs)
    if bisNPC and string.match(nodeChar.getPath(),"^combattracker") then
        nodeCT = nodeChar;
    end
    if nodeCT then
        -- check that we still have the combat effect source item
        -- otherwise remove it
        checkEffectsAfterDelete(nodeCT);
    end
  --onEncumbranceChanged();
end

-- this checks to see if an effect is missing a associated item that applied the effect 
-- when items are deleted and then clears that effect if it's missing.
function checkEffectsAfterDelete(nodeChar)
    local sUser = User.getUsername();
    for _,nodeEffect in pairs(DB.getChildren(nodeChar, "effects")) do
        local sLabel = DB.getValue(nodeEffect, "label", "");
        local sEffSource = DB.getValue(nodeEffect, "source_name", "");
        -- see if the node exists and if it's in an inventory node
        local nodeFound = DB.findNode(sEffSource);
        local bDeleted = ((nodeFound == nil) and string.match(sEffSource,"inventorylist"));
        if (bDeleted) then
            local msg = {font = "msgfont", icon = "roll_effect"};
            msg.text = "Effect ['" .. sLabel .. "'] ";
            msg.text = msg.text .. "removed [from " .. DB.getValue(nodeChar, "name", "") .. "]";
            -- HANDLE APPLIED BY SETTING
            if sEffSource and sEffSource ~= "" then
                msg.text = msg.text .. " [by Deletion]";
            end
            if EffectManager.isGMEffect(nodeChar, nodeEffect) then
                if sUser == "" then
                    msg.secret = true;
                    Comm.addChatMessage(msg);
                elseif sUser ~= "" then
                    Comm.addChatMessage(msg);
                    Comm.deliverChatMessage(msg, sUser);
                end
            else
                Comm.deliverChatMessage(msg);
            end
            nodeEffect.delete();
        end
        
    end
end


---------------------------------------


-- add the effect if the item is equipped and doesn't exist already
function updateItemEffects(nodeItem)
--Debug.console("manager_effect_adnd.lua","updateItemEffects1","nodeItem",nodeItem);
--Debug.console("manager_effect_adnd.lua","updateItemEffects","User.isHost()",User.isHost());
    local nodeChar = DB.getChild(nodeItem, "...");
    if not nodeChar then
        return;
    end
--Debug.console("manager_effect_adnd.lua","updateItemEffects","nodeItem",nodeItem);
    local sName = DB.getValue(nodeItem, "name", "");
    -- we swap the node to the combat tracker node
    -- so the "effect" is written to the right node
    if not string.match(nodeChar.getPath(),"^combattracker") then
        nodeChar = CharManager.getCTNodeByNodeChar(nodeChar);
    end
--Debug.console("manager_effect_adnd.lua","updateItemEffects","nodeChar3",nodeChar);
    -- if not in the combat tracker bail
    if not nodeChar then
        return;
    end
    
    local nCarried = DB.getValue(nodeItem, "carried", 0);
    local bEquipped = (nCarried == 2);
    local nIdentified = DB.getValue(nodeItem, "isidentified", 1);
    -- local bOptionID = OptionsManager.isOption("MIID", "on");
    -- if not bOptionID then 
        -- nIdentified = 1;
    -- end
-- Debug.console("manager_effect_adnd.lua","updateItemEffects","sUser",sUser);
-- Debug.console("manager_effect_adnd.lua","updateItemEffects","nodeChar",nodeChar);
-- Debug.console("manager_effect_adnd.lua","updateItemEffects","nodeItem",nodeItem);
-- Debug.console("manager_effect_adnd.lua","updateItemEffects","nCarried",nCarried);
-- Debug.console("manager_effect_adnd.lua","updateItemEffects","bEquipped",bEquipped);
-- Debug.console("manager_effect_adnd.lua","updateItemEffects","nIdentified",nIdentified);

    for _,nodeItemEffect in pairs(DB.getChildren(nodeItem, "effectlist")) do
        updateItemEffect(nodeItemEffect, sName, nodeChar, nil, bEquipped, nIdentified);
    end -- for item's effects list
end

-- update single effect for item
-- update single effect for item
function updateItemEffect(nodeItemEffect, sName, nodeChar, sUser, bEquipped, nIdentified)
    local sCharacterName = DB.getValue(nodeChar, "name", "");
    local sItemSource = nodeItemEffect.getPath();
    local sLabel = DB.getValue(nodeItemEffect, "effect", "");
-- Debug.console("manager_effect_adnd.lua","updateItemEffect","bEquipped",bEquipped);    
--Debug.console("manager_effect_adnd.lua","updateItemEffect","nodeItemEffect",nodeItemEffect);  
    if sLabel and sLabel ~= "" then -- if we have effect string
        local bFound = false;
        for _,nodeEffect in pairs(DB.getChildren(nodeChar, "effects")) do
            local nActive = DB.getValue(nodeEffect, "isactive", 0);
            local nDMOnly = DB.getValue(nodeEffect, "isgmonly", 0);
            if (nActive ~= 0) then
                local sEffSource = DB.getValue(nodeEffect, "source_name", "");
                if (sEffSource == sItemSource) then
                    bFound = true;
                    if (not bEquipped) then
                        sendEffectRemovedMessage(nodeChar, nodeEffect, sLabel, nDMOnly, sUser)
                        nodeEffect.delete();
                        break;
                    end -- not equipped
                end -- effect source == item source
            end -- was active
        end -- nodeEffect for
        
        if (not bFound and bEquipped) then
            local rEffect = {};
            local nRollDuration = 0;
            local dDurationDice = DB.getValue(nodeItemEffect, "durdice");
            local nModDice = DB.getValue(nodeItemEffect, "durmod", 0);
            if (dDurationDice and dDurationDice ~= "") then
                nRollDuration = StringManager.evalDice(dDurationDice, nModDice);
            else
                nRollDuration = nModDice;
            end
            local nDMOnly = 0;
            local sVisibility = DB.getValue(nodeItemEffect, "visibility", "");
--Debug.console("manager_effect_adnd.lua","updateItemEffect","sVisibility",sVisibility);
--Debug.console("manager_effect_adnd.lua","updateItemEffect","nIdentified",nIdentified);

            if sVisibility == "hide" then
                nDMOnly = 1;
            elseif sVisibility == "show"  then
                nDMOnly = 0;
            elseif nIdentified == 0 then
                nDMOnly = 1;
            elseif nIdentified > 0  then
                nDMOnly = 0;
            end
            
            rEffect.nDuration = nRollDuration;
            rEffect.sName = sName .. ";" .. sLabel;
            rEffect.sLabel = sLabel; 
            rEffect.sUnits = DB.getValue(nodeItemEffect, "durunit", "");
            rEffect.nInit = 0;
            rEffect.sSource = sItemSource;
            rEffect.nGMOnly = nDMOnly;
            rEffect.sApply = "";
            
            sendEffectAddedMessage(nodeChar, rEffect, sLabel, nDMOnly, sUser)
            EffectManager.addEffect("", "", nodeChar, rEffect, false);
        end
    end
end


-- flip through all pc/npc effectslist (generally do this in addNPC()/addPC()
-- nodeChar: node of PC/NPC in PC/NPCs record list
-- nodeEntry: node in combat tracker for PC/NPC
function updateCharEffects(nodeChar,nodeEntry)
    for _,nodeCharEffect in pairs(DB.getChildren(nodeChar, "effectlist")) do
        updateCharEffect(nodeCharEffect,nodeEntry);
    end -- for item's effects list 
end
-- apply effect from npc/pc/item to the node
-- nodeCharEffect: node in effectlist on PC/NPC
-- nodeEntry: node in combat tracker for PC/NPC
function updateCharEffect(nodeCharEffect,nodeEntry)
    local sUser = User.getUsername();
    local sName = DB.getValue(nodeEntry, "name", "");
    local sLabel = DB.getValue(nodeCharEffect, "effect", "");
    local nRollDuration = 0;
    local dDurationDice = DB.getValue(nodeCharEffect, "durdice");
    local nModDice = DB.getValue(nodeCharEffect, "durmod", 0);
    if (dDurationDice and dDurationDice ~= "") then
        nRollDuration = StringManager.evalDice(dDurationDice, nModDice);
    else
        nRollDuration = nModDice;
    end
--Debug.console("manager_effect_adnd.lua","updateCharEffect","nRollDuration",nRollDuration);
    local nDMOnly = 0;
    local sVisibility = DB.getValue(nodeCharEffect, "visibility", "");
    if sVisibility == "show" then
        nDMOnly = 0;
    elseif sVisibility == "hide" then
        nDMOnly = 1;
    end
--Debug.console("manager_effect_adnd.lua","updateCharEffect","sVisibility",sVisibility);

    local rEffect = {};
    rEffect.nDuration = nRollDuration;
    --rEffect.sName = sName .. ";" .. sLabel;
    rEffect.sName = sLabel;
    rEffect.sLabel = sLabel; 
    rEffect.sUnits = DB.getValue(nodeCharEffect, "durunit", "");
    rEffect.nInit = 0;
    --rEffect.sSource = nodeEntry.getPath();
    rEffect.nGMOnly = nDMOnly;
    rEffect.sApply = "";
    --EffectManager.addEffect("", "", nodeEntry, rEffect, true);
    
    --notifyEffectAdd(nodeEntry,rEffect);
    EffectManager.addEffect("", "", nodeEntry, rEffect, false);
    sendEffectAddedMessage(nodeEntry, rEffect, sLabel, nDMOnly);
end

-- get the Connected Player's name that has this identity
function getUserFromNode(node)
  local sNodePath = node.getPath();
  local _, sRecord = DB.getValue(node, "link", "", "");    
  local sUser = nil;
  for _,vUser in ipairs(User.getActiveUsers()) do
    for _,vIdentity in ipairs(User.getActiveIdentities(vUser)) do
      if (sRecord == ("charsheet." .. vIdentity)) then
        sUser = vUser;
        break;
      end
    end
  end
  return sUser;
end

-- build message to send that effect removed
function sendEffectRemovedMessage(nodeChar, nodeEffect, sLabel, nDMOnly)
  local sUser = getUserFromNode(nodeChar);
--Debug.console("manager_effect_adnd.lua","sendEffectRemovedMessage","sUser",sUser);  
  local sCharacterName = DB.getValue(nodeChar, "name", "");
  -- Build output message
  local msg = ChatManager.createBaseMessage(ActorManager.getActorFromCT(nodeChar),sUser);
  msg.text = "Advanced Effect ['" .. sLabel .. "'] ";
  msg.text = msg.text .. "removed [from " .. sCharacterName .. "]";
  -- HANDLE APPLIED BY SETTING
  local sEffSource = DB.getValue(nodeEffect, "source_name", "");    
  if sEffSource and sEffSource ~= "" then
      msg.text = msg.text .. " [by " .. DB.getValue(DB.findNode(sEffSource), "name", "") .. "]";
  end
  sendRawMessage(sUser,nDMOnly,msg);
end
-- build message to send that effect added
function sendEffectAddedMessage(nodeCT, rNewEffect, sLabel, nDMOnly)
  local sUser = getUserFromNode(nodeCT);
--Debug.console("manager_effect_adnd.lua","sendEffectAddedMessage","sUser",sUser);  
  -- Build output message
  local msg = ChatManager.createBaseMessage(ActorManager.getActorFromCT(nodeCT),sUser);
  msg.text = "Advanced Effect ['" .. rNewEffect.sName .. "'] ";
  msg.text = msg.text .. "-> [to " .. DB.getValue(nodeCT, "name", "") .. "]";
  if rNewEffect.sSource and rNewEffect.sSource ~= "" then
    msg.text = msg.text .. " [by " .. DB.getValue(DB.findNode(rNewEffect.sSource), "name", "") .. "]";
  end
    sendRawMessage(sUser,nDMOnly,msg);
end
-- send message
function sendRawMessage(sUser, nDMOnly, msg)
  local sIdentity = nil;
  if sUser and sUser ~= "" then 
    sIdentity = User.getCurrentIdentity(sUser) or nil;
  end
  if sIdentity then
    msg.icon = "portrait_" .. User.getCurrentIdentity(sUser) .. "_chat";
  else
    msg.font = "msgfont";
    msg.icon = "roll_effect";
  end
  if nDMOnly == 1 then
      msg.secret = true;
      Comm.addChatMessage(msg);
  elseif nDMOnly ~= 1 then 
      --Comm.addChatMessage(msg);
      Comm.deliverChatMessage(msg);
  end
end

-- pass effect to here to see if the effect is being triggered
-- by an item and if so if it's valid
function isValidCheckEffect(rActor,nodeEffect)
    local bResult = false;
    local nActive = DB.getValue(nodeEffect, "isactive", 0);
    local bItem = false;
    local bActionItemUsed = false;
    local bActionOnly = false;
    local nodeItem = nil;

    local sSource = DB.getValue(nodeEffect,"source_name","");
    -- if source is a valid node and we can find "actiononly"
    -- setting then we set it.
    local node = DB.findNode(sSource);
    if (node and node ~= nil) then
        nodeItem = node.getChild("...");
        if nodeItem and nodeItem ~= nil then
            bActionOnly = (DB.getValue(node,"actiononly",0) ~= 0);
        end
    end

    -- if there is a itemPath do some sanity checking
    if (rActor.itemPath and rActor.itemPath ~= "") then 
        -- here is where we get the node path of the item, not the 
        -- effectslist entry
        if ((DB.findNode(rActor.itemPath) ~= nil)) then
            if (node and node ~= nil and nodeItem and nodeItem ) then
                local sNodePath = nodeItem.getPath();
                if bActionOnly and sNodePath ~= "" and (sNodePath == rActor.itemPath) then
                    bActionItemUsed = true;
                    bItem = true;
                else
                    bActionItemUsed = false;
                    bItem = true; -- is item but doesn't match source path for this effect
                end
            end
        end
    end
--Debug.console("manager_effect_adnd.lua","isValidCheckEffect","nActive",nActive);    
--Debug.console("manager_effect_adnd.lua","isValidCheckEffect","bActionOnly",bActionOnly);    
--Debug.console("manager_effect_adnd.lua","isValidCheckEffect","bActionItemUsed",bActionItemUsed);    
    if nActive ~= 0 and bActionOnly and bActionItemUsed then
        bResult = true;
    elseif nActive ~= 0 and not bActionOnly and bActionItemUsed then
        bResult = true;
    elseif nActive ~= 0 and bActionOnly and not bActionItemUsed then
        bResult = false;
    elseif nActive ~= 0 then
        bResult = true;
    end
--Debug.console("manager_effect_adnd.lua","isValidCheckEffect","bResult",bResult);    
  -- if ( nActive ~= 0 and ( not bItem or (bItem and bActionItemUsed) ) ) then
        -- bResult = true;
    -- elseif nActive ~= 0 and bActionOnly and not (bItem or bActionItemUsed) then
        -- bResult = false;
    -- elseif nActive ~= 0 and (not bActionOnly and bItem) then
        -- bResult = true;
    -- end
    return bResult;
end



--
--          REPLACEMENT FUNCTIONS
--
-- CoreRPG EffectManager manager_effect_adnd.lua 
-- AD&D CORE ONLY
local aEffectVarMap = {
  ["sName"] = { sDBType = "string", sDBField = "label" },
  ["nGMOnly"] = { sDBType = "number", sDBField = "isgmonly" },
  ["sSource"] = { sDBType = "string", sDBField = "source_name", bClearOnUntargetedDrop = true },
  ["sTarget"] = { sDBType = "string", bClearOnUntargetedDrop = true },
  ["nDuration"] = { sDBType = "number", sDBField = "duration", vDBDefault = 1, sDisplay = "[D: %d]" },
  ["nInit"] = { sDBType = "number", sDBField = "init", sSourceChangeSet = "initresult", bClearOnUntargetedDrop = true },
};
-- replace CoreRPG EffectManager manager_effect_adnd.lua onInit() with this
-- AD&D CORE ONLY
function manager_effect_onInit()
  --CombatManager.setCustomInitChange(manager_effect_processEffects);
  OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYEFF, handleApplyEffect);
  OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_EXPIREEFF, handleExpireEffect);
end

-- replace 5E EffectManager5E manager_effect_5E.lua evalAbilityHelper() with this
-- AD&D CORE ONLY
function evalAbilityHelper(rActor, sEffectAbility)
  -- local sSign, sModifier, sShortAbility = sEffectAbility:match("^%[([%+%-]?)([H2]?)([A-Z][A-Z][A-Z])%]$");
  
  -- local nAbility = nil;
  -- if sShortAbility == "STR" then
    -- nAbility = ActorManager2.getAbilityBonus(rActor, "strength");
  -- elseif sShortAbility == "DEX" then
    -- nAbility = ActorManager2.getAbilityBonus(rActor, "dexterity");
  -- elseif sShortAbility == "CON" then
    -- nAbility = ActorManager2.getAbilityBonus(rActor, "constitution");
  -- elseif sShortAbility == "INT" then
    -- nAbility = ActorManager2.getAbilityBonus(rActor, "intelligence");
  -- elseif sShortAbility == "WIS" then
    -- nAbility = ActorManager2.getAbilityBonus(rActor, "wisdom");
  -- elseif sShortAbility == "CHA" then
    -- nAbility = ActorManager2.getAbilityBonus(rActor, "charisma");
  -- elseif sShortAbility == "LVL" then
    -- nAbility = ActorManager2.getAbilityBonus(rActor, "level");
  -- elseif sShortAbility == "PRF" then
    -- nAbility = ActorManager2.getAbilityBonus(rActor, "prf");
  -- end
  
  -- if nAbility then
    -- if sSign == "-" then
      -- nAbility = 0 - nAbility;
    -- end
    -- if sModifier == "H" then
      -- if nAbility > 0 then
        -- nAbility = math.floor(nAbility / 2);
      -- else
        -- nAbility = math.ceil(nAbility / 2);
      -- end
    -- elseif sModifier == "2" then
      -- nAbility = nAbility * 2;
    -- end
  -- end
  
  -- return nAbility;
    return 0;
end

-- replace CoreRPG ActionsManager manager_actions.lua decodeActors() with this
function decodeActors(draginfo)
--Debug.console("manager_effect_Adnd.lua","decodeActors","draginfo",draginfo);
--printstack();
  local rSource = nil;
  local aTargets = {};
    
  
  for k,v in ipairs(draginfo.getShortcutList()) do
    if k == 1 then
      rSource = ActorManager.getActor(v.class, v.recordname);
    else
      local rTarget = ActorManager.getActor(v.class, v.recordname);
      if rTarget then
        table.insert(aTargets, rTarget);
      end
    end
  end

    -- itemPath data filled if itemPath if exists
    local sItemPath = draginfo.getMetaData("itemPath");
    local sSpellPath = draginfo.getMetaData("spellPath");
--Debug.console("manager_effect_Adnd.lua","decodeActors","sItemPath",sItemPath);
    if (sItemPath and sItemPath ~= "") then
        rSource.itemPath = sItemPath;
    end
    if (sSpellPath and sSpellPath ~= "") then
        rSource.spellPath = sSpellPath;
    end
    --
    
  return rSource, aTargets;
end

-- replace 5E EffectManager5E manager_effect_5E.lua getEffectsByType() with this
function getEffectsByType(rActor, sEffectType, aFilter, rFilterActor, bTargetedOnly)
-- Debug.console("manager_effect_adnd.lua","getEffectsByType","==rActor",rActor);    
-- Debug.console("manager_effect_adnd.lua","getEffectsByType","==sEffectType",sEffectType);    
  if not rActor then
    return {};
  end
  local results = {};
--Debug.console("manager_effect_adnd.lua","getEffectsByType","------------>rActor",rActor);    
  
  -- Set up filters
  local aRangeFilter = {};
  local aOtherFilter = {};
  if aFilter then
    for _,v in pairs(aFilter) do
      if type(v) ~= "string" then
        table.insert(aOtherFilter, v);
      elseif StringManager.contains(DataCommon.rangetypes, v) then
        table.insert(aRangeFilter, v);
      else
        table.insert(aOtherFilter, v);
      end
    end
  end
  
  -- Determine effect type targeting
  local bTargetSupport = StringManager.isWord(sEffectType, DataCommon.targetableeffectcomps);
  
--Debug.console("manager_effect_adnd.lua","getEffectsByType","rActor",rActor);    
--Debug.console("manager_effect_adnd.lua","getEffectsByType","sEffectType",sEffectType);    
-- Debug.console("manager_effect_adnd.lua","getEffectsByType","aFilter",aFilter);    
-- Debug.console("manager_effect_adnd.lua","getEffectsByType","rFilterActor",rFilterActor);    
-- Debug.console("manager_effect_adnd.lua","getEffectsByType","bTargetedOnly",bTargetedOnly);    

  -- Iterate through effects
  for _,v in pairs(DB.getChildren(ActorManager.getCTNode(rActor), "effects")) do
    -- Check active
    local nActive = DB.getValue(v, "isactive", 0);
    --if ( nActive ~= 0 and ( not bItemTriggered or (bItemTriggered and bItemSource) ) ) then
        if (EffectManagerADND.isValidCheckEffect(rActor,v)) then
      local sLabel = DB.getValue(v, "label", "");
      local sApply = DB.getValue(v, "apply", "");

      -- IF COMPONENT WE ARE LOOKING FOR SUPPORTS TARGETS, THEN CHECK AGAINST OUR TARGET
      local bTargeted = EffectManager.isTargetedEffect(v);
      if not bTargeted or EffectManager.isEffectTarget(v, rFilterActor) then
        local aEffectComps = EffectManager.parseEffect(sLabel);

        -- Look for type/subtype match
        local nMatch = 0;
        for kEffectComp,sEffectComp in ipairs(aEffectComps) do
          local rEffectComp = EffectManager5E.parseEffectComp(sEffectComp);
          -- Handle conditionals
          if rEffectComp.type == "IF" then
            if not EffectManager5E.checkConditional(rActor, v, rEffectComp.remainder) then
              break;
            end
          elseif rEffectComp.type == "IFT" then
            if not rFilterActor then
              break;
            end
            if not EffectManager5E.checkConditional(rFilterActor, v, rEffectComp.remainder, rActor) then
              break;
            end
            bTargeted = true;
          
          -- Compare other attributes
          else
            -- Strip energy/bonus types for subtype comparison
            local aEffectRangeFilter = {};
            local aEffectOtherFilter = {};
            local j = 1;
            while rEffectComp.remainder[j] do
              local s = rEffectComp.remainder[j];
              if #s > 0 and ((s:sub(1,1) == "!") or (s:sub(1,1) == "~")) then
                s = s:sub(2);
              end
              if StringManager.contains(DataCommon.dmgtypes, s) or s == "all" or 
                  StringManager.contains(DataCommon.bonustypes, s) or
                  StringManager.contains(DataCommon.conditions, s) or
                  StringManager.contains(DataCommon.connectors, s) then
                -- SKIP
              elseif StringManager.contains(DataCommon.rangetypes, s) then
                table.insert(aEffectRangeFilter, s);
              else
                table.insert(aEffectOtherFilter, s);
              end
              
              j = j + 1;
            end
          
            -- Check for match
            local comp_match = false;
            if rEffectComp.type == sEffectType then

              -- Check effect targeting
              if bTargetedOnly and not bTargeted then
                comp_match = false;
              else
                comp_match = true;
              end
            
              -- Check filters
              if #aEffectRangeFilter > 0 then
                local bRangeMatch = false;
                for _,v2 in pairs(aRangeFilter) do
                  if StringManager.contains(aEffectRangeFilter, v2) then
                    bRangeMatch = true;
                    break;
                  end
                end
                if not bRangeMatch then
                  comp_match = false;
                end
              end
              if #aEffectOtherFilter > 0 then
                local bOtherMatch = false;
                for _,v2 in pairs(aOtherFilter) do
                  if type(v2) == "table" then
                    local bOtherTableMatch = true;
                    for k3, v3 in pairs(v2) do
                      if not StringManager.contains(aEffectOtherFilter, v3) then
                        bOtherTableMatch = false;
                        break;
                      end
                    end
                    if bOtherTableMatch then
                      bOtherMatch = true;
                      break;
                    end
                  elseif StringManager.contains(aEffectOtherFilter, v2) then
                    bOtherMatch = true;
                    break;
                  end
                end
                if not bOtherMatch then
                  comp_match = false;
                end
              end
            end

            -- Match!
            if comp_match then
              nMatch = kEffectComp;
              if nActive == 1 then
                table.insert(results, rEffectComp);
              end
            end
          end
        end -- END EFFECT COMPONENT LOOP

-- Debug.console("manager_effect_adnd.lua","getEffectsByType","END EFFECT COMPONENT LOOP");    
-- Debug.console("manager_effect_adnd.lua","getEffectsByType","nMatch",nMatch);    
-- Debug.console("manager_effect_adnd.lua","getEffectsByType","sApply",sApply);    
-- Debug.console("manager_effect_adnd.lua","getEffectsByType","v",v);    

        -- Remove one shot effects
        if nMatch > 0 then
          if nActive == 2 then
            DB.setValue(v, "isactive", "number", 1);
          else
            if sApply == "action" then
              EffectManager.notifyExpire(v, 0);
            elseif sApply == "roll" then
              EffectManager.notifyExpire(v, 0, true);
            elseif sApply == "single" then
              EffectManager.notifyExpire(v, nMatch, true);
            end
          end
        end
      end -- END TARGET CHECK
    end  -- END ACTIVE CHECK
  end  -- END EFFECT LOOP
  
  -- RESULTS
  return results;
end

-- replace 5E EffectManager5E manager_effect_5E.lua hasEffect() with this
function hasEffect(rActor, sEffect, rTarget, bTargetedOnly, bIgnoreEffectTargets)
  if not sEffect or not rActor then
    return false;
  end
  local sLowerEffect = sEffect:lower();
  
  -- Iterate through each effect
  local aMatch = {};
--Debug.console("manager_effect_adnd.lua","hasEffect","rActor",rActor);    
--Debug.console("manager_effect_adnd.lua","hasEffect","sEffect",sEffect);    
--Debug.console("manager_effect_adnd.lua","hasEffect","rTarget",rTarget);    
--Debug.console("manager_effect_adnd.lua","hasEffect","bIgnoreEffectTargets",bIgnoreEffectTargets);    
--Debug.console("manager_effect_adnd.lua","hasEffect","bTargetedOnly",bTargetedOnly);    
  for _,v in pairs(DB.getChildren(ActorManager.getCTNode(rActor), "effects")) do
    local nActive = DB.getValue(v, "isactive", 0);
        if (EffectManagerADND.isValidCheckEffect(rActor,v)) then
      -- Parse each effect label
      local sLabel = DB.getValue(v, "label", "");
      local bTargeted = EffectManager.isTargetedEffect(v);
      local aEffectComps = EffectManager.parseEffect(sLabel);

      -- Iterate through each effect component looking for a type match
      local nMatch = 0;
      for kEffectComp,sEffectComp in ipairs(aEffectComps) do
        local rEffectComp = EffectManager5E.parseEffectComp(sEffectComp);
        -- Handle conditionals
        if rEffectComp.type == "IF" then
          if not EffectManager5E.checkConditional(rActor, v, rEffectComp.remainder) then
            break;
          end
        elseif rEffectComp.type == "IFT" then
          if not rTarget then
            break;
          end
          if not EffectManager5E.checkConditional(rTarget, v, rEffectComp.remainder, rActor) then
            break;
          end
        
        -- Check for match
        elseif rEffectComp.original:lower() == sLowerEffect then
          if bTargeted and not bIgnoreEffectTargets then
            if EffectManager.isEffectTarget(v, rTarget) then
              nMatch = kEffectComp;
            end
          elseif not bTargetedOnly then
            nMatch = kEffectComp;
          end
        end
        
      end

-- Debug.console("manager_effect_adnd.lua","hasEffect","nMatch",nMatch);    
-- Debug.console("manager_effect_adnd.lua","hasEffect","sApply",sApply);    
      -- If matched, then remove one-off effects
      if nMatch > 0 then
        if nActive == 2 then
          DB.setValue(v, "isactive", "number", 1);
        else
          table.insert(aMatch, v);
          local sApply = DB.getValue(v, "apply", "");
          if sApply == "action" then
            EffectManager.notifyExpire(v, 0);
          elseif sApply == "roll" then
            EffectManager.notifyExpire(v, 0, true);
          elseif sApply == "single" then
            EffectManager.notifyExpire(v, nMatch, true);
          end
        end
      end
    end
  end
  
  if #aMatch > 0 then
    return true;
  end
  return false;
end

-- replace 5E EffectManager5E manager_effect_5E.lua checkConditional() with this
function checkConditional(rActor, nodeEffect, aConditions, rTarget, aIgnore)
  local bReturn = true;
  
  if not aIgnore then
    aIgnore = {};
  end
  table.insert(aIgnore, nodeEffect.getNodeName());
  
  for _,v in ipairs(aConditions) do
    local sLower = v:lower();
    if sLower == DataCommon.healthstatusfull then
      local nPercentWounded = ActorManager2.getPercentWounded(rActor);
      if nPercentWounded > 0 then
        bReturn = false;
      end
    elseif sLower == DataCommon.healthstatushalf then
      local nPercentWounded = ActorManager2.getPercentWounded(rActor);
      if nPercentWounded < .5 then
        bReturn = false;
      end
    elseif sLower == DataCommon.healthstatuswounded then
      local nPercentWounded = ActorManager2.getPercentWounded(rActor);
      if nPercentWounded == 0 then
        bReturn = false;
      end
    elseif StringManager.contains(DataCommon.conditions, sLower) then
      if not EffectManager5E.checkConditionalHelper(rActor, sLower, rTarget, aIgnore) then
        bReturn = false;
      end
    elseif StringManager.contains(DataCommon.conditionaltags, sLower) then
      if not EffectManager5E.checkConditionalHelper(rActor, sLower, rTarget, aIgnore) then
        bReturn = false;
      end
    else
      local sAlignCheck = sLower:match("^align%s*%(([^)]+)%)$");
      local sSizeCheck = sLower:match("^size%s*%(([^)]+)%)$");
      local sTypeCheck = sLower:match("^type%s*%(([^)]+)%)$");
      local sCustomCheck = sLower:match("^custom%s*%(([^)]+)%)$");
      local sArmorCheck = sLower:match("^armor%s*%(([^)]+)%)$");
      if sAlignCheck then
        if not ActorManager2.isAlignment(rActor, sAlignCheck) then
          bReturn = false;
        end
      elseif sSizeCheck then
        if not ActorManager2.isSize(rActor, sSizeCheck) then
          bReturn = false;
        end
      elseif sTypeCheck then
        if not ActorManager2.isCreatureType(rActor, sTypeCheck) then
          bReturn = false;
        end
      elseif sCustomCheck then
        if not EffectManager5E.checkConditionalHelper(rActor, sCustomCheck, rTarget, aIgnore) then
          bReturn = false;
        end
      elseif sArmorCheck then
        if not ActorManagerADND.isArmorType(rActor, sArmorCheck) then
          bReturn = false;
        end
      end
    end
  end
  
  table.remove(aIgnore);
  
  return bReturn;
end

-- replace 5E EffectManager5E manager_effect_5E.lua checkConditionalHelper() with this
function checkConditionalHelper(rActor, sEffect, rTarget, aIgnore)
  if not rActor then
    return false;
  end
  
  local bReturn = false;
  
  for _,v in pairs(DB.getChildren(ActorManager.getCTNode(rActor), "effects")) do
    local nActive = DB.getValue(v, "isactive", 0);
        if (EffectManagerADND.isValidCheckEffect(rActor,v) and not StringManager.contains(aIgnore, v.getNodeName())) then
    --if nActive ~= 0 and not StringManager.contains(aIgnore, v.getNodeName()) then
      -- Parse each effect label
      local sLabel = DB.getValue(v, "label", "");
      local bTargeted = EffectManager.isTargetedEffect(v);
      local aEffectComps = EffectManager.parseEffect(sLabel);

      -- Iterate through each effect component looking for a type match
      local nMatch = 0;
      for kEffectComp, sEffectComp in ipairs(aEffectComps) do
        local rEffectComp = EffectManager5E.parseEffectComp(sEffectComp);
        -- CHECK FOR FOLLOWON EFFECT TAGS, AND IGNORE THE REST
        if rEffectComp.type == "AFTER" or rEffectComp.type == "FAIL" then
          break;
        
        -- CHECK CONDITIONALS
        elseif rEffectComp.type == "IF" then
          if not EffectManager5E.checkConditional(rActor, v, rEffectComp.remainder, nil, aIgnore) then
            break;
          end
        elseif rEffectComp.type == "IFT" then
          if not rTarget then
            break;
          end
          if not EffectManager5E.checkConditional(rTarget, v, rEffectComp.remainder, rActor, aIgnore) then
            break;
          end
        
        -- CHECK FOR AN ACTUAL EFFECT MATCH
        elseif rEffectComp.original:lower() == sEffect then
          if bTargeted then
            if EffectManager.isEffectTarget(v, rTarget) then
              bReturn = true;
            end
          else
            bReturn = true;
          end
        end
      end
    end
  end
  
  return bReturn;
end

-- replace 5E ActionDamage manager_action_damage.lua performRoll() with this
-- extension only
function manager_action_damage_performRoll(draginfo, rActor, rAction)
  local rRoll = ActionDamage.getRoll(rActor, rAction);

    if (draginfo and rActor.itemPath and rActor.itemPath ~= "") then
        draginfo.setMetaData("itemPath",rActor.itemPath);
--Debug.console("manager_effect_adnd.lua","manager_action_damage_performRoll","rActor.itemPath",rActor.itemPath);    
    end
  
  ActionsManager.performAction(draginfo, rActor, rRoll);
end

-- replace 5E ActionAttack manager_action_attack.lua performRoll() with this
-- extension only
function manager_action_attack_performRoll(draginfo, rActor, rAction)
  local rRoll = ActionAttack.getRoll(rActor, rAction);

    if (draginfo and rActor.itemPath and rActor.itemPath ~= "") then
        draginfo.setMetaData("itemPath",rActor.itemPath);
--Debug.console("manager_effect_adnd.lua","manager_action_attack_performRoll","rActor.itemPath",rActor.itemPath);    
    end
    
  ActionsManager.performAction(draginfo, rActor, rRoll);
end

-- replace 5E PowerManager manager_power.lua performAction() with this
-- extension only
function manager_power_performAction(draginfo, rActor, rAction, nodePower)
  if not rActor or not rAction then
    return false;
  end
  
    -- add itemPath to rActor so that when effects are checked we can 
    -- make compare against action only effects
    local nodeWeapon = nodeAction.getChild("...");
    local _, sRecord = DB.getValue(nodeWeapon, "shortcut", "", "");
  rActor.itemPath = sRecord;
    if (draginfo and rActor.itemPath and rActor.itemPath ~= "") then
        draginfo.setMetaData("itemPath",rActor.itemPath);
    end
    --

  evalAction(rActor, nodePower, rAction);

  local rRolls = {};
  if rAction.type == "cast" then
    rAction.subtype = (rAction.subtype or "");
    if rAction.subtype == "" then
      table.insert(rRolls, ActionPower.getPowerCastRoll(rActor, rAction));
    end
    if ((rAction.subtype == "") or (rAction.subtype == "atk")) and rAction.range then
      table.insert(rRolls, ActionAttack.getRoll(rActor, rAction));
    end
    if ((rAction.subtype == "") or (rAction.subtype == "save")) and ((rAction.save or "") ~= "") then
      table.insert(rRolls, ActionPower.getSaveVsRoll(rActor, rAction));
    end
  
  elseif rAction.type == "attack" then
    table.insert(rRolls, ActionAttack.getRoll(rActor, rAction));
    
  elseif rAction.type == "powersave" then
    table.insert(rRolls, ActionPower.getSaveVsRoll(rActor, rAction));

  elseif rAction.type == "damage" then
    table.insert(rRolls, ActionDamage.getRoll(rActor, rAction));
    
  elseif rAction.type == "heal" then
    table.insert(rRolls, ActionHeal.getRoll(rActor, rAction));
    
  elseif rAction.type == "effect" then
    local rRoll = ActionEffect.getRoll(draginfo, rActor, rAction);
    if rRoll then
      table.insert(rRolls, rRoll);
    end
  end
  
  if #rRolls > 0 then
    ActionsManager.performMultiAction(draginfo, rActor, rRolls[1].sType, rRolls);
  end
  return true;
end

-- these functions we run with initiative value changes
function updateForInitiative(nodeField)
  updateEffectsForNewInitiative(nodeField);
end

-- run these functions when initiative is ROLLED
function updateForInitiativeRolled(nodeField)
  if ManagerCharlistADND then
    ManagerCharlistADND.onUpdate(nodeField);
  end
end

-- when player's initiative changes we run this to update effect for new "initiative" if it's not 0
function updateEffectsForNewInitiative(nodeField)
  local nodeCT = nodeField.getParent();
  local nInitResult = DB.getValue(nodeCT,"initresult",0);
  for _,nodeEffect in pairs(DB.getChildren(nodeCT, "effects")) do
    local nInit = DB.getValue(nodeEffect,"init",0);
    if (nInit ~= 0) then 
      -- change effect init to the new value rolled
      DB.setValue(nodeEffect,"init","number", nInitResult);
    end
  end
end

---- replace for Psionic nonsense
function onEffectActorStartTurn(nodeActor, nodeEffect)
  local sEffName = DB.getValue(nodeEffect, "label", "");
  local aEffectComps = EffectManager.parseEffect(sEffName);
    for _,sEffectComp in ipairs(aEffectComps) do
    local rEffectComp = EffectManager5E.parseEffectComp(sEffectComp);
    -- Conditionals
    if rEffectComp.type == "IFT" then
      break;
    elseif rEffectComp.type == "IF" then
      local rActor = ActorManager.getActorFromCT(nodeActor);
      if not EffectManager5E.checkConditional(rActor, nodeEffect, rEffectComp.remainder) then
        break;
      end
    
    -- Ongoing damage and regeneration
    elseif rEffectComp.type == "DMGO" or rEffectComp.type == "REGEN" or rEffectComp.type == "DMGPSPO" then
      local nActive = DB.getValue(nodeEffect, "isactive", 0);
      if nActive == 2 then
        DB.setValue(nodeEffect, "isactive", "number", 1);
      else
        applyOngoingDamageAdjustment(nodeActor, nodeEffect, rEffectComp);
      end

    -- NPC power recharge
    elseif rEffectComp.type == "RCHG" then
      local nActive = DB.getValue(nodeEffect, "isactive", 0);
      if nActive == 2 then
        DB.setValue(nodeEffect, "isactive", "number", 1);
      else
        EffectManager5E.applyRecharge(nodeActor, nodeEffect, rEffectComp);
      end
    end
  end
end

function applyOngoingDamageAdjustment(nodeActor, nodeEffect, rEffectComp)
  if #(rEffectComp.dice) == 0 and rEffectComp.mod == 0 then
    return;
  end
  
  local rTarget = ActorManager.getActor("ct", nodeActor);
  if rEffectComp.type == "REGEN" then
    local nPercentWounded = ActorManager2.getPercentWounded2("ct", nodeActor);
    
    -- If not wounded, then return
    if nPercentWounded <= 0 then
      return;
    end
    -- Regeneration does not work once creature falls below 1 hit point
    if nPercentWounded >= 1 then
      return;
    end
    
    local rAction = {};
    rAction.label = "Regeneration";
    rAction.clauses = {};
    
    local aClause = {};
    aClause.dice = rEffectComp.dice;
    aClause.modifier = rEffectComp.mod;
    table.insert(rAction.clauses, aClause);
    
    local rRoll = ActionHeal.getRoll(nil, rAction);
    if EffectManager.isGMEffect(nodeActor, nodeEffect) then
      rRoll.bSecret = true;
    end
    ActionsManager.actionDirect(nil, "heal", { rRoll }, { { rTarget } });
  elseif rEffectComp.type == "DMGO" then
    local rAction = {};
    rAction.label = "Ongoing damage";
    rAction.clauses = {};
    
    local aClause = {};
    aClause.dice = rEffectComp.dice;
    aClause.modifier = rEffectComp.mod;
    aClause.dmgtype = string.lower(table.concat(rEffectComp.remainder, ","));
    table.insert(rAction.clauses, aClause);
    
    local rRoll = ActionDamage.getRoll(nil, rAction);
    if EffectManager.isGMEffect(nodeActor, nodeEffect) then
      rRoll.bSecret = true;
    end
    ActionsManager.actionDirect(nil, "damage", { rRoll }, { { rTarget } });
  elseif rEffectComp.type == "DMGPSPO" then
    local rAction = {};
    rAction.label = "Ongoing PSP expenditure";
    rAction.clauses = {};
    
    local aClause = {};
    aClause.dice = rEffectComp.dice;
    aClause.modifier = rEffectComp.mod;
    aClause.dmgtype = string.lower(table.concat(rEffectComp.remainder, ","));
    table.insert(rAction.clauses, aClause);
    
    local rRoll = ActionDamagePSP.getRoll(nil, rAction);
    if EffectManager.isGMEffect(nodeActor, nodeEffect) then
      rRoll.bSecret = true;
    end
    ActionsManager.actionDirect(nil, "damage_psp", { rRoll }, { { rTarget } });
  end
end
---- end psionic work

--function adndOnEffectAddStart(rNewEffect)
--Debug.console("manager_effect_adnd.lua","adndOnEffectAddStart","rNewEffect",rNewEffect); 
--end

-- AD&D Core only function, rolls dice rolls in [xDx] boxes
-- used for STR: [1d5] style effects, only rolled when applied.
-- moved to AddEnd instead of start because here we get the target node and
-- we can do stuff fancy stuff since we have target node 
-- like [$STR/2] or [$LVL*10], [$ARCANE*10] [$DIVINE*12] 
-- (generic level, arcane level, divine level)
function adndOnEffectAddEnd(nodeTargetEffect, rNewEffect)
  local nodeTarget = nodeTargetEffect.getChild("...");
  local nodeChar = ActorManager.getCreatureNode(nodeTarget);
  local bisPC = (ActorManager.getType(nodeTarget) == "pc");
  local bNodeSourceIsPC = false;
  local nodeCaster = nil;
  if (bisPC) then
    nodeCaster = nodeChar;
  else
    nodeCaster = nodeTarget;
  end
  
Debug.console("manager_effect_adnd.lua","adndOnEffectAddEnd","nodeTarget",nodeTarget); 
Debug.console("manager_effect_adnd.lua","adndOnEffectAddEnd","nodeTargetEffect",nodeTargetEffect); 
Debug.console("manager_effect_adnd.lua","adndOnEffectAddEnd","rNewEffect",rNewEffect); 
  -- setup a nodeSource 
  local sSource = rNewEffect.sSource;
Debug.console("manager_effect_adnd.lua","adndOnEffectAddEnd","sSource",sSource); 
  local nodeSource = nodeCaster; -- if no sSource then it's based from the caster?
  if (sSource and sSource ~= "") then 
    nodeSource = DB.findNode(sSource);
Debug.console("manager_effect_adnd.lua","adndOnEffectAddEnd","nodeSource1",nodeSource); 
    if (nodeSource) then
      bNodeSourceIsPC = (ActorManager.getType(nodeSource) == "pc");
Debug.console("manager_effect_adnd.lua","adndOnEffectAddEnd","bNodeSourceIsPC",bNodeSourceIsPC); 
      if bNodeSourceIsPC then
        nodeSource = ActorManager.getCreatureNode(nodeSource);
Debug.console("manager_effect_adnd.lua","adndOnEffectAddEnd","nodeSource2",nodeSource); 
      end
    end
  else
    --nodeSource = nodeCaster;
Debug.console("manager_effect_adnd.lua","adndOnEffectAddEnd","nodeSource3",nodeSource); 
  end
  -- end nodeSource
Debug.console("manager_effect_adnd.lua","adndOnEffectAddEnd","nodeSource4",nodeSource); 
  local sEffectFullString = "";
  local sName = rNewEffect.sName;
    -- split the name/label for effect for each:
    -- STRING: tag;STRING: tag;STRING: tag; 
    -- to table of "STRING: tag"
  local aEachEffect = StringManager.split(sName,";",true);
  -- flip through each sEffectName and look for dice
  for _,sEffectName in pairs(aEachEffect) do
    local sNewName = sEffectName;
  -- MATCH [1d6] string in effect text 
    for sDice in string.gmatch(sEffectName,"%[%d+[dD]%d+%]") do
      local aDice,nMod = StringManager.convertStringToDice(sDice);
      local nRoll = StringManager.evalDice(aDice,nMod);
      sNewName = sNewName:gsub("%[%d+[dD]%d+%]",tostring(nRoll));
Debug.console("manager_effect_adnd.lua","adndOnEffectAddStart","Dice rolled for effect:",sEffectName,"nRoll=",nRoll);
    end  -- for sDice
    
Debug.console("manager_effect_adnd.lua","adndOnEffectAddStart","sNewName",sNewName);
    -- find anything else in []'s and consider it a math function with macros
    -- like [$STR*2] or [$DEX/3] or [$LVL*10]
    local nStart, nEnd, sFound = sNewName:find("%[(.*)%]");
    if nStart and nEnd and sFound then     
Debug.console("manager_effect_adnd.lua","adndOnEffectAddStart","nStart",nStart);
Debug.console("manager_effect_adnd.lua","adndOnEffectAddStart","nEnd",nEnd);    
Debug.console("manager_effect_adnd.lua","adndOnEffectAddStart","sFound0",sFound);    
      for sMacro in string.gmatch(sFound,"%$(%w+)") do
Debug.console("manager_effect_adnd.lua","adndOnEffectAddStart","sMacro",sMacro);   
        -- match STR|DEX|CON/etc..
        local sStatName = DataCommon.ability_stol[sMacro];
        if (sStatName) then
          if bisPC then
            local nodeChar = ActorManager.getCreatureNode(nodeTarget);
            nScore = DB.getValue(nodeChar,"abilities." .. sStatName .. ".total",0);
          else
            nScore = DB.getValue(nodeTarget,"abilities." .. sStatName .. ".total",0);
          end
        sFound = sFound:gsub("%$" .. sMacro,tostring(nScore));
Debug.console("manager_effect_adnd.lua","adndOnEffectAddStart","sFound1",sFound);    
        end -- end found sStatName

        -- these need to be run by the source, not the target.
        if nodeSource then
          -- -- match for $LVL
          sFound = sFound:gsub("%$LEVEL",tostring(CharManager.getActiveClassMaxLevel(nodeSource)));
          -- -- match for $ARCANE
          sFound = sFound:gsub("%$ARCANE",tostring(PowerManager.getCasterLevelByType(nodeSource,"arcane",bNodeSourceIsPC)));
          -- -- match for $DIVINE
          sFound = sFound:gsub("%$DIVINE",tostring(PowerManager.getCasterLevelByType(nodeSource,"divine",bNodeSourceIsPC)));
        end
        
      end -- end sMacro fore
Debug.console("manager_effect_adnd.lua","adndOnEffectAddStart","sFound2",sFound);    
      local nDiceResult = math.floor(StringManager.evalDiceMathExpression(sFound));
Debug.console("manager_effect_adnd.lua","adndOnEffectAddStart","nDiceResult",nDiceResult);    
      -- start/end widened because we dont include []'s in search start/end
      sNewName = CoreUtilities.replaceStringAt(sNewName,tostring(nDiceResult),nStart-1,nEnd)
Debug.console("manager_effect_adnd.lua","adndOnEffectAddStart","sNewName",sNewName);    
    end

    local sSep = "";
    if sEffectFullString ~= "" then
      sSep = ";";
    end
    sEffectFullString = sEffectFullString .. sSep .. sNewName;
  end -- for sEffectName
  -- we changed the effect name so update
  if (sEffectFullString ~= "") then
    --DB.setValue(nodeTargetEffect,"name","string",sEffectFullString);
    DB.setValue(nodeTargetEffect,"label","string",sEffectFullString);
    rNewEffect.sName = sEffectFullString;
  end
end
