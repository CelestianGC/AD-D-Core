--
--
-- Library of tools to use for importing text for npc, spells and other things
--
--
--

function onInit()
end

function onClose()
end

-- ignore case
function nocase(pattern)
  -- find an optional '%' (group 1) followed by any character (group 2)
  local p = pattern:gsub("(%%?)(.)", function(percent, letter)
    if percent ~= "" or not letter:match("%a") then
      -- if the '%' matched, or `letter` is not a letter, return "as is"
      return percent .. letter
    else
      -- else, return a case-insensitive character class of the matched letter
      return string.format("[%s%s]", letter:lower(), letter:upper())
    end

  end)
  return p
end

-- set generic text value
function setTextValue(node,sLine,sMatch,sValue,sFilter)
  local sFound = string.match(sLine,nocase(sMatch) .. "(.*)$");
  sFound = StringManager.trim(sFound);
  if (sFound ~= nil and sFilter ~= nil) then
Debug.console("manager_import.lua","setTextValue","sFilter",sFilter);    
    sFound = string.match(sFound,nocase(sFilter));
  end
  if sFound ~= nil then
Debug.console("manager_import.lua","setTextValue","sValue",sValue);    
Debug.console("manager_import.lua","setTextValue","sFound",sFound);    
    DB.setValue(node,sValue,"string",StringManager.capitalize(sFound));
  end
end

-- set generic number value
function setNumberValue(node,sLine,sMatch,sValue,sFilter)
  local sFound = string.match(sLine,nocase(sMatch) .. "(.*)$");
  sFound = StringManager.trim(sFound);
  if (sFound ~= nil and sFilter ~= nil) then
Debug.console("manager_import.lua","setNumberValue","sFilter",sFilter);    
    sFound = string.match(sFound,nocase(sFilter));
  end
  if sFound ~= nil then
    sFound = sFound:gsub(" ",""); -- remove ALL spaces
    sFound = sFound:gsub(",",""); -- remove ALL commas
    local nFound = tonumber(sFound) or 0;
Debug.console("manager_import.lua","setNumberValue","sValue",sValue);    
Debug.console("manager_import.lua","setNumberValue","nFound",nFound);    
    DB.setValue(node,sValue,"number",nFound);
  end
end

-- set description
function setDescription(node,sDescription, sTag)
  sDescription = cleanDescription(sDescription);
  sDescription = contextHighlight(sDescription);
  DB.setValue(node,sTag,"formattedtext",sDescription);
end

-- set npc name
function setName(node,sName)
Debug.console("manager_import.lua","setName","sName",sName);
  if (sName == nil) then
    sName = "Unknown NPC";
  end
  DB.setValue(node,"name","string",StringManager.capitalize(sName));
end

-- clean up the anomalies left over from copy/pasting text from a PDF, fi re to fire, fl oor to floor
function cleanDescription(sDesc)
  local sCleanDesc = string.gsub(sDesc,nocase("fi "),"fi");
  sCleanDesc = string.gsub(sCleanDesc,nocase("fl "),"fl");
  return sCleanDesc;
end

function contextHighlight(sText)
  local sHighlighted = sText;
  local sWordsMatch = "[%s%w%d%+-,%(%)%%/']+"; -- get numbers, dice also
  local sWordsMatchONLY = "[%s%w,%%/']+"; --(dont want  number or dice), used in sAfter search
  -- these items we get words before and after and bold it
  local aSurrounded = {"saving throw","damage","attack","victim","inflict","cause","regain","stun","paraly","regen","drain","reduce","unconscious","have any effect"};
  -- these items we get words after and bold it
  local aAfter = {"resist","immun","vulnerab","can only be","only affect","only effect","hit only","hit by only","damage by only","damage only"};
  
  -- -- Treasure:
  sHighlighted = string.gsub(sHighlighted,nocase("^([%w%s,/]+):"),"<i><u>%1:</u></i>");
  sHighlighted = string.gsub(sHighlighted,nocase("<p>([%w%s,/]+):"),"<p><i><u>%1:</u></i>");

  for _,sFindMatch in pairs(aAfter) do
    sHighlighted = string.gsub(sHighlighted,sFindMatch .. "(" .. nocase(sWordsMatchONLY) ..")","<u>".. sFindMatch .. "%1</u>");
  end
  for _,sFindMatch in pairs(aSurrounded) do
    sHighlighted = string.gsub(sHighlighted,"(" .. nocase(sWordsMatch) ..")".. sFindMatch .."(" .. nocase(sWordsMatch) ..")","<b>%1".. sFindMatch .."%2</b>");
  end

