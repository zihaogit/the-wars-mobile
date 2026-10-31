extends RefCounted

const KING_X := 16.0
const PLAYER_COLOR := Color("#63d6cb")
const AI_COLOR := Color("#e68168")
const GOLD_COLOR := Color("#f1cb78")
const STONE_DARK := Color("#303b40")

var game: Variant


func _init(match: Variant) -> void:
	game = match


func build_world() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#131b20")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#b5c3bb")
	environment.ambient_light_energy = 0.8
	var world := WorldEnvironment.new()
	world.environment = environment
	game.add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58.0, -26.0, 0.0)
	sun.light_color = Color("#ffe4bb")
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	game.add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-38.0, 150.0, 0.0)
	fill.light_color = Color("#9fc9c1")
	fill.light_energy = 0.3
	game.add_child(fill)

	var camera := Camera3D.new()
	camera.name = "BattleCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 23.0
	camera.position = Vector3(0.0, 29.0, -8.0)
	game.add_child(camera)
	camera.look_at(Vector3.ZERO, Vector3(0.0, 0.0, -1.0))
	camera.current = true

	game._add_box("ArenaGround", Vector3(38.0, 0.45, 20.0), Vector3(0.0, -0.3, 0.0), Color("#34483c"))
	game._add_box("ArenaInset", Vector3(36.8, 0.08, 18.8), Vector3(0.0, -0.045, 0.0), Color("#53624a"))
	game._add_box("PlayerTerritory", Vector3(18.0, 0.025, 18.0), Vector3(-9.0, 0.008, 0.0), Color("#465b50"))
	game._add_box("RivalTerritory", Vector3(18.0, 0.025, 18.0), Vector3(9.0, 0.008, 0.0), Color("#5b4943"))
	for segment_index in range(24):
		var start_x := lerpf(-KING_X, KING_X, float(segment_index) / 24.0)
		var end_x := lerpf(-KING_X, KING_X, float(segment_index + 1) / 24.0)
		var start := Vector3(start_x, 0.035, game._lane_z(start_x))
		var finish := Vector3(end_x, 0.035, game._lane_z(end_x))
		var segment: MeshInstance3D = game._add_box(
			"LaneStone",
			Vector3(start.distance_to(finish), 0.1, 5.5),
			(start + finish) * 0.5,
			Color("#424a45")
		)
		segment.rotation.y = -atan2(finish.z - start.z, finish.x - start.x)
		var inlay: MeshInstance3D = game._add_box(
			"LaneInlay",
			Vector3(start.distance_to(finish), 0.035, 4.5),
			Vector3((start.x + finish.x) * 0.5, 0.105, (start.z + finish.z) * 0.5),
			Color("#596052")
		)
		inlay.rotation.y = segment.rotation.y

	for x in [-15.0, -11.0, 11.0, 15.0]:
		for z in [-8.0, 8.0]:
			game._add_cylinder("GardenStone", 0.75, 0.24, Vector3(x, -0.02, z), Color("#596650"), 7)
			game._add_sphere("Shrub", 0.55, Vector3(x, 0.3, z), Color("#52694b"))


func build_construction_sites() -> void:
	for player_side in [true, false]:
		var side_x: Array[float] = []
		side_x.assign([-9.0, -4.0] if player_side else [4.0, 9.0])
		var team_color: Color = PLAYER_COLOR if player_side else AI_COLOR
		for x in side_x:
			for z in [-5.4, 5.4]:
				var site_node := Node3D.new()
				site_node.name = "PlayerBuildPlot" if player_side else "RivalBuildPlot"
				site_node.position = Vector3(x, 0.0, z)
				game.add_child(site_node)
				game._add_cylinder("BuildPlotStone", 1.25, 0.2, Vector3(0.0, 0.02, 0.0), Color("#303a38"), 8, site_node)
				game._add_torus("BuildPlotRing", 1.08, 0.075, Vector3(0.0, 0.15, 0.0), team_color, site_node)
				game._add_cylinder("BuildPlotCenter", 0.16, 0.08, Vector3(0.0, 0.16, 0.0), team_color, 6, site_node)
				game.building_sites.append({
					"node": site_node,
					"is_player": player_side,
					"building": "",
					"level": 0,
					"cooldown": 0.0,
					"model": null
				})


