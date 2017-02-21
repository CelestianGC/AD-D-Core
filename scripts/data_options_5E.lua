-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerOptions();
end

function registerOptions()
	OptionsManager.registerOption2("RMMT", true, "option_header_client", "option_label_RMMT", "option_entry_cycler", 
			{ labels = "option_val_on|option_val_multi", values = "on|multi", baselabel = "option_val_off", baseval = "off", default = "multi" });

	OptionsManager.registerOption2("SHRR", false, "option_header_game", "option_label_SHRR", "option_entry_cycler", 
			{ labels = "option_val_on|option_val_friendly", values = "on|pc", baselabel = "option_val_off", baseval = "off", default = "on" });
	OptionsManager.registerOption2("PSMN", false, "option_header_game", "option_label_PSMN", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });

	OptionsManager.registerOption2("INIT", false, "option_header_combat", "option_label_INIT", "option_entry_cycler", 
			{ labels = "option_val_on|option_val_group", values = "on|group", baselabel = "option_val_off", baseval = "off", default = "group" });
	OptionsManager.registerOption2("NPCD", false, "option_header_combat", "option_label_NPCD", "option_entry_cycler", 
			{ labels = "option_val_fixed", values = "fixed", baselabel = "option_val_variable", baseval = "off", default = "off" });
	OptionsManager.registerOption2("BARC", false, "option_header_combat", "option_label_BARC", "option_entry_cycler", 
			{ labels = "option_val_tiered", values = "tiered", baselabel = "option_val_standard", baseval = "", default = "" });
	OptionsManager.registerOption2("SHPC", false, "option_header_combat", "option_label_SHPC", "option_entry_cycler", 
			{ labels = "option_val_detailed|option_val_status", values = "detailed|status", baselabel = "option_val_off", baseval = "off", default = "detailed" });
	OptionsManager.registerOption2("SHNPC", false, "option_header_combat", "option_label_SHNPC", "option_entry_cycler", 
			{ labels = "option_val_detailed|option_val_status", values = "detailed|status", baselabel = "option_val_off", baseval = "off", default = "status" });
	OptionsManager.registerOption2("WNDC", false, "option_header_combat", "option_label_WNDC", "option_entry_cycler", 
			{ labels = "option_val_detailed", values = "detailed", baselabel = "option_val_simple", baseval = "off", default = "off" });

	OptionsManager.registerOption2("TNPCE", false, "option_header_token", "option_label_TNPCE", "option_entry_cycler", 
			{ labels = "option_val_tooltip|option_val_icons|option_val_iconshover|option_val_mark|option_val_markhover", values = "tooltip|on|hover|mark|markhover", baselabel = "option_val_off", baseval = "off", default = "on" });
	OptionsManager.registerOption2("TNPCH", false, "option_header_token", "option_label_TNPCH", "option_entry_cycler", 
			{ labels = "option_val_tooltip|option_val_bar|option_val_barhover|option_val_dot|option_val_dothover", values = "tooltip|bar|barhover|dot|dothover", baselabel = "option_val_off", baseval = "off", default = "dot" });
	OptionsManager.registerOption2("TPCE", false, "option_header_token", "option_label_TPCE", "option_entry_cycler", 
			{ labels = "option_val_tooltip|option_val_icons|option_val_iconshover|option_val_mark|option_val_markhover", values = "tooltip|on|hover|mark|markhover", baselabel = "option_val_off", baseval = "off", default = "on" });
	OptionsManager.registerOption2("TPCH", false, "option_header_token", "option_label_TPCH", "option_entry_cycler", 
			{ labels = "option_val_tooltip|option_val_bar|option_val_barhover|option_val_dot|option_val_dothover", values = "tooltip|bar|barhover|dot|dothover", baselabel = "option_val_off", baseval = "off", default = "dot" });

	OptionsManager.registerOption2("HRST", false, "option_header_houserule", "option_label_HRST", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "on" });
	OptionsManager.registerOption2("HRNH", false, "option_header_houserule", "option_label_HRNH", "option_entry_cycler", 
			{ labels = "option_val_max|option_val_random", values = "max|random", baselabel = "option_val_standard", baseval = "off", default = "off" });
	OptionsManager.registerOption2("HRFC", false, "option_header_houserule", "option_label_HRFC", "option_entry_cycler", 
			{ labels = "option_val_fumbleandcrit|option_val_fumble|option_val_crit", values = "both|fumble|criticalhit", baselabel = "option_val_off", baseval = "", default = "" });
	OptionsManager.registerOption2("HREN", false, "option_header_houserule", "option_label_HREN", "option_entry_cycler", 
			{ labels = "option_val_variant", values = "variant", baselabel = "option_val_standard", baseval = "", default = "" });
	OptionsManager.registerOption2("HRHV", false, "option_header_houserule", "option_label_HRHV", "option_entry_cycler", 
			{ labels = "option_val_HRHV_fast|option_val_HRHV_slow", values = "fast|slow", baselabel = "option_val_standard", baseval = "", default = "" });
	OptionsManager.registerOption2("HRIS", false, "option_header_houserule", "option_label_HRIS", "option_entry_cycler", 
			{ labelsraw = "2|3", values = "2|3", baselabel = "option_val_standard", baseval = "", default = "" });
	OptionsManager.registerOption2("HRDD", false, "option_header_houserule", "option_label_HRDD", "option_entry_cycler", 
			{ labels = "option_val_variant", values = "variant", baselabel = "option_val_standard", baseval = "", default = "" });
end
