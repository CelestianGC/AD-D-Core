-- data library for ad&d core ruleset
--
--
--

function onInit()
  DesktopManager.showDockTitleText(true);
  DesktopManager.setDockTitleFont("sidebar");
  DesktopManager.setDockTitleFrame("", 25, 2, 25, 5);
  DesktopManager.setDockTitlePosition("top", 2, 14);
  DesktopManager.setStackIconSizeAndSpacing(54, 29, 3, 3);
  DesktopManager.setDockIconSizeAndSpacing(136, 24, 0, 6);
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
function processUpdateADND(sCommand, sParams)
  if User.isHost() then
    local aBlockFrames = {};
    local aFrames = Interface.getFrames();
    for _,sFrame in pairs(aFrames) do
      local sThisFrame = sFrame:match("^referenceblock%-([%w%a]+)");
      if (sThisFrame) then
        table.insert(aBlockFrames,sThisFrame);
Debug.console("data_library_adnd.lua","processUpdateADND","sThisFrame",sThisFrame);            
      end
    end -- for frames
  
  
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

 -- for _,nodeClass in pairs(DB.getChildren("class")) do
  -- Debug.console("data_library_adnd.lua","processUpdateADND","name",DB.getValue(nodeClass,"name","NO-NAME"));
  -- for _,nodeAdvance in pairs(DB.getChildren("advancement")) do
    -- DB.setValue(nodeAdvance,"powerdisplaymode","string","action");
    -- DB.setValue(nodeAdvance,"powermode","string","standard");
    -- Debug.console("data_library_adnd.lua","processUpdateADND","level",DB.getValue(nodeAdvance,"level"));
  -- end
 -- end

 -- this was to test using dice rolls with math works! 
-- Debug.console("data_library_adnd.lua","processUpdateADND","sParams",sParams);
  -- local nDiceResult = math.floor(StringManager.evalDiceMathExpression(sParams));
-- Debug.console("data_library_adnd.lua","processUpdateADND","nDiceResult",nDiceResult);
  -- end -- is host
  
  --local nCount = 0;
  --for _,nodeNPC in pairs(DB.getChildren("npc")) do
  --  nCount = nCount + 1;
    -- local sNPCName = DB.getValue(nodeNPC,"name","");
    -- this was to set all action/power tab modes to standard/action buttons
    --<powerdisplaymode type="string">action</powerdisplaymode>
    -- DB.setValue(nodeNPC,"powerdisplaymode","string","action");
    -- DB.setValue(nodeNPC,"powermode","string","standard");
    -- this was to search for "Surprise" abilities and make sure the 
    -- surprise value was set properly.
    -- for _,nodeAbility in pairs(DB.getChildren(nodeNPC, "abilitynoteslist")) do
-- --Debug.console("data_library_adnd.lua","processUpdateADND","nodeAbility",nodeAbility);     
      -- local sName = DB.getValue(nodeAbility,"name","");
      -- local sText = DB.getValue(nodeAbility,"text","");
      -- local sTextLower = sText:lower();
      -- if (sName == "Surprise" and sTextLower:match("surprised only")) then
-- Debug.console("data_library_adnd.lua","processUpdateADND","sNPCName",sNPCName);    
-- Debug.console("data_library_adnd.lua","processUpdateADND","sName",sName);
-- Debug.console("data_library_adnd.lua","processUpdateADND","sTextLower",sTextLower);
        -- local nMatch1,nMatch2 = sTextLower:match("surprised only on a (%d) or (%d)");
        -- if (nMatch1 and nMatch2) then
          -- nMatch2 = tonumber(nMatch2) or 0;
          -- DB.setValue(nodeNPC,"surprise.total","number",nMatch2);
-- Debug.console("data_library_adnd.lua","processUpdateADND","a)nMatch1",nMatch1);        
-- Debug.console("data_library_adnd.lua","processUpdateADND","a)nMatch2",nMatch2);        
        -- else
          -- nMatch1 = sTextLower:match("surprised only on a (%d)") or sTextLower:match("surprised only on the roll of a (%d)") or sTextLower:match("surprised on a 1 (%d)")
          -- if (nMatch1) then
            -- nMatch1 = tonumber(nMatch1) or 0;
-- Debug.console("data_library_adnd.lua","processUpdateADND","b)nMatch1",nMatch1);        
            -- DB.setValue(nodeNPC,"surprise.total","number",nMatch1);
          -- end
        -- end
      -- end
      
    -- end
  -- end
  -- Debug.console("data_library_adnd.lua","processUpdateADND","NPC nCount",nCount);

  -- local sMajor, sMinor, sPoint = Interface.getVersion();
  -- Debug.console("data_library_adnd.lua","processUpdateADND","sMajor",sMajor);          
  -- Debug.console("data_library_adnd.lua","processUpdateADND","sMinor",sMinor);          
  -- Debug.console("data_library_adnd.lua","processUpdateADND","sPoint",sPoint);       

-- damage changed on a weapon, bulk update  
  -- for _,nodeItem in pairs(DB.getChildren("item")) do
