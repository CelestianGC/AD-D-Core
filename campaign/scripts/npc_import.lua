-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
--Debug.console("npc_import.lua","onInit","getDatabaseNode",getDatabaseNode());
end


function createBlankNPC()
    local node = DB.createChild("npc"); 
Debug.console("npc_import.lua","createTable","node",node);    

	if node then
		local w = Interface.openWindow("npc", node.getNodeName());
		if w and w.header and w.header.subwindow and w.header.subwindow.name then
			w.header.subwindow.name.setFocus();
		end
	end
    return node;
end

function processImportText()
    local sText = importtext.getValue() or "";
    if (sText ~= "") then
      local aNPCText = {};
      for sLine in string.gmatch(sText, '([^\r\n]+)') do
          table.insert(aNPCText, sLine);
      end
      local nodeNPC = createBlankNPC();

      -- find the first value in the text line and take it's value
      -- and put it in the second value of the nodeNPC
      local text_matches = {
                        {"^frequency:","frequency"},
                        {"^rarity:","frequency"},
                        {"^no. encountered:","numberappearing"},
                        {"^no. appearing:","numberappearing"},
                        {"^number encountered:","numberappearing"},
                        {"^size:","size"},
                        {"^move:","speed"},
                        {"^movement:","speed"},
                        {"^armour class:","actext"},
                        {"^armor class:","actext"},
                        {"^ac:","actext"},
                        {"^armorclass:","actext"},
                        {"^hit dice:","hitDice"},
                        {"^hitdice:","hitDice"},
                        {"^hd:","hitDice"},
                        {"^hit dice:","hdtext"},
                        {"^hitdice:","hdtext"},
                        {"^hd:","hdtext"},
                        {"^attacks:","numberattacks"},
                        {"^attack:","numberattacks"},
                        {"^no. of attacks:","numberattacks"},
                        {"^damage:","damage"},
                        {"^damage/attack:","damage"},
                        {"^damag.attack:","damage"},
                        {"^damag..attack:","damage"},
                        {"^special attacks:","specialAttacks"},
                        {"^special defences:","specialDefense"},
                        {"^special defenses:","specialDefense"},
                        {"^special:","specialDefense"},
                        {"^magic resistance:","magicresistance"},
                        {"^lair probability:","inlair"},
                        {"^%% in lair:","inlair"},
                        {"^in lair:","inlair"},
                        {"^intelligence:","intelligence_text"},
                        {"^alignment:","alignment"},
                        {"^morale:","morale"},
                        -- {"treasure:","treasure"},
                        {"^treasure type:","treasure"},
                        {"^diet:","diet"},
                        {"^organization:","organization"},
                        {"^climate/terrain:","climate"},
                        {"^climat.terrain:","climate"},
                        {"^active time:","activity"},
                        {"^activity cycle:","activity"},
                        {"^type:","type"},
                        };
      local number_matches = {
                        {"^thaco:","thaco"},
                        {"^thac0:","thaco"},
                        };
      local sDescription = "";
      local sParagraph = "";
      for _,sLine in ipairs(aNPCText) do
