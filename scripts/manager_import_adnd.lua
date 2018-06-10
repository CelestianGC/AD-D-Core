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