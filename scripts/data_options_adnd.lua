-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerOptions();
	
  if (getRulesetName() == "2E") then
    OptionsManager.addOptionValue("DDCL", "option_val_DDCL_adnd1", "desktopdecal_adnd1", true);
    OptionsManager.addOptionValue("DDCL", "option_val_DDCL_adnd2", "desktopdecal_adnd2", true);
    OptionsManager.addOptionValue("DDCL", "option_val_DDCL_adnd3", "desktopdecal_adnd3", true);
    OptionsManager.addOptionValue("DDCL", "option_val_DDCL_adnd4", "desktopdecal_adnd4", true);
    OptionsManager.setOptionDefault("DDCL", "desktopdecal_adnd2");
  end
end

-- return ruleset name
function getRulesetName()
  local sRulesetName = User.getRulesetName();
  return sRulesetName;
end

function registerOptions()
	OptionsManager.registerOption2("TNPCE", false, "option_header_token", "option_label_TNPCE", "option_entry_cycler", 
			{ labels = "option_val_tooltip|option_val_icons|option_val_iconshover|option_val_mark|option_val_markhover", values = "tooltip|on|hover|mark|markhover", baselabel = "option_val_off", baseval = "off", default = "on" });
	OptionsManager.registerOption2("TNPCH", false, "option_header_token", "option_label_TNPCH", "option_entry_cycler", 
			{ labels = "option_val_tooltip|option_val_bar|option_val_barhover|option_val_dot|option_val_dothover", values = "tooltip|bar|barhover|dot|dothover", baselabel = "option_val_off", baseval = "off", default = "dot" });

    -- show npc effects to DM
  OptionsManager.registerOption2("DM_SHOW_NPC_EFFECTS", false, "option_header_token", "option_label_DM_SHOW_NPC_EFFECTS", "option_entry_cycler", 
			{ labels = "option_val_tooltip|option_val_icons|option_val_iconshover|option_val_mark|option_val_markhover", values = "tooltip|on|hover|mark|markhover", baselabel = "option_val_off", baseval = "off", default = "on" });
    -- show npc health bars to DM
  OptionsManager.registerOption2("DM_SHOW_NPC_HEALTHBAR", false, "option_header_token", "option_label_DM_SHOW_NPC_HEALTHBAR", "option_entry_cycler", 
			{ labels = "option_val_tooltip|option_val_bar|option_val_barhover|option_val_dot|option_val_dothover", values = "tooltip|bar|barhover|dot|dothover", baselabel = "option_val_off", baseval = "off", default = "dot" });

  OptionsManager.registerOption2("TPCE", false, "option_header_token", "option_label_TPCE", "option_entry_cycler", 
			{ labels = "option_val_tooltip|option_val_icons|option_val_iconshover|option_val_mark|option_val_markhover", values = "tooltip|on|hover|mark|markhover", baselabel = "option_val_off", baseval = "off", default = "on" });
	OptionsManager.registerOption2("TPCH", false, "option_header_token", "option_label_TPCH", "option_entry_cycler", 
			{ labels = "option_val_tooltip|option_val_bar|option_val_barhover|option_val_dot|option_val_dothover", values = "tooltip|bar|barhover|dot|dothover", baselabel = "option_val_off", baseval = "off", default = "dot" });

	OptionsManager.registerOption2("TNAM", false, "option_header_token", "option_label_TNAM", "option_entry_cycler", 
			{ labels = "option_val_tooltip|option_val_title|option_val_titlehover", values = "tooltip|on|hover", baselabel = "option_val_off", baseval = "off", default = "tooltip" });
            
	OptionsManager.registerOption2("HRNH", false, "option_header_houserule", "option_label_HRNH", "option_entry_cycler", 
			{ labels = "option_val_max|option_val_random|option_val_80plus", values = "max|random|80plus", baselabel = "option_val_off", baseval = "off", default = "random" });
  OptionsManager.registerOption2("HouseRule_InitEachRound", false, "option_header_houserule", "option_label_HOUSE_RULE_INIT_EACH_ROUND", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
  OptionsManager.registerOption2("HouseRule_Encumbrance_Coins", false, "option_header_houserule", "option_label_HREC", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
  OptionsManager.registerOption2("HouseRule_CRIT_TYPE", false, "option_header_houserule", "option_label_HR_CRIT", "option_entry_cycler", 
			{ labels = "option_val_hr_crit_maxdmg|option_val_hr_crit_timestwo|option_val_hr_crit_none", values = "max|timestwo|none", baselabel = "option_val_hr_crit_doubledice", baseval = "doubledice", default = "doubledice" });
  OptionsManager.registerOption2("HouseRule_ASCENDING_AC", false, "option_header_houserule", "option_label_HR_ASENDING_AC", "option_entry_cycler", 
      { labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
end
