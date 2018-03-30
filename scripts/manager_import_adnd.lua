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
  DB.setValue(node,"name","string",StringManager.capitalize(sName));
end

-- clean up the annomiles left over from copy/pasting text from a PDF, fi re to fire, fl oor to floor
function cleanDescription(sDesc)
  local sCleanDesc = string.gsub(sDesc,nocase("fi "),"fi");
  sCleanDesc = string.gsub(sCleanDesc,nocase("fl "),"fl");
  return sCleanDesc;
end

function contextHighlight(sText)
  local sWordsMatch = "[%s%w%d%+-]+";
  -- highlight resistance
  local sHighlighted = string.gsub(sText,nocase("resistance to (%w+)"),"<b>resistance to %1</b>");
  -- highlight immune/immunity
  sHighlighted = string.gsub(sHighlighted,nocase("immune to (%w+)"),"<b>immune to %1</b>");
  sHighlighted = string.gsub(sHighlighted,nocase("immunity to (%w+)"),"<b>immunity to %1</b>");
  -- vulnerability/vulnerable
  sHighlighted = string.gsub(sHighlighted,nocase("vulnerable to (%w+)"),"<b>vulnerable to %1</b>");
  sHighlighted = string.gsub(sHighlighted,nocase("vulnerability to (%w+)"),"<b>vulnerability to %1</b>");
  -- saving throw
  sHighlighted = string.gsub(sHighlighted,nocase("saving throw (" .. sWordsMatch ..")"),"<b>saving throw %1</b>");
  sHighlighted = string.gsub(sHighlighted,nocase("saving throws (" .. sWordsMatch ..")"),"<b>saving throws %1</b>");
  -- damage
  sHighlighted = string.gsub(sHighlighted,nocase("(" .. sWordsMatch ..") damage"),"<b>%1 damage</b>");
  --sHighlighted = string.gsub(sHighlighted,nocase("(%d+d%d+) points of damage"),"<b>%1 points of damage</b>");
  -- Treasure:
  sHighlighted = string.gsub(sHighlighted,nocase("Treasure: "),"<h>%Treasure: </h><p></p>");

Debug.console("manager_import.lua","contextHighlight","sHighlighted",sHighlighted);      
  return sHighlighted;
end