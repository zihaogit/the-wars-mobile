extends RefCounted

const PLAYER_COLOR := Color("#63d6cb")
const AI_COLOR := Color("#e68168")
const GOLD_COLOR := Color("#f1cb78")
const UI_PANEL := Color("#172027")
const UI_CARD := Color("#202a30")
const KING_HEALTH_MAX := 500
const UNIT_LIMIT := 12

var game: Variant
var player_king_health_bar: ProgressBar
var ai_king_health_bar: ProgressBar
var player_gold_label: Label
var ai_gold_label: Label
var wave_label: Label
var wave_message: Label
var selected_hero_name: Label
var selected_hero_role: Label
var selected_hero_title: Label
var selected_hero_description: Label
var selected_hero_ability: Label
var selected_hero_stats: Label
var selected_hero_portrait: TextureRect
var hero_portraits: Dictionary = {}
var result_title: Label
var result_details: Label
var build_buttons: Dictionary = {}
var build_status_labels: Dictionary = {}
var build_portraits: Dictionary = {}
var building_buttons: Dictionary = {}
var lane_radar: Control
var result_overlay: ColorRect


func _init(match: Variant) -> void:
	game = match
	hero_portraits = game.hero_portraits


func build() -> void:
	var hud := CanvasLayer.new()
	hud.name = "BattleHUD"
	game.add_child(hud)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	hud.add_child(root)

	var top := _panel(root, Rect2(0.018, 0.018, 0.964, 0.09), UI_PANEL)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 18)
	top.add_child(top_row)

	var player_status := VBoxContainer.new()
	player_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_status.add_theme_constant_override("separation", 2)
	top_row.add_child(player_status)
	_new_label(player_status, "YOUR KING", 14, PLAYER_COLOR)
	player_king_health_bar = _new_health_bar(player_status, PLAYER_COLOR, KING_HEALTH_MAX)

	var center_status := VBoxContainer.new()
	center_status.custom_minimum_size.x = 280.0
	center_status.alignment = BoxContainer.ALIGNMENT_CENTER
	center_status.add_theme_constant_override("separation", 1)
	top_row.add_child(center_status)
	wave_label = _new_label(center_status, "ROUND 01   /   NEXT IN 08", 16, Color("#f0eadc"))
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_gold_label = _new_label(center_status, "GOLD 100   WOOD 060   FOOD 00/08", 13, GOLD_COLOR)
	player_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ai_gold_label = _new_label(center_status, "RIVAL GOLD   100", 11, AI_COLOR)
	ai_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var resource_divider := ColorRect.new()
	resource_divider.custom_minimum_size = Vector2(2.0, 42.0)
	resource_divider.color = Color("#685b3c")
	top_row.add_child(resource_divider)

	var rival_status := VBoxContainer.new()
	rival_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rival_status.add_theme_constant_override("separation", 2)
	top_row.add_child(rival_status)
	var rival_title := _new_label(rival_status, "RIVAL KING", 14, AI_COLOR)
	rival_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ai_king_health_bar = _new_health_bar(rival_status, AI_COLOR, KING_HEALTH_MAX)
	ai_king_health_bar.fill_mode = ProgressBar.FILL_END_TO_BEGIN

	var command_deck := _panel(root, Rect2(0.018, 0.71, 0.964, 0.275), UI_PANEL)
	var command_row := HBoxContainer.new()
	command_row.add_theme_constant_override("separation", 8)
	command_deck.add_child(command_row)

	var map_panel := PanelContainer.new()
	map_panel.custom_minimum_size.x = 170.0
	map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_panel.add_theme_stylebox_override("panel", _style(UI_CARD, false))
	command_row.add_child(map_panel)
	var map_content := VBoxContainer.new()
	map_content.add_theme_constant_override("separation", 2)
	map_panel.add_child(map_content)
	_new_label(map_content, "BATTLE MAP", 12, GOLD_COLOR)
	lane_radar = game._make_lane_radar()
	lane_radar.name = "KingLaneMap"
	lane_radar.custom_minimum_size = Vector2(160.0, 76.0)
	lane_radar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lane_radar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_content.add_child(lane_radar)

	var portrait_panel := PanelContainer.new()
	portrait_panel.custom_minimum_size.x = 174.0
	portrait_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait_panel.add_theme_stylebox_override("panel", _style(Color("#121a20"), true, GOLD_COLOR))
	command_row.add_child(portrait_panel)
	selected_hero_portrait = TextureRect.new()
	selected_hero_portrait.name = "SelectedHeroPortrait"
	selected_hero_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	selected_hero_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	selected_hero_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	selected_hero_portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selected_hero_portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	selected_hero_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_panel.add_child(selected_hero_portrait)

	var profile_panel := PanelContainer.new()
	profile_panel.custom_minimum_size.x = 248.0
	profile_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	profile_panel.add_theme_stylebox_override("panel", _style(UI_CARD, false))
	command_row.add_child(profile_panel)
	var profile := VBoxContainer.new()
	profile.add_theme_constant_override("separation", 1)
	profile_panel.add_child(profile)
	_new_label(profile, "SELECTED HERO", 12, GOLD_COLOR)
	selected_hero_name = _new_label(profile, "HERO NAME", 18, Color("#f0eadc"))
	selected_hero_title = _new_label(profile, "HERO TITLE", 12, PLAYER_COLOR)
	selected_hero_role = _new_label(profile, "HERO ROLE", 12, Color("#c1cbc6"))
	selected_hero_description = _new_label(profile, "Hero description.", 12, Color("#dce4df"))
	selected_hero_description.visible = false
	selected_hero_ability = _new_label(profile, "ABILITY", 12, GOLD_COLOR)
	selected_hero_stats = _new_label(profile, "STATS", 12, Color("#f0eadc"))

	var roster_panel := PanelContainer.new()
	roster_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roster_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	roster_panel.add_theme_stylebox_override("panel", _style(UI_CARD, false))
	command_row.add_child(roster_panel)
	var roster_layout := VBoxContainer.new()
	roster_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	roster_layout.add_theme_constant_override("separation", 3)
	roster_panel.add_child(roster_layout)
	var build_header := HBoxContainer.new()
	roster_layout.add_child(build_header)
	var build_title := _new_label(build_header, "COMMAND GRID  /  RECRUIT NEXT WAVE", 15, PLAYER_COLOR)
	build_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var build_note := _new_label(build_header, "BUY UNITS WITH GOLD", 12, Color("#c1cbc6"))
	build_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	var card_row := HBoxContainer.new()
	card_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_row.add_theme_constant_override("separation", 6)
	roster_layout.add_child(card_row)
	for hero_id in game.HERO_ORDER:
		_add_hero_card(card_row, hero_id)

	var construction_row := HBoxContainer.new()
	construction_row.custom_minimum_size.y = 38.0
	construction_row.add_theme_constant_override("separation", 6)
	roster_layout.add_child(construction_row)
	_add_building_command_button(construction_row, "tower", "SPIRE")
	_add_building_command_button(construction_row, "lumber", "TIMBER CAMP")
	_add_building_command_button(construction_row, "farm", "FARM")
	var upgrade_button := Button.new()
	upgrade_button.name = "UpgradeBuildingButton"
	upgrade_button.custom_minimum_size.y = 38.0
	upgrade_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrade_button.add_theme_font_size_override("font_size", 11)
	upgrade_button.pressed.connect(game._upgrade_selected_building)
	construction_row.add_child(upgrade_button)
	building_buttons["upgrade"] = upgrade_button

	wave_message = _new_label(root, "TAP A UNIT TO SELECT, THEN TAP THE MAP TO MOVE", 13, Color("#e4e6dc"))
	wave_message.anchor_left = 0.12
	wave_message.anchor_right = 0.88
	wave_message.anchor_top = 0.675
	wave_message.anchor_bottom = 0.71
	wave_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_build_result_overlay(root)
	_sync_game_references()
	update_build_bay()
	update_building_controls()


