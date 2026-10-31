extends Node3D

const ArenaViewScript = preload("res://scripts/arena_view.gd")
const BattleHudScript = preload("res://scripts/battle_hud.gd")

class KingLaneRadar extends Control:
	var player_x := -12.0
	var ai_x := 12.0
	var player_units: Array[float] = []
	var ai_units: Array[float] = []


	func _draw() -> void:
		var left := 12.0
		var right := size.x - 12.0
		var middle := size.y * 0.5
		draw_rect(Rect2(left, middle - 15.0, right - left, 30.0), Color("#172127"))
		draw_line(Vector2(left, middle), Vector2(right, middle), Color("#82908e"), 3.0)
		draw_circle(Vector2(left, middle), 6.0, Color("#63d6cb"))
		draw_circle(Vector2(right, middle), 6.0, Color("#e68168"))
		draw_circle(Vector2(_map_x(player_x), middle), 5.0, Color("#f2eee0"))
		draw_circle(Vector2(_map_x(ai_x), middle), 5.0, Color("#f2eee0"))
		for unit_x in player_units:
			draw_circle(Vector2(_map_x(unit_x), middle - 7.0), 3.2, Color("#6ed9ce"))
		for unit_x in ai_units:
			draw_circle(Vector2(_map_x(unit_x), middle + 7.0), 3.2, Color("#e68669"))


	func _map_x(world_x: float) -> float:
		return lerpf(12.0, size.x - 12.0, clampf((world_x + 17.0) / 34.0, 0.0, 1.0))


const KING_X := 16.0
const SPAWN_X := 12.7
const LANE_HALF_WIDTH := 2.5
const PLAYER_COLOR := Color("#63d6cb")
const AI_COLOR := Color("#e68168")
const GOLD_COLOR := Color("#f1cb78")
const STONE_DARK := Color("#303b40")
const WAVE_INTERVAL := 12.0
const FIRST_WAVE_DELAY := 8.0
const STARTING_GOLD := 100
const WAVE_INCOME := 75
const UNIT_LIMIT := 12
const AI_BUILDS_PER_WAVE := 2
const KING_HEALTH_MAX := 500
const STARTING_WOOD := 60
const STARTING_FOOD_CAP := 8

var wave_number := 0
var wave_time_left := FIRST_WAVE_DELAY
var player_gold := STARTING_GOLD
var ai_gold := STARTING_GOLD
var player_wood := STARTING_WOOD
var player_food_used := 0
var player_king_health := KING_HEALTH_MAX
var ai_king_health := KING_HEALTH_MAX
var HEROES: Dictionary = {}
var HERO_ORDER: Array[String] = []
var selected_player_hero := ""
var selected_ai_hero := ""
var player_build_queue: Array[String] = []
var ai_build_queue: Array[String] = []
var player_army: Array[Dictionary] = []
var ai_army: Array[Dictionary] = []
var game_over := false
var selected_player_unit: Node3D

var player_king_visual: Node3D
var ai_king_visual: Node3D
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
var lane_radar: KingLaneRadar
var result_overlay: ColorRect
var building_sites: Array[Dictionary] = []
var building_buttons: Dictionary = {}
var selected_building_site := -1
var selected_build_mode := ""
var arena_view: Variant
var battle_hud: Variant


func _ready() -> void:
	if not _load_hero_roster():
		set_process(false)
		return
	arena_view = ArenaViewScript.new(self)
	battle_hud = BattleHudScript.new(self)
	selected_player_hero = HERO_ORDER[0]
	selected_ai_hero = HERO_ORDER[1]
	_build_world()
	_build_construction_sites()
	_build_bases()
	_build_hud()
	_update_hud()


