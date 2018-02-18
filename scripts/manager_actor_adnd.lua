--
--
--
--
--

function onInit()
end

-- check to see if the armor worn by rActor matches sArmorCheck
function isArmorType(rActor, sArmorCheck)
    local bMatch = false;
    local sType, nodeActor = ActorManager.getTypeAndNode(rActor);
    local aCheckSplit = StringManager.split(sArmorCheck:lower(), ",", true);
    local aArmorList = getArmorWorn(nodeActor);
   	for _,v in ipairs(aCheckSplit) do
        -- v==armor type
         if StringManager.contains(aArmorList, v) then
            bMatch = true;
         end
    end

    return bMatch;
end

-- get a list of all the armor worn by this node
function getArmorWorn(node)
    local aArmorList = {};
	for _,vNode in pairs(DB.getChildren(node, "inventorylist")) do
		if DB.getValue(vNode, "carried", 0) == 2 then
			local bIsArmor, _, sSubtypeLower = ItemManager2.isArmor(vNode);
            if bIsArmor then
                local sName = DB.getValue(vNode,"name",""):lower();
                table.insert(aArmorList, sName);    
            end
        end
    end
    return aArmorList;
end

-- return any targets a Combat Tracker node currently has.
function getTargets(rActor)
    local nodeCT = DB.findNode(rActor.sCTNode);
    local aTargetRefs = {};
    if (nodeCT ~= nil) then
      local nodeTargets = DB.getChildren(nodeCT,"targets");
      for _,node in pairs(nodeTargets) do
        local sNodeRef = DB.getValue(node,"noderef","");
        local nodeRef = DB.findNode(sNodeRef);
        if nodeRef ~= nil then
          table.insert(aTargetRefs,nodeRef.getPath());
        end
      end
    end -- nodeCT != nil
    return aTargetRefs;
end