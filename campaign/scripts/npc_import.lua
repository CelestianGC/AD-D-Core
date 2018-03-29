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
                        {"frequency","frequency"},
                        {"no. encountered","numberappearing"},
                        {"no. appearing","numberappearing"},
                        {"size","size"},
                        {"move","speed"},
                        {"armour class","ac"},
                        {"ac","ac"},
                        {"armorclass","ac"},
                        {"armour class","actext"},
                        {"ac","actext"},
                        {"armorclass","actext"},
                        {"hit dice","hitDice"},
                        {"hitdice","hitDice"},
                        {"hd","hitDice"},
                        {"hit dice","hdtext"},
                        {"hitdice","hdtext"},
                        {"hd","hdtext"},
                        -- {"hit dice","hd"},
                        -- {"hitdice","hd"},
                        -- {"hd","hd"},
                        {"attacks","numberattacks"},
                        {"no. of attacks","numberattacks"},
                        {"damage","damage"},
                        {"damage/attack","damage"},
                        {"special attacks","specialAttacks"},
                        {"special defences","specialDefense"},
                        {"special defenses","specialDefense"},
                        {"magic resistance","magicresistance"},
                        {"lair probability","inlair"},
                        {"intelligence","intelligence_text"},
                        {"alignment","alignment"},
                        {"morale","morale"},
                        -- {"treasure","treasure"},
                        {"diet","diet"},
                        {"organization","organization"},
                        {"climate/terrain","climate"},
                        {"active time","activity"},
                        {"type","type"},
                        };
      local number_matches = {
                        {"thaco","thaco"},
                        {"thac0","thaco"},
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
          if (string.match(sLine:lower(),"^".. sMatch .. ":")) then
            bProcessed = true;
            setTextValue(nodeNPC,sLine,sMatch,sValue);
          end
        end
        for _, sFind in ipairs(number_matches) do
          local sMatch = sFind[1];
          local sValue = sFind[2];
          if (string.match(sLine:lower(),"^".. sMatch .. ":")) then
            bProcessed = true;
            setNumberValue(nodeNPC,sLine,sMatch,sValue);
          end
        end
        -- 2e mm uses "xp value" and has commas and spaces you gotta clean out
        if (string.match(sLine:lower(),"^xp value:")) then
          bProcessed = true;
          setExperience(nodeNPC,sLine);
        end
        -- osric uses "level/xp: 6/1,000+10/hp" style exp entry
        if (string.match(sLine:lower(),"^level/xp:")) then
          bProcessed = true;
          setExpLevel(nodeNPC,sLine);
        end
        -- we use the first line as the name as default
        if (DB.getValue(nodeNPC,"name","") == "") then
          bProcessed = true;
          setName(nodeNPC,sLine)
        end
        -- otherwise this line is going to be considered description
        if not bProcessed then
          sParagraph = sParagraph .. " " .. sLine;
          -- check for period 
          -- if so sDescription = sDescription .. sParagraph .."\n";
          if sLine:match("%.$") then
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
      setDescription(nodeNPC,sDescription,"text");
      setHD(nodeNPC);
      setAC(nodeNPC);
      setActionWeapon(nodeNPC);
      
    end
end

function setTextValue(nodeNPC,sLine,sMatch,sValue)
  local sFound = string.match(sLine:lower(),"^" .. sMatch .. ":(.*)$");
  sFound = StringManager.trim(sFound);
  if sFound ~= nil then
Debug.console("npc_import.lua","setTextValue","sValue",sValue);    
Debug.console("npc_import.lua","setTextValue","sFound",sFound);    
    DB.setValue(nodeNPC,sValue,"string",StringManager.capitalize(sFound));
  end
end
function setNumberValue(nodeNPC,sLine,sMatch,sValue)
  local sFound = string.match(sLine:lower(),"^" .. sMatch .. ":(.*)$");
  sFound = StringManager.trim(sFound);
  if sFound ~= nil then
    local nFound = tonumber(sFound) or 0;
Debug.console("npc_import.lua","setNumberValue","sValue",sValue);    
Debug.console("npc_import.lua","setNumberValue","nFound",nFound);    
    DB.setValue(nodeNPC,sValue,"number",nFound);
  end
end

-- this parses up "level/xp: 6/1,000+10/hp" style entries and calculates exp based on max hp
function setExpLevel(nodeNPC,sLine)
  local sFound = string.match(sLine:lower(),"^level/xp:(.*)$");
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
      sHD = sDiceCount .. "d8";
    end
  end
  DB.setValue(nodeNPC,"hd","string",sHD);
end

-- set numeric value of ac
function setAC(nodeNPC)
  local sACText = DB.getValue(nodeNPC,"actext","");
  local nAC = 10;
  if (sACText ~= "") then
    if (string.match(sACText,"%d+")) then
      local sAC = sACText:match("^(%-?%d+)"); -- grab first number
Debug.console("npc_import.lua","setAC","sAC",sAC); 
      nAC = tonumber(sAC) or 10;
    end
  end
  DB.setValue(nodeNPC,"ac","number",nAC);
end

-- set description
function setDescription(nodeSpell,sDescription, sTag)
  DB.setValue(nodeSpell,sTag,"formattedtext",sDescription);
end

-- set npc name
function setName(nodeNPC,sName)
  DB.setValue(nodeNPC,"name","string",StringManager.capitalize(sName));
end

-- apply "damage" string and do best effort to parse and make action/weapons
function setActionWeapon(nodeNPC)
  local sDamageRaw = DB.getValue(nodeNPC,"damage","");
  sDamageRaw = string.gsub(sDamageRaw:lower(),"by weapon","");
  if (sDamageRaw ~= "") then
    local nCount = 0;
    local aAttacks = StringManager.split(sDamageRaw, "/", true);
    local nodeWeapons = nodeNPC.createChild("weaponlist");    
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