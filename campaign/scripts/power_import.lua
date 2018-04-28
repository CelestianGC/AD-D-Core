-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
--Debug.console("power_import.lua","onInit","getDatabaseNode",getDatabaseNode());
end

function createBlankPower()
    local node = DB.createChild("spell"); 
Debug.console("power_import.lua","createTable","node",node);    

	if node then
		local w = Interface.openWindow("power", node.getNodeName());
		if w and w.header and w.header.subwindow and w.header.subwindow.name then
			w.header.subwindow.name.setFocus();
		end
	end
    return node;
end

function processImportText()
    local sText = importtext.getValue() or "";
    if (sText ~= "") then
    -- create array, each entry and a new line
    local aImportText = {};
    for sLine in string.gmatch(sText, '([^\r\n]+)') do
        table.insert(aImportText, sLine);
    end
    
    -- string Level: Magic user 8
    -- field 1: "^level:", find string with this match
    -- field 2: "level", "Magic user 8" is placed into node as this name
    -- field 3:[optional] "(%d+)$", filter specific from matched string (Magic user 8) to end result of "8"
    local text_matches = {
                      {"^range:","range"},
                      {"^saving throw:","save"},
                      {"^casting time:","castingtime"},
                      {"^components:","components"},
                      {"^area of effect:","aoe"},
                      {"^effect:","aoe"},
                      {"^duration:","duration"},
                      {"^school:","school"},
                      {"^sphere:","sphere"},
                      {"^type:","type"},
                      
                      {"^arcane ","school","(.*)$"},
                      {"^phantasmal ","school","(.*)$"},
                      {"^druidic ","sphere","(.*)$"},
                      {"^clerical ","sphere","(.*)$"},
                      
                      };
    local number_matches = {
                      {"^level:","level","(%d+)$"},
                      };
    local nodeSpell = createBlankPower();
    local sDescription = "";
    local sParagraph = "";
    for _,sLine in ipairs(aImportText) do
Debug.console("power_import.lua","processImportText","sLine",sLine);    
      -- each line is flipped through
      local bProcessed = false;
      for _, sFind in ipairs(text_matches) do
        local sMatch = sFind[1];
        local sValue = sFind[2];
        local sFilter = sFind[3];
        if (string.match(sLine:lower(),sMatch)) then
          bProcessed = true;
          ManagerImportADND.setTextValue(nodeSpell,sLine,sMatch,sValue,sFilter);
        end
      end
      for _, sFind in ipairs(number_matches) do
        local sMatch = sFind[1];
        local sValue = sFind[2];
        local sFilter = sFind[3];
        if (string.match(sLine:lower(),sMatch)) then
          bProcessed = true;
          ManagerImportADND.setNumberValue(nodeSpell,sLine,sMatch,sValue,sFilter);
        end
      end

      -- we use the first line as the name as default
      if (DB.getValue(nodeSpell,"name","") == "") then
        bProcessed = true;
        ManagerImportADND.setName(nodeSpell,sLine)
      end
      -- otherwise this line is going to be considered description
      if not bProcessed then
        sParagraph = sParagraph .. " " .. sLine;
        -- check for period 
        -- if so sDescription = sDescription .. sParagraph .."\n";
        if sLine:match("%.$") then
          sDescription = sDescription .. "<p>" .. sParagraph .."</p>";
Debug.console("power_import.lua","processImportText","END sParagraph",sParagraph);
          sParagraph = "";
        end
      end
    end -- end loop for each line
    
    if (sParagraph ~= "") then
      sDescription = sDescription .. "<p>" .. sParagraph .."</p>";
    end
    -- fix some values that need it
    ManagerImportADND.setDescription(nodeSpell,sDescription,"description");
    -- set castinginitiative by using castingtime 
    setCastingInitiative(nodeSpell);
    -- set type Arcane/Divine
    setType(nodeSpell);
    -- set reversible
    setReverse(nodeSpell);
    
    -- set summary
    setShortDescription(nodeSpell);
    
    -- set source to Import
    setSource(nodeSpell,"Imported from Text");

    -- setup spell actions
    setActions(nodeSpell)
  end
end

-- set Source
function setSource(nodeSpell,sName)
  DB.setValue(nodeSpell,"source","string",StringManager.capitalize(sName));
end

function setCastingInitiative(nodeSpell)
  local sCastingTime = DB.getValue(nodeSpell,"castingtime","");
  if (sCastingTime ~= "") then
    local sValue,sRemaining = string.match(sCastingTime,"^(%d+)(.*)$");
    local nCastInit = tonumber(sValue) or 1; -- default is segment, so straight value
    if (not string.find(sRemaining:lower(),"segment[sS]?")) then
      nCastInit = 99; -- anything else is longer than initiative can cope with
    end
    DB.setValue(nodeSpell,"castinitiative","number",nCastInit);
  end
end

function setType(nodeSpell)
    local sType = "Arcane";
    local sSphere = DB.getValue(nodeSpell,"sphere","");
    local sSchool = DB.getValue(nodeSpell,"school","");
    if (sSphere ~= "") then
      sType = "Divine"
    elseif (sSchool ~= "") then -- this isn't necessary since we default to this but...
      sType = "Arcane"
    end
    DB.setValue(nodeSpell,"type","string",sType);
