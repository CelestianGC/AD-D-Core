--
-- AD&D Specific combat needs
--
--

function onInit()
  -- replace default roll with adnd_roll to allow
  -- control-dice click to prompt for manual roll
  ActionsManager.roll = adnd_roll;
  --

  -- replace this with ours
  CombatManager.nextActor = nextActor;
  CombatManager.addBattle = addBattle;
  CombatManager2.rollRandomInit = rollRandomInit;
  ----
  CombatManager.setCustomSort(sortfuncADnD);
  CombatManager.setCustomAddNPC(addNPC);
  CombatManager.setCustomAddPC(addPC);
  
  CombatManager.setCustomCombatReset(resetInit);
  
  CombatManager.setCustomRoundStart(onRoundStart);
  
  CombatManager.setCustomTurnStart(onTurnStart);

  if User.isHost() then
    DB.addHandler("combattracker.list.*.active", "onUpdate", updateInititiativeIndicator);
    updateAllInititiativeIndicators();
  end
end

function resetInit()
  function resetCombatantInit(nodeCT)
    DB.setValue(nodeCT, "initresult", "number", 0);
    DB.setValue(nodeCT, "reaction", "number", 0);
    
    --set not rolled initiative portrait icon to active on new round
    CharlistManagerADND.turnOffInitRolled(nodeCT);
  end
  CombatManager.callForEachCombatant(resetCombatantInit);
end

function rollRandomInit(nMod, bADV)
  local nInitResult = math.random(DataCommonADND.nDefaultInitiativeDice);
  if bADV then
    nInitResult = math.max(nInitResult, math.random(DataCommonADND.nDefaultInitiativeDice));
  end
  nInitResult = nInitResult + nMod;
  return nInitResult;
end

function onRoundStart(nCurrent)
  if OptionsManager.isOption("HouseRule_InitEachRound", "on") then
    CombatManager2.rollInit();
  end
  -- toggle portrait initiative icon
  CharlistManagerADND.turnOffAllInitRolled();
end

function onTurnStart(nodeEntry)
	if not nodeEntry then
		return;
	end
	
	-- Handle beginning of turn changes
	DB.setValue(nodeEntry, "reaction", "number", 0);
end

-- get widget
function getHasInitiativeWidget(nodeField)
--Debug.console("manager_combat_adnd","getHasInitiativeWidget","nodeField",nodeField);     
  local widgetInitIndicator = nil;
  local nodeCT = nodeField;
  local tokenCT = CombatManager.getTokenFromCT(nodeCT);
  if (tokenCT) then
    widgetInitIndicator = tokenCT.findWidget("initiativeindicator");
    if not widgetInitIndicator then
      widgetInitIndicator = createWidget(tokenCT,nodeCT);
    end
  end
  return widgetInitIndicator;
end
-- create has initiative indicator widget if it doesn't exist.
function createWidget(tokenCT,nodeCT)
  local sInitiativeIconName = "token_has_initiative";
  local nWidth, nHeight = tokenCT.getSize();
  local nScale = tokenCT.getScale();
  local sName = DB.getValue(nodeCT,"name","Unknown");
  widgetInitIndicator = tokenCT.addBitmapWidget(sInitiativeIconName);
  widgetInitIndicator.setBitmap(sInitiativeIconName);
  widgetInitIndicator.setName("initiativeindicator");
  widgetInitIndicator.setTooltipText(sName .. " has initiative.");
  --widgetInitIndicator.setPosition("top", 0, 0);
  widgetInitIndicator.setPosition("center", 0, 0);
  --widgetInitIndicator.setSize(nWidth*2, nHeight*2);
  return widgetInitIndicator;
end

-- show/hide widget
function setInitiativeIndicator(widgetInitIndicator,bShowINIT)
  if widgetInitIndicator then
    widgetInitIndicator.setVisible(bShowINIT);
  end
end

-- update has initiative first time start up
function updateAllInititiativeIndicators()
  for _,vChild in pairs(CombatManager.getCombatantNodes()) do
    local bActive = (DB.getValue(vChild,"active",0) == 1);
    setInitiativeIndicator(getHasInitiativeWidget(vChild),bActive);
  end
end
-- update has initiative first time start up
function updateInititiativeIndicator(nodeField)
  local nodeCT = nodeField.getParent();
  local bActive = (DB.getValue(nodeCT,"active",0) == 1);
  setInitiativeIndicator(getHasInitiativeWidget(nodeCT),bActive);
end

