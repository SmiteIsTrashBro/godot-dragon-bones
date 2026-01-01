@tool
extends Node2D

signal dragonbones_event(node: NodePath, event_name: String)

@export_file_path("*.json") var skeleton_json: String
@export_file_path("*.json") var texture_json: String
@export_tool_button("Convert to Skeleton2D") var convert_action = convert

const DragonBones = preload("dragon_bones.gd")

func convert():
	var data = _validate_and_load_data()
	if data.is_empty():
		return
	
	var armature_data = data.db_data.armatures.front()
	var root_node = _create_armature(armature_data)
	
	# Phase 1: Skeleton
	var bone_nodes = _build_skeleton(root_node, armature_data)
	
	# Phase 2: Visuals
	_attach_sprites(root_node, bone_nodes, armature_data, data.texture_data)
	
	# Phase 3: Animations
	_build_animations(root_node, bone_nodes, armature_data)
	

	#print("Conversion Complete: ", root_node.name)



# -----------------------------
# Phase 1: Validation & Loading
# -----------------------------
func _validate_and_load_data() -> Dictionary:
	if not skeleton_json:
		push_error("DragonBones load failed: skeleton JSON not loaded or invalid.")
		return {}
	if not texture_json:
		push_error("DragonBones load failed: texture atlas data not loaded or invalid.")
		return {}
	
	var db_data = DragonBones.load_from_file(skeleton_json)
	if not db_data:
		push_error("Failed to load DragonBones data from: " + str(skeleton_json))
		return {}
	
	var texture_data = DragonBones.load_texture_from_file(texture_json)
	if not texture_data:
		push_error("Failed to load TextureAtlas data from: " + str(texture_json))
		return {}
	
	return {"db_data": db_data, "texture_data": texture_data}


# -----------------------------
# Phase 2: Skeleton Setup
# -----------------------------
func _create_armature(armature_data) -> Node:
	var existing_node = get_node_or_null(armature_data.name)
	if existing_node: 
		existing_node.free()
		
	var armature = Node2D.new()
	armature.name = armature_data.name
	add_child(armature)
	armature.owner = get_tree().edited_scene_root
	
	return armature


func _build_skeleton(root_node, armature_data) -> Dictionary:
	var scene_root = get_tree().edited_scene_root
	
	var skeleton = Skeleton2D.new()
	skeleton.name = "Skeleton"
	root_node.add_child(skeleton)
	skeleton.owner = scene_root
	 
	var bone_nodes = {}
	for bone_data in armature_data.bones:
		var bone_node = Bone2D.new()
		bone_node.name = bone_data.name
		bone_node.set_length(maxf(1.0, bone_data.length))
		bone_node.set_autocalculate_length_and_angle(false)
		bone_nodes[bone_data.name] = bone_node
	
	for bone_data in armature_data.bones:
		var bone_node = bone_nodes[bone_data.name]
		if bone_data.parent and bone_nodes.has(bone_data.parent):
			bone_nodes[bone_data.parent].add_child(bone_node)
		else:
			skeleton.add_child(bone_node)
		
		if bone_data.transform:
			bone_node.position = Vector2(bone_data.transform.x, bone_data.transform.y)
			bone_node.rotation_degrees = bone_data.transform.skY
			bone_node.scale = Vector2(bone_data.transform.scX, bone_data.transform.scY)
		
		bone_node.rest = bone_node.transform
		bone_node.owner = scene_root
		
	# Setup IK constraints
	var ik_group = SoupGroup.new()
	ik_group.name = "IKConstraints"
	skeleton.add_child(ik_group)
	ik_group.owner = scene_root
	
	for ik in armature_data.ik_constraints:
		match ik.chain:
			0:
				var constraint = SoupLookAt.new()
				constraint.target_node = bone_nodes[ik.target]
				constraint.bone_node = bone_nodes[ik.bone]
				constraint.name = ik.name
				constraint.enabled = true
				ik_group.add_child(constraint)
				constraint.owner = scene_root
			1:
				var constraint = SoupTwoBoneIK.new()
				constraint.target_node = bone_nodes[ik.target]
				constraint.joint_one_bone_node = bone_nodes[ik.bone].get_parent()
				constraint.joint_two_bone_node = bone_nodes[ik.bone]
				constraint.flip_bend_direction = ik.bend_positive
				constraint.name = ik.name
				constraint.enabled = true
				ik_group.add_child(constraint)
				constraint.owner = scene_root
			_:
				push_warning("Skipping IK constraint '%s', chain > 1" % ik.name)
	
	return bone_nodes