func _load_hero_roster() -> bool:
	var roster_path := "res://heroes/hero_roster.json"
	var file := FileAccess.open(roster_path, FileAccess.READ)
	if file == null:
		push_error("Cannot open hero roster %s: %s" % [roster_path, error_string(FileAccess.get_open_error())])
		return false

	var parser := JSON.new()
	var parse_result := parser.parse(file.get_as_text())
	if parse_result != OK:
		push_error("Cannot parse hero roster %s at line %d: %s" % [
			roster_path,
			parser.get_error_line(),
			parser.get_error_message()
		])
		return false

	var roster_data: Variant = parser.data
	if not roster_data is Dictionary or not roster_data.get("heroes") is Array:
		push_error("Hero roster must contain a heroes array: %s" % roster_path)
		return false

	for entry: Variant in roster_data.heroes:
		if not entry is Dictionary:
			push_error("Hero roster entries must be objects: %s" % roster_path)
			return false
		for field in ["id", "name", "title", "role", "portrait", "description", "ability", "cost", "health", "damage", "speed", "range"]:
			if not entry.has(field):
				push_error("Hero roster entry is missing '%s': %s" % [field, roster_path])
				return false
		var hero_id: String = entry.id
		if hero_id.is_empty() or HEROES.has(hero_id):
			push_error("Hero roster contains an empty or duplicate id '%s': %s" % [hero_id, roster_path])
			return false
		var portrait_path: String = entry.portrait
		var portrait := load(portrait_path) as Texture2D
		if portrait == null:
			push_error("Cannot load hero portrait as a Texture2D: %s" % portrait_path)
			return false
		HEROES[hero_id] = entry
		hero_portraits[hero_id] = portrait
		HERO_ORDER.append(hero_id)

	if HERO_ORDER.is_empty():
		push_error("Hero roster contains no playable heroes: %s" % roster_path)
		return false
	return true


func _process(delta: float) -> void:
	if game_over:
		return

	wave_time_left -= delta
	if wave_time_left <= 0.0:
		_start_wave()

	_update_army(player_army, ai_army, 1.0, delta)
	_update_army(ai_army, player_army, -1.0, delta)
	_update_towers(delta)
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if game_over or not event is InputEventScreenTouch:
		return
	var touch := event as InputEventScreenTouch
	if touch.pressed:
		_handle_battlefield_tap(touch.position)


func _handle_battlefield_tap(screen_position: Vector2) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	var site_index := _find_build_site_at_screen_position(screen_position)
	if not selected_build_mode.is_empty():
		if site_index < 0:
			wave_message.text = "TAP A MARKED BUILD PLOT TO PLACE"
			wave_message.modulate = GOLD_COLOR
			return
		_place_building(site_index, selected_build_mode)
		return

	if site_index >= 0:
		var site: Dictionary = building_sites[site_index]
		if bool(site.is_player) and not String(site.building).is_empty():
			selected_building_site = site_index
			selected_player_unit = null
			_update_selection_ring()
			_update_build_site_selection()
			wave_message.text = "%s  //  TAP UPGRADE IN THE COMMAND GRID" % [
				_get_building_definition(String(site.building)).name
			]
			wave_message.modulate = PLAYER_COLOR
			_update_building_controls()
			return

	var closest_unit: Node3D
	var closest_distance := 56.0
	for unit in player_army:
		var node: Node3D = unit.node
		if not is_instance_valid(node):
			continue
		var unit_screen_position := camera.unproject_position(node.global_position + Vector3.UP)
		var screen_distance := unit_screen_position.distance_to(screen_position)
		if screen_distance < closest_distance:
			closest_distance = screen_distance
			closest_unit = node

	if is_instance_valid(closest_unit):
		selected_player_unit = closest_unit
		selected_building_site = -1
		wave_message.text = "UNIT SELECTED   //   TAP THE MAP TO MOVE"
		wave_message.modulate = PLAYER_COLOR
		_update_selection_ring()
		_update_build_site_selection()
		_update_building_controls()
		return

	if not is_instance_valid(selected_player_unit):
		return

	var ray_origin := camera.project_ray_origin(screen_position)
	var ray_direction := camera.project_ray_normal(screen_position)
	if is_zero_approx(ray_direction.y):
		return
	var ground_distance := -ray_origin.y / ray_direction.y
	if ground_distance < 0.0:
		return
	var target := ray_origin + ray_direction * ground_distance
	target.x = clampf(target.x, -KING_X + 1.0, KING_X - 1.0)
	target.z = clampf(target.z, -8.0, 8.0)

	for index in range(player_army.size()):
		var unit: Dictionary = player_army[index]
		if unit.node != selected_player_unit:
			continue
		unit.manual_target = target
		unit.has_manual_target = true
		player_army[index] = unit
		wave_message.text = "MOVE ORDER   //   TAP YOUR UNIT TO SELECT ANOTHER"
		wave_message.modulate = PLAYER_COLOR
		return