--
--
-- AD&D Style ordering (low to high initiative)
--
function sortfuncADnD(node2, node1)
  local bHost = User.isHost();
  local sOptCTSI = OptionsManager.getOption("CTSI");
  
  local sFaction1 = DB.getValue(node1, "friendfoe", "");
  local sFaction2 = DB.getValue(node2, "friendfoe", "");
  
  local bShowInit1 = bHost or ((sOptCTSI == "friend") and (sFaction1 == "friend")) or (sOptCTSI == "on");
  local bShowInit2 = bHost or ((sOptCTSI == "friend") and (sFaction2 == "friend")) or (sOptCTSI == "on");
  
  if bShowInit1 ~= bShowInit2 then
    if bShowInit1 then
      return true;
    elseif bShowInit2 then
      return false;
    end
  else
    if bShowInit1 then
      local nValue1 = DB.getValue(node1, "initresult", 0);
      local nValue2 = DB.getValue(node2, "initresult", 0);
      if nValue1 ~= nValue2 then
        return nValue1 > nValue2;
      end
      
      nValue1 = DB.getValue(node1, "init", 0);
      nValue2 = DB.getValue(node2, "init", 0);
      if nValue1 ~= nValue2 then
        return nValue1 > nValue2;
      end
    else
      if sFaction1 ~= sFaction2 then
        if sFaction1 == "friend" then
          return true;
        elseif sFaction2 == "friend" then
          return false;
        end
      end
    end
  end
  
  local sValue1 = DB.getValue(node1, "name", "");
  local sValue2 = DB.getValue(node2, "name", "");
  if sValue1 ~= sValue2 then
    return sValue1 < sValue2;
  end

  return node1.getNodeName() < node2.getNodeName();
end

---
-- NPC functions
---
-- calculate npc level from HD and return it -celestian
-- move to manager_action_save.lua?
function getNPCLevelFromHitDice(nodeNPC) 
    local nLevel = 1;
    local nHitDice = 0;
    local sHitDice = DB.getValue(nodeNPC, "hitDice", "1");
    if (sHitDice) then
        -- Match #-#, #+# or just #
        -- (\d+)([\-\+])?(\d+)?
        -- Full match  0-4  `12+3`
        -- Group 1.  0-2  `12`
        -- Group 2.  2-3  `+`
        -- Group 3.  3-4  `3`
        local nAdjustment = 0;
        local match1, match2, match3 = sHitDice:match("(%d+)([%-+])(%d+)");
        if (match1 and not match2) then -- single digit
            nHitDice = tonumber(match1);
        elseif (match1 and match2 and match3) then -- match x-x or x+x
            nHitDice = tonumber(match1);
            -- minus
            if (match2 == "-") then
                nAdjustment = tonumber(match2 .. match3);
            else -- plus
                nAdjustment = tonumber(match3);
            end
            if (nAdjustment ~= 0) then
                local nFourCount = (nAdjustment/4);
                if (nFourCount < 0) then
                    nFourCount = math.ceil(nFourCount);
                else
                    nFourCount = math.floor(nFourCount);
                end
                nLevel = (nHitDice+nFourCount);
            else -- adjust = 0
                nLevel = nHitDice;
            end -- nAdjustment
        else -- didn't find X-X or X+x-x
            match1 = sHitDice:match("(%d+)");
            if (match1) then -- single digit
                nHitDice = tonumber(match1);
                nLevel = nHitDice;
            else
                -- pop up menu and ask them for a decent value? -celestian
                ChatManager.SystemMessage("Unable to find a working hitDice [" .. sHitDice .. "] for " .. DB.getValue(nodeNPC, "name", "") .." to calculate saves. It should be # or #+# or #-#."); 
                nAdjustment = 0;
                nHitDice = 0;
            end
        end
    end -- hitDice
    
    return nLevel;
end

-- get NPC HitDice for use on Matrix chart.
-- Smaller than 1-1 (-1)
-- 1-1
-- 1
-- 1+
-- ...
-- 16+
function getNPCHitDice(nodeNPC)
--Debug.console("manager_combat_adnd","getNPCHitDice","nodeNPC",nodeNPC);  
  local sSantizedHitDice = "-1";
  local sHitDice = DB.getValue(nodeNPC, "hitDice", "1");
  local s1, s2, s3 = sHitDice:match("(%d+)([%-+])(%d+)");
  if s1 and s2 and s3 then
    -- deal with 1+,1-2,1-1
    if s1 == "1" then
      if s2 == "+" then
        sSantizedHitDice = "1+";
      elseif (s2 == "-") and ((tonumber(s3) or 0) < 1) then -- if 1-X and X > 1
        sSantizedHitDice = "-1";
      else
        sSantizedHitDice = "1-1";
      end
    else
      local nHD = tonumber(s1) or 16;
      if nHD > 16 then
        sSantizedHitDice = "16";
      else
        sSantizedHitDice = s1;
      end
    end
  elseif s1 then
    sSantizedHitDice = s1;
  else -- no string matched
    sSantizedHitDice = sHitDice:match("(%d+)");
  end
  
