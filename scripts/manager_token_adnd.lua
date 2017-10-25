function onInit()
    -- use the onDoubleClick here instead of CoreRPG version
    Token.onDoubleClick = onDoubleClick;
end

function onDoubleClick(tokenMap, vImage)
local tokenName = tokenMap.getName();
local nodeNPC = DB.findNode(tokenName);
    if (tokeName ~= "" and nodeNPC) then
        -- local sClass = "npc";
        -- local sName = DB.getValue(nodeNPC,"name","");
        -- CombatManager.addNPC(sClass, nodeNPC, sName);    
        spawnNPC(nodeNPC,tokenMap);
    else
        local nodeCT = CombatManager.getCTFromToken(tokenMap);
        if nodeCT then
            local sClass, sRecord = DB.getValue(nodeCT, "link", "", "");
            if sClass == "charsheet" then
                if DB.isOwner(sRecord) then
                    Interface.openWindow(sClass, sRecord);
                    vImage.clearSelectedTokens();
                end
            else
                if User.isHost() or (DB.getValue(nodeCT, "friendfoe", "") == "friend") then
                    Interface.openWindow("npc", nodeCT);
                    vImage.clearSelectedTokens();
                end
            end
        end
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

