extends Control

@onready var title: Label = $Title
@onready var bot_list: VBoxContainer = $BotList
@onready var policy_option: OptionButton = $PolicyOptionButton
@onready var info_label: Label = $InfoLabel
@onready var charge_button: Button = $ChargeButton
@onready var start_button: Button = $StartButton

var bot_checkboxes := {}
var attachment_boxes := {}

func _ready():
	_setup_bots()
	_setup_policies()
	charge_button.pressed.connect(_on_charge_pressed)
	start_button.pressed.connect(_on_start_pressed)
	EventBus.squad_changed.connect(_update_ui)
	EventBus.resources_changed.connect(_update_ui)
	_update_ui()

func _setup_bots():
	for child in bot_list.get_children():
		child.queue_free()
	bot_checkboxes.clear()
	attachment_boxes.clear()
	for bot in Game.bots:
		var bot_type = Game.get_bot_type(bot)
		var hbox = HBoxContainer.new()
		var checkbox = CheckBox.new()
		checkbox.text = bot_type["name"]
		checkbox.button_pressed = bot["selected"]
		var bot_id = bot["instance_id"]
		checkbox.pressed.connect(_on_bot_selected)
		hbox.add_child(checkbox)
		bot_checkboxes[bot["instance_id"]] = checkbox
		var slots_label = Label.new()
		slots_label.text = " Слоты: %d/%d" % [Game.get_bot_slots_used(bot), bot_type["slots"]]
		hbox.add_child(slots_label)
		var battery_label = Label.new()
		battery_label.text = " Батарея: %d" % Game.get_bot_battery_capacity(bot)
		hbox.add_child(battery_label)
		bot_list.add_child(hbox)
		var att_hbox = HBoxContainer.new()
		for att_id in GameData.ATTACHMENTS:
			var att = GameData.ATTACHMENTS[att_id]
			var att_check = CheckBox.new()
			att_check.text = att["name"]
			att_check.button_pressed = att_id in bot["attachments"]
			var att_check_id = bot["instance_id"] + "_" + att_id
			att_check.toggled.connect(_on_attachment_toggled.bind(bot["instance_id"], att_id, att_check))
			att_hbox.add_child(att_check)
			attachment_boxes[att_check_id] = att_check
		bot_list.add_child(att_hbox)
		bot_list.add_child(VSeparator.new())

func _setup_policies():
	policy_option.clear()
	for pol_id in GameData.POLICIES:
		var pol = GameData.POLICIES[pol_id]
		policy_option.add_item(pol["name"])
		policy_option.set_item_id(policy_option.item_count - 1, hash(pol_id))
		policy_option.set_item_metadata(policy_option.item_count - 1, pol_id)
	for i in range(policy_option.item_count):
		var meta = policy_option.get_item_metadata(i)
		if meta == Game.selected_policy_id:
			policy_option.select(i)
			break
	policy_option.item_selected.connect(_on_policy_selected)

func _on_attachment_toggled(is_toggled, bot_id, att_id, att_check):
	Game.toggle_attachment(bot_id, att_id, att_check.button_pressed)
	_setup_bots()

func _on_bot_selected():
	for bot in Game.bots:
		var checkbox = bot_checkboxes.get(bot["instance_id"])
		if checkbox:
			Game.set_bot_selected(bot["instance_id"], checkbox.button_pressed)
	EventBus.squad_changed.emit()

func _on_policy_selected(index):
	var pol_id = policy_option.get_item_metadata(index)
	Game.selected_policy_id = pol_id

func _on_charge_pressed():
	Game.charge_selected_bots()

func _on_start_pressed():
	if Game.can_start_mission():
		get_parent()._show_screen("Mission")
		get_node("../MissionScreen").start_mission()

func _update_ui():
	var charge_cost = Game.get_squad_charge_cost()
	charge_button.text = "Зарядить отряд (%d энергии)" % charge_cost
	charge_button.disabled = (charge_cost <= 0) or (Game.energy < charge_cost)
	start_button.disabled = not Game.can_start_mission()
	if Game.can_start_mission():
		info_label.text = "Отряд готов к миссии."
	else:
		var selected = Game.get_selected_bots()
		if selected.is_empty():
			info_label.text = "Выберите хотя бы одного бота."
		else:
			var has_miner = false
			for bot in selected:
				var bot_type = Game.get_bot_type(bot)
				if bot_type.get("can_mine", false):
					has_miner = true
					break
			if not has_miner:
				info_label.text = "Нужен хотя бы один Добытчик."
			else:
				info_label.text = "Все боты должны быть заряжены."
