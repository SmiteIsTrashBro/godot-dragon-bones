# material_import.gd
@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("DragonBonesSprite", "Node2D", preload("sprite.gd"), preload("icon.png"))

func _exit_tree():
	remove_custom_type("DragonBonesSprite")