func build_structure_model(building_id: String, level: int, parent: Node3D) -> Node3D:
	var model := Node3D.new()
	model.name = "%sLevel%d" % [building_id.capitalize(), level]
	parent.add_child(model)
	var stone := Color("#64716b")
	var trim := Color("#c4a767") if level == 1 else Color("#e0c77e")
	match building_id:
		"tower":
			game._add_cylinder("TowerBase", 0.78, 0.55, Vector3(0.0, 0.42, 0.0), stone, 8, model)
			game._add_box("TowerBody", Vector3(0.88, 1.35 + level * 0.12, 0.88), Vector3(0.0, 1.25, 0.0), Color("#738079"), false, model)
			game._add_box("TowerWindow", Vector3(0.28, 0.55, 0.08), Vector3(0.0, 1.35, -0.46), Color("#f0c96f"), true, model)
			game._add_cone("TowerRoof", 0.82, 0.85, Vector3(0.0, 2.28 + level * 0.12, 0.0), trim, model)
			game._add_sphere("TowerBeacon", 0.18, Vector3(0.0, 2.78 + level * 0.12, 0.0), Color("#f3d37d"), true, model)
		"lumber":
			game._add_box("CampHut", Vector3(1.35, 1.0, 1.05), Vector3(0.0, 0.72, 0.0), Color("#7d6448"), false, model)
			game._add_cone("CampRoof", 1.0, 0.8, Vector3(0.0, 1.57, 0.0), Color("#56644c"), model)
			for log_index in range(level + 1):
				game._add_cylinder(
					"TimberStack",
					0.16,
					0.9,
					Vector3(-0.74, 0.34 + float(log_index) * 0.2, 0.45),
					Color("#a17b51"),
					7,
					model
				)
		"farm":
			game._add_box("Farmhouse", Vector3(1.05, 0.82, 0.92), Vector3(0.0, 0.62, 0.0), Color("#897454"), false, model)
			game._add_cone("FarmRoof", 0.84, 0.65, Vector3(0.0, 1.36, 0.0), Color("#8c654a"), model)
			for row in range(3):
				game._add_box(
					"CropRow",
					Vector3(0.25, 0.28 + level * 0.04, 1.45),
					Vector3(-0.7 + float(row) * 0.7, 0.35, 0.78),
					Color("#77904e"),
					false,
					model
				)
	var badge_height := 2.8 if building_id == "tower" else 2.05
	for badge_index in range(level):
		game._add_sphere(
			"LevelBadge",
			0.12,
			Vector3(-0.7 + float(badge_index) * 0.24, badge_height, 0.0),
			trim,
			true,
			model
		)
	return model


func build_bases() -> void:
	game.set("player_king_visual", build_king("YourKing", -KING_X, PLAYER_COLOR))
	game.set("ai_king_visual", build_king("RivalKing", KING_X, AI_COLOR))


func build_king(king_name: String, x: float, team_color: Color) -> Node3D:
	var keep := Node3D.new()
	keep.name = king_name
	keep.position = Vector3(x, 0.0, 0.0)
	game.add_child(keep)

	game._add_cylinder("KeepFoundation", 2.45, 0.55, Vector3(0.0, 0.1, 0.0), STONE_DARK, 8, keep)
	game._add_cylinder("KingKeep", 1.72, 2.4, Vector3(0.0, 1.52, 0.0), Color("#59666a"), 8, keep)
	game._add_cylinder("KeepTrim", 1.95, 0.2, Vector3(0.0, 2.55, 0.0), team_color, 8, keep)
	game._add_cylinder("KeepCrown", 1.42, 0.52, Vector3(0.0, 2.9, 0.0), STONE_DARK, 8, keep)
	game._add_cone("KeepSpire", 0.92, 1.6, Vector3(0.0, 3.95, 0.0), team_color, keep)
	var heart: MeshInstance3D = game._add_sphere("KingHeart", 0.49, Vector3(0.0, 4.85, 0.0), GOLD_COLOR, true, keep)
	heart.name = "KingHeart"
	game._add_torus("KeepHalo", 1.75, 0.1, Vector3(0.0, 2.5, 0.0), team_color, keep)

	for side in [-1.0, 1.0]:
		for depth in [-1.0, 1.0]:
			game._add_box(
				"KeepButtress",
				Vector3(0.38, 1.25, 0.38),
				Vector3(side * 1.8, 0.75, depth * 1.8),
				Color("#83908a"),
				false,
				keep
			)
	return keep


func build_wave_hero(hero_id: String, is_player: bool, spawn: Vector3) -> Node3D:
	var team_color: Color = PLAYER_COLOR if is_player else AI_COLOR
	var body_color := Color("#637c78") if is_player else Color("#76544e")
	var hero := Node3D.new()
	hero.name = "%s_%s_Wave_%02d" % [
		"Player" if is_player else "Rival",
		hero_id.capitalize(),
		game.wave_number
	]
	hero.position = spawn
	game.add_child(hero)
	build_hero_model(hero_id, team_color, body_color, hero)
	return hero


