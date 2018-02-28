---
--
-- Replace some of the CoreRPG functions to add new functionality
--
---
OOB_MSGTYPE_WHISPER = "whisper";
OOB_MSGTYPE_WHISPER_DING = "whisperding";

function onInit()
  -- use custom whisper function that triggers DING options
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_WHISPER, handleWhisperCustom);
  -- send DING request to OOB
  OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_WHISPER_DING, handleWhisperDING);
  
  -- option in option_header_client section, enable/disable to receive DING on private message received
	OptionsManager.registerOption2("ADND_PM_DING", false, "option_header_client", "option_label_ADND_PM_DING", "option_entry_cycler", 
			{ labels = "option_label_ADND_PM_DING_enabled" , values = "enabled", baselabel = "option_label_ADND_PM_DING_disabled", baseval = "disabled", default = "disabled" });    

end

-- notify oob to deal with this
function notifyWhisperDING(sUser)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_WHISPER_DING;
  msgOOB.user_name = sUser;
	Comm.deliverOOBMessage(msgOOB, "");
end
-- oob takes control and DING
function handleWhisperDING(msgOOB)
  local sUser = msgOOB.user_name;
  if sUser ~= nil then
    User.ringBell(sUser);
  else
    -- nil user == Host/GM
    User.ringBell();
  end
end

-- custom handleWhisper to use DING on PM received
function handleWhisperCustom(msgOOB)
	-- Validate
	if not msgOOB.sender or not msgOOB.receiver or not msgOOB.text then
		return;
	end

	-- Check to see if GM has asked to see whispers
	if User.isHost() then
		if msgOOB.sender == "" then
			return;
		end
		if msgOOB.receiver ~= "" and OptionsManager.isOption("SHPW", "off") then
			return;
		end
		
	-- Ignore messages not targeted to this user
	else
		if msgOOB.receiver == "" then
			return;
		end
		if not User.isOwnedIdentity(msgOOB.receiver) then
			return;
		end
	end
	
	-- Get the send and receiver labels
	local sSender, sReceiver;
	if msgOOB.sender == "" then
		sSender = "GM";
	else
		sSender = User.getIdentityLabel(msgOOB.sender) or "<unknown>";
	end
	if msgOOB.receiver == "" then
		sReceiver = "GM";
	else
		sReceiver = User.getIdentityLabel(msgOOB.receiver) or "<unknown>";
	end

	-- Remember last whisperer
	if not User.isHost() or msgOOB.receiver == "" then
		sLastWhisperer = sSender;
	end
	
	-- Build the message to display
	local msg = { font = "whisperfont", text = "", mode = "whisper", icon = { "indicator_whisper" } };
	msg.sender = sSender;
	if OptionsManager.isOption("PCHT", "on") then
		if msgOOB.sender == "" then
			table.insert(msg.icon, "portrait_gm_token");
		else
			table.insert(msg.icon, "portrait_" .. msgOOB.sender .. "_chat");
		end
	end
	if User.isHost() then
		if msgOOB.receiver ~= "" then
			msg.sender = msg.sender .. " -> " .. sReceiver;
		end
	else
		if #(User.getOwnedIdentities()) > 1 then
			msg.sender = msg.sender .. " -> " .. sReceiver;
		end
	end
	msg.text = msg.text .. msgOOB.text;
	
  -- set sUser to the owner 
  local sUser = User.getIdentityOwner(msgOOB.receiver);
  -- check options settings
  local bRingOnReceive = OptionsManager.isOption("ADND_PM_DING", "enabled");
  -- ding bell if option on
  if bRingOnReceive then
    notifyWhisperDING(sUser);
  end
  
	-- Show whisper message
	Comm.addChatMessage(msg);
end