func _find_build_site_at_screen_position(screen_position: Vector2) -> int:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return -1

	var closest_index := -1
	var closest_distance := 76.0
	for index in range(building_sites.size()):
		var site: Dictionary = building_sites[index]
		var node: Node3D = site.node
		var site_screen_position := camera.unproject_position(node.global_position + Vector3.UP * 0.7)
		var screen_distance := site_screen_position.distance_to(screen_position)
		if screen_distance < closest_distance:
			closest_distance = screen_distance
			closest_index = index
	return closest_index


func _get_building_definition(building_id: String) -> Dictionary:
	match building_id:
		"tower":
			return {
				"name": "Sentinel Spire",
				"gold": 55,
				"wood": 20,
				"upgrade_gold": 35,
				"upgrade_wood": 15,
				"max_level": 3
			}
		"lumber":
			return {
				"name": "Timber Camp",
				"gold": 35,
				"wood": 20,
				"upgrade_gold": 25,
				"upgrade_wood": 10,
				"max_level": 3
			}
		"farm":
			return {
				"name": "Harveststead",
				"gold": 30,
				"wood": 25,
				"upgrade_gold": 25,
				"upgrade_wood": 12,
				"max_level": 3
			}
	return {}


func _begin_build(building_id: String) -> void:
	if game_over:
		return
	if selected_build_mode == building_id:
		selected_build_mode = ""
		_update_building_controls()
		wave_message.text = "BUILD ORDER CANCELLED"
		wave_message.modulate = GOLD_COLOR
		return
	var definition := _get_building_definition(building_id)
	if definition.is_empty():
		push_error("Unknown building command: %s" % building_id)
		return
	if player_gold < int(definition.gold) or player_wood < int(definition.wood):
		wave_message.text = "NOT ENOUGH RESOURCES  //  %d GOLD, %d WOOD REQUIRED" % [
			definition.gold,
			definition.wood
		]
		wave_message.modulate = GOLD_COLOR
		return
	var has_open_site := false
	for site in building_sites:
		if bool(site.is_player) and String(site.building).is_empty():
			has_open_site = true
			break
	if not has_open_site:
		wave_message.text = "NO OPEN PLOTS  //  ALL BUILD SITES ARE OCCUPIED"
		wave_message.modulate = GOLD_COLOR
		return
	selected_build_mode = building_id
	selected_building_site = -1
	selected_player_unit = null
	_update_selection_ring()
	_update_build_site_selection()
	_update_building_controls()
	wave_message.text = "PLACE %s  //  TAP AN EMPTY BLUE PLOT" % definition.name.to_upper()
	wave_message.modulate = PLAYER_COLOR


func _place_building(site_index: int, building_id: String) -> bool:
	if site_index < 0 or site_index >= building_sites.size():
		return false
	var site: Dictionary = building_sites[site_index]
	if not bool(site.is_player):
		wave_message.text = "INVALID PLOT  //  BUILD INSIDE YOUR OWN TERRITORY"
		wave_message.modulate = GOLD_COLOR
		return false
	if not String(site.building).is_empty():
		wave_message.text = "INVALID PLOT  //  THIS SITE IS OCCUPIED"
		wave_message.modulate = GOLD_COLOR
		return false
	var definition := _get_building_definition(building_id)
	if definition.is_empty():
		push_error("Unknown building placement: %s" % building_id)
		return false
	if player_gold < int(definition.gold) or player_wood < int(definition.wood):
		selected_build_mode = ""
		wave_message.text = "NOT ENOUGH RESOURCES  //  BUILD CANCELLED"
		wave_message.modulate = GOLD_COLOR
		_update_building_controls()
		return false

	player_gold -= int(definition.gold)
	player_wood -= int(definition.wood)
	site.building = building_id
	site.level = 1
	site.cooldown = 0.0
	site.model = _build_structure_model(building_id, 1, site.node)
	building_sites[site_index] = site
	selected_building_site = site_index
	selected_build_mode = ""
	_update_build_site_selection()
	wave_message.text = "%s BUILT  //  LEVEL 1" % definition.name.to_upper()
	wave_message.modulate = PLAYER_COLOR
	_update_build_bay()
	_update_building_controls()
	_update_hud()
	return true