func _sync_game_references() -> void:
	var references := {
		"player_king_health_bar": player_king_health_bar,
		"ai_king_health_bar": ai_king_health_bar,
		"player_gold_label": player_gold_label,
		"ai_gold_label": ai_gold_label,
		"wave_label": wave_label,
		"wave_message": wave_message,
		"selected_hero_name": selected_hero_name,
		"selected_hero_role": selected_hero_role,
		"selected_hero_title": selected_hero_title,
		"selected_hero_description": selected_hero_description,
		"selected_hero_ability": selected_hero_ability,
		"selected_hero_stats": selected_hero_stats,
		"selected_hero_portrait": selected_hero_portrait,
		"hero_portraits": hero_portraits,
		"result_title": result_title,
		"result_details": result_details,
		"build_buttons": build_buttons,
		"build_status_labels": build_status_labels,
		"build_portraits": build_portraits,
		"building_buttons": building_buttons,
		"lane_radar": lane_radar,
		"result_overlay": result_overlay
	}
	for property_name in references:
		game.set(property_name, references[property_name])


func _add_building_command_button(parent: Node, building_id: String, short_name: String) -> void:
	var definition: Dictionary = game._get_building_definition(building_id)
	var button := Button.new()
	button.name = "%sBuildCommand" % building_id.capitalize()
	button.custom_minimum_size.y = 38.0
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_stylebox_override("normal", _style(UI_CARD, false))
	button.add_theme_stylebox_override("hover", _style(Color("#26383b"), true))
	button.add_theme_stylebox_override("pressed", _style(Color("#324341"), true))
	button.pressed.connect(game._begin_build.bind(building_id))
	parent.add_child(button)
	building_buttons[building_id] = button
	button.set_meta("short_name", short_name)
	button.set_meta("gold_cost", int(definition.gold))
	button.set_meta("wood_cost", int(definition.wood))


