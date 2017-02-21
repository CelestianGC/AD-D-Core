-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	DB.addHandler("charsheet.*.inspiration", "onUpdate", onUpdate);
	CharacterListManager.addDecorator("inspiration", addInspirationWidget);
end

function onUpdate(nodeInspiration)
	updateWidgets(nodeInspiration.getChild("..").getName());
end

function addInspirationWidget(control, sIdentity)
	local widget = control.addBitmapWidget("charlist_inspiration");
	widget.setPosition("center", -25, 9);
	widget.setVisible(false);
	widget.setName("inspiration");

	local textwidget = control.addTextWidget("mini_name", "");
	textwidget.setPosition("center", -25, 9);
	textwidget.setVisible(false);
	textwidget.setName("inspirationtext");
	
	updateWidgets(sIdentity);
end

function updateWidgets(sIdentity)
	local ctrlChar = CharacterListManager.getEntry(sIdentity);
	if not ctrlChar then
		return;
	end
	local widget = ctrlChar.findWidget("inspiration");
	local textwidget = ctrlChar.findWidget("inspirationtext");
	if not widget or not textwidget then
		return;
	end	
	local nInspiration = DB.getValue("charsheet." .. sIdentity .. ".inspiration", 0);
	if nInspiration <= 0 then
		widget.setVisible(false);
		textwidget.setVisible(false);
	elseif nInspiration == 1 then
		widget.setVisible(true);
		textwidget.setVisible(false);
	else
		widget.setVisible(true);
		textwidget.setVisible(true);
		textwidget.setText(nInspiration);
	end
end