Debug.console("manager_import.lua","contextHighlight","sHighlighted",sHighlighted);      
  return sHighlighted;
end

-- strip out formattedtext from a string
function stripFormattedText(sText)
  local sTextOnly = sText;
  sTextOnly = sTextOnly:gsub("</p>","\n");
  sTextOnly = sTextOnly:gsub("<.?[ubiphUBIPH]>","");
  sTextOnly = sTextOnly:gsub("<.?table>","");
  sTextOnly = sTextOnly:gsub("<.?frame>","");
  sTextOnly = sTextOnly:gsub("<.?t.?>","");
  sTextOnly = sTextOnly:gsub("<.?list>","");
  sTextOnly = sTextOnly:gsub("<.?li>","");
  return sTextOnly;  
end

---------------
-- NPC reusable import functions
---------------

function createBlankNPC()
    local node = DB.createChild("npc"); 
Debug.console("manager_import_adnd.lua","createTable","node",node);    

  if node then
    local w = Interface.openWindow("npc", node.getNodeName());
    if w and w.header and w.header.subwindow and w.header.subwindow.name then
      w.header.subwindow.name.setFocus();
    end
  end
    return node;
end


-- this parses up "level/xp: 6/1,000+10/hp" style entries and calculates exp based on max hp
function setExpLevelOSRIC(nodeNPC,sLine)
  local sFound = string.match(sLine:lower(),"^level/x%.?p%.?:(.*)$");
  sFound = sFound:gsub(" ",""); -- remove ALL spaces
  sFound = sFound:gsub(",",""); -- remove ALL commas
  local sLevel, sEXP, sPerHP = string.match(sFound:lower(),"^(%d+)\/(%d+)%+(%d+)\/");
  local nLevel = tonumber(sLevel) or 0;
  if (nLevel > 0) then
    DB.setValue(nodeNPC,"level","number",nLevel);
    DB.setValue(nodeNPC,"thaco","number",(21-nLevel)); -- best guess, OSRIC doesn't use THACO
  end
  local nEXP = tonumber(sEXP) or 0;
  local nPerHP = tonumber(sPerHP) or 0;
  if (nPerHP > 0) then
    -- nMaxHP presumes we've received HD field already otherwise this wont work
    setHD(nodeNPC);
    local sHD = DB.getValue(nodeNPC,"hd","1d1");
    local nMaxHP = StringManager.evalDiceString(sHD, true, true);
    local nPerHPTotal = nPerHP * nMaxHP;
    nEXP = nEXP + nPerHPTotal;
  end
  DB.setValue(nodeNPC,"xp","number",nEXP);
end

-- this parses up "level/xp value: VII/1,000+10/hp" style entries and calculates exp based on max hp
function setExpLevelTSR1(nodeNPC,sLine)
  local sFound = string.match(sLine:lower(),"^level/xp value:(.*)$");
  sFound = sFound:gsub(" ",""); -- remove ALL spaces
  sFound = sFound:gsub(",",""); -- remove ALL commas
  local sLevel, sEXP, sPerHP = string.match(sFound:lower(),"^(.+)\/(%d+)%+(%d+)\/");
  local nLevel = tonumber(sLevel) or 0;
  -- if (nLevel > 0) then
    -- DB.setValue(nodeNPC,"level","number",nLevel);
    -- DB.setValue(nodeNPC,"thaco","number",(21-nLevel)); -- best guess, OSRIC doesn't use THACO
  -- end
  local nEXP = tonumber(sEXP) or 0;
  local nPerHP = tonumber(sPerHP) or 0;
  if (nPerHP > 0) then
    -- nMaxHP presumes we've received HD field already otherwise this wont work
    setHD(nodeNPC);
    local sHD = DB.getValue(nodeNPC,"hd","1d1");
    local nMaxHP = StringManager.evalDiceString(sHD, true, true);
    local nPerHPTotal = nPerHP * nMaxHP;
    nEXP = nEXP + nPerHPTotal;
  end
  DB.setValue(nodeNPC,"xp","number",nEXP);
end