--Debug.console("manager_combat_adnd","getNPCHitDice","sSantizedHitDice",sSantizedHitDice);  
  return sSantizedHitDice;
end

-- return the Best ac hit from a roll for this NPC
function getACHitFromMatrixForNPC(nodeNPC,nRoll)
  local nACHit = 20;
  local sHitDice = getNPCHitDice(nodeNPC);
--Debug.console("manager_combat_adnd","getACHitFromMatrixForNPC","DataCommonADND.aMatrix",DataCommonADND.aMatrix);         
  if DataCommonADND.aMatrix[sHitDice] then
    local aMatrixRolls = DataCommonADND.aMatrix[sHitDice];
-- Debug.console("manager_combat_adnd","getACHitFromMatrixForNPC","DataCommonADND.aMatrix[sHitDice]",DataCommonADND.aMatrix[sHitDice]);         
-- Debug.console("manager_combat_adnd","getACHitFromMatrixForNPC","aMatrixRolls",aMatrixRolls);         
    -- starting from AC -10 and work up till we find match to our nRoll
    --for i=-10,10,1 do
    for i=21,1,-1 do
      local sCurrentTHAC = "thac" .. i;
      local nAC = 11 - i;
      local nCurrentTHAC = aMatrixRolls[i];
-- Debug.console("manager_combat_adnd","getACHitFromMatrixForNPC","sCurrentTHAC",sCurrentTHAC);        
-- Debug.console("manager_combat_adnd","getACHitFromMatrixForNPC","nAC",nAC);        
-- Debug.console("manager_combat_adnd","getACHitFromMatrixForNPC","nCurrentTHAC",nCurrentTHAC);        
      if nCurrentTHAC == nRoll then
        -- find first AC that matches our roll
        nACHit = nAC;
        break;
      end
    end
    
  end
--Debug.console("manager_combat_adnd","getACHitFromMatrixForNPC","nACHit",nACHit);    
  return nACHit;
end

-- return the Best ac hit from a roll for PC
function getACHitFromMatrixForPC(nodePC,nRoll)
  local nACHit = 20;
  local nodeCombat = nodePC.createChild("combat"); -- make sure these exist
  local nodeMATRIX = nodeCombat.createChild("matrix"); -- make sure these exist
  
  -- starting from AC -10 and work up till we find match to our nRoll
  for i=-10,10,1 do
    local sCurrentTHAC = "thac" .. i;
    local nAC = i;
    local nCurrentTHAC = DB.getValue(nodeMATRIX,sCurrentTHAC, 100);
    if nCurrentTHAC == nRoll then
      -- find first AC that matches our roll
      nACHit = i;
      break;
    end
  end
--Debug.console("manager_combat_adnd","getACHitFromMatrixForPC","nACHit",nACHit);        
  return nACHit;
end

-- return best AC Hit for this node (pc/npc) from Matrix with this nRoll
function getACHitFromMatrix(node,nRoll)
  local nACHit = 20;
  --local bisNPC = (not ActorManager.isPC(node));
  --local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);
  -- get the link from the combattracker record to see what this is.
	local bisPC = (node.getPath():match("^charsheet%."));
  if (bisPC) then
    nACHit = getACHitFromMatrixForPC(node,nRoll);
  else
    -- NPCs get this from matrix for HD value
    nACHit = getACHitFromMatrixForNPC(node,nRoll);
  end
  
--Debug.console("manager_combat_adnd","getACHitFromMatrix","nACHit",nACHit);        
  return nACHit;
end

-- Set NPC Saves -celestian
-- move to manager_action_save.lua?
function updateNPCSaves(nodeEntry, nodeNPC, bForceUpdate)
--    Debug.console("manager_combat2.lua","updateNPCSaves","nodeNPC",nodeNPC);
    if  (bForceUpdate) or (DB.getChildCount(nodeNPC, "saves") <= 0) then
        for i=1,10,1 do
            local sSave = DataCommon.saves[i];
            local nSave = DB.getValue(nodeNPC, "saves." .. sSave .. ".score", -1);
            if (nSave <= 0 or bForceUpdate) then
                ActionSave.setNPCSave(nodeEntry, sSave, nodeNPC)
            end
        end
    end
