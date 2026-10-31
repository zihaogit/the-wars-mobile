extends SceneTree


func _initialize() -> void:
	call_deferred("_run_match_flow_checks")


func _run_match_flow_checks() -> void:
	var scene: Variant = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame

	if not _check(scene.HEROES.size() == 3, "The external hero roster should load all three original heroes."):
		return
	if not _check(scene.build_buttons.size() == 3, "The touch command grid should show all three hero choices."):
		return
	if not _check(scene.hero_portraits.size() == 3, "Every hero should have a loaded illustrated portrait."):
		return
	if not _check(scene.selected_hero_portrait.texture == scene.hero_portraits["ASH"], "The selected hero portrait should match the queued hero."):
		return
	if not _check(scene.hero_portraits["ASH"].get_width() >= 512, "Hero portraits should retain their source resolution."):
		return
	if not _check(scene.building_sites.size() == 8, "The arena should provide mirrored, visible build plots."):
		return
	if not _check(
		scene.player_wood == 60 and scene._player_food_capacity() == 8,
		"The match should start with wood and headquarters supply."
	):
		return
	if not _check(scene.building_buttons.size() == 4, "The command grid should expose three buildings and an upgrade action."):
		return
	if not _check(scene.find_child("HeroRecruitmentTower", true, false) == null, "The game should not require an invented Hero Hall."):
		return
	if not _check(scene.find_child("HeroHallBuildPlot", true, false) == null, "The game should not require a fixed Hero Hall placement plot."):
		return

	var torren_button: Button = scene.build_buttons["TORREN"]
	torren_button.emit_signal("pressed")
	if not _check(scene.selected_player_hero == "TORREN", "Tapping a hero command should queue that hero."):
		return
	if not _check(scene.selected_hero_name.text == "Torren Stoneward", "The hero profile should show the selected character's name."):
		return
	if not _check(scene.selected_hero_title.text == "The Deepwall", "The hero profile should show the selected character's title."):
		return
	if not _check(scene.selected_hero_portrait.texture == scene.hero_portraits["TORREN"], "Selecting a hero should update the large portrait."):
		return

	var iri_button: Button = scene.build_buttons["IRI"]
	iri_button.emit_signal("pressed")
	if not _check(scene.selected_player_hero == "IRI", "The command grid should save the selected hero."):
		return
	if not _check(scene.selected_hero_name.text == "Iri Solwind", "The deployment profile should follow the selected hero card."):
		return
	if not _check(scene.selected_hero_portrait.texture == scene.hero_portraits["IRI"], "Selecting Iri should show her portrait."):
		return
	if not _check(
		scene.player_build_queue == ["TORREN", "IRI"],
		"Recruit buttons should queue multiple units for the next round."
	):
		return
	if not _check(scene.player_gold == 25, "Recruiting should charge each unit immediately from player gold."):
		return
	if not _check(
		scene.build_status_labels["IRI"].text == "QUEUED  x1",
		"A build card should show how many units are queued."
	):
		return

	scene._start_wave()
	if not _check(scene.player_army.size() == 2, "A wave should deploy all affordable queued player units."):
		return
	if not _check(
		scene.player_army[0].hero_id == "TORREN" and scene.player_army[1].hero_id == "IRI",
		"The wave should preserve the player's chosen build order."
	):
		return
	if not _check(scene.ai_army.size() == 2, "The AI should spend its own gold to build multiple units."):
		return
	if not _check(
		scene.ai_army[0].hero_id == "ASH" and scene.ai_army[1].hero_id == "ASH",
		"The AI should counter the player's queued Iri composition."
	):
		return
	var camera: Camera3D = scene.get_viewport().get_camera_3d()
	var player_unit: Node3D = scene.player_army[0].node
	var select_touch := InputEventScreenTouch.new()
	select_touch.pressed = true
	select_touch.position = camera.unproject_position(player_unit.global_position + Vector3.UP)
	scene._unhandled_input(select_touch)
	if not _check(scene.selected_player_unit == player_unit, "A touch should select a friendly battlefield unit."):
		return
	var move_touch := InputEventScreenTouch.new()
	move_touch.pressed = true
	move_touch.position = camera.unproject_position(Vector3(0.0, 0.0, 4.0))
	scene._unhandled_input(move_touch)
	if not _check(scene.player_army[0].has_manual_target, "A second touch should issue a movement order."):
		return
	var mouse_click := InputEventMouseButton.new()
	mouse_click.button_index = MOUSE_BUTTON_LEFT
	mouse_click.pressed = true
	scene._unhandled_input(mouse_click)
	if not _check(scene.player_army[0].has_manual_target, "Battlefield orders should work through touch, not require a mouse."):
		return
	if not _check(
		scene.player_build_queue.is_empty() and scene.ai_build_queue.is_empty(),
		"Deployed build queues should clear after a round."
	):
		return
	if not _check(scene.player_gold == 100, "Player income should be awarded after the round's queued units deploy."):
		return
	if not _check(scene.ai_gold == 115, "AI income and recruitment costs should be tracked independently."):
		return

	scene._damage_unit(scene.ai_army, 0, 99999)
	if not _check(not scene.game_over, "Defeating an individual wave hero must not end the match."):
		return

	if not _check(
		scene._queue_hero("TORREN") and scene._queue_hero("TORREN"),
		"The next build phase should allow the player to invest in a chosen strategy."
	):
		return
	if not _check(scene.player_gold == 30, "A second-round build should spend the player's remaining gold immediately."):
		return
	scene._start_wave()
	if not _check(scene.player_army.size() == 4, "The next wave should add both newly queued player recruits."):
		return
	if not _check(
		scene.player_army[2].hero_id == "TORREN" and scene.player_army[3].hero_id == "TORREN",
		"The next wave should preserve repeated recruit orders."
	):
		return
	if not _check(scene.ai_army.size() == 3, "The rival should reinforce its existing army in the next wave."):
		return
	if not _check(
		scene.ai_army[1].hero_id == "IRI" and scene.ai_army[2].hero_id == "IRI",
		"The rival should adapt its counter-pick to the player's Torren-heavy army."
	):
		return

	scene.player_gold = 0
	if not _check(not scene._queue_hero("TORREN"), "An unaffordable recruit should not be silently queued."):
		return
	if not _check(scene.player_army.size() == 4 and scene.player_build_queue.is_empty(), "An unaffordable recruit must not add another unit."):
		return

	var king_health_max: int = scene.get_script().get_script_constant_map()["KING_HEALTH_MAX"]
	scene._damage_king(false, king_health_max - 1)
	if not _check(not scene.game_over, "A King must survive while it has health remaining."):
		return

	scene._damage_king(false, 1)
	if not _check(scene.game_over, "Defeating the enemy King should end the match."):
		return
	if not _check(scene.result_overlay.visible, "King defeat should show the match result overlay."):
		return
	if not _check(scene.result_title.text == "ENEMY KING DEFEATED", "The result overlay should announce the victory."):
		return

	var defeat_scene: Variant = load("res://scenes/main.tscn").instantiate()
	root.add_child(defeat_scene)
	await process_frame
	defeat_scene._damage_king(true, 500)
	if not _check(defeat_scene.game_over, "Defeating the player's King should end the match."):
		return
	if not _check(defeat_scene.result_title.text == "YOUR KING HAS FALLEN", "The result overlay should announce the defeat."):
		return

	var construction_scene: Variant = load("res://scenes/main.tscn").instantiate()
	root.add_child(construction_scene)
	await process_frame
	var construction_camera: Camera3D = construction_scene.get_viewport().get_camera_3d()
	construction_scene.building_buttons["tower"].emit_signal("pressed")
	if not _check(
		construction_scene.selected_build_mode == "tower",
		"A build command should enter touch placement mode."
	):
		return
	var tower_site: Dictionary = construction_scene.building_sites[0]
	var tower_screen_position := construction_camera.unproject_position(
		tower_site.node.global_position + Vector3.UP * 0.7
	)
	construction_scene._handle_battlefield_tap(tower_screen_position)
	if not _check(
		construction_scene.building_sites[0].building == "tower"
		and construction_scene.building_sites[0].level == 1,
		"A tap on a friendly open plot should place the selected tower."
	):
		return
	if not _check(
		construction_scene.player_gold == 45 and construction_scene.player_wood == 40,
		"Building placement should deduct both listed resources."
	):
		return
	construction_scene.building_buttons["upgrade"].emit_signal("pressed")
	if not _check(
		construction_scene.building_sites[0].level == 2,
		"The selected structure should upgrade from its command-grid action."
	):
		return
	if not _check(
		construction_scene.player_gold == 10 and construction_scene.player_wood == 25,
		"Upgrading should charge its gold and wood costs."
	):
		return

	construction_scene.player_gold = 100
	construction_scene.player_wood = 60
	construction_scene._place_building(1, "farm")
	if not _check(
		construction_scene._player_food_capacity() == 11,
		"A farm should expand the player's food capacity."
	):
		return
	construction_scene.player_gold = 100
	construction_scene.player_wood = 60
	construction_scene._place_building(2, "lumber")
	construction_scene.player_wood = 60
	construction_scene._start_wave()
	if not _check(
		construction_scene.player_wood == 78,
		"Wave income should include base timber income and the camp's production."
	):
		return

	print("Match-flow checks passed: touch orders, legal construction, upgrades, gold/wood/food, resource income, adaptive AI, waves, and King-only outcomes.")
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