func update_building_controls() -> void:
	if not building_buttons.has("upgrade"):
		return
	var has_open_site := false
	for site in game.building_sites:
		if bool(site.is_player) and String(site.building).is_empty():
			has_open_site = true
			break

	for building_id in ["tower", "lumber", "farm"]:
		var button: Button = building_buttons[building_id]
		var gold_cost: int = int(button.get_meta("gold_cost"))
		var wood_cost: int = int(button.get_meta("wood_cost"))
		button.text = "%s  %dG/%dW" % [
			String(button.get_meta("short_name")),
			gold_cost,
			wood_cost
		]
		button.disabled = (
			game.game_over
			or not has_open_site
			or game.player_gold < gold_cost
			or game.player_wood < wood_cost
		)
		button.add_theme_stylebox_override(
			"normal",
			_style(
				Color("#29363a") if game.selected_build_mode == building_id else UI_CARD,
				true,
				GOLD_COLOR if game.selected_build_mode == building_id else PLAYER_COLOR
			)
		)

	var upgrade_button: Button = building_buttons["upgrade"]
	if game.selected_building_site >= 0 and game.selected_building_site < game.building_sites.size():
		var site: Dictionary = game.building_sites[game.selected_building_site]
		var definition: Dictionary = game._get_building_definition(String(site.building))
		if not definition.is_empty() and bool(site.is_player):
			var level: int = int(site.level)
			if level >= int(definition.max_level):
				upgrade_button.text = "%s  MAX LEVEL" % definition.name.to_upper()
				upgrade_button.disabled = true
			else:
				var gold_cost: int = int(definition.upgrade_gold)
				var wood_cost: int = int(definition.upgrade_wood)
				upgrade_button.text = "UPGRADE %s  %dG/%dW" % [
					definition.name.to_upper(),
					gold_cost,
					wood_cost
				]
				upgrade_button.disabled = (
					game.game_over or game.player_gold < gold_cost or game.player_wood < wood_cost
				)
			return
	upgrade_button.text = "SELECT A BUILDING TO UPGRADE"
	upgrade_button.disabled = true