# -----------------------------
# Phase 3: Sprite Attachment
# -----------------------------
func _attach_sprites(root_node, bone_nodes, armature_data, texture_data):
	var skin_data = armature_data.skins.get(0)
	if not skin_data:
		return
		
	var scene_root = get_tree().edited_scene_root
	
	var body_parts = Node2D.new()
	body_parts.name = "Sprites"
	root_node.add_child(body_parts)
	root_node.move_child(body_parts, 0)
	body_parts.owner = scene_root
	
	var atlas_texture = load(texture_data.image_path)
	var sub_textures = texture_data.sub_textures
	
	var slot_textures = {}
	for slot_data in skin_data.slots:
		slot_textures[slot_data.name] = slot_data.displays.get(0)
		
	for index in range(armature_data.slots.size()):
		var slot_data = armature_data.slots[index]
		var parent_bone = bone_nodes.get(slot_data.parent)
		var texture = slot_textures.get(slot_data.name)
		
		if !parent_bone or !texture: 
			continue
			
		var sub_tex = sub_textures[texture.name]
		var sprite_node = Sprite2D.new()
		sprite_node.name = slot_data.name
		sprite_node.texture = atlas_texture
		sprite_node.region_enabled = true
		sprite_node.region_rect = Rect2(sub_tex.x, sub_tex.y, sub_tex.width, sub_tex.height)
		sprite_node.centered = false
		sprite_node.offset = Vector2(
			sub_tex.frameX - (sub_tex.frameWidth / 2.0),
			sub_tex.frameY - (sub_tex.frameHeight / 2.0)
		)
		
		body_parts.add_child(sprite_node)
		sprite_node.owner = scene_root
		
		var rt = RemoteTransform2D.new()
		rt.name = slot_data.name + "RT"
		rt.use_global_coordinates = true
		# Sprite offsets
		rt.position = Vector2(texture.transform.x, texture.transform.y)
		rt.scale = Vector2(texture.transform.scX, texture.transform.scY)
		rt.rotation_degrees = texture.transform.skY
		rt.skew = deg_to_rad(texture.transform.skY - texture.transform.skY)
		parent_bone.add_child(rt)
		rt.owner = scene_root
		rt.remote_path = rt.get_path_to(sprite_node)


# -----------------------------
# Phase 4: Animation Baking
# -----------------------------
func _build_animations(root_node, bone_nodes, armature_data) -> void:
	var scene_root = get_tree().edited_scene_root
	
	var anim_player = AnimationPlayer.new()
	anim_player.name = "Animation"
	root_node.add_child(anim_player)
	root_node.move_child(anim_player, 0)
	anim_player.owner = scene_root
	
	var anim_lib = AnimationLibrary.new()
	anim_player.add_animation_library("", anim_lib)
	
	for anim_data in armature_data.animations:
		var frame_rate = float(armature_data.frame_rate)
		var duration = anim_data.duration / frame_rate
		
		var anim := Animation.new()
		anim.length = duration

		if anim_data.play_times == 0:
			anim.loop_mode = Animation.LOOP_LINEAR
		else:
			anim.loop_mode = Animation.LOOP_NONE

		anim_lib.add_animation(anim_data.name, anim)
		
		var time = 0.0
		var event_track = -1
		
		for frame_data in anim_data.frame_timelines:
			if frame_data.events:
				if event_track == -1:
					event_track = anim.add_track(Animation.TYPE_METHOD)
					anim.track_set_path(event_track, "..")
					
				for event_name in frame_data.events:
					var key_data = {
						"method": "emit_signal",
						"args": ["dragonbones_event", get_path_to(root_node), event_name]
					}
					anim.track_insert_key(event_track, time, key_data)
					
			time += frame_data.duration / frame_rate

		var bone_timelines = {}
		for bone_data in anim_data.bone_timelines:
			bone_timelines[bone_data.name] = bone_data
		
		for bone_name in bone_nodes:
			var bone_node = bone_nodes[bone_name]
			var pos_track = anim.add_track(Animation.TYPE_VALUE)
			anim.track_set_path(pos_track, "%s:position" % root_node.get_path_to(bone_node))
			
			var timeline = bone_timelines.get(bone_name)
			if timeline:
				time = 0.0
				for keyframe in timeline.translate_frames:
					anim.track_insert_key(pos_track, time, bone_node.position + Vector2(keyframe.x, keyframe.y))
					time += keyframe.duration / frame_rate
			else:
				anim.track_insert_key(pos_track, 0.0, bone_node.position)