end

function setReverse(nodeSpell)
  local sName = DB.getValue(nodeSpell,"name","");
  if (string.find(sName,"revers")) then
    DB.setValue(nodeSpell,"reversible","number",1);
  end
end

function setShortDescription(nodeSpell)
  local sRange = DB.getValue(nodeSpell,"range","");
  local sAOE = DB.getValue(nodeSpell,"aoe","");
  local sCastTime = DB.getValue(nodeSpell,"castingtime","");
  local sDuration = DB.getValue(nodeSpell,"duration","");
  local sSave = DB.getValue(nodeSpell,"save","");
  local sSummary = "Range: " .. sRange .. ", AOE: " .. sAOE .. ", Cast Time: " .. sCastTime .. ", Duration: " .. sDuration .. ", Save: " .. sSave;
  DB.setValue(nodeSpell,"shortdescription","string",sSummary);
end

-- <actions>
  -- <id-00001>
    -- <atkmod type="number">0</atkmod>
    -- <order type="number">1</order>
    -- <savedcmod type="number">0</savedcmod>
    -- <savetype type="string">spell</savetype>
    -- <type type="string">cast</type>
  -- </id-00001>
  -- <id-00002>
    -- <castermax type="number">0</castermax>
    -- <castertype type="string">casterlevel</castertype>
    -- <durdice type="dice">d4,d4</durdice>
    -- <durmod type="number">77</durmod>
    -- <durunit type="string">minute</durunit>
    -- <durvalue type="number">7</durvalue>
    -- <label type="string">SAMPLE;EFFECT;STRING</label>
    -- <order type="number">2</order>
    -- <type type="string">effect</type>
  -- </id-00002>
function setActions(nodeSpell)
  local sName = DB.getValue(nodeSpell,"name","");
  local sDurationRaw = DB.getValue(nodeSpell,"duration","");
  
  local nodeActions = nodeSpell.createChild("actions");
  local nodeAction = nodeActions.createChild();
  DB.setValue(nodeAction,"type","string","cast");
  DB.setValue(nodeAction,"savetype","string","spell"); -- default to spell

  if sDurationRaw and string.find(sDurationRaw,"^%d+") then
Debug.console("power_import.lua","setActions","sDurationRaw",sDurationRaw);  
    local sDurationLower = sDurationRaw:lower();
    -- "2 rounds + 1 round/ level"
    local _, sModValue = string.match(sDurationRaw,"(%d+ %w+ %+ )(%d+)");
    local nModValue = tonumber(sModValue) or 0;
    local bDice = false;
    local aDurDice, nDiceMod = nil, nil;
    local sDurationDice = string.match(sDurationRaw,"(%d+[dD]%d+)");
Debug.console("power_import.lua","setActions","sDurationDice",sDurationDice); 
    if sDurationDice and sDurationDice ~= "" then
      bDice = true;
      aDurDice, nDiceMod = StringManager.convertStringToDice(sDurationDice);
    end
    local bCasterLevel = (string.find(sDurationLower,"caster level") ~= nil) or (string.find(sDurationLower,"/ level") ~= nil);
    local sDurationValue = string.match(sDurationRaw,"(%d+)");
    local nDurationValue = tonumber(sDurationValue) or 0;
    local sDurationUnit = "round";
    local sEffectLabel = sName;
    --{"round", "rounds", "minute", "minutes", "hour", "hours", "day", "days"})
    if string.find(sDurationLower,"minute") or string.find(sDurationLower,"turn") then
      sDurationUnit = "minute";
    elseif string.find(sDurationLower,"hour") then
      sDurationUnit = "hour";
    elseif string.find(sDurationLower,"day") then
      sDurationUnit = "day";
    end
Debug.console("power_import.lua","setActions","sDurationUnit",sDurationUnit);  

    nodeAction = nodeActions.createChild(); -- another node for effect type
    DB.setValue(nodeAction,"type","string","effect");
    DB.setValue(nodeAction,"order","number",2);

    -- duration
    DB.setValue(nodeAction,"durunit","string",sDurationUnit);
    DB.setValue(nodeAction,"label","string",sEffectLabel);
    
Debug.console("power_import.lua","setActions","bCasterLevel",bCasterLevel);  
Debug.console("power_import.lua","setActions","bDice",bDice);  
Debug.console("power_import.lua","setActions","nDurationValue",nDurationValue);
Debug.console("power_import.lua","setActions","nModValue",nModValue);
    if (bCasterLevel) then
      DB.setValue(nodeAction,"castertype","string","casterlevel");
      if (nModValue ~= 0) then
        DB.setValue(nodeAction,"durvalue","number",nModValue);
        DB.setValue(nodeAction,"durmod","number",nDurationValue);
      else
        DB.setValue(nodeAction,"durvalue","number",nDurationValue);
      end
    else
      if (bDice) then 
        DB.setValue(nodeAction,"durdice","dice",aDurDice);
        DB.setValue(nodeAction,"durmod","number",nDiceMod);
      else
        DB.setValue(nodeAction,"durmod","number",nDurationValue);
      end
    end
  end
end