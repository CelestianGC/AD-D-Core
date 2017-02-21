-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

dieslots = {};

function setDice(n)
	if n < 0 then
		return;
	end

	if #dieslots > n then
		-- Need to close some entries
		for i = n+1, #dieslots do
			dieslots[tonumber(i)].destroy();
			dieslots[tonumber(i)] = nil;
		end
		return;
	end
	
	-- Otherwise, need to create some
	for i = #dieslots+1, n do
		dieslots[tonumber(i)] = createControl("statchatdieslot", "dieslot" .. i);
	end
end

function onInit()
	setDice(windowlist.window.dice.getValue());
end

function isRolled()
	return (rolled.getValue() == 1);
end

function onRolledChanged()
	if rolled.getValue() == 0 then
		for _,v in ipairs(dieslots) do
			v.setValue(0);
		end

		updateTotal();
	end
end

function applyRoll(aDice)
	-- Sort results
	local aSorted = {};
	for _,v in ipairs(aDice) do
		table.insert(aSorted, v.result);
	end
	table.sort(aSorted, function(a,b) return a > b end);

	-- Insert into dieslots
	for k,v in ipairs(aSorted) do
		if k <= #dieslots then
			dieslots[k].setValue(v);
		end
	end
	
	rolled.setValue(1);
	
	updateTotal();
end

function updateTotal()
	local slots = #dieslots;
	local dropped = windowlist.window.dropdice.getValue();
	
	local sum = modifier.getValue();
	
	for i = 1, slots - dropped do
		sum = sum + dieslots[i].getValue();
		dieslots[i].setColor("ff000000");
	end
	
	for i = slots - dropped + 1, slots do
		dieslots[i].setColor("7f000000");
	end
	
	total.setValue(sum);
end
