-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
--Debug.console("npc_import.lua","onInit","getDatabaseNode",getDatabaseNode());
end


function processImportText()
    local sText = importtext.getValue() or "";
    if (sText ~= "") then
      local aNPCText = {};
      for sLine in string.gmatch(sText, '([^\r\n]+)') do
          table.insert(aNPCText, sLine);
      end
      local nodeNPC = ManagerImportADND.createBlankNPC();

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
          ManagerImportADND.setExperience(nodeNPC,sLine);
        end
        -- osric uses "level/xp: 6/1,000+10/hp" style exp entry
        if (string.match(sLine:lower(),"^level/x%.?p%.?:")) then
          bProcessed = true;
          ManagerImportADND.setExpLevelOSRIC(nodeNPC,sLine);
        end
        -- TSR1 uses "level/xp value: VII/1,000+10/hp"
        if (string.match(sLine:lower(),"^level/xp value:")) then
          bProcessed = true;
          ManagerImportADND.setExpLevelTSR1(nodeNPC,sLine);
        end
        
        -- Swords and Wizadry uses "Challenge Level/XP: 4/120" style exp entry
        if (string.match(sLine:lower(),"^challenge level/xp:")) then
          bProcessed = true;
          ManagerImportADND.setExpLevelSW(nodeNPC,sLine);
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
      ManagerImportADND.setHD(nodeNPC);
      ManagerImportADND.setAC(nodeNPC);
      ManagerImportADND.setActionWeapon(nodeNPC);
      ManagerImportADND.setSomeDefaults(nodeNPC);
    end
end