end
-- set Level, Arcane/Divine levels based on HD "level"
function updateNPCLevels(nodeNPC, bForceUpdate) 
    if  (bForceUpdate) then
      local nLevel = getNPCLevelFromHitDice(nodeNPC);
      DB.setValue(nodeNPC, "arcane.totalLevel","number",nLevel);
      DB.setValue(nodeNPC, "divine.totalLevel","number",nLevel);
      DB.setValue(nodeNPC, "psionic.totalLevel","number",nLevel);
      DB.setValue(nodeNPC, "level","number",nLevel);
    end
end

-- remove everything in (*) because thats DM only "Orc (3HD)" and return "Orc"
function stripHiddenNameText(sStr)
  return StringManager.trim(sStr:gsub("%(.*%)", "")); 
end
-- get the hidden portion in "name" within ()'s and return it, "Orc (3HD)" and return "(3HD)"
function getHiddenNameText(sStr)
  return string.match(sStr, "%(.*%)");
end

function addNPC(sClass, nodeNPC, sName)
--Debug.console("manager_combat2.lua","addNPC","sClass",sClass);
  local sNPCFullName = DB.getValue(nodeNPC,"name","");
  local sNPCName = stripHiddenNameText(sNPCFullName);
  local sNPCNameHidden = getHiddenNameText(sNPCFullName);
  
  if sName == nil then 
    sName = sNPCName; -- set name to non-hidden part
  else
    sNPCNameHidden = getHiddenNameText(sName);
    sName = stripHiddenNameText(sName);
  end
  
  local nodeEntry, nodeLastMatch = CombatManager.addNPCHelper(nodeNPC, sName);
  
  -- save DM only "hiddten text" if necessary to display in host CT
  if sNPCNameHidden ~= nil and sNPCNameHidden ~= "" then
    DB.setValue(nodeEntry,"name_hidden","string",sNPCNameHidden);
  end

  -- update NPC Saves for HD
  updateNPCSaves(nodeEntry, nodeNPC);

  -- Fill in spells
  CampaignDataManager2.updateNPCSpells(nodeEntry);

  -- Set initiative from Dexterity modifier
