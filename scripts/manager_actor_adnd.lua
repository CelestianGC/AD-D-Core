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