-- "Challenge Level/XP: 4/120"
function setExpLevelSW(nodeNPC,sLine)
  local sFound = string.match(sLine:lower(),"^challenge level/xp:(.*)$");
  sFound = sFound:gsub(" ",""); -- remove ALL spaces
  sFound = sFound:gsub(",",""); -- remove ALL commas
  local sLevel, sEXP = string.match(sFound:lower(),"^(%d+)\/(%d+)");
  local nLevel = tonumber(sLevel) or 0;
  if (nLevel > 0) then
    DB.setValue(nodeNPC,"level","number",nLevel);
    DB.setValue(nodeNPC,"thaco","number",(21-nLevel)); -- best guess, OSRIC/SW doesn't use THACO
  end
  local nEXP = tonumber(sEXP) or 0;
  DB.setValue(nodeNPC,"xp","number",nEXP);
end

-- clean up exp entries
function setExperience(nodeNPC,sLine)
  local sEXP = string.match(sLine:lower(),"^xp value:(.*)$");
  sEXP = sEXP:gsub(" ",""); -- remove ALL spaces
  sEXP = sEXP:gsub(",",""); -- remove ALL commas
  if sEXP ~= nil then
    local nEXP = tonumber(sEXP) or 0;
    DB.setValue(nodeNPC,"xp","number",nEXP);
  end
end

-- this is run at end to clean up/fix HD value
function setHD(nodeNPC)
  local sHitDice = DB.getValue(nodeNPC,"hitDice","");
  local sHD = "1d1";
  if (sHitDice ~= "") then
    sHitDice = sHitDice:gsub("hp","");
    sHitDice = StringManager.trim(sHitDice);
    if (string.match(sHitDice,"^%d+[+\-]%d+$")) then -- 1-1
      local sDiceCount, sRemaining = sHitDice:match("^(%d+)(.*)$"); -- grab first number and then rest
      local nDiceCount = tonumber(sDiceCount) or 0;
      if nDiceCount < 1 then nDiceCount = 1; end
      sHD = nDiceCount .. "d8" .. sRemaining;
    elseif (string.match(sHitDice,"^%d+[dD]%d$")) then -- 1d3
      sHD = sHitDice; 
    elseif (string.match(sHitDice,"^%d+$")) then -- just "11"
      local nDiceCount = sHitDice:match("^(%d+)$");
      nDiceCount = tonumber(nDiceCount) or 0;
      if nDiceCount < 1 then nDiceCount = 1; end
      sHD = nDiceCount .. "d8";
    elseif (string.match(sHitDice,"^%d+[+\-]%d+[dD]%d$")) then -- 11+1d4
      local sDiceCount, sRemaining = sHitDice:match("^(%d+)([+\-]%d+[dD]%d+)$"); 
      local nDiceCount = tonumber(sDiceCount) or 0;
      if nDiceCount < 1 then nDiceCount = 1; end
      sHD = nDiceCount .. "d8" .. sRemaining;
    elseif (string.match(sHitDice,"^%d+[+\-]%d+[dD]%d[+\-]%d+$")) then -- 11+1d4+1
      local sDiceCount, sRemaining = sHitDice:match("^(%d+)([+\-]%d+[dD]%d[+\-]%d+)$"); 
      local nDiceCount = tonumber(sDiceCount) or 0;
      if nDiceCount < 1 then nDiceCount = 1; end
      sHD = nDiceCount .. "d8" .. sRemaining;
    else
      local sDiceCount = sHitDice:match("^(%d+)"); -- last try, hope we get something
Debug.console("manager_import_adnd.lua","setHD","sDiceCount",sDiceCount);       
      if sDiceCount and sDiceCount ~= "" then
        local nDiceCount = tonumber(sDiceCount) or 0;
        if nDiceCount < 1 then nDiceCount = 1; end
        sHD = nDiceCount .. "d8";
      else
        -- no hitdice, so thaco will be 0, set to 20
        local sHDLevel = sHitDice:match("^(%d+)"); 
        local nHD = tonumber(sHDLevel) or 1;
        if (nHD < 1) then
          nHD = 1;
        end
        DB.setValue(nodeNPC,"thaco","number",(21-nHD));
      end
    end
  end
  DB.setValue(nodeNPC,"hd","string",sHD);
end

-- set numeric value of ac
function setAC(nodeNPC)
  local sACText = DB.getValue(nodeNPC,"actext","");
Debug.console("manager_import_adnd.lua","setAC","sACText",sACText); 
  local nAC = 10;
  if (sACText ~= "") then
    if (string.match(sACText,"%d+")) then
      local sAC = sACText:match("^(%-?%d+)"); -- grab first number
      if not sAC or sAC == "" then
        sAC = sACText:match("(%-?%d+)"); -- grab any number if we got nothing
      end
      nAC = tonumber(sAC) or 10;
    end
  end
  DB.setValue(nodeNPC,"ac","number",nAC);