func _upgrade_selected_building() -> bool:
	if selected_building_site < 0 or selected_building_site >= building_sites.size():
		return false
	var site: Dictionary = building_sites[selected_building_site]
	if not bool(site.is_player) or String(site.building).is_empty():
		return false
	var definition := _get_building_definition(String(site.building))
	if int(site.level) >= int(definition.max_level):
		wave_message.text = "BUILDING AT MAXIMUM LEVEL"
		wave_message.modulate = GOLD_COLOR
		return false
	if player_gold < int(definition.upgrade_gold) or player_wood < int(definition.upgrade_wood):
		wave_message.text = "UPGRADE NEEDS %d GOLD AND %d WOOD" % [
			definition.upgrade_gold,
			definition.upgrade_wood
		]
		wave_message.modulate = GOLD_COLOR
		return false

	player_gold -= int(definition.upgrade_gold)
	player_wood -= int(definition.upgrade_wood)
	site.level = int(site.level) + 1
	var previous_model: Node3D = site.model
	if is_instance_valid(previous_model):
		previous_model.queue_free()
	site.model = _build_structure_model(String(site.building), int(site.level), site.node)
	building_sites[selected_building_site] = site
	wave_message.text = "%s UPGRADED  //  LEVEL %d" % [definition.name.to_upper(), site.level]
	wave_message.modulate = PLAYER_COLOR
	_update_build_bay()
	_update_building_controls()
	_update_hud()
	return true


func _update_towers(delta: float) -> void:
	for index in range(building_sites.size()):
		var site: Dictionary = building_sites[index]
		if not bool(site.is_player) or String(site.building) != "tower":
			continue
		site.cooldown = maxf(0.0, float(site.cooldown) - delta)
		var level: int = int(site.level)
		var tower_position: Vector3 = site.node.global_position
		var target_index := _find_attack_target(ai_army, tower_position, 7.0 + float(level - 1))
		if target_index >= 0 and float(site.cooldown) <= 0.0:
			_damage_unit(ai_army, target_index, 12 + level * 5)
			site.cooldown = 1.0
		building_sites[index] = site


func _update_selection_ring() -> void:
	for unit in player_army:
		var node: Node3D = unit.node
		if not is_instance_valid(node):
			continue
		var ring: MeshInstance3D
		for child: Node in node.get_children():
			ring = child.get_node_or_null("HeroSelectionRing") as MeshInstance3D
			if ring != null:
				break
		if ring != null:
			ring.scale = Vector3.ONE * (1.45 if node == selected_player_unit else 1.0)


func _update_build_site_selection() -> void:
	for index in range(building_sites.size()):
		var site: Dictionary = building_sites[index]
		var node: Node3D = site.node
		var ring := node.get_node_or_null("BuildPlotRing") as MeshInstance3D
		if ring != null:
			ring.scale = Vector3.ONE * (1.28 if index == selected_building_site else 1.0)


func _start_wave() -> void:
	wave_number += 1
	wave_time_left += WAVE_INTERVAL
	var player_orders := player_build_queue.duplicate()
	_plan_ai_build(player_orders)
	var ai_orders := ai_build_queue.duplicate()
	player_build_queue.clear()
	ai_build_queue.clear()

	var player_deployed := 0
	for hero_id in player_orders:
		if _spawn_wave_hero(true, hero_id, true):
			player_deployed += 1
	for hero_id in ai_orders:
		_spawn_wave_hero(false, hero_id, true)

	player_gold += WAVE_INCOME
	ai_gold += WAVE_INCOME
	player_wood += _player_wood_income()
	if player_deployed > 0:
		wave_message.text = "ROUND %02d   //   %d REINFORCEMENT%s DEPLOYED" % [
			wave_number,
			player_deployed,
			"" if player_deployed == 1 else "S"
		]
		wave_message.modulate = PLAYER_COLOR
	else:
		wave_message.text = "ROUND %02d   //   NO REINFORCEMENTS QUEUED" % wave_number
		wave_message.modulate = GOLD_COLOR
	_update_build_bay()
	_update_building_controls()


