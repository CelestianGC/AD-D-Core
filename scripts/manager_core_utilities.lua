--
--
-- Various utility functions
--
--
--

function onInit()
end


-- this is to replace a string value at a specific location
-- why the heck doesn't lua have this natively? -- celestian
function replaceStringAt(sOriginal,sReplacement,nStart,nEnd)
  local sFinal = nil;
  if (nStart == 1) then
    sFinal = sReplacement .. sOriginal:sub(nEnd+1,sOriginal:len());
  else
    sFinal = sOriginal:sub(1,nStart-1) .. sReplacement .. sOriginal:sub(nEnd+1,sOriginal:len());
  end
  return sFinal;
end

-- find a weapon, by name, and return it as node
function getWeaponNodeByName(sWeapon)
  local nodeWeapon = nil;
  for _,nodeItem in pairs(DB.getChildrenGlobal("item")) do
    local sItemName = DB.getValue(nodeItem,"name");
    if sItemName:lower() == sWeapon:lower() then 
      if ItemManager2.isWeapon(nodeItem) then
        nodeWeapon = nodeItem;
        break;
      end
    end
  end
  return nodeWeapon;
end