--  local nDex = DB.getValue(nodeNPC, "abilities.dexterity.score", 10);
--  local nDexMod = math.floor((nDex - 10) / 2);
--  DB.setValue(nodeEntry, "init", "number", nDexMod);

  -- base modifier for initiative
  -- we set modifiers based on size per DMG for AD&D -celestian
  DB.setValue(nodeEntry, "init", "number", 0);
  
  -- Determine size
  local sSize = StringManager.trim(DB.getValue(nodeEntry, "size", ""):lower());
  local sSizeNoLower = StringManager.trim(DB.getValue(nodeEntry, "size", ""));
  if sSize == "tiny" or string.find(sSizeNoLower,"T") then
        -- tokenscale doesn't work, guessing it's "reset" when
        -- the token is actually dropped on the map
        -- need to figure out a work around -celestian
    DB.setValue(nodeEntry, "tokenscale", "number", 0.5);
        DB.setValue(nodeEntry, "init", "number", 0);
  elseif sSize == "small" or string.find(sSizeNoLower,"S") then
        -- tokenscale doesn't work, guessing it's "reset" when
        -- the token is actually dropped on the map
    DB.setValue(nodeEntry, "tokenscale", "number", 0.75);
        DB.setValue(nodeEntry, "init", "number", 3);
  elseif sSize == "medium" or string.find(sSizeNoLower,"M") then
        DB.setValue(nodeEntry, "init", "number", 3);
  elseif sSize == "large" or string.find(sSizeNoLower,"L") then
    DB.setValue(nodeEntry, "space", "number", 10);
        DB.setValue(nodeEntry, "init", "number", 6);
  elseif sSize == "huge" or string.find(sSizeNoLower,"H") then
    DB.setValue(nodeEntry, "space", "number", 15);
        DB.setValue(nodeEntry, "init", "number", 9);
  elseif sSize == "gargantuan" or string.find(sSizeNoLower,"G") then
    DB.setValue(nodeEntry, "space", "number", 20);
        DB.setValue(nodeEntry, "init", "number", 12);
  end
    -- if the combat window initiative is set to something, use it instead --celestian
    local nInitMod = DB.getValue(nodeNPC, "initiative.total", 0);
    if nInitMod ~= 0 then
        DB.setValue(nodeEntry, "init", "number", nInitMod);
    end

  local nHP = rollNPCHitPoints(nodeNPC);
  DB.setValue(nodeEntry, "hptotal", "number", nHP);
  
  -- Track additional damage types and intrinsic effects
  local aEffects = {};
  
  -- Vulnerabilities
  local aVulnTypes = CombatManager2.parseResistances(DB.getValue(nodeEntry, "damagevulnerabilities", ""));
  if #aVulnTypes > 0 then
    for _,v in ipairs(aVulnTypes) do
      if v ~= "" then
        table.insert(aEffects, "VULN: " .. v);
      end
    end
  end
      
  -- Damage Resistances
  local aResistTypes = CombatManager2.parseResistances(DB.getValue(nodeEntry, "damageresistances", ""));
  if #aResistTypes > 0 then
    for _,v in ipairs(aResistTypes) do
      if v ~= "" then
        table.insert(aEffects, "RESIST: " .. v);
      end
    end
  end
  
  -- Damage immunities
  local aImmuneTypes = CombatManager2.parseResistances(DB.getValue(nodeEntry, "damageimmunities", ""));
  if #aImmuneTypes > 0 then
    for _,v in ipairs(aImmuneTypes) do
      if v ~= "" then
        table.insert(aEffects, "IMMUNE: " .. v);
      end
    end
  end

  -- Condition immunities
  local aImmuneCondTypes = {};
  local sCondImmune = DB.getValue(nodeEntry, "conditionimmunities", ""):lower();
  for _,v in ipairs(StringManager.split(sCondImmune, ",;\r", true)) do
    if StringManager.isWord(v, DataCommon.conditions) then
      table.insert(aImmuneCondTypes, v);
    end
  end
  if #aImmuneCondTypes > 0 then
    table.insert(aEffects, "IMMUNE: " .. table.concat(aImmuneCondTypes, ", "));
  end
  
  -- Decode traits and actions
    -- if it has no actions... 
    if DB.getChildCount(nodeEntry, "actions") == 0 then
        -- add a single default entry that has at least a melee attack, ranged attack, simple damage and saves for each type. -celestian
        --Debug.console("manager_combat2.lua","addNPC","!Actions",DB.getChildren(nodeEntry, "actions"));
        local nodeDefaultActions = nodeEntry.createChild("actions");
    if nodeDefaultActions then
      local nodeDefaultAction = nodeDefaultActions.createChild();
      if nodeDefaultAction then
        DB.setValue(nodeDefaultAction, "name", "string", "Default:");
        DB.setValue(nodeDefaultAction, "desc", "string", "Melee Weapon Attack: +0 to hit. Ranged Weapon Attack: +0 to hit. Hit: 1d6 slashing damage.\rVictims must make a saving throw versus spell. Victims must make a saving throw versus poison. Victims must make a saving throw versus rod.\rVictims must make a saving throw versus polymorph. Victims must make a saving throw versus breath.");
      end
    end
    end

  -- -- Add special effects
  if #aEffects > 0 then
    EffectManager.addEffect("", "", nodeEntry, { sName = table.concat(aEffects, "; "), nDuration = 0, nGMOnly = 1 }, false);
  end

    -- check to see if npc effects exists and if so apply --celestian
    EffectManagerADND.updateCharEffects(nodeNPC,nodeEntry);
    
    -- now flip through inventory and pass each to updateEffects()
    -- so that if they have a combat_effect it will be applied.
    for _,nodeItem in pairs(DB.getChildren(nodeEntry, "inventorylist")) do
        EffectManagerADND.updateItemEffects(nodeItem,true);
    end
    -- end
    
  -- Roll initiative and sort
  local sOptINIT = OptionsManager.getOption("INIT");
    if (nInitMod == 0) then
        nInitMod = DB.getValue(nodeEntry, "init", 0);
    end
    local nInitiativeRoll = math.random(DataCommonADND.nDefaultInitiativeDice) + nInitMod;
  if sOptINIT == "group" then
    if nodeLastMatch then
      local nLastInit = DB.getValue(nodeLastMatch, "initresult", 0);
      DB.setValue(nodeEntry, "initresult", "number", nLastInit);
    else
      DB.setValue(nodeEntry, "initresult", "number", nInitiativeRoll);
    end
  elseif sOptINIT == "on" then
    DB.setValue(nodeEntry, "initresult", "number", nInitiativeRoll);
  end

    -- set mode/display default to standard/actions
    DB.setValue(nodeEntry,"powermode","string", "standard");
    DB.setValue(nodeEntry,"powerdisplaymode","string","action");
    
    -- sanitize special defense/attack string
    setSpecialDefenseAttack(nodeEntry);
    
    
  return nodeEntry;
end

