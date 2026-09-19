extends PanelContainer

@onready var title_label: Label = $VBox/TitleLabel
@onready var text_label: Label = $VBox/TextLabel
@onready var choices_box: VBoxContainer = $VBox/ChoicesBox

var current_crisis := {}

func show_crisis(crisis_data):
	current_crisis = crisis_data
	title_label.text = crisis_data["title"]
	text_label.text = crisis_data["text"]
	
	for child in choices_box.get_children():
		child.queue_free()
	
	for choice in crisis_data["choices"]:
		var button = Button.new()
		button.text = choice["label"]
		var choice_data = choice
		button.pressed.connect(_on_choice_selected.bind(choice_data))
		choices_box.add_child(button)
	
	visible = true

func _on_choice_selected(choice):
	_apply_effects(choice)
	visible = false
	EventBus.crisis_finished.emit()

func _apply_effects(choice):
	for effect in choice["effects"]:
		var type = effect.get("type", "")
		var value = effect.get("value", 0)
		
		match type:
			"add_metal":
				Game.bonus_metal += value
			"lose_metal":
				Game.bonus_metal -= value
			"add_data":
				Game.bonus_data += value
			"delay":
				var mission_screen = get_parent().get_node("MissionScreen")
				mission_screen.duration += value
			"drain_battery":
				_drain_batteries(value)
			"lose_bot":
				_lose_bot()
			"end_mission_success":
				var mission_screen = get_parent().get_node("MissionScreen")
				mission_screen._finish_mission(true)

func _drain_batteries(amount):
	var mission_screen = get_parent().get_node("MissionScreen")
	for bot_id in mission_screen.bot_batteries.keys():
		var bot = Game.get_bot(bot_id)
		if bot.is_empty() or bot["lost"]:
			continue
		mission_screen.bot_batteries[bot_id] -= amount
		if mission_screen.bot_batteries[bot_id] <= 0:
			bot["lost"] = true
			mission_screen._log("Бот %s потерян!" % Game.get_bot_type(bot)["name"])

func _lose_bot():
	var mission_screen = get_parent().get_node("MissionScreen")
	for bot_id in mission_screen.bot_batteries.keys():
		var bot = Game.get_bot(bot_id)
		if not bot["lost"]:
			bot["lost"] = true
			mission_screen._log("Бот %s потерян!" % Game.get_bot_type(bot)["name"])
			break
	
	if mission_screen._all_bots_lost():
		mission_screen._finish_mission(false)
