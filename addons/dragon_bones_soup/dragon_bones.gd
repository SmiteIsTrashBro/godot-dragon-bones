# dragonbones_loader.gd
extends RefCounted

# ============================================================================
# BASIC STRUCTURES
# ============================================================================

static func make_transform(data: Dictionary) -> Dictionary:
	return {
		"x": data.get("x", 0.0),
		"y": data.get("y", 0.0),
		"scX": data.get("scX", 1.0),
		"scY": data.get("scY", 1.0),
		"skX": data.get("skX", 0.0),
		"skY": data.get("skY", 0.0)
	}

static func make_bounding_box(data: Dictionary) -> Dictionary:
	return {
		"x": data.get("x", 0.0),
		"y": data.get("y", 0.0),
		"width": data.get("width", 0.0),
		"height": data.get("height", 0.0)
	}

# ============================================================================
# BONE STRUCTURE
# ============================================================================

static func make_bone(data: Dictionary) -> Dictionary:
	var bone = {
		"name": data.get("name", ""),
		"parent": data.get("parent", ""),
		"length": data.get("length", 0.0),
		"transform": null
	}
	if data.has("transform"):
		bone.transform = make_transform(data["transform"])
	return bone

static func make_slot(data: Dictionary) -> Dictionary:
	return {
		"name": data.get("name", ""),
		"parent": data.get("parent", ""),
		"color": data.get("color", "")
	}

static func make_ik_constraint(data: Dictionary) -> Dictionary:
	return {
		"name": data.get("name", ""),
		"bone": data.get("bone", ""),
		"target": data.get("target", ""),
		"bend_positive": data.get("bendPositive", true),
		"chain": int(data.get("chain", 0))
	}

# ============================================================================
# SKIN/DISPLAY
# ============================================================================

static func make_display(data: Dictionary) -> Dictionary:
	var display = {
		"name": data.get("name", ""),
		"path": data.get("path", ""),
		"transform": null
	}
	if data.has("transform"):
		display.transform = make_transform(data["transform"])
	return display

static func make_skin_slot(data: Dictionary) -> Dictionary:
	var skin_slot = {
		"name": data.get("name", ""),
		"displays": []
	}
	if data.has("display"):
		for display_data in data["display"]:
			skin_slot.displays.append(make_display(display_data))
	return skin_slot

static func make_skin_data(data: Dictionary) -> Dictionary:
	var skin = {
		"name": data.get("name", "default"),
		"slots": []
	}
	if data.has("slot"):
		for slot_data in data["slot"]:
			skin.slots.append(make_skin_slot(slot_data))
	return skin

# ============================================================================
# ANIMATION FRAMES
# ============================================================================

static func make_transform_frame(data: Dictionary) -> Dictionary:
	var frame = {
		"duration": data.get("duration", 1),
		"x": data.get("x", 0.0),
		"y": data.get("y", 0.0),
		"tween_easing": data.get("tweenEasing", null),
		"curve": []
	}
	if data.has("curve"):
		frame.curve = data["curve"].duplicate()
	return frame

static func make_rotate_frame(data: Dictionary) -> Dictionary:
	return {
		"duration": data.get("duration", 1),
		"rotate": data.get("rotate", 0.0),
		"tween_easing": data.get("tweenEasing", null)
	}

static func make_scale_frame(data: Dictionary) -> Dictionary:
	return {
		"duration": data.get("duration", 1),
		"scX": data.get("scX", 1.0),
		"scY": data.get("scY", 1.0),
		"tween_easing": data.get("tweenEasing", null)
	}

# ============================================================================
# ANIMATION TIMELINES
# ============================================================================

static func make_bone_timeline(data: Dictionary) -> Dictionary:
	var timeline = {
		"name": data.get("name", ""),
		"translate_frames": [],
		"rotate_frames": [],
		"scale_frames": []
	}
	
	if data.has("translateFrame"):
		for frame_data in data["translateFrame"]:
			timeline.translate_frames.append(make_transform_frame(frame_data))
	
	if data.has("rotateFrame"):
		for frame_data in data["rotateFrame"]:
			timeline.rotate_frames.append(make_rotate_frame(frame_data))
	
	if data.has("scaleFrame"):
		for frame_data in data["scaleFrame"]:
			timeline.scale_frames.append(make_scale_frame(frame_data))
	
	return timeline

static func make_slot_timeline(data: Dictionary) -> Dictionary:
	var timeline = {
		"name": data.get("name", ""),
		"display_frames": [],
		"color_frames": []
	}
	if data.has("displayFrame"):
		timeline.display_frames = data["displayFrame"].duplicate()
	if data.has("colorFrame"):
		timeline.color_frames = data["colorFrame"].duplicate()
	return timeline
	
	
static func make_frame_timeline(data: Dictionary) -> Dictionary:
	var frame = {
		"duration": data.get("duration", 0),
		"action": data.get("action", ""),
		"sound": data.get("sound", ""),
		"events": data.get("events", []).map(
			func(e): return e.get("name", null)
		)
	}
	return frame