func _plan_ai_build(player_orders: Array[String]) -> void:
	selected_ai_hero = _choose_ai_hero(player_orders)
	var builds := 0
	while builds < AI_BUILDS_PER_WAVE and ai_army.size() + ai_build_queue.size() < UNIT_LIMIT:
		var cost: int = HEROES[selected_ai_hero].cost
		if ai_gold < cost:
			break
		ai_gold -= cost
		ai_build_queue.append(selected_ai_hero)
		builds += 1


func _choose_ai_hero(player_orders: Array[String]) -> String:
	var player_composition: Dictionary = {}
	for hero_id in player_orders:
		player_composition[hero_id] = int(player_composition.get(hero_id, 0)) + 1
	for unit in player_army:
		var hero_id: String = unit.hero_id
		player_composition[hero_id] = int(player_composition.get(hero_id, 0)) + 1

	var threat_id := selected_player_hero
	var threat_count: int = int(player_composition.get(threat_id, 0))
	for hero_id in HERO_ORDER:
		var count: int = int(player_composition.get(hero_id, 0))
		if count > threat_count:
			threat_id = hero_id
			threat_count = count

	match threat_id:
		"IRI":
			return "ASH"
		"TORREN":
			return "IRI"
		_:
			return "TORREN"


func _queue_hero(hero_id: String) -> bool:
	if game_over or not HEROES.has(hero_id):
		return false
	selected_build_mode = ""
	_update_build_site_selection()
	if player_food_used >= _player_food_capacity():
		wave_message.text = "SUPPLY LIMIT REACHED  //  BUILD A FARM TO EXPAND"
		wave_message.modulate = GOLD_COLOR
		return false
	if player_army.size() + player_build_queue.size() >= UNIT_LIMIT:
		wave_message.text = "LANE FULL   //   WAIT FOR A UNIT TO FALL BEFORE BUILDING"
		wave_message.modulate = GOLD_COLOR
		return false
	var cost: int = HEROES[hero_id].cost
	if player_gold < cost:
		wave_message.text = "NEED %d GOLD   //   %s WAS NOT BUILT" % [
			cost,
			HEROES[hero_id].name
		]
		wave_message.modulate = GOLD_COLOR
		return false

	player_gold -= cost
	player_food_used += 1
	player_build_queue.append(hero_id)
	selected_player_hero = hero_id
	_update_build_bay()
	_update_building_controls()
	wave_message.text = "%s RECRUITED   //   DEPLOYING NEXT ROUND" % HEROES[hero_id].name
	wave_message.modulate = PLAYER_COLOR
	return true


func _spawn_wave_hero(is_player: bool, hero_id: String, prepaid: bool = false) -> bool:
	var army := player_army if is_player else ai_army
	var cost: int = HEROES[hero_id].cost

	if army.size() >= UNIT_LIMIT:
		if is_player and not prepaid:
			wave_message.text = "YOUR LANE IS FULL   //   BUILD QUEUED FOR THE NEXT WAVE"
			wave_message.modulate = GOLD_COLOR
		return false

	if is_player and not prepaid and player_gold < cost:
		wave_message.text = "NEED %d GOLD   //   %s WAS NOT BUILT" % [
			cost,
			HEROES[hero_id].name
		]
		wave_message.modulate = GOLD_COLOR
		return false

	if is_player and not prepaid and player_food_used >= _player_food_capacity():
		wave_message.text = "SUPPLY LIMIT REACHED  //  BUILD A FARM TO EXPAND"
		wave_message.modulate = GOLD_COLOR
		return false

	if is_player and not prepaid:
		player_gold -= cost
		player_food_used += 1

	var data: Dictionary = HEROES[hero_id]
	var lane_offset := float(army.size() % 3 - 1) * 0.46
	var spawn_x := -SPAWN_X if is_player else SPAWN_X
	var unit := _build_wave_hero(hero_id, is_player, Vector3(spawn_x, 0.0, lane_offset))
	army.append({
		"node": unit,
		"hero_id": hero_id,
		"health": data.health,
		"max_health": data.health,
		"damage": data.damage,
		"speed": data.speed,
		"range": data.range,
		"food": 1,
		"cooldown": 0.65,
		"manual_target": Vector3.ZERO,
		"has_manual_target": false
	})
	return true


