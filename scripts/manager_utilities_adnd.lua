---
--- Various utility functions
---
---

function onInit()
end

function onClose()
end

-- replace oldWindow with a new window of sClass type
function replaceWindow(oldWindow, sClass, sNodePath)
--Debug.console("manager_utilities_adnd.lua","replaceWindow","oldWindow",oldWindow);
  local x,y = oldWindow.getPosition();
  local w,h = oldWindow.getSize();
  -- Close here otherwise you just close the one you just made since paths are the same at times (drag/drop inline replace item/npc)
  oldWindow.close(); 
  --
  local wNew = Interface.openWindow(sClass, sNodePath);
  wNew.setPosition(x,y);
  wNew.setSize(w,h);
end 

-- check all modules loaded and local records
-- for skill with name of sSkillName 
function findSkillRecord(sSkillName)
  local nodeFound = nil;
  for _,nodeSkill in pairs(DB.getChildrenGlobal("skill")) do
    local sName = DB.getValue(nodeSkill,"name");
    sName = sName:gsub("%[%d+%]",""); -- remove bracket cost 'Endurance[2]' and just get name clean.
    sName = StringManager.trim(sName);
    
    if (sName:lower() == sSkillName:lower()) then
      nodeFound = nodeSkill;
      break;
    end
  end
  return nodeFound;
end

--
-- Control+Drag/Drop story or ref-manual link, capture text and append that text
-- into the target record
--
function onDropStory(x, y, draginfo, nodeTarget, sTargetValueName)
  
  -- this is the value we're placing the text into on the target node
  if not sTargetValueName then
    sTargetValueName = 'text';
  end
  
  if not nodeTarget then
    return false;
  end
  
  --Debug.console("manager_utilities_adnd.lua","onDropStory","nodeTarget",nodeTarget);
  
  if draginfo.isType("shortcut") then
    --local nodeTarget = getDatabaseNode();
    local bLocked = (DB.getValue(nodeTarget,"locked",0) == 1);
    
    -- if record not locked and control pressed
    if not bLocked and Input.isControlPressed() then
      local nodeSource = draginfo.getDatabaseNode();
      local sClass, sRecord = draginfo.getShortcutData();
      -- if ref-manual page
      if (sClass == 'referencemanualpage') then
        local nodeRefMan = DB.findNode(sRecord);
        local sText = '';
        -- flip through blocks
        -- we need to story the blocks so we get them in the right order
        local aNodeBlocks = UtilityManager.getSortedTable(DB.getChildren(nodeRefMan, "blocks"));
        for _,nodeBlock in ipairs(aNodeBlocks) do
          local sBlockType = DB.getValue(nodeBlock,"blocktype","");
          -- if the block is text append value in it to our text
          if sBlockType == 'singletext' then
            local sBlockText = DB.getValue(nodeBlock,"text","");
            sText = sText .. sBlockText;
          end
        end
        -- grab current text in target
        local sCurrentText = DB.getValue(nodeTarget,sTargetValueName);
        -- append target current text and source text together
        if sText then
          DB.setValue(nodeTarget,sTargetValueName,"formattedtext",sCurrentText .. sText);
        end
      -- if encounter/story entry
      elseif (sClass == "encounter") then
        -- grab text from source
        local sText = DB.getValue(nodeSource,"text");
        -- grab current text in target
        local sCurrentText = DB.getValue(nodeTarget,sTargetValueName);
        -- append target current text and source text together
        if sText then
          DB.setValue(nodeTarget,sTargetValueName,"formattedtext",sCurrentText .. sText);
        end
      end
    end
  end
end


-- get Identity of a char node or from the CT node that is a PC
function getIdentityFromCTNode(nodeCT)
  local rActor = ActorManager.getActorFromCT(nodeCT);
  local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);    
  return getIdentityFromCharNode(nodeActor);
end
function getIdentityFromCharNode(nodeChar)
  return nodeChar.getName();
end

-- output a message simple function
function outputUserMessage(sResource, ...)
  local sFormat = Interface.getString(sResource);
  local sMsg = string.format(sFormat, ...);
  ChatManager.SystemMessage(sMsg);
end

function outputBroadcastMessage(rActor, sResource, ...)
  local sFormat = Interface.getString(sResource);
  local sMsg = string.format(sFormat, ...);
  ChatManager.Message(sMsg, true, rActor)
end
