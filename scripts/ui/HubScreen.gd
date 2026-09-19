extends Control

@onready var title: Label = $VBox/Title
@onready var info_label: Label = $VBox/InfoLabel
@onready var mission_button: Button = $VBox/MissionButton

func _ready():
	mission_button.pressed.connect(_on_mission_button_pressed)

func _on_mission_button_pressed():
	get_parent().get_parent()._show_screen("Squad")
