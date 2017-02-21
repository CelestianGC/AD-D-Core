-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onDragStart(button, x, y, draginfo)
	draginfo.setType("statdieslot");
	draginfo.setNumberData(getValue());
	draginfo.setCustomData(self);
	draginfo.disableHotkeying(true);
	
	local base = draginfo.createBaseData("number");
	base.setNumberData(getValue());

	setColor("ffbb0000");

	return true;
end

function onDragEnd()
	window.updateTotal();
end

function onDrop(x, y, draginfo)
	if draginfo.isType("statdieslot") then
		local myvalue = getValue();
	
		-- Swap values
		setValue(draginfo.getNumberData());
		draginfo.getCustomData().setValue(myvalue);

		window.updateTotal();
		
		return true;
	end
	
	return false;
end

function onValueChanged()
	window.updateTotal();
end
