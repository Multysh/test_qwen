extends Node

var energy := GameData.START_ENERGY
var metal := GameData.START_METAL
var data := GameData.START_DATA

var researched_techs := []
var unlocked_archive := ["awakening"]

var bots := []
var selected_policy_id := "standard"
var mission_count := 0

var bonus_metal := 0
var bonus_data := 0

func _ready():
	bots = [
		{
			"instance_id": "bot_scout",
			"type_id": "scout",
			"attachments": ["ore_sensor"],
			"selected": false,
			"charged": false,
			"lost": false
		},
		{
			"instance_id": "bot_miner",
			"type_id": "miner",
			"attachments": ["ore_sensor", "manipulator"],
			"selected": false,
			"charged": false,
			"lost": false
		}
	]

func add_energy(amount):
	energy += amount
	if energy > GameData.ENERGY_MAX:
		energy = GameData.ENERGY_MAX
	EventBus.resources_changed.emit()

func spend_energy(amount) -> bool:
	if energy >= amount:
		energy -= amount
		EventBus.resources_changed.emit()
		return true
	return false

func add_metal(amount):
	metal += amount
	EventBus.resources_changed.emit()

func spend_metal(amount) -> bool:
	if metal >= amount:
		metal -= amount
		EventBus.resources_changed.emit()
		return true
	return false

func add_data(amount):
	data += amount
	EventBus.resources_changed.emit()

func spend_data(amount) -> bool:
	if data >= amount:
		data -= amount
		EventBus.resources_changed.emit()
		return true
	return false

func get_bot(instance_id) -> Dictionary:
	for bot in bots:
		if bot["instance_id"] == instance_id:
			return bot
	return {}

func get_selected_bots() -> Array:
	var result := []
	for bot in bots:
		if bot["selected"] and not bot["lost"]:
			result.append(bot)
	return result

func set_bot_selected(instance_id, selected):
	for bot in bots:
		if bot["instance_id"] == instance_id:
			bot["selected"] = selected
			break
	EventBus.squad_changed.emit()

func toggle_attachment(instance_id, attachment_id, enabled) -> bool:
	var bot = get_bot(instance_id)
	if bot.is_empty():
		return false
	
	if enabled:
		if not attachment_id in bot["attachments"]:
			var slots_used = get_bot_slots_used(bot)
			var bot_type = get_bot_type(bot)
			if slots_used >= bot_type["slots"]:
				return false
			bot["attachments"].append(attachment_id)
	else:
		if attachment_id in bot["attachments"]:
			bot["attachments"].erase(attachment_id)
	
	EventBus.squad_changed.emit()
	return true

func get_bot_type(bot) -> Dictionary:
	return GameData.BOTS.get(bot["type_id"], {})

func get_bot_slots_used(bot) -> int:
	return len(bot["attachments"])

func get_bot_battery_capacity(bot) -> int:
	var bot_type = get_bot_type(bot)
	var capacity = bot_type["base_battery"]
	for att_id in bot["attachments"]:
		var att = GameData.ATTACHMENTS.get(att_id, {})
		capacity += att.get("battery_bonus", 0)
	return capacity

func get_bot_charge_cost(bot) -> int:
	var bot_type = get_bot_type(bot)
	var cost = bot_type["charge_cost"]
	for att_id in bot["attachments"]:
		var att = GameData.ATTACHMENTS.get(att_id, {})
		cost += att.get("charge_extra", 0)
	
	if has_tech("battery_optimization"):
		cost = max(10, cost - 10)
	
	return cost

func get_squad_charge_cost() -> int:
	var total = 0
	for bot in bots:
		if bot["selected"] and not bot["charged"] and not bot["lost"]:
			total += get_bot_charge_cost(bot)
	return total

func charge_selected_bots() -> bool:
	var cost = get_squad_charge_cost()
	if cost <= 0:
		return true
	if not spend_energy(cost):
		return false
	for bot in bots:
		if bot["selected"] and not bot["lost"]:
			bot["charged"] = true
	EventBus.squad_changed.emit()
	EventBus.resources_changed.emit()
	return true

func can_start_mission() -> bool:
	var selected = get_selected_bots()
	if selected.is_empty():
		return false
	var has_miner = false
	for bot in selected:
		var bot_type = get_bot_type(bot)
		if bot_type.get("can_mine", false):
			has_miner = true
			break
	if not has_miner:
		return false
	for bot in selected:
		if not bot["charged"]:
			return false
	return true

func has_tech(tech_id) -> bool:
	return tech_id in researched_techs

func unlock_tech(tech_id):
	if not tech_id in researched_techs:
		researched_techs.append(tech_id)
		if tech_id == "improved_sensor":
			unlock_archive("personal")

func unlock_archive(archive_id):
	if not archive_id in unlocked_archive:
		unlocked_archive.append(archive_id)
		EventBus.archive_updated.emit()