end

-- apply "damage" string and do best effort to parse and make action/weapons
function setActionWeapon(nodeNPC)
  local sDamageRaw = DB.getValue(nodeNPC,"damage","");
  sDamageRaw = string.gsub(sDamageRaw:lower(),"by weapon","");
  sDamageRaw = string.gsub(sDamageRaw:lower(),"or","");
  local sAttacksRaw = DB.getValue(nodeNPC,"numberattacks","");
  sAttacksRaw = string.gsub(sAttacksRaw:lower(),"by weapon","");
  sAttacksRaw = string.gsub(sAttacksRaw:lower(),"or","");
  sAttacksRaw = StringManager.trim(sAttacksRaw);
  sDamageRaw = StringManager.trim(sDamageRaw);
  local aAttacks = {};
  
Debug.console("manager_import_adnd.lua","setActionWeapon","sDamageRaw",sDamageRaw);                  
Debug.console("manager_import_adnd.lua","setActionWeapon","sAttacksRaw",sAttacksRaw);                  

  if (sDamageRaw ~= "" or sAttacksRaw ~= "") then
    if (string.match(sDamageRaw,"/")) then
      aAttacks = StringManager.split(sDamageRaw, "/", true);
Debug.console("manager_import_adnd.lua","setActionWeapon","aAttacks1",aAttacks);                  
    end
    if #aAttacks < 1 then
Debug.console("manager_import_adnd.lua","setActionWeapon","aAttacks2",aAttacks);     
      for sDice in string.gmatch(sDamageRaw,"%d+[dD%-]%d+[%+%-]%d+") do
Debug.console("manager_import_adnd.lua","setActionWeapon","sDice1",sDice);                  
        table.insert(aAttacks, sDice)
      end
      -- for sDice, sOther in string.gmatch(sDamageRaw,"(%d+[dD%-]%d+)([^%d%+%-])") do
-- Debug.console("manager_import_adnd.lua","setActionWeapon","sDice2",sDice);                  
-- Debug.console("manager_import_adnd.lua","setActionWeapon","sOther1",sOther);                  
        -- if sDice ~= "" and sOther ~= "" then
          -- table.insert(aAttacks, sDice);
        -- end
      -- end
      for sDice in string.gmatch(sDamageRaw,"(%d+[dD%-]%d+)") do
Debug.console("manager_import_adnd.lua","setActionWeapon","sDice5",sDice);                  
        table.insert(aAttacks, sDice)
      end
    end
    if #aAttacks < 1 then
Debug.console("manager_import_adnd.lua","setActionWeapon","aAttacks3",aAttacks);         
      for sDice in string.gmatch(sAttacksRaw,"%d+[dD%-]%d+[%+%-]%d+") do
Debug.console("manager_import_adnd.lua","setActionWeapon","sDice3",sDice);                  
        table.insert(aAttacks, sDice)
      end
      -- for sDice, sOther in string.gmatch(sAttacksRaw,"(%d+[dD-]%d+)([^%d%+%-])") do
-- Debug.console("manager_import_adnd.lua","setActionWeapon","sDice4",sDice);                  
-- Debug.console("manager_import_adnd.lua","setActionWeapon","sOther2",sOther);   
        -- if sDice ~= "" and sOther ~= "" then
          -- table.insert(aAttacks, sDice);
        -- end
      -- end
      for sDice in string.gmatch(sAttacksRaw,"(%d+[dD%-]%d+)") do
Debug.console("manager_import_adnd.lua","setActionWeapon","sDice6",sDice);                  
        table.insert(aAttacks, sDice)
      end
    end
    if #aAttacks > 0 then

  -- this will try and fix 1-4, 1-8, 2-8 damage dice
      for nIndex,sAttack in pairs(aAttacks) do 
  Debug.console("manager_import_adnd.lua","setActionWeapon","nIndex",nIndex);            
  Debug.console("manager_import_adnd.lua","setActionWeapon","sAttack",sAttack);            
        if (string.match(sAttack,"^(%d+)([%-])(%d+)$")) then
          local sCount, sSign, sSize = string.match(sAttack,"^(%d+)([%-])(%d+)$");
          local nCount = tonumber(sCount) or 1;
          local nSize = tonumber(sSize) or 1;
          local sRemainder = "";
          if nCount > 1 then
            local nSizeAdjusted = math.ceil(nSize/nCount);
  Debug.console("manager_import_adnd.lua","setActionWeapon","nSizeAdjusted",nSizeAdjusted);       
            local nRemainder = nSize - (nSizeAdjusted*nCount);
  Debug.console("manager_import_adnd.lua","setActionWeapon","nRemainder",nRemainder);       
            if nRemainder > 0 then
              sRemainder = "+" .. nRemainder;
            elseif nRemainder < 0 then
              sRemainder = nRemainder;
            end
            nSize = nSizeAdjusted;
          end
          aAttacks[nIndex] = nCount .. "d" .. nSize .. sRemainder;
  Debug.console("manager_import_adnd.lua","setActionWeapon","aAttacks[nIndex]",aAttacks[nIndex]);       
        end
      end
      -- end dice fix
      
