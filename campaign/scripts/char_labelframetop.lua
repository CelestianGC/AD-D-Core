local widget = nil;

function onInit()
	if icons and icons[1] then
		setIcon(icons[1]);
	end
end

function setIcon(sIcon)
	if widget then
		widget.destroy();
	end
	
	if sIcon then
		widget = addBitmapWidget(sIcon);
		widget.setPosition("topleft", 2, 8);
	end
end