-- Debug.console("data_library_adnd.lua","processUpdateADND","nodeItem",nodeItem);  
    -- updateDamageString(nodeItem);
  -- end

  -- sound testing
  -- local sURLCommand = "winamp.exe";
  -- sURLCommand = "file:///";
  
  -- local sCommandOpts = " /PLCLEAR /PLADD ";
  -- sCommandOpts = "";
  
  -- local sSoundFilePath = "D:\\Sounds\\ADnD\\Creature\\";
  -- local sSoundFile = sSoundFilePath .. sParams;
  -- local sSoundString = sURLCommand .. sCommandOpts ..  sSoundFile;
  
  -- --sSoundString = "vlc://pause:10";
  -- --sSoundString = "vlc://quit";
  -- --sSoundString = "vlc:///D:\\Sounds\\ADnD\\Creature\\878b87_Godzilla_Roar_Sound_FX.mp3"
  -- --sSoundString = "file:///D:\\Sounds\\ADnD\\Creature\\878b87_Godzilla_Roar_Sound_FX.mp3"
  
-- Debug.console("data_library_adnd.lua","processUpdateADND","sSoundString",sSoundString);    
  -- Interface.openWindow("url",sSoundString);
  end -- isHost()
end

function fixNPCPowerToWEapons()
    -- this is to flip through all powers of a npc, find ones with are action type "melee"
    -- and if slash/piercing/bludgeoning we convert it to weapon attack, grab first damage within the power
    -- and add that also, then remove the damage/melee action.
    local nCount = 0 ;
    local aDeleteTheseNodes = {};
    for _,nodeNPC in pairs(UtilityManager.getSortedTable(DB.getChildren("npc"))) do
      local sNPCName = DB.getValue(nodeNPC,"name","");
      local nodeWeapons = nodeNPC.createChild("weaponlist");  
--Debug.console("data_library_adnd.lua","processUpdateADND","sNPCName",sNPCName);              
      for _, nodePower in pairs(DB.getChildren(nodeNPC,"powers")) do
        local sPowerName = DB.getValue(nodePower,"name","");
        local sDesc = DB.getValue(nodePower,"description","");
--Debug.console("data_library_adnd.lua","processUpdateADND","sPowerName",sPowerName);              
        for _, nodeAction in pairs(DB.getChildren(nodePower,"actions")) do
          local sActionName = DB.getValue(nodeAction,"name","");
          local sActionType = DB.getValue(nodeAction,"type","");
          local sAtkType = DB.getValue(nodeAction,"atktype","");
          local nSpeedFactor = DB.getValue(nodeAction,"castinitiative",1);
--Debug.console("data_library_adnd.lua","processUpdateADND","sActionName",sActionName);              
--Debug.console("data_library_adnd.lua","processUpdateADND","sActionType",sActionType);    
          -- get actions with atkType melee, convert them to a weapon attack
          if (sAtkType == "melee") then --or (sAtkType == "ranged")
--Debug.console("data_library_adnd.lua","processUpdateADND","sPowerName",sPowerName);              
--Debug.console("data_library_adnd.lua","processUpdateADND","sActionName",sActionName);              
--Debug.console("data_library_adnd.lua","processUpdateADND","sActionType",sActionType);              
--Debug.console("data_library_adnd.lua","processUpdateADND","sAtkType",sAtkType);           

            for _,sDamageNode in pairs(getDamageActions(nodePower)) do
--Debug.console("data_library_adnd.lua","processUpdateADND","DMG:sDamageNode",sDamageNode);            
              local nodeDamage = DB.findNode(sDamageNode);
              local nodeActionDamage = nodeDamage.getChild("...");
-- Debug.console("data_library_adnd.lua","processUpdateADND","DMG:nodeActionDamage",nodeActionDamage);            
-- Debug.console("data_library_adnd.lua","processUpdateADND","DMG:nodeDamage",nodeDamage);            
              -- <bonus type="number">0</bonus>
              -- <castermax type="number">10</castermax>
              -- <customvalue type="number">0</customvalue>
              -- <dice type="dice">d6</dice>
              -- <dicecustom type="dice"></dicecustom>
              -- <type type="string">bludgeoning</type>
              local aDice = DB.getValue(nodeDamage,"dice");
              local aDiceCustom = DB.getValue(nodeDamage,"dicecustom");
              local nBonus = DB.getValue(nodeDamage,"bonus",0);
              local sType = DB.getValue(nodeDamage,"type","");
              
              if aDice == nil then aDice = aDiceCustom; end;
              if (sType == "bludgeoning" or sType == "slashing" or sType == "piercing") then 
                nCount = nCount + 1;
                -- we're replacing this node as a weapon style attack so remove it.
