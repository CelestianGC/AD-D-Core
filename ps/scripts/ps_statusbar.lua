-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local ctrlBar = nil;

local bOffset = false;
local x,y,w,h = 0;
local backcolor = "828182";

local nMax = 0;
local nCurrent = 0;

function onInit()
	ctrlBar = window.createControl("statusbarindicator", getName() .. "_bar");
	
	updateSize();
	updatePosition();
	
	if barback and barback[1] then
		backcolor = barback[1];
	end
	
	if reverse and reverse[1] then
		bOffset = isHorizontal();
	else
		bOffset = not isHorizontal();
	end
end

function isHorizontal()
	if h > w then
		return false;
	else
		return true;
	end
end

function updatePosition()
	x,y = getPosition();
end

function updateSize()
	w,h = getSize();
end 

function updateBackColor(backcolorstr)
	backcolor = backcolorstr;
	update();
end

function setValue(num)
	nCurrent = tonumber(num) or 0;
	update();
end

function setMax(num)
	nMax = tonumber(num) or 0;
	update();
end

function getValue()
	return nCurrent;
end

function getMax()
	return nMax;
end

function updateText(sText)
	setTooltipText(sText);
	if ctrlBar then
		ctrlBar.setTooltipText(sText);
	end
end

function update()
	updatePosition();
	updateSize();

	if ctrlBar then
		local nPercent;
		if nMax == 0 then
			nPercent = 0;
		else
			nPercent = nCurrent / nMax;
		end
		if nPercent > 1 then
			nPercent = 1;
		elseif nPercent < 0 then
			nPercent = 0;
		end

		local nFrom, nLen;
		if isHorizontal() then
			nLen = math.floor(((w - 2) * nPercent) + 0.5);
			if bOffset then
				nFrom = x + (w - nLen) - 1;
			else
				nFrom = x + 1;
			end
			ctrlBar.setStaticBounds(nFrom, y + 1, nLen, h - 2);
		else
			nLen = math.floor(((h - 2) * nPercent) + 0.5);
			if bOffset then
				nFrom = y + (h - nLen) - 1;
			else
				nFrom = y + 1;
			end
			ctrlBar.setStaticBounds(x + 1, nFrom, w - 2, nLen);
		end
		
		ctrlBar.setBackColor(backcolor);
	end
end
