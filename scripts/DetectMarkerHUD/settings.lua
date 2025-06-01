local storage = require('openmw.storage')
local util = require('openmw.util')
local Settings = require('openmw.interfaces').Settings

Settings.registerPage {
	key = 'DetectMarkerHUDPage',
	l10n = 'DetectMarkerHUD',
	name = 'Detect Marker HUD',
	description = 'DetectMarkerHUDDescription',
}

Settings.registerGroup {
	key = 'SettingsDetectMarkerHUDDisplay',
	page = 'DetectMarkerHUDPage',
	l10n = 'DetectMarkerHUD',
	name = 'DisplaySettings',
	description = 'DisplaySettingsDesc',
	permanentStorage = true,
	settings = {
		{
			key = 'Margin',
			renderer = 'number',
			argument = {
				integer = true,
				min = 0,
			},
			name = 'Margin',
			description = 'MarginDesc',
			default = 16,
		},
		{
			key = 'IconSize',
			renderer = 'number',
			argument = {
				integer = true,
				min = 1,
			},
			name = 'MarkerIconSize',
			default = 32,
		},
		{
			key = 'UseGenericIcon',
			renderer = 'checkbox',
			name = 'UseGenericIcon',
			default = false,
		},
		{
			key = 'KeyMarkerColor',
			renderer = 'color',
			name = 'KeyMarkerColor',
			default = util.color.rgb(0.36, 0.79, 0.43),
		},
		{
			key = 'EnchantmentMarkerColor',
			renderer = 'color',
			name = 'EnchantmentMarkerColor',
			default = util.color.rgb(0.32, 0.59, 0.85),
		},
		{
			key = 'AnimalMarkerColor',
			renderer = 'color',
			name = 'AnimalMarkerColor',
			default = util.color.rgb(0.92, 0.41, 0.37),
		},
		{
			key = 'NPCHeightOffset',
			renderer = 'number',
			argument = {
				min = 0,
				max = 256,
			},
			name = 'NPCHeightOffset',
			description = 'NPCHeightOffsetDesc',
			default = '96',
		},
	},
}

Settings.registerGroup {
	key = 'SettingsDetectMarkerHUDPerfomance',
	page = 'DetectMarkerHUDPage',
	l10n = 'DetectMarkerHUD',
	name = 'PerformanceSettings',
	description = 'PerformanceSettingsDesc',
	permanentStorage = true,
	settings = {
		{
			key = 'MaxObjectTest',
			renderer = 'number',
			argument = {
				integer = true,
				min = 10,
			},
			name = 'MaxObjectTest',
			description = 'MaxObjectTestDesc',
			default = 100,
		},
	},
}

return {
	display = storage.playerSection('SettingsDetectMarkerHUDDisplay'),
	performance = storage.playerSection('SettingsDetectMarkerHUDPerfomance'),
}
