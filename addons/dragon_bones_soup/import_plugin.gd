# material_import.gd
@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("DragonBonesSprite", "Node2D", preload("skeleton_importer.gd"), preload("icon.png"))

func _exit_tree():
	remove_custom_type("DragonBonesSprite")