Debug.console("npc_import.lua","importTextAsNPC","sLine",sLine);    
        -- each line is flipped through
        local bProcessed = false;
        for _, sFind in ipairs(text_matches) do
          local sMatch = sFind[1];
          local sValue = sFind[2];
          if (string.match(sLine:lower(),sMatch)) then
            bProcessed = true;
            ManagerImportADND.setTextValue(nodeNPC,sLine,sMatch,sValue);
          end
        end
        for _, sFind in ipairs(number_matches) do
          local sMatch = sFind[1];
          local sValue = sFind[2];
          if (string.match(sLine:lower(),sMatch)) then
            bProcessed = true;
            ManagerImportADND.setNumberValue(nodeNPC,sLine,sMatch,sValue);
          end
        end
        -- 2e mm uses "xp value" and has commas and spaces you gotta clean out
        if (string.match(sLine:lower(),"^xp value:")) then
          bProcessed = true;
          setExperience(nodeNPC,sLine);
        end
        -- osric uses "level/xp: 6/1,000+10/hp" style exp entry
        if (string.match(sLine:lower(),"^level/x%.?p%.?:")) then
          bProcessed = true;
          setExpLevelOSRIC(nodeNPC,sLine);
        end
        -- TSR1 uses "level/xp value: VII/1,000+10/hp"
        if (string.match(sLine:lower(),"^level/xp value:")) then
          bProcessed = true;
          setExpLevelTSR1(nodeNPC,sLine);
        end
        
        -- Swords and Wizadry uses "Challenge Level/XP: 4/120" style exp entry
        if (string.match(sLine:lower(),"^challenge level/xp:")) then
          bProcessed = true;
          setExpLevelSW(nodeNPC,sLine);
        end
        -- we use the first line as the name as default
        if (DB.getValue(nodeNPC,"name","") == "") then
          bProcessed = true;
          ManagerImportADND.setName(nodeNPC,sLine)
        end
        -- otherwise this line is going to be considered description
        if not bProcessed then
          sParagraph = sParagraph .. " " .. sLine;
          -- check for period 
          -- if so sDescription = sDescription .. sParagraph .."\n";
          if sLine:match("%..?$") then
            sDescription = sDescription .. "<p>" .. sParagraph .."</p>";
Debug.console("npc_import.lua","importTextAsNPC","END sParagraph",sParagraph);
            sParagraph = "";
          end
        end
      end -- end loop for each line
      
      if (sParagraph ~= "") then
        sDescription = sDescription .. "<p>" .. sParagraph .."</p>";
      end
      -- fix some NPC values that need it
      ManagerImportADND.setDescription(nodeNPC,sDescription,"text");
      setHD(nodeNPC);
      setAC(nodeNPC);
      setActionWeapon(nodeNPC);
      
    end
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
      sHD = sDiceCount .. "d8" .. sRemaining;
    elseif (string.match(sHitDice,"^%d+[dD]%d$")) then -- 1d3
      sHD = sHitDice; 
    elseif (string.match(sHitDice,"^%d+$")) then -- just "11"
      local nDiceCount = sHitDice:match("^(%d+)$");
      sHD = nDiceCount .. "d8";
    elseif (string.match(sHitDice,"^%d+[+\-]%d+[dD]%d$")) then -- 11+1d4
      local sDiceCount, sRemaining = sHitDice:match("^(%d+)([+\-]%d+[dD]%d+)$"); 
      sHD = sDiceCount .. "d8" .. sRemaining;
    elseif (string.match(sHitDice,"^%d+[+\-]%d+[dD]%d[+\-]%d+$")) then -- 11+1d4+1
      local sDiceCount, sRemaining = sHitDice:match("^(%d+)([+\-]%d+[dD]%d[+\-]%d+)$"); 
      sHD = sDiceCount .. "d8" .. sRemaining;
    else
      local sDiceCount = sHitDice:match("^(%d+)"); -- last try, hope we get something
Debug.console("npc_import.lua","setHD","sDiceCount",sDiceCount);       
      if sDiceCount and sDiceCount ~= "" then
        sHD = sDiceCount .. "d8";
      else
        -- no hitdice, so thaco will be 0, set to 20
        DB.setValue(nodeNPC,"thaco","number",20);
      end
    end
  end
  DB.setValue(nodeNPC,"hd","string",sHD);
end

-- set numeric value of ac
function setAC(nodeNPC)
  local sACText = DB.getValue(nodeNPC,"actext","");
Debug.console("npc_import.lua","setAC","sACText",sACText); 
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
  
