extends Control

@onready var resources_label: Label = $TopBar/HBox/ResourcesLabel
@onready var hub_button: Button = $TopBar/HBox/HubButton
@onready var squad_button: Button = $TopBar/HBox/SquadButton
@onready var mission_button: Button = $TopBar/HBox/MissionButton
@onready var research_button: Button = $TopBar/HBox/ResearchButton
@onready var archive_button: Button = $TopBar/HBox/ArchiveButton
@onready var save_button: Button = $TopBar/HBox/SaveButton
@onready var load_button: Button = $TopBar/HBox/LoadButton

@onready var screens: Control = $Screens
@onready var hub_screen: Control = $Screens/HubScreen
@onready var squad_screen: Control = $Screens/SquadScreen
@onready var mission_screen: Control = $Screens/MissionScreen
@onready var research_screen: Control = $Screens/ResearchScreen
@onready var archive_screen: Control = $Screens/ArchiveScreen

@onready var crisis_modal: PanelContainer = $CrisisModal
@onready var generator_timer: Timer = $GeneratorTimer

var current_screen := "Hub"

func _ready():
	_update_resources()
	_show_screen("Hub")
	hub_button.pressed.connect(_on_hub_button_pressed)
	squad_button.pressed.connect(_on_squad_button_pressed)
	mission_button.pressed.connect(_on_mission_button_pressed)
	research_button.pressed.connect(_on_research_button_pressed)
	archive_button.pressed.connect(_on_archive_button_pressed)
	save_button.pressed.connect(_on_save_button_pressed)
	load_button.pressed.connect(_on_load_button_pressed)
	generator_timer.timeout.connect(_on_generator_timer_timeout)
	EventBus.resources_changed.connect(_update_resources)
	EventBus.crisis_started.connect(_on_crisis_started)
	EventBus.mission_finished.connect(_on_mission_finished)
	_update_buttons()

func _update_resources():
	resources_label.text = "Энергия: %d | Металл: %d | Данные: %d" % [Game.energy, Game.metal, Game.data]

func _show_screen(screen_name):
	current_screen = screen_name
	hub_screen.visible = (screen_name == "Hub")
	squad_screen.visible = (screen_name == "Squad")
	mission_screen.visible = (screen_name == "Mission")
	research_screen.visible = (screen_name == "Research")
	archive_screen.visible = (screen_name == "Archive")
	_update_buttons()

func _update_buttons():
	hub_button.disabled = (current_screen == "Hub")
	squad_button.disabled = (current_screen == "Squad") or mission_screen.is_mission_active()
	mission_button.disabled = (current_screen == "Mission") or mission_screen.is_mission_active()
	research_button.disabled = (current_screen == "Research") or mission_screen.is_mission_active()
	archive_button.disabled = (current_screen == "Archive")

func _on_hub_button_pressed():
	_show_screen("Hub")

func _on_squad_button_pressed():
	if not mission_screen.is_mission_active():
		_show_screen("Squad")

func _on_mission_button_pressed():
	if not mission_screen.is_mission_active():
		_show_screen("Squad")

func _on_research_button_pressed():
	if not mission_screen.is_mission_active():
		_show_screen("Research")

func _on_archive_button_pressed():
	if not mission_screen.is_mission_active():
		_show_screen("Archive")

func _on_save_button_pressed():
	SaveSystem.save_game()

func _on_load_button_pressed():
	SaveSystem.load_game()

func _on_generator_timer_timeout():
	Game.add_energy(GameData.GENERATOR_ENERGY_PER_TICK)

func _on_crisis_started(crisis_data):
	crisis_modal.show_crisis(crisis_data)

func _on_hub_mission_button_pressed():
	_show_screen("Squad")

func _on_mission_finished(result):
	_show_screen("Hub")