func _add_hero_card(parent: Node, hero_id: String) -> void:
	var data: Dictionary = game.HEROES[hero_id]
	var button := Button.new()
	button.name = "%sBuildButton" % hero_id
	button.custom_minimum_size = Vector2(0.0, 0.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_stylebox_override("normal", _style(UI_CARD, false))
	button.add_theme_stylebox_override("hover", _style(Color("#26383b"), true))
	button.add_theme_stylebox_override("pressed", _style(Color("#324341"), true))
	button.add_theme_stylebox_override("focus", _style(Color("#26383b"), true))
	button.pressed.connect(game._queue_hero.bind(hero_id))
	build_buttons[hero_id] = button
	parent.add_child(button)

	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 6.0
	content.offset_top = 3.0
	content.offset_right = -6.0
	content.offset_bottom = -3.0
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 2)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	button.add_child(content)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(96.0, 68.0)
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	portrait.texture = game.hero_portraits[hero_id]
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(portrait)
	build_portraits[hero_id] = portrait

	var name_label := _new_label(content, data.name, 14, Color("#f0eadc"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	var role_label := _new_label(content, data.role, 12, Color("#b9c3c0"))
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_label.clip_text = true
	var stats_label := _new_label(content, "%d HP   /   %d ATK" % [data.health, data.damage], 11, Color("#dce4df"))
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var order_label := _new_label(content, "RECRUIT  /  %d GOLD" % data.cost, 12, GOLD_COLOR)
	order_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	order_label.name = "BuildOrderStatus"
	build_status_labels[hero_id] = order_label


func update_build_bay() -> void:
	for hero_id in build_buttons:
		var button: Button = build_buttons[hero_id]
		var selected: bool = hero_id == game.selected_player_hero
		var queued_count: int = game.player_build_queue.count(hero_id)
		var can_build: bool = (
			not game.game_over
			and game.player_gold >= int(game.HEROES[hero_id].cost)
			and game.player_food_used < game._player_food_capacity()
			and game.player_army.size() + game.player_build_queue.size() < UNIT_LIMIT
		)
		var accent: Color = GOLD_COLOR if selected else Color("#59666a")
		button.add_theme_stylebox_override(
			"normal",
			_style(Color("#29363a") if selected else UI_CARD, true, accent)
		)
		button.disabled = not can_build
		button.modulate = Color.WHITE if can_build else Color("#78817f")
		var status: Label = build_status_labels[hero_id]
		status.text = (
			"QUEUED  x%d" % queued_count
			if queued_count > 0
			else "RECRUIT  /  %d GOLD  1 FOOD" % game.HEROES[hero_id].cost
		)
		status.add_theme_color_override(
			"font_color",
			GOLD_COLOR if queued_count > 0 else Color("#d0b779")
		)

	var selected_data: Dictionary = game.HEROES[game.selected_player_hero]
	selected_hero_name.text = selected_data.name
	selected_hero_title.text = selected_data.title
	selected_hero_role.text = selected_data.role
	selected_hero_description.text = selected_data.description
	selected_hero_role.tooltip_text = selected_data.description
	selected_hero_ability.text = "ABILITY  /  %s" % selected_data.ability.get_slice(":", 0)
	selected_hero_ability.tooltip_text = selected_data.ability
	selected_hero_stats.text = "%d HP  |  %d ATK  |  RANGE %.1f\nSPEED %.1f  |  %d GOLD" % [
		selected_data.health,
		selected_data.damage,
		selected_data.range,
		selected_data.speed,
		selected_data.cost
	]
	selected_hero_portrait.texture = game.hero_portraits[game.selected_player_hero]
	player_gold_label.text = "YOUR GOLD   %03d" % game.player_gold
	ai_gold_label.text = "RIVAL GOLD   %03d" % game.ai_gold


func _build_result_overlay(root: Control) -> void:
	result_overlay = ColorRect.new()
	result_overlay.name = "MatchResultOverlay"
	result_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_overlay.color = Color("#cc0b1115")
	result_overlay.visible = false
	root.add_child(result_overlay)

	var panel := PanelContainer.new()
	panel.name = "ResultPanel"
	panel.anchor_left = 0.28
	panel.anchor_right = 0.72
	panel.anchor_top = 0.35
	panel.anchor_bottom = 0.65
	panel.add_theme_stylebox_override("panel", _style(Color("#f01c292d"), false))
	result_overlay.add_child(panel)

	var content := VBoxContainer.new()
	content.name = "ResultContent"
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)
	result_title = _new_label(content, "KING DEFEATED", 26, Color("#f0eadc"))
	result_title.name = "ResultTitle"
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_details = _new_label(content, "The battle is over.", 15, Color("#d1dad3"))
	result_details.name = "ResultDetails"
	result_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var restart := Button.new()
	restart.text = "PLAY AGAIN"
	restart.custom_minimum_size = Vector2(180.0, 44.0)
	restart.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	restart.pressed.connect(game._restart_match)
	content.add_child(restart)


func _panel(parent: Control, rect: Rect2, color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = rect.position.x
	panel.anchor_top = rect.position.y
	panel.anchor_right = rect.end.x
	panel.anchor_bottom = rect.end.y
	panel.add_theme_stylebox_override("panel", _style(color, false))
	parent.add_child(panel)
	return panel


func _new_label(parent: Node, text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _new_health_bar(parent: Node, color: Color, maximum: int) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(190.0, 12.0)
	bar.min_value = 0
	bar.max_value = maximum
	bar.value = maximum
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _flat_style(Color("#29363a")))
	bar.add_theme_stylebox_override("fill", _flat_style(color))
	parent.add_child(bar)
	return bar


func _style(
	color: Color,
	outlined: bool = true,
	outline_color: Color = PLAYER_COLOR
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = outline_color if outlined else Color("#53605f")
	style.set_border_width_all(2 if outlined else 1)
	style.set_corner_radius_all(5)
	style.shadow_color = Color("#a0000000")
	style.shadow_size = 3
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style


func _flat_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(3)
	return style
