--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function setItemRecordType(sRecordType)
	local sDisplayClass = LibraryData.getRecordDisplayClass(sRecordType, getDatabaseNode());
	setItemClass(sDisplayClass);
end

function setItemClass(sDisplayClass)
	local node = getDatabaseNode();
	if node and sDisplayClass ~= "" then
		link.setValue(sDisplayClass, node.getPath());
	else
		link.setVisible(false);
		link.setEnabled(false);
	end
end

function setColumnInfo(aColumns, nDefaultColumnWidth)
-- Debug.console("ref_groupedlist_groupitem_adnd.lua","setColumnInfo","aColumns",aColumns);
-- Debug.console("ref_groupedlist_groupitem_adnd.lua","setColumnInfo","nDefaultColumnWidth",nDefaultColumnWidth);
	for kColumn,rColumn in ipairs(aColumns) do
		local sControlClass = "string_refgroupedlistgroupitem";
		if rColumn.sType == "number" then
			if rColumn.bDisplaySign then
				sControlClass = "number_signed_refgroupedlistgroupitem";
			else
				sControlClass = "number_refgroupedlistgroupitem";
			end
		elseif rColumn.sType == "formattedtext" then
			if rColumn.bWrapped then
				sControlClass = "string_refgroupedlistgroupitem_ft_wrap";
			else
				sControlClass = "string_refgroupedlistgroupitem_ft";
			end
		elseif rColumn.bCentered then
			if rColumn.bWrapped then
				sControlClass = "string_refgroupedlistgroupitem_center";
			else
				sControlClass = "string_refgroupedlistgroupitem_center_wrap";
			end
		elseif kColumn == 1 then
			if rColumn.bWrapped then
				sControlClass = "string_refgroupedlistgroupitem_link_wrap";
			else
				sControlClass = "string_refgroupedlistgroupitem_link";
			end
		else
			if rColumn.bWrapped then
				sControlClass = "string_refgroupedlistgroupitem_wrap";
			end
		end
		
    -- AD&D specific value
    if (rColumn.bItemDamage) then
      if rColumn.bWrapped then
        sControlClass = "itemdamage_refgroupedlistgroupitem_wrap";
      else
        -- add unwrapped version
        sControlClass = "itemdamage_refgroupedlistgroupitem_wrap";
      end
    end
    -- end AD&D specific value
    
		local cField = createControl(sControlClass, rColumn.sName);
-- Debug.console("ref_groupedlist_groupitem_adnd.lua","setColumnInfo","cField",cField);    
-- Debug.console("ref_groupedlist_groupitem_adnd.lua","setColumnInfo","sControlClass",sControlClass);    
-- Debug.console("ref_groupedlist_groupitem_adnd.lua","setColumnInfo","rColumn.sName",rColumn.sName);    
-- Debug.console("ref_groupedlist_groupitem_adnd.lua","setColumnInfo","------------------------------");    
		if rColumn.sType == "formattedtext" then
			cField.setValue(getFTColumnValue(rColumn.sName) or "")
		end
		cField.setAnchoredWidth(rColumn.nWidth or nDefaultColumnWidth)
	end
end

function getFTColumnValue(sColumnName)
	local sText = DB.getText(getDatabaseNode(), sColumnName)
	if (sText or "") == "" then
		return "";
	end
	
	local sTemp = sText:sub(1, math.min(sText:find("\n") or #sText, 100));
	if #sTemp < #sText then
		local nSpaceBreak = sTemp:reverse():find("%s");
		if nSpaceBreak then
			sTemp = sTemp:sub(1, #sTemp - nSpaceBreak - 1);
		end
		sTemp = sTemp .. "...";
	end
	return sTemp;
end