Debug.console("data_library_adnd.lua","processUpdateADND","sNPCName",sNPCName);              
                DB.setValue(nodeAction,"atktype","string",""); -- remove melee/ranged attack
                -- can't delete a node in a for loop for a child in loop
                table.insert(aDeleteTheseNodes,nodeActionDamage.getPath());
                
  Debug.console("data_library_adnd.lua","processUpdateADND","DMG:sPowerName",sPowerName);                       
  --Debug.console("data_library_adnd.lua","processUpdateADND","DMG:nSpeedFactor",nSpeedFactor);                       
  --Debug.console("data_library_adnd.lua","processUpdateADND","DMG:sDesc",sDesc);                       
  --Debug.console("data_library_adnd.lua","processUpdateADND","DMG:aDice",aDice);                       
  --Debug.console("data_library_adnd.lua","processUpdateADND","DMG:nBonus",nBonus);                       
  --Debug.console("data_library_adnd.lua","processUpdateADND","DMG:sType",sType);                       
                local nodeWeapon = nodeWeapons.createChild();
                DB.setValue(nodeWeapon,"name","string",sPowerName);
                DB.setValue(nodeWeapon,"speedfactor","number",nSpeedFactor);
                
                DB.setValue(nodeWeapon,"itemnote.name","string",sPowerName);
                DB.setValue(nodeWeapon,"itemnote.text","formattedtext",sDesc);
                DB.setValue(nodeWeapon,"itemnote.locked","number",1);
                DB.setValue(nodeWeapon, "shortcut", "windowreference", "quicknote", nodeWeapon.getPath() .. '.itemnote');
                
                local nodeDamageLists = nodeWeapon.createChild("damagelist"); 
                local nodeWeaponDamage = nodeDamageLists.createChild();
                DB.setValue(nodeWeaponDamage,"dice","dice",aDice);
                DB.setValue(nodeWeaponDamage,"bonus","number",nBonus);
                DB.setValue(nodeWeaponDamage,"stat","string","base");
                DB.setValue(nodeWeaponDamage,"type","string",sType);
              end -- slash/piercing/bludgeoning
            end -- sDamageNode
          end -- sAtkType
        end -- for actions
      end -- for nodePower
    end -- for npc
    for _,sDeleteNode in pairs(aDeleteTheseNodes) do
      local nodeDelete = DB.findNode(sDeleteNode);
      nodeDelete.delete();
    end -- 
Debug.console("data_library_adnd.lua","processUpdateADND","nCount--------------------->",nCount);              

end
-- find all the damage for this power
function getDamageActions(nodePower)
  local aDamageActions = {}
  for _, nodeAction in pairs(DB.getChildren(nodePower,"actions")) do
    local bIsDamage = (DB.getChildCount(nodeAction,"damagelist") > 0);
    if (bIsDamage) then
      for _, nodeDamage in pairs(DB.getChildren(nodeAction,"damagelist")) do
        table.insert(aDamageActions,nodeDamage.getPath());
      end
    end
  end
  return aDamageActions;
end

-- damage changed on a weapon, bulk update
function updateDamageString(nodeItem)
Debug.console("data_library_adnd.lua","updateDamageString","nodeItem",nodeItem); 
  local sDamageAll = "";
  --weaponlist
  local aWeaponNodes = UtilityManager.getSortedTable(DB.getChildren(nodeItem, "weaponlist"));
  local bUpdateDamageString = (#aWeaponNodes > 0)
  for _,nodeWeapon in ipairs(aWeaponNodes) do
Debug.console("data_library_adnd.lua","updateDamageString","nodeWeapon",nodeWeapon); 
    local nType = DB.getValue(nodeWeapon,"type",0);
    local sBaseAbility = "strength";
    if nType == 1 then
      sBaseAbility = "dexterity";
    end
    -- flip through all damage entries and update damage display string
    -- also update the weapons "damage" string field to contain them all so
    -- that they show up decently in the item records "weapons" list.
    local aDamageNodes = UtilityManager.getSortedTable(DB.getChildren(nodeWeapon, "damagelist"));
    for _,nodeDMG in ipairs(aDamageNodes) do
Debug.console("data_library_adnd.lua","updateDamageString","nodeDMG",nodeDMG); 
      local nMod = DB.getValue(nodeDMG, "bonus", 0);
      local sAbility = DB.getValue(nodeDMG, "stat", "");
      if sAbility == "base" then
        sAbility = sBaseAbility;
      end
      local aDice = DB.getValue(nodeDMG, "dice", {});
      if #aDice > 0 or nMod ~= 0 then
        local sDamage = StringManager.convertDiceToString(DB.getValue(nodeDMG, "dice", {}), nMod);
        local sType = DB.getValue(nodeDMG, "type", "");
        if sType ~= "" then
          sDamage = sDamage .. " " .. sType;
        end
          sDamageAll = sDamageAll .. sDamage .. ";";
          --DB.setValue(nodeDMG, "damageasstring","string",sDamage);
      end
    end
    -- and lastly add the damage string for all of them
  end -- aWeaponNodes  
Debug.console("data_library_adnd.lua","updateDamageString","bUpdateDamageString",bUpdateDamageString); 
  if bUpdateDamageString then
    DB.setValue(nodeItem,"damage","string",sDamageAll);
Debug.console("data_library_adnd.lua","updateDamageString","updateDamageString",sDamageAll); 
  end
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
