-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onSummaryChanged();
	update();
end

function onSummaryChanged()
	local nLevel = level.getValue();
	local sSchool = school.getValue();
	
	local aText = {};
	if nLevel > 0 then
		table.insert(aText, Interface.getString("level") .. " " .. nLevel);
	end
	if sSchool ~= "" then
		table.insert(aText, sSchool);
	end
	if nLevel == 0 then
		table.insert(aText, Interface.getString("ref_label_cantrip"));
	end
	if ritual.getValue() ~= 0 then
		table.insert(aText, "(" .. Interface.getString("ref_label_ritual") .. ")");
	end
	
	summary_label.setValue(StringManager.capitalize(table.concat(aText, " ")));
end

function updateControl(sControl, bReadOnly, bForceHide)
	if not self[sControl] then
		return false;
	end
	
	return self[sControl].update(bReadOnly, bForceHide);
end

function update()
	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());

	local bSection1 = false;
	if updateControl("shortdescription", bReadOnly) then bSection1 = true; end;
	
	local bSection2 = false;
	if updateControl("level", bReadOnly, bReadOnly) then bSection2 = true; end;
	if updateControl("school", bReadOnly, bReadOnly) then bSection2 = true; end;
	if updateControl("ritual", bReadOnly, bReadOnly) then bSection2 = true; end;
	if (not bReadOnly) or (level.getValue() == 0 and school.getValue() == "") then
		summary_label.setVisible(false);
	else
		summary_label.setVisible(true);
		bSection2 = true;
	end
	
	local bSection3 = false;
	if updateControl("castingtime", bReadOnly) then bSection3 = true; end;
	if updateControl("range", bReadOnly) then bSection3 = true; end;
	if updateControl("components", bReadOnly) then bSection3 = true; end;
	if updateControl("duration", bReadOnly) then bSection3 = true; end;
	if updateControl("description", bReadOnly) then bSection3 = true; end;

	local bSection4 = false;
	if updateControl("source", bReadOnly) then bSection4 = true; end;
	
	divider.setVisible(bSection1 and bSection2);
	divider2.setVisible((bSection1 or bSection2) and bSection3);
	divider3.setVisible((bSection1 or bSection2 or bSection3) and bSection4);
end