-- generate hitpoint value for NPC and return it
function rollNPCHitPoints(nodeNPC)
  -- Set current hit points
  local sOptHRNH = OptionsManager.getOption("HRNH");
  local nHP = DB.getValue(nodeNPC, "hp", 0);
  if (nHP == 0) then -- if HP value not set, we roll'm
    local sHD = StringManager.trim(DB.getValue(nodeNPC, "hd", ""));
    if sOptHRNH == "max" and sHD ~= "" then
      -- max hp
      nHP = StringManager.evalDiceString(sHD, true, true);
    elseif sOptHRNH == "random" and sHD ~= "" then
      nHP = math.max(StringManager.evalDiceString(sHD, true), 1);
      elseif sOptHRNH == "80plus" and sHD ~= "" then        
          -- roll hp, if it's less than 80% of what max then set to 80% of max
          -- i.e. if hp max is 100, 80% of that is 80. If the random is less than
          -- that the value will be set to 80.
          local nMaxHP = StringManager.evalDiceString(sHD, true, true);
          local n80 = math.floor(nMaxHP * 0.8);
          nHP = math.max(StringManager.evalDiceString(sHD, true), 1);
          if (nHP < n80) then
              nHP = n80;
          end
    end
  end
  return nHP
end

-- clean up and create special attack and defense strings.
function setSpecialDefenseAttack(node)
    local sSD = DB.getValue(node,"specialDefense",""):lower();
    local sSA = DB.getValue(node,"specialAttacks",""):lower();

    local sDefense = "";
    local sAttacks = "";
    if (not string.match(sSD,"nil") and not string.match(sSD,"see desc") and sSD ~= "") then
        sDefense = DB.getValue(node,"specialDefense","");
    end
    if (not string.match(sSA,"nil") and not string.match(sSA,"see desc") and sSA ~= "") then
        sAttacks = DB.getValue(node,"specialAttacks","");
    end
    
    DB.setValue(node,"specialDefense","string",sDefense);
    DB.setValue(node,"specialAttacks","string",sAttacks);
end


---
-- PC functions
---
-- custom version of the one in CoreRPG to deal with adding new 
-- pcs to the combat tracker to deal with item effects. --celestian
function addPC(nodePC)
  -- Parameter validation
  if not nodePC then
    return;
  end

  -- Create a new combat tracker window
  local nodeEntry = DB.createChild("combattracker.list");
  if not nodeEntry then
    return;
  end
  
  -- Set up the CT specific information
  DB.setValue(nodeEntry, "link", "windowreference", "charsheet", nodePC.getNodeName());
  DB.setValue(nodeEntry, "friendfoe", "string", "friend");

  local sToken = DB.getValue(nodePC, "token", nil);
  if not sToken or sToken == "" then
    sToken = "portrait_" .. nodePC.getName() .. "_token"
  end
  DB.setValue(nodeEntry, "token", "token", sToken);
    
    -- now flip through inventory and pass each to updateEffects()
    -- so that if they have a combat_effect it will be applied.
    for _,nodeItem in pairs(DB.getChildren(nodePC, "inventorylist")) do
        EffectManagerADND.updateItemEffects(nodeItem,true);
    end
    -- end

    -- check to see if npc effects exists and if so apply --celestian
    EffectManagerADND.updateCharEffects(nodePC,nodeEntry);

    -- make sure active users get ownership of their CT nodes
    -- otherwise effects applied by items/etc won't work.
    -- AccessManagerADND.manageCTOwners(nodeEntry);
end

function getTHAC(nodeChar,nRoll)

end

--
-- CoreRPG Replaced functions for customizations
--
--
function nextActor(bSkipBell, bNoRoundAdvance)
	if not User.isHost() then
		return;
	end

	local nodeActive = CombatManager.getActiveCT();
	local nIndexActive = 0;
	
	-- Check the skip hidden NPC option
	local bSkipHidden = OptionsManager.isOption("CTSH", "on");
  local bSkipDeadNPC = OptionsManager.isOption("CT_SKIP_DEAD_NPC", "on");
	
	-- Determine the next actor
	local nodeNext = nil;
	local aEntries = CombatManager.getSortedCombatantList();
	if #aEntries > 0 then
		if nodeActive then
			for i = 1,#aEntries do
				if aEntries[i] == nodeActive then
					nIndexActive = i;
					break;
				end
			end
		end
		if bSkipHidden or bSkipDeadNPC then
			local nIndexNext = 0;
			for i = nIndexActive + 1, #aEntries do
				if DB.getValue(aEntries[i], "friendfoe", "") == "friend" then
					nIndexNext = i;
					break;
				else
          local nPercentWounded = ActorManager2.getPercentWounded(aEntries[i]);
          local bisNPC = (not ActorManager.isPC(aEntries[i]));
          -- is the actor dead?
          local bSkipDead = (bSkipDeadNPC and bisNPC and nPercentWounded >= 1);
          -- is the actor hidden?
          local bSkipHiddenActor = (bSkipHidden and CombatManager.isCTHidden(aEntries[i]));
          
          if (not bSkipDead and not bSkipHiddenActor) then
						nIndexNext = i;
						break;
          end
        end
			end
			if nIndexNext > nIndexActive then
				nodeNext = aEntries[nIndexNext];
				for i = nIndexActive + 1, nIndexNext - 1 do
					CombatManager.showTurnMessage(aEntries[i], false);
				end
			end
		else
			nodeNext = aEntries[nIndexActive + 1];
		end
	end

	-- If next actor available, advance effects, activate and start turn
	if nodeNext then
		-- End turn for current actor
		CombatManager.onTurnEndEvent(nodeActive);
	
		-- Process effects in between current and next actors
		if nodeActive then
			CombatManager.onInitChangeEvent(nodeActive, nodeNext);
		else
			CombatManager.onInitChangeEvent(nil, nodeNext);
		end
		
		-- Start turn for next actor
		CombatManager.requestActivation(nodeNext, bSkipBell);
		CombatManager.onTurnStartEvent(nodeNext);
	elseif not bNoRoundAdvance then
		if bSkipHidden or bSkipDeadNPC then
			for i = nIndexActive + 1, #aEntries do
				CombatManager.showTurnMessage(aEntries[i], false);
			end
		end
		CombatManager.nextRound(1);
	end