func _update_army(
	army: Array[Dictionary],
	enemy_army: Array[Dictionary],
	direction: float,
	delta: float
) -> void:
	for index in range(army.size() - 1, -1, -1):
		var unit: Dictionary = army[index]
		var node: Node3D = unit.node
		if not is_instance_valid(node):
			if node == selected_player_unit:
				selected_player_unit = null
			army.remove_at(index)
			continue

		unit.cooldown = maxf(0.0, unit.cooldown - delta)
		var target_index := _find_attack_target(enemy_army, node.position, unit.range)

		if target_index >= 0:
			if unit.cooldown <= 0.0:
				_damage_unit(enemy_army, target_index, unit.damage)
				unit.cooldown = 1.0
		elif _in_king_range(node.position, direction):
			if unit.cooldown <= 0.0:
				_damage_king(direction < 0.0, unit.damage)
				unit.cooldown = 1.0
		elif bool(unit.has_manual_target):
			var manual_target: Vector3 = unit.manual_target
			var to_target := Vector3(manual_target.x - node.position.x, 0.0, manual_target.z - node.position.z)
			if to_target.length() <= 0.1:
				unit.has_manual_target = false
			else:
				node.position += to_target.normalized() * unit.speed * delta
				node.rotation.y = atan2(to_target.x, to_target.z)
		else:
			node.position.x += direction * unit.speed * delta
			node.position.z = move_toward(node.position.z, _lane_z(node.position.x), delta * 1.5)
			node.rotation.y = -PI / 2.0 if direction > 0.0 else PI / 2.0

		army[index] = unit


func _find_attack_target(
	enemy_army: Array[Dictionary],
	position: Vector3,
	attack_range: float
) -> int:
	var closest_index := -1
	var closest_distance := attack_range + 0.35
	for index in range(enemy_army.size()):
		var enemy: Dictionary = enemy_army[index]
		var enemy_node: Node3D = enemy.node
		if not is_instance_valid(enemy_node):
			continue
		var distance := position.distance_to(enemy_node.position)
		if distance < closest_distance:
			closest_distance = distance
			closest_index = index
	return closest_index


func _in_king_range(position: Vector3, direction: float) -> bool:
	var enemy_king_x := -KING_X if direction > 0.0 else KING_X
	return absf(position.x - enemy_king_x) <= 2.2


func _damage_unit(army: Array[Dictionary], index: int, amount: int) -> void:
	if index < 0 or index >= army.size():
		return
	var unit: Dictionary = army[index]
	unit.health -= amount
	if unit.health <= 0:
		var node: Node3D = unit.node
		if is_instance_valid(node):
			node.queue_free()
		if node == selected_player_unit:
			selected_player_unit = null
		if army == player_army:
			player_food_used = maxi(0, player_food_used - int(unit.get("food", 1)))
		army.remove_at(index)
		if army == player_army:
			_update_build_bay()
	else:
		army[index] = unit


func _damage_king(is_player_king: bool, amount: int) -> void:
	if game_over:
		return

	if is_player_king:
		player_king_health = maxi(0, player_king_health - amount)
		if player_king_health == 0:
			_finish_match(false)
	else:
		ai_king_health = maxi(0, ai_king_health - amount)
		if ai_king_health == 0:
			_finish_match(true)


func _finish_match(player_won: bool) -> void:
	game_over = true
	result_overlay.visible = true
	if player_won:
		result_title.text = "ENEMY KING DEFEATED"
		result_title.add_theme_color_override("font_color", PLAYER_COLOR)
		result_details.text = "Your King survived. The lane is yours."
	else:
		result_title.text = "YOUR KING HAS FALLEN"
		result_title.add_theme_color_override("font_color", AI_COLOR)
		result_details.text = "The rival army broke through your base."
	_update_building_controls()


func _restart_match() -> void:
	get_tree().reload_current_scene()


