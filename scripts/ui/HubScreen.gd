extends Control

@onready var title: Label = $Title
@onready var info_label: Label = $InfoLabel
@onready var mission_button: Button = $MissionButton

func _ready():
	mission_button.pressed.connect(_on_mission_button_pressed)

func _on_mission_button_pressed():
	get_parent()._show_screen("Squad")