end

-- replace default roll with adnd_roll to allow
-- control-dice click to prompt for manual roll
function adnd_roll(rSource, vTargets, rRoll, bMultiTarget)
  if #(rRoll.aDice) > 0 then
    if not rRoll.bTower and (OptionsManager.isOption("MANUALROLL", "on") or (User.isHost() and Input.isControlPressed())) then
      local wManualRoll = Interface.openWindow("manualrolls", "");
      wManualRoll.addRoll(rRoll, rSource, vTargets);
    else
      local rThrow = ActionsManager.buildThrow(rSource, vTargets, rRoll, bMultiTarget);
      Comm.throwDice(rThrow);
    end
  else
    if bMultiTarget then
      ActionsManager.handleResolution(rRoll, rSource, vTargets);
    else
      ActionsManager.handleResolution(rRoll, rSource, { vTargets });
    end
  end
end 

--
-- Replaced CoreRPG version of "addBattle()" so we can tweak hp/ac/weapon list
-- --celestian
--
function addBattle(nodeBattle)
	local aModulesToLoad = {};
	local sTargetNPCList = LibraryData.getCustomData("battle", "npclist") or "npclist";
	for _, vNPCItem in pairs(DB.getChildren(nodeBattle, sTargetNPCList)) do
		local sClass, sRecord = DB.getValue(vNPCItem, "link", "", "");
		if sRecord ~= "" then
			local nodeNPC = DB.findNode(sRecord);
			if not nodeNPC then
				local sModule = sRecord:match("@(.*)$");
				if sModule and sModule ~= "" and sModule ~= "*" then
					if not StringManager.contains(aModulesToLoad, sModule) then
						table.insert(aModulesToLoad, sModule);
					end
				end
			end
		end
		for _,vPlacement in pairs(DB.getChildren(vNPCItem, "maplink")) do
			local sClass, sRecord = DB.getValue(vPlacement, "imageref", "", "");
			if sRecord ~= "" then
				local nodeImage = DB.findNode(sRecord);
				if not nodeImage then
					local sModule = sRecord:match("@(.*)$");
					if sModule and sModule ~= "" and sModule ~= "*" then
						if not StringManager.contains(aModulesToLoad, sModule) then
							table.insert(aModulesToLoad, sModule);
						end
					end
				end
			end
		end
	end
	if #aModulesToLoad > 0 then
		local wSelect = Interface.openWindow("module_dialog_missinglink", "");
		wSelect.initialize(aModulesToLoad, onBattleNPCLoadCallback, { nodeBattle = nodeBattle });
		return;
	end
	
	if CombatManager.fCustomAddBattle then
		return CombatManager.fCustomAddBattle(nodeBattle);
	end
	
	-- Cycle through the NPC list, and add them to the tracker
	for _, vNPCItem in pairs(DB.getChildren(nodeBattle, sTargetNPCList)) do
		-- Get link database node
		local nodeNPC = nil;
		local sClass, sRecord = DB.getValue(vNPCItem, "link", "", "");
		if sRecord ~= "" then
			nodeNPC = DB.findNode(sRecord);
		end
		local sName = DB.getValue(vNPCItem, "name", "");
		
		if nodeNPC then
			local aPlacement = {};
			for _,vPlacement in pairs(DB.getChildren(vNPCItem, "maplink")) do
				local rPlacement = {};
				local _, sRecord = DB.getValue(vPlacement, "imageref", "", "");
				rPlacement.imagelink = sRecord;
				rPlacement.imagex = DB.getValue(vPlacement, "imagex", 0);
				rPlacement.imagey = DB.getValue(vPlacement, "imagey", 0);
				table.insert(aPlacement, rPlacement);
			end
			
			local nCount = DB.getValue(vNPCItem, "count", 0);
			for i = 1, nCount do
				local nodeEntry = CombatManager.addNPC(sClass, nodeNPC, sName);
				if nodeEntry then
					local sFaction = DB.getValue(vNPCItem, "faction", "");
					if sFaction ~= "" then
						DB.setValue(nodeEntry, "friendfoe", "string", sFaction);
					end
					local sToken = DB.getValue(vNPCItem, "token", "");
					if sToken == "" or not Interface.isToken(sToken) then
						local sLetter = StringManager.trim(sName):match("^([a-zA-Z])");
						if sLetter then
							sToken = "tokens/Medium/" .. sLetter:lower() .. ".png@Letter Tokens";
						else
							sToken = "tokens/Medium/z.png@Letter Tokens";
						end
					end
					if sToken ~= "" then
						DB.setValue(nodeEntry, "token", "token", sToken);
						
						if aPlacement[i] and aPlacement[i].imagelink ~= "" then
							TokenManager.setDragTokenUnits(DB.getValue(nodeEntry, "space"));
							local tokenAdded = Token.addToken(aPlacement[i].imagelink, sToken, aPlacement[i].imagex, aPlacement[i].imagey);
							TokenManager.endDragTokenWithUnits(nodeEntry);
							if tokenAdded then
								TokenManager.linkToken(nodeEntry, tokenAdded);
							end
						end
					end
					
					-- Set identification state from encounter record, and disable source link to prevent overriding ID for existing CT entries when identification state changes
					local sSourceClass,sSourceRecord = DB.getValue(nodeEntry, "sourcelink", "", "");
					DB.setValue(nodeEntry, "sourcelink", "windowreference", "", "");
					DB.setValue(nodeEntry, "isidentified", "number", DB.getValue(vNPCItem, "isidentified", 1));
					DB.setValue(nodeEntry, "sourcelink", "windowreference", sSourceClass, sSourceRecord);
				else
					ChatManager.SystemMessage(Interface.getString("ct_error_addnpcfail") .. " (" .. sName .. ")");
				end
        
        -- add custom features for 2E ruleset hp/ac/weapon
        local nHP = DB.getValue(vNPCItem,"hp",0);
        local nAC = DB.getValue(vNPCItem,"ac",11);
        local sWeaponList = DB.getValue(vNPCItem,"weapons","");
        if (nHP ~= 0) then
          DB.setValue(nodeEntry, "hp", "number", nHP);
          DB.setValue(nodeEntry, "hptotal", "number", nHP);
        end
        if (nAC <= 10) then
          DB.setValue(nodeEntry, "ac", "number", nAC);
        end
        if (sWeaponList ~= "") then
          local aWeapons = StringManager.split(sWeaponList, ",", true);
          for _,sWeapon in ipairs(StringManager.split(sWeaponList, ";", true)) do
            local nodeSourceWeapon = CoreUtilities.getWeaponNodeByName(sWeapon);
            if nodeSourceWeapon then
              local nodeWeapons = nodeEntry.createChild("weaponlist");
              for _,v in pairs(DB.getChildren(nodeSourceWeapon, "weaponlist")) do
                local nodeWeapon = nodeWeapons.createChild();
                DB.copyNode(v,nodeWeapon);
                local sName = DB.getValue(v,"name","");
                local sText = DB.getValue(v,"text","");
                DB.setValue(nodeWeapon,"itemnote.name","string",sName);
                DB.setValue(nodeWeapon,"itemnote.text","formattedtext",sText);
                DB.setValue(nodeWeapon,"itemnote.locked","number",1);
              end
            else
              ChatManager.SystemMessage("Encounter [" .. DB.getValue(nodeBattle,"name","") .. "], unable to find weapon [" .. sWeapon .. "] for NPC [" .. DB.getValue(nodeEntry,"name","") .."].");
            end
          end -- for weapons
        end -- end weaponlist
        ---- end custom stuff for 2E ruleset encounter spawns
        
			end -- end for
		else
			ChatManager.SystemMessage(Interface.getString("ct_error_addnpcfail2") .. " (" .. sName .. ")");
		end
	end
	
	Interface.openWindow("combattracker_host", "combattracker");
end