# ============================================================================
# ANIMATION
# ============================================================================

static func make_animation_clip(data: Dictionary) -> Dictionary:
	var anim = {
		"name": data.get("name", ""),
		"duration": data.get("duration", 0),
		"play_times": data.get("playTimes", 1),
		"bone_timelines": [],
		"slot_timelines": [],
		"frame_timelines": []
	}
	
	if data.has("bone"):
		for bone_data in data["bone"]:
			anim.bone_timelines.append(make_bone_timeline(bone_data))
	
	if data.has("slot"):
		for slot_data in data["slot"]:
			anim.slot_timelines.append(make_slot_timeline(slot_data))
			
	if data.has("frame"):
		for frame_data in data["frame"]:
			anim.frame_timelines.append(make_frame_timeline(frame_data))
	
	return anim

# ============================================================================
# ARMATURE
# ============================================================================

static func make_default_action(data: Dictionary) -> Dictionary:
	return {
		"action": data.get("gotoAndPlay", "")
	}

static func make_armature(data: Dictionary) -> Dictionary:
	var armature = {
		"type": data.get("type", "Armature"),
		"name": data.get("name", ""),
		"frame_rate": data.get("frameRate", 24),
		"bounding_box": null,
		"bones": [],
		"slots": [],
		"ik_constraints": [],
		"skins": [],
		"animations": [],
		"default_actions": []
	}
	
	if data.has("aabb"):
		armature.bounding_box = make_bounding_box(data["aabb"])
	
	if data.has("bone"):
		for bone_data in data["bone"]:
			armature.bones.append(make_bone(bone_data))
	
	if data.has("slot"):
		for slot_data in data["slot"]:
			armature.slots.append(make_slot(slot_data))
	
	if data.has("ik"):
		for ik_data in data["ik"]:
			armature.ik_constraints.append(make_ik_constraint(ik_data))
	
	if data.has("skin"):
		for skin_data in data["skin"]:
			armature.skins.append(make_skin_data(skin_data))
	
	if data.has("animation"):
		for anim_data in data["animation"]:
			armature.animations.append(make_animation_clip(anim_data))
	
	if data.has("defaultActions"):
		for action_data in data["defaultActions"]:
			armature.default_actions.append(make_default_action(action_data))
	
	return armature

# ============================================================================
# ROOT DOCUMENT
# ============================================================================

static func make_dragonbones_data(data: Dictionary) -> Dictionary:
	var db = {
		"name": data.get("name", ""),
		"version": data.get("version", ""),
		"compatible_version": data.get("compatibleVersion", ""),
		"frame_rate": data.get("frameRate", 24),
		"armatures": []
	}
	
	if data.has("armature"):
		for armature_data in data["armature"]:
			db.armatures.append(make_armature(armature_data))
	
	return db
	
static func make_texture_atlas_data(data: Dictionary, base_path: String) -> Dictionary:
	var atlas_data = {
		"name": data.get("name", ""),
		"image_path": base_path.path_join(data.get("imagePath", "")),
		"width": data.get("width", 0),
		"height": data.get("height", 0),
		"texture": PlaceholderTexture2D.new(),
		"sub_textures": {}
	}
	
	# Parse SubTexture entries
	if data.has("SubTexture"):
		var sub_textures = data.SubTexture
		if typeof(sub_textures) == TYPE_ARRAY:
			for sub_tex in sub_textures:
				var name = sub_tex.get("name", "")
				if name:
					atlas_data.sub_textures[name] = {
						"x": sub_tex.get("x", 0),
						"y": sub_tex.get("y", 0),
						"width": sub_tex.get("width", 0),
						"height": sub_tex.get("height", 0),
						"frameX": abs(sub_tex.get("frameX", 0)),
						"frameY": abs(sub_tex.get("frameY", 0)),
						"frameWidth": sub_tex.get("frameWidth", sub_tex.get("width", 0)),
						"frameHeight": sub_tex.get("frameHeight", sub_tex.get("height", 0))
					}
	
	return atlas_data

# ============================================================================
# LOADER FUNCTIONS
# ============================================================================

static func load_from_file(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Failed to open file: " + path)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	return load_from_json(json_string)

static func load_from_json(json_string: String) -> Dictionary:
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		push_error("Failed to parse JSON: " + json.get_error_message())
		return {}
	
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Invalid JSON structure")
		return {}
	
	return make_dragonbones_data(data)
	
static func load_texture_from_file(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Failed to open file: " + path)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	return load_texture_from_json(json_string, path.get_base_dir())

static func load_texture_from_json(json_string: String, base_path: String = "") -> Dictionary:
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		push_error("Failed to parse JSON: " + json.get_error_message())
		return {}
	
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Invalid JSON structure")
		return {}
	
	return make_texture_atlas_data(data, base_path)