Debug.console("npc_import.lua","setActionWeapon","sDamageRaw",sDamageRaw);                  
Debug.console("npc_import.lua","setActionWeapon","sAttacksRaw",sAttacksRaw);                  

  if (sDamageRaw ~= "" or sAttacksRaw ~= "") then
    if (string.match(sDamageRaw,"/")) then
      aAttacks = StringManager.split(sDamageRaw, "/", true);
Debug.console("npc_import.lua","setActionWeapon","aAttacks1",aAttacks);                  
    end
    if #aAttacks < 1 then
Debug.console("npc_import.lua","setActionWeapon","aAttacks2",aAttacks);     
      for sDice in string.gmatch(sDamageRaw,"%d+[dD-]%d+[%+-]%d+") do
Debug.console("npc_import.lua","setActionWeapon","sDice1",sDice);                  
        table.insert(aAttacks, sDice)
      end
      for sDice, sOther in string.gmatch(sDamageRaw,"(%d+[dD-]%d+)([^%d%+-])") do
Debug.console("npc_import.lua","setActionWeapon","sDice2",sDice);                  
Debug.console("npc_import.lua","setActionWeapon","sOther1",sOther);                  
        table.insert(aAttacks, sDice)
      end
      for sDice in string.gmatch(sDamageRaw,"(%d+[dD-]%d+)") do
Debug.console("npc_import.lua","setActionWeapon","sDice5",sDice);                  
        table.insert(aAttacks, sDice)
      end
    end
    if #aAttacks < 1 then
Debug.console("npc_import.lua","setActionWeapon","aAttacks3",aAttacks);         
      for sDice in string.gmatch(sAttacksRaw,"%d+[dD-]%d+[%+-]%d+") do
Debug.console("npc_import.lua","setActionWeapon","sDice3",sDice);                  
        table.insert(aAttacks, sDice)
      end
      for sDice, sOther in string.gmatch(sAttacksRaw,"(%d+[dD-]%d+)([^%d%+-])") do
Debug.console("npc_import.lua","setActionWeapon","sDice4",sDice);                  
Debug.console("npc_import.lua","setActionWeapon","sOther2",sOther);                  
        table.insert(aAttacks, sDice)
      end
      for sDice in string.gmatch(sAttacksRaw,"(%d+[dD-]%d+)") do
Debug.console("npc_import.lua","setActionWeapon","sDice6",sDice);                  
        table.insert(aAttacks, sDice)
      end
    end
    if #aAttacks > 0 then

  -- this will try and fix 1-4, 1-8, 2-8 damage dice
      for nIndex,sAttack in pairs(aAttacks) do 
  Debug.console("npc_import.lua","setActionWeapon","nIndex",nIndex);            
  Debug.console("npc_import.lua","setActionWeapon","sAttack",sAttack);            
        if (string.match(sAttack,"^(%d+)([-])(%d+)$")) then
          local sCount, sSign, sSize = string.match(sAttack,"^(%d+)([-])(%d+)$");
          local nCount = tonumber(sCount) or 1;
          local nSize = tonumber(sSize) or 1;
          local sRemainder = "";
          if nCount > 1 then
            local nSizeAdjusted = math.ceil(nSize/nCount);
  Debug.console("npc_import.lua","setActionWeapon","nSizeAdjusted",nSizeAdjusted);       
            local nRemainder = nSize - (nSizeAdjusted*nCount);
  Debug.console("npc_import.lua","setActionWeapon","nRemainder",nRemainder);       
            if nRemainder > 0 then
              sRemainder = "+" .. nRemainder;
            elseif nRemainder < 0 then
              sRemainder = nRemainder;
            end
            nSize = nSizeAdjusted;
          end
          aAttacks[nIndex] = nCount .. "d" .. nSize .. sRemainder;
  Debug.console("npc_import.lua","setActionWeapon","aAttacks[nIndex]",aAttacks[nIndex]);       
        end
      end
      -- end dice fix
      
Debug.console("npc_import.lua","setActionWeapon","aAttacks-->",aAttacks);       
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