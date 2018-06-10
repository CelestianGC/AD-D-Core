-- data library for ad&d core ruleset
--
--
--

function onInit()
  DesktopManager.showDockTitleText(true);
  DesktopManager.setDockTitleFont("sidebar");
  DesktopManager.setDockTitleFrame("", 25, 2, 25, 5);
  DesktopManager.setDockTitlePosition("top", 2, 14);
  -- DesktopManager.setStackIconSizeAndSpacing(54, 29, 3, 3);
  -- DesktopManager.setDockIconSizeAndSpacing(136, 24, 0, 6);
  DesktopManager.setStackIconSizeAndSpacing(43, 27, 3, 3);
  DesktopManager.setDockIconSizeAndSpacing(100, 24, 0, 6);
  DesktopManager.setLowerDockOffset(2, 0, 2, 0);
    
  -- we don't use either of these types of records in AD&D, so hide them
	LibraryData.setRecordTypeInfo("feat", nil);
	LibraryData.setRecordTypeInfo("vehicle", nil);
  --

  if User.isHost()  then
    Comm.registerSlashHandler("readycheck", processReadyCheck);
    Comm.registerSlashHandler("updateadnd", processUpdateADND);
  end
end

function processReadyCheck(sCommand, sParams)
  if User.isHost() then
    local wWindow = Interface.openWindow("readycheck","");
    if wWindow then
      local aList = ConnectionManagerADND.getUserLoggedInList();
      -- share this window with every person connected.
      for _,name in pairs(aList) do
        wWindow.share(name);
      end
    end
  end
end

-- function that Celestian uses to bulk update things as needed
function processUpdateADND()
  if User.isHost() then
    -- option to flip through spells and add "cast" "initiative" and "duration" effect with name of spell
    
    -- I use this to set default values on spells w/o them
    -- for _,nodeSpell in pairs(DB.getChildren("spell")) do
      -- local sName = DB.getValue(nodeSpell,"name","UNKNOWN");
      -- local sDuration = DB.getValue(nodeSpell,"duration",""):lower();
      -- local bNoDuration = (sDuration:match("instant") ~= nil or sDuration:match("perm") ~= nil or sDuration == "" or sDuration == nil);
      -- local sCastingTime = DB.getValue(nodeSpell,"castingtime","99"):lower();
      -- local bCastingTimeSegment = (sCastingTime:match("^%d+$"));
      -- local nCastinitiative = tonumber(sCastingTime:match("%d+")) or 99;
      -- if not bCastingTimeSegment then -- if round/turn/whatever set to 99
        -- nCastinitiative = 99;
      -- end
      -- local sSave = DB.getValue(nodeSpell,"save","none"):lower();
      -- local bNoSave = (sSave:match("none") ~= nil or sSave == "" or sSave == nil);
      -- if (DB.getChildCount(nodeSpell,"actions") < 1) then
