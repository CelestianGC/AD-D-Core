function onInit()
    -- use the onDoubleClick here instead of CoreRPG version
    
  --- disabled for now, will revisit when export will export TOKENS on the map
  --Token.onDoubleClick = onDoubleClick;
  
  -- this captures alt-double click to jump to token in CT
  -- or w/o alt and load sheet for token
  Token.onDoubleClick = onDoubleClickADND;
    
  -- DB.addHandler("options.DM_SHOW_NPC_EFFECTS", "onUpdate", TokenManager.onOptionChanged);
  -- DB.addHandler("options.DM_SHOW_NPC_HEALTHBAR", "onUpdate", TokenManager.onOptionChanged);
end

function onDoubleClickADND(tokenMap, vImage)
--local tokenName = tokenMap.getName();
--local nodeNPC = DB.findNode(tokenName);
--    if (tokeName ~= "" and nodeNPC) then
        -- local sClass = "npc";
        -- local sName = DB.getValue(nodeNPC,"name","");
        -- CombatManager.addNPC(sClass, nodeNPC, sName);    
--        spawnNPC(nodeNPC,tokenMap);
--    else
        -- local nodeCT = CombatManager.getCTFromToken(tokenMap);
        -- if nodeCT then
            -- local sClass, sRecord = DB.getValue(nodeCT, "link", "", "");
            -- if sClass == "charsheet" then
                -- if DB.isOwner(sRecord) then
                    -- Interface.openWindow(sClass, sRecord);
                    -- vImage.clearSelectedTokens();
                -- end
            -- else
                -- if User.isHost() or (DB.getValue(nodeCT, "friendfoe", "") == "friend") then
                    -- Interface.openWindow("npc", nodeCT);
                    -- vImage.clearSelectedTokens();
                -- end
            -- end
        -- end
--    end    
  if User.isHost() and Input.isAltPressed() then
    local ctwnd = Interface.findWindow("combattracker_host", "combattracker");
    if ctwnd then
      local nodeCT = CombatManager.getCTFromToken(tokenMap);
      local sNodeID = nodeCT.getPath();
       for k,v in pairs(ctwnd.list.getWindows()) do
        if v.getDatabaseNode().getPath() == sNodeID then 
          ctwnd.list.scrollToWindow(v);
          v.name.setFocus();
        end
      end
    end
  else
    TokenManager.onDoubleClick(tokenMap, vImage);
  end

end

-- spawn the npc passed using token as location
function spawnNPC(nodeNPC,tokenMap)
    if nodeNPC then
        local xpos, ypos = tokenMap.getPosition();
        local sName = DB.getValue(nodeNPC,"name","");
        local sClass = "npc";
        local sRecord = tokenMap.getContainerNode().getNodeName();
        
        -- local aPlacement = {};
        -- for _,vPlacement in pairs(DB.getChildren(vNPCItem, "maplink")) do
            -- local rPlacement = {};
            -- local _, sRecord = DB.getValue(vPlacement, "imageref", "", "");
            -- rPlacement.imagelink = sRecord;
            -- rPlacement.imagex = DB.getValue(vPlacement, "imagex", 0);
            -- rPlacement.imagey = DB.getValue(vPlacement, "imagey", 0);
            -- table.insert(aPlacement, rPlacement);
        -- end
        
        --local nCount = DB.getValue(vNPCItem, "count", 1);
        local nCount = 1;
        for i = 1, nCount do
            local nodeEntry = CombatManager.addNPC(sClass, nodeNPC, sName);
            if nodeEntry then
                -- local sFaction = DB.getValue(vNPCItem, "faction", "");
                -- if sFaction ~= "" then
                    -- DB.setValue(nodeEntry, "friendfoe", "string", sFaction);
                -- end
                local sToken = tokenMap.getPrototype();
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
                    
                    TokenManager.setDragTokenUnits(DB.getValue(nodeEntry, "space"));
                    local tokenAdded = Token.addToken(sRecord, sToken, xpos, ypos);
                    TokenManager.endDragTokenWithUnits(nodeEntry);
                    if tokenAdded then
                        TokenManager.linkToken(nodeEntry, tokenAdded);
                    end
                end
            else
                ChatManager.SystemMessage(Interface.getString("ct_error_addnpcfail") .. " (" .. sName .. ")");
            end
        end
    tokenMap.delete();
    else
        ChatManager.SystemMessage(Interface.getString("ct_error_addnpcfail2") .. " (" .. sName .. ")");
    end
end