Debug.console("manager_import_adnd.lua","setActionWeapon","aAttacks-->",aAttacks);       
      local nodeWeapons = nodeNPC.createChild("weaponlist");  
      local nCount = 0;
      for _,sAttack in pairs(aAttacks) do 
        nCount = nCount + 1;
        local nSpeedFactor = getSpeedFactorFromSize(nodeNPC);
        local aDice, sMod = StringManager.convertStringToDice(sAttack);
        local nMod = tonumber(sMod) or 0;
        local nodeWeapon = nodeWeapons.createChild();
        local sAttckName = "Attack #" .. nCount
        
        DB.setValue(nodeWeapon,"name","string",sAttckName);
        DB.setValue(nodeWeapon,"speedfactor","number",nSpeedFactor);
        DB.setValue(nodeWeapon,"itemnote.name","string",sAttckName);
        DB.setValue(nodeWeapon,"itemnote.text","formattedtext","Imported from:" .. sAttack);
        DB.setValue(nodeWeapon,"itemnote.locked","number",1);
        DB.setValue(nodeWeapon, "shortcut", "windowreference", "quicknote", nodeWeapon.getPath() .. '.itemnote');
        
        local nodeDamageLists = nodeWeapon.createChild("damagelist"); 
        local nodeDamage = nodeDamageLists.createChild();
        DB.setValue(nodeDamage,"dice","dice",aDice);
        DB.setValue(nodeDamage,"bonus","number",nMod);
        DB.setValue(nodeDamage,"stat","string","base");
        DB.setValue(nodeDamage,"type","string","slashing");
      end -- end for
    end
  end
end

-- get a default speedfactor from size of NPC
function getSpeedFactorFromSize(nodeNPC)
  local nSpeedFactor = 0;
  local sSizeRaw = StringManager.trim(DB.getValue(nodeNPC, "size", ""));
  local sSize = sSizeRaw:lower();
  
  if sSize == "tiny" or string.find(sSizeRaw,"T") then
    nSpeedFactor = 0;
  elseif sSize == "small" or string.find(sSizeRaw,"S") then
    nSpeedFactor = 3;
  elseif sSize == "medium" or string.find(sSizeRaw,"M") then
    nSpeedFactor = 3;
  elseif sSize == "large" or string.find(sSizeRaw,"L") then
    nSpeedFactor = 6;
  elseif sSize == "huge" or string.find(sSizeRaw,"H") then
    nSpeedFactor = 9;
  elseif sSize == "gargantuan" or string.find(sSizeRaw,"G") then
    nSpeedFactor = 12;
  end
  
  return nSpeedFactor;
end

-- if these values not set, give it a default
function setSomeDefaults(nodeNPC) 
  DB.setValue(nodeNPC,"powerdisplaymode","string","action");
  DB.setValue(nodeNPC,"size","string",DB.getValue(nodeNPC,"size","Medium"));
  DB.setValue(nodeNPC,"type","string",DB.getValue(nodeNPC,"type","Other"));
  DB.setValue(nodeNPC,"alignment","string",DB.getValue(nodeNPC,"alignment","Neutral"));
  
  local sHitDice = DB.getValue(nodeNPC,"hitDice","");
  local sHDLevel = sHitDice:match("^(%d+)"); 
  local nLevel = tonumber(sHDLevel) or 1;
  if (nLevel < 1) then
    nLevel = 1;
  end
  -- Set thaco to something sane if not set
  local nTHACO = DB.getValue(nodeNPC,"thaco",999);
  if (nTHACO == 999) then
    DB.setValue(nodeNPC,"thaco","number",(21-nLevel));
  end
  -- set these to match base HD
  DB.setValue(nodeNPC,"arcane.totalLevel","number",nLevel);
  DB.setValue(nodeNPC,"divine.totalLevel","number",nLevel);
end