-- Debug.console("data_library_adnd.lua","processUpdateADND","sName",sName);        
-- Debug.console("data_library_adnd.lua","processUpdateADND","sDuration",sDuration);        
-- Debug.console("data_library_adnd.lua","processUpdateADND","bNoDuration",bNoDuration);        
-- Debug.console("data_library_adnd.lua","processUpdateADND","sCastingTime",sCastingTime);        
-- Debug.console("data_library_adnd.lua","processUpdateADND","nCastinitiative",nCastinitiative);        
-- Debug.console("data_library_adnd.lua","processUpdateADND","sSave",sSave);        
-- Debug.console("data_library_adnd.lua","processUpdateADND","bNoSave",bNoSave);        
      -- DB.setValue(nodeSpell,"castinitiative","number",nCastinitiative);
        -- local nodeActions = nodeSpell.createChild("actions");
        -- if nodeActions then
          -- local nodeActionCast = nodeActions.createChild();
          -- if nodeActionCast then
            -- DB.setValue(nodeActionCast, "type", "string", "cast");
            -- if not bNoSave then
              -- DB.setValue(nodeActionCast, "savetype", "string", "spell");
            -- end
          -- end
          -- local nodeActionDuration = nodeActions.createChild();
          -- if nodeActionDuration and (not bNoDuration) then
            -- DB.setValue(nodeActionDuration, "type", "string", "effect");
            -- DB.setValue(nodeActionDuration, "label","string",sName);
          -- end
        -- end
      -- end
    -- end

    -- this was to add psionic stats for all npcs that didnt have them
  -- for _,nodeNPC in pairs(DB.getChildren("npc")) do
  -- Debug.console("data_library_adnd.lua","processUpdateADND","npc-name",DB.getValue(nodeNPC,"name","NO-NAME"));
  -- Debug.console("data_library_adnd.lua","processUpdateADND","nodeNPC",nodeNPC);
  -- local nMTHACO = DB.getValue(nodeNPC,"combat.mthaco.base",20);
    -- DB.setValue(nodeNPC,"combat.mthaco.base","number",nMTHACO);
    -- AbilityScoreADND.updateStrength(nodeNPC);
    -- AbilityScoreADND.updateDexterity(nodeNPC);
    -- AbilityScoreADND.updateWisdom(nodeNPC);
    -- AbilityScoreADND.updateConstitution(nodeNPC);
    -- AbilityScoreADND.updateCharisma(nodeNPC);
    -- AbilityScoreADND.updateIntelligence(nodeNPC);
  -- end -- for
  
    -- cleanup names using " - " instead of ", "
    -- for _,nodeNPC in pairs(DB.getChildren("npc")) do
    -- Debug.console("data_library_adnd.lua","processUpdateADND","npc-name",DB.getValue(nodeNPC,"name","NO-NAME"));
    -- Debug.console("data_library_adnd.lua","processUpdateADND","nodeNPC",nodeNPC);
    -- local sName = DB.getValue(nodeNPC,"name","");
    -- sName = sName:gsub("%s%-%s",', '); -- replace - with comma
    -- DB.setValue(nodeNPC,"name","string",sName);
    -- Debug.console("data_library_adnd.lua","processUpdateADND","sName",sName);
    -- end -- for
  
    -- this was to add a default attack in actions/weapons if they had one
    -- listed in attacks but had no actual weaponlist created
    -- local nCount = 0;
    -- for _,nodeNPC in pairs(DB.getChildren("npc")) do
    -- nCount = nCount + 1;
    -- local nActionCount = DB.getChildCount(nodeNPC,"weaponlist");
    -- local sAtkCount = DB.getValue(nodeNPC,"numberattacks","");
    -- local sDamage = DB.getValue(nodeNPC,"damage","");
    -- local nAtkCount = tonumber(sAtkCount:match("(%d+)")) or 0;
    -- local sAtkCountNumberString = sAtkCount:match("(%d+)");
    -- if (nActionCount <= 0 and nAtkCount > 0) then
    
    -- Debug.console("data_library_adnd.lua","processUpdateADND","npc-name",DB.getValue(nodeNPC,"name","NO-NAME"));
    -- Debug.console("data_library_adnd.lua","processUpdateADND","nodeNPC",nodeNPC);
      -- Debug.console("data_library_adnd.lua","processUpdateADND","nActionCount",nActionCount);
      -- Debug.console("data_library_adnd.lua","processUpdateADND","sAtkCountNumberString",sAtkCountNumberString);
      -- Debug.console("data_library_adnd.lua","processUpdateADND","sDamage",sDamage);
      -- Debug.console("data_library_adnd.lua","processUpdateADND","sAtkCount",sAtkCount);
      -- Debug.console("data_library_adnd.lua","processUpdateADND","nAtkCount",nAtkCount);
      -- setActionWeapon(nodeNPC);
    -- end
    -- end -- for
    -- Debug.console("data_library_adnd.lua","processUpdateADND","nCount=",nCount);
  
  
    -- -- this is to add story stub to manually created attacks w/o shortcuts
    -- -- also capitalizes the attack names attack to Attack
    -- for _,nodeNPC in pairs(DB.getChildren("npc")) do
      -- for _, nodeWeapon in pairs(DB.getChildren(nodeNPC,"weaponlist")) do
        -- local sName = DB.getValue(nodeWeapon,"name","")
        -- sName = StringManager.capitalize(sName);
        -- DB.setValue(nodeWeapon, "name","string",sName);
        -- Debug.console("data_library_adnd.lua","processUpdateADND","weapon-name",sName);
        -- local sClass, sRecord = DB.getValue(nodeWeapon, "shortcut", "", "");
        -- if (sClass == "" and sRecord == "") then
          -- Debug.console("data_library_adnd.lua","processUpdateADND","npc-name",DB.getValue(nodeNPC,"name","NO-NAME"));
          -- DB.setValue(nodeWeapon, "shortcut", "windowreference", "quicknote", nodeWeapon.getPath() .. '.itemnote');
        -- end
      -- end
    -- end
  
  -- fix some unidentified issues caused by some code no longer around
  -- for _,nodeNPC in pairs(DB.getChildren("npc")) do
    -- local nCount = 0;
    -- for _, nodeWeapon in pairs(DB.getChildren(nodeNPC,"weaponlist")) do
      -- nCount = nCount + 1;
      -- local sName = DB.getValue(nodeWeapon,"name","");