func _update_hud() -> void:
	if not is_instance_valid(player_gold_label):
		return
	player_king_health_bar.value = player_king_health
	ai_king_health_bar.value = ai_king_health
	player_gold_label.text = "GOLD %03d   WOOD %03d   FOOD %02d/%02d" % [
		player_gold,
		player_wood,
		player_food_used,
		_player_food_capacity()
	]
	wave_label.text = "ROUND %02d   /   NEXT IN %02d" % [
		wave_number + 1,
		ceili(maxf(0.0, wave_time_left))
	]

	lane_radar.player_units.clear()
	lane_radar.ai_units.clear()
	for unit in player_army:
		var node: Node3D = unit.node
		if is_instance_valid(node):
			lane_radar.player_units.append(node.position.x)
	for unit in ai_army:
		var node: Node3D = unit.node
		if is_instance_valid(node):
			lane_radar.ai_units.append(node.position.x)
	lane_radar.queue_redraw()


func _player_food_capacity() -> int:
	var capacity := STARTING_FOOD_CAP
	for site in building_sites:
		if bool(site.is_player) and String(site.building) == "farm":
			capacity += int(site.level) * 3
	return capacity


func _player_wood_income() -> int:
	var income := 8
	for site in building_sites:
		if bool(site.is_player) and String(site.building) == "lumber":
			income += int(site.level) * 10
	return income


func _build_world() -> void:
	arena_view.build_world()


func _lane_z(x: float) -> float:
	return sin((x + KING_X) / (KING_X * 2.0) * TAU) * 1.7


func _build_construction_sites() -> void:
	arena_view.build_construction_sites()


func _build_structure_model(building_id: String, level: int, parent: Node3D) -> Node3D:
	return arena_view.build_structure_model(building_id, level, parent)

func _build_bases() -> void:
	arena_view.build_bases()


func _build_wave_hero(hero_id: String, is_player: bool, spawn: Vector3) -> Node3D:
	return arena_view.build_wave_hero(hero_id, is_player, spawn)


func _build_hud() -> void:
	battle_hud.build()


func _update_building_controls() -> void:
	battle_hud.update_building_controls()


func _update_build_bay() -> void:
	battle_hud.update_build_bay()


func _make_lane_radar() -> Control:
	return KingLaneRadar.new()


func _add_box(
	node_name: String,
	size: Vector3,
	position: Vector3,
	color: Color,
	glowing: bool = false,
	parent: Node3D = null
) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add_mesh(node_name, mesh, position, _material(color, glowing), parent)


func _add_cylinder(
	node_name: String,
	radius: float,
	height: float,
	position: Vector3,
	color: Color,
	sides: int = 8,
	parent: Node3D = null
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = sides
	return _add_mesh(node_name, mesh, position, _material(color), parent)


func _add_cone(
	node_name: String,
	radius: float,
	height: float,
	position: Vector3,
	color: Color,
	parent: Node3D = null
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 6
	return _add_mesh(node_name, mesh, position, _material(color, true), parent)


func _add_sphere(
	node_name: String,
	radius: float,
	position: Vector3,
	color: Color,
	glowing: bool = false,
	parent: Node3D = null
) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 24
	mesh.rings = 16
	return _add_mesh(node_name, mesh, position, _material(color, glowing), parent)


func _add_capsule(
	node_name: String,
	radius: float,
	height: float,
	position: Vector3,
	color: Color,
	parent: Node3D = null
) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 20
	mesh.rings = 8
	return _add_mesh(node_name, mesh, position, _material(color), parent)


func _add_torus(
	node_name: String,
	radius: float,
	thickness: float,
	position: Vector3,
	color: Color,
	parent: Node3D = null
) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - thickness
	mesh.outer_radius = radius
	var instance := _add_mesh(node_name, mesh, position, _material(color, true), parent)
	instance.rotation.x = PI / 2.0
	return instance


func _add_mesh(
	node_name: String,
	mesh: Mesh,
	position: Vector3,
	material: Material,
	parent: Node3D = null
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = position
	instance.material_override = material
	if parent == null:
		add_child(instance)
	else:
		parent.add_child(instance)
	return instance


func _material(color: Color, glowing: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.72
	material.metallic = 0.1
	if glowing:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 0.55
	return material