func build_hero_model(
	hero_id: String,
	team_color: Color,
	body_color: Color,
	parent: Node3D,
	show_team_markers: bool = true
) -> Node3D:
	var model := Node3D.new()
	model.name = "%sModel" % hero_id.capitalize()
	parent.add_child(model)
	match hero_id:
		"TORREN":
			model.scale = Vector3.ONE * 1.08
		"IRI":
			model.scale = Vector3(0.96, 1.05, 0.96)

	if show_team_markers:
		game._add_torus("HeroSelectionRing", 0.58, 0.055, Vector3(0.0, 0.08, 0.0), team_color, model)
		game._add_cylinder("TeamSigil", 0.32, 0.045, Vector3(0.0, 0.1, 0.0), team_color, 8, model)
	var cape_color := Color("#9a473d") if hero_id == "ASH" else Color("#495e76")
	var cape: MeshInstance3D = game._add_box(
		"HeroMantle",
		Vector3(0.66, 0.96, 0.14),
		Vector3(0.0, 1.02, 0.29),
		cape_color,
		false,
		model
	)
	cape.rotation.x = -0.12
	for side in [-1.0, 1.0]:
		game._add_capsule(
			"HeroLeg",
			0.15,
			0.52,
			Vector3(side * 0.16, 0.38, 0.0),
			Color("#39474c"),
			model
		)
		game._add_box(
			"HeroBoot",
			Vector3(0.31, 0.17, 0.43),
			Vector3(side * 0.16, 0.14, -0.08),
			Color("#202b30"),
			false,
			model
		)

	game._add_capsule("HeroBody", 0.32, 0.92, Vector3(0.0, 0.96, 0.0), body_color, model)
	var chest: MeshInstance3D = game._add_sphere("HeroBreastplate", 0.34, Vector3(0.0, 1.08, -0.14), team_color, false, model)
	chest.scale = Vector3(1.0, 0.94, 0.6)
	var belt: MeshInstance3D = game._add_box("HeroBelt", Vector3(0.57, 0.12, 0.42), Vector3(0.0, 0.62, 0.0), Color("#343c3e"), false, model)
	belt.rotation.z = -0.04

	for side in [-1.0, 1.0]:
		var shoulder: MeshInstance3D = game._add_sphere(
			"HeroShoulderArmor",
			0.25,
			Vector3(side * 0.4, 1.34, 0.0),
			team_color,
			false,
			model
		)
		shoulder.scale = Vector3(1.18, 0.82, 0.95)
		var arm: MeshInstance3D = game._add_capsule(
			"HeroArm",
			0.13,
			0.6,
			Vector3(side * 0.48, 0.91, -0.02),
			body_color,
			model
		)
		arm.rotation.z = side * -0.28
		game._add_cylinder(
			"HeroWristGuard",
			0.16,
			0.2,
			Vector3(side * 0.53, 0.68, -0.02),
			Color("#9c845a"),
			6,
			model
		)
		game._add_sphere(
			"HeroGlove",
			0.14,
			Vector3(side * 0.54, 0.61, -0.05),
			Color("#485457"),
			false,
			model
		)

	game._add_sphere("HeroHead", 0.22, Vector3(0.0, 1.69, -0.015), Color("#d9c9ad"), false, model)
	var helmet: MeshInstance3D = game._add_sphere("HeroHelmet", 0.265, Vector3(0.0, 1.87, 0.015), team_color, false, model)
	helmet.scale = Vector3(1.2, 0.6, 1.08)
	for side in [-1.0, 1.0]:
		game._add_sphere(
			"HeroEye",
			0.035,
			Vector3(side * 0.075, 1.67, -0.25),
			Color("#202326"),
			false,
			model
		)
	game._add_box("HeroVisor", Vector3(0.32, 0.07, 0.11), Vector3(0.0, 1.58, -0.21), GOLD_COLOR, true, model)
	game._add_sphere("HeroChestEmblem", 0.09, Vector3(0.0, 1.04, -0.34), GOLD_COLOR, true, model)
	match hero_id:
		"TORREN":
			game._add_box("GuardianShield", Vector3(0.12, 0.82, 0.62), Vector3(-0.58, 0.98, -0.17), Color("#b49b55"), false, model)
			game._add_sphere("GuardianShieldBoss", 0.13, Vector3(-0.58, 0.98, -0.27), GOLD_COLOR, true, model)
			game._add_box("GuardianArmor", Vector3(0.76, 0.4, 0.24), Vector3(0.0, 1.08, -0.28), Color("#556167"), false, model)
			game._add_cone("GuardianCrest", 0.16, 0.42, Vector3(0.0, 2.12, 0.02), GOLD_COLOR, model)
		"IRI":
			var bow: MeshInstance3D = game._add_torus("RangerBow", 0.42, 0.055, Vector3(0.54, 1.04, -0.12), GOLD_COLOR, model)
			bow.rotation.x = PI / 2.0
			game._add_box("RangerArrow", Vector3(0.7, 0.045, 0.045), Vector3(0.47, 1.03, -0.23), Color("#e4d7b6"), false, model)
			var hood: MeshInstance3D = game._add_cone("RangerHood", 0.34, 0.52, Vector3(0.0, 1.93, 0.02), Color("#536953"), model)
			hood.rotation.z = PI
		_:
			var sword: MeshInstance3D = game._add_cylinder("VanguardWeapon", 0.045, 0.92, Vector3(0.56, 1.2, -0.2), GOLD_COLOR, 8, model)
			sword.rotation.z = -0.38
			var blade: MeshInstance3D = game._add_cone("VanguardBlade", 0.13, 0.38, Vector3(0.73, 1.79, -0.2), Color("#d6e0df"), model)
			blade.rotation.z = -0.38
			game._add_cone("DawnCrest", 0.13, 0.38, Vector3(0.0, 2.05, 0.02), Color("#e6bc69"), model)
	return model