-- Debug.console("data_library_adnd.lua","processUpdateADND","npc-name",DB.getValue(nodeNPC,"name","NO-NAME"));    
-- Debug.console("data_library_adnd.lua","processUpdateADND","weapon-name",DB.getValue(nodeWeapon,"name","NO-NAME"));    
      -- if sName:match("unidentified item") then
        -- DB.setValue(nodeWeapon,"name","string","Attack #" .. nCount);
        -- Debug.console("data_library_adnd.lua","processUpdateADND","SET weapon-name",DB.getValue(nodeWeapon,"name","NO-NAME"));    
      -- end
    -- end
  -- end

  
  
  
  
  end -- is host
end


-- apply "damage" string and do best effort to parse and make action/weapons
function setActionWeapon(nodeNPC)
  local sDamageRaw = DB.getValue(nodeNPC,"damage","");
  sDamageRaw = sDamageRaw:lower();
  local byWeapon = sDamageRaw:match("by weapon");
  sDamageRaw = string.gsub(sDamageRaw:lower(),"by weapon","");
  sDamageRaw = string.gsub(sDamageRaw:lower(),"or","");
  sDamageRaw = StringManager.trim(sDamageRaw);
  local aAttacks = {};
  
Debug.console("data_library_adnd.lua","setActionWeapon","sDamageRaw",sDamageRaw);                  

  if (sDamageRaw ~= "" or byWeapon) then
    if (string.match(sDamageRaw,"/") and not string.match(sDamageRaw,"n/a")) then
      aAttacks = StringManager.split(sDamageRaw, "/", true);
Debug.console("data_library_adnd.lua","setActionWeapon","aAttacks1",aAttacks);                  
    end
    if #aAttacks < 1 then
Debug.console("data_library_adnd.lua","setActionWeapon","aAttacks2",aAttacks);     
      for sDice in string.gmatch(sDamageRaw,"%d+[dD-]%d+[%+-]%d+") do
Debug.console("data_library_adnd.lua","setActionWeapon","sDice1",sDice);                  
        table.insert(aAttacks, sDice)
      end
      for sDice, sOther in string.gmatch(sDamageRaw,"(%d+[dD-]%d+)([^%d%+-])") do
Debug.console("data_library_adnd.lua","setActionWeapon","sDice2",sDice);                  
Debug.console("data_library_adnd.lua","setActionWeapon","sOther1",sOther);                  
        table.insert(aAttacks, sDice)
      end
      for sDice in string.gmatch(sDamageRaw,"(%d+[dD-]%d+)") do
Debug.console("data_library_adnd.lua","setActionWeapon","sDice5",sDice);                  
        table.insert(aAttacks, sDice)
      end
    end
    -- if no attacks found and has byWeapon
    if #aAttacks < 1 and byWeapon then
      table.insert(aAttacks,"1d6");
      Debug.console("data_library_adnd.lua","setActionWeapon","Useing default byweapon 1d6");            
    elseif #aAttacks < 1 then
    table.insert(aAttacks,"1d0+1"); 
    Debug.console("data_library_adnd.lua","setActionWeapon","No attacks found in damage I could use");            
    end
    
    if #aAttacks > 0 then
  -- this will try and fix 1-4, 1-8, 2-8 damage dice
      for nIndex,sAttack in pairs(aAttacks) do 
  Debug.console("data_library_adnd.lua","setActionWeapon","nIndex",nIndex);            
  Debug.console("data_library_adnd.lua","setActionWeapon","sAttack",sAttack);            
        if (string.match(sAttack,"^(%d+)([-])(%d+)$")) then
          local sCount, sSign, sSize = string.match(sAttack,"^(%d+)([-])(%d+)$");
          local nCount = tonumber(sCount) or 1;
          local nSize = tonumber(sSize) or 1;
          local sRemainder = "";
          if nCount > 1 then
            local nSizeAdjusted = math.ceil(nSize/nCount);
  Debug.console("data_library_adnd.lua","setActionWeapon","nSizeAdjusted",nSizeAdjusted);       
            local nRemainder = nSize - (nSizeAdjusted*nCount);
  Debug.console("data_library_adnd.lua","setActionWeapon","nRemainder",nRemainder);       
            if nRemainder > 0 then
              sRemainder = "+" .. nRemainder;
            elseif nRemainder < 0 then
              sRemainder = nRemainder;
            end
            nSize = nSizeAdjusted;
          end
          aAttacks[nIndex] = nCount .. "d" .. nSize .. sRemainder;
  Debug.console("data_library_adnd.lua","setActionWeapon","aAttacks[nIndex]",aAttacks[nIndex]);       
        end
      end
      -- end dice fix
      
Debug.console("data_library_adnd.lua","setActionWeapon","aAttacks-->",aAttacks);       
      local nodeWeapons = nodeNPC.createChild("weaponlist");  
      local nCount = 0;
      for _,sAttack in pairs(aAttacks) do 
        nCount = nCount + 1;
        local nSpeedFactor = 1;
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
    else
Debug.console("data_library_adnd.lua","setActionWeapon","NO ATTACKS-->",aAttacks);       
    end
  end
end
