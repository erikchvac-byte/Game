## collision_validator.gd
## Run via: execute_editor_script with content of this file
## Reports y_sort_offset values, orphan CollisionShape2D nodes, and group membership.
## Usage: paste entire file content into execute_editor_script's `code` param.

var issues: Array[String] = []
var ok_count := 0

func _run() -> void:
	_mcp_print("=== Collision / Y-Sort Validator ===")

	var world_scene_path := "res://World/world.tscn"
	var player_scene_path := "res://Player/player.tscn"

	# ---- Y-SORT OFFSET TABLE ----
	# Expected values for inline world.tscn nodes (name → expected offset)
	var expected_y_sort: Dictionary = {
		"Well": 24,
		"PlayerHome": 35,
		"Plant": 24,
		"DryingRack": 30,
		"Big Rock": 31,
		"TreeWillowWeeping": 53,
		"HouseTwostoryTeal": 42,
		"BigMushroomStump": 22,
		"GreyHoodie": 19,
		"Cave entrance": 15,
		"StumpHome001": 12,
		"ForestCreature": 11,
	}

	# Check via scene file text (since y_sort_offset is not a runtime property)
	var file := FileAccess.open(world_scene_path, FileAccess.READ)
	if not file:
		_mcp_print("ERROR: Could not open " + world_scene_path)
		return
	var content := file.get_as_text()
	file.close()

	_mcp_print("\n-- Y-SORT OFFSETS (world.tscn) --")
	for node_name: String in expected_y_sort:
		var expected: int = expected_y_sort[node_name]
		var search_str := 'y_sort_offset = %d' % expected
		# Find the node definition then look for y_sort_offset near it
		var node_marker := '[node name="%s"' % node_name
		var node_pos := content.find(node_marker)
		if node_pos == -1:
			_report_issue("NOT FOUND in world.tscn: node '%s'" % node_name)
			continue
		# Check next 300 chars for y_sort_offset
		var snippet := content.substr(node_pos, 300)
		# Find next node boundary
		var next_node := snippet.find("[node", 1)
		if next_node > 0:
			snippet = snippet.substr(0, next_node)
		if search_str in snippet:
			_mcp_print("  OK  %-22s y_sort_offset=%d" % [node_name, expected])
			ok_count += 1
		else:
			# Check if any y_sort_offset is present at all
			if "y_sort_offset" in snippet:
				var line_start := snippet.find("y_sort_offset")
				var line := snippet.substr(line_start, 30)
				_report_issue("WRONG  %-22s expected=%d  found: %s" % [node_name, expected, line])
			else:
				_report_issue("MISSING %-22s expected y_sort_offset=%d" % [node_name, expected])

	# Check player.tscn
	_mcp_print("\n-- Y-SORT OFFSETS (player.tscn) --")
	var pfile := FileAccess.open(player_scene_path, FileAccess.READ)
	if pfile:
		var pcontent := pfile.get_as_text()
		pfile.close()
		if "y_sort_offset = 14" in pcontent:
			_mcp_print("  OK  Player y_sort_offset=14")
			ok_count += 1
		else:
			_report_issue("MISSING Player y_sort_offset=14 in player.tscn")

	# Check tree base scenes
	_mcp_print("\n-- Y-SORT OFFSETS (tree base scenes) --")
	var tree_scenes := [
		"res://scenes/interactables/trees/pine_tree.tscn",
		"res://scenes/interactables/trees/maple_tree.tscn",
		"res://scenes/interactables/trees/fir_tree.tscn",
	]
	for path: String in tree_scenes:
		var tfile := FileAccess.open(path, FileAccess.READ)
		if not tfile:
			_report_issue("NOT FOUND: " + path)
			continue
		var tcontent := tfile.get_as_text()
		tfile.close()
		if "y_sort_offset = 22" in tcontent:
			_mcp_print("  OK  %s y_sort_offset=22" % path.get_file())
			ok_count += 1
		else:
			_report_issue("MISSING y_sort_offset=22 in " + path.get_file())

	# Check for nested CollisionShape2D bug in world.tscn
	_mcp_print("\n-- COLLISION SHAPE PARENT CHECK --")
	var lines := content.split("\n")
	var current_parent := ""
	for line: String in lines:
		if line.begins_with("[node ") and "type=\"CollisionShape2D\"" in line:
			var parent_start := line.find("parent=\"")
			if parent_start >= 0:
				var parent_end := line.find("\"", parent_start + 8)
				current_parent = line.substr(parent_start + 8, parent_end - parent_start - 8)
				# Check if parent path ends in a CollisionShape2D node name
				# Heuristic: if last segment of parent path contains "Shape" or "Col"
				var last_seg := current_parent.get_file() if "/" in current_parent else current_parent
				if "Shape" in last_seg or (last_seg != "." and last_seg.ends_with("Col")):
					_report_issue("POSSIBLE ORPHAN CollisionShape2D under '%s' — parent may not be a physics body" % current_parent)
				else:
					_mcp_print("  OK  CollisionShape2D under '%s'" % current_parent)
					ok_count += 1

	# Summary
	_mcp_print("\n=== SUMMARY: %d OK, %d issues ===" % [ok_count, issues.size()])
	for issue: String in issues:
		_mcp_print("  !! " + issue)

func _report_issue(msg: String) -> void:
	issues.append(msg)
	_mcp_print("  !! " + msg)
