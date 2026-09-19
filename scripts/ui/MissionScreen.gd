extends Control

@onready var title: Label = $VBox/Title
@onready var progress_bar: ProgressBar = $VBox/ProgressBar
@onready var time_label: Label = $VBox/TimeLabel
@onready var bot_status_label: Label = $VBox/BotStatusLabel
@onready var log_label: Label = $VBox/LogLabel

var active := false
var paused := false
var elapsed := 0
var duration := 0
var bonus_metal := 0
var bonus_data := 0
var current_crisis_index := 0
var mission_failed := false
var bot_batteries := {}

var mission_timer: Timer

func _ready():
	mission_timer = Timer.new()
	mission_timer.wait_time = 1.0
	mission_timer.autostart = false
	mission_timer.timeout.connect(_on_mission_tick)
	add_child(mission_timer)
	
	EventBus.crisis_finished.connect(_on_crisis_finished)

func is_mission_active() -> bool:
	return active

func start_mission():
	active = true
	paused = false
	elapsed = 0
	duration = GameData.get_mission_base_seconds()
	bonus_metal = 0
	bonus_data = 0
	current_crisis_index = 0
	mission_failed = false
	bot_batteries.clear()
	
	var selected_bots = Game.get_selected_bots()
	for bot in selected_bots:
		bot_batteries[bot["instance_id"]] = Game.get_bot_battery_capacity(bot)
	
	mission_timer.start()
	_update_ui()
	_log("Миссия началась.")

func _on_mission_tick():
	if not active or paused:
		return
	
	elapsed += 1
	
	for bot_id in bot_batteries.keys():
		var bot = Game.get_bot(bot_id)
		if bot.is_empty() or bot["lost"]:
			continue
		bot_batteries[bot_id] -= 1
		if bot_batteries[bot_id] <= 0:
			bot["lost"] = true
			_log("Бот %s потерян!" % Game.get_bot_type(bot)["name"])
	
	if _all_bots_lost():
		_finish_mission(false)
		return
	
	for crisis_time in GameData.CRISIS_TIMES:
		if elapsed == crisis_time and current_crisis_index < len(GameData.CRISIS_ORDER):
			var crisis_id = GameData.CRISIS_ORDER[current_crisis_index]
			var crisis = GameData.CRISES[crisis_id]
			EventBus.crisis_started.emit(crisis)
			paused = true
			current_crisis_index += 1
			return
	
	if elapsed >= duration:
		_finish_mission(true)

func _all_bots_lost() -> bool:
	for bot_id in bot_batteries.keys():
		var bot = Game.get_bot(bot_id)
		if not bot["lost"]:
			return false
	return true

func _on_crisis_finished():
	paused = false
	_update_ui()

func _finish_mission(success: bool):
	active = false
	mission_timer.stop()
	
	if success:
		_calculate_rewards()
		Game.mission_count += 1
		if Game.mission_count == 1:
			Game.unlock_archive("first_log")
		_log("Миссия завершена успешно!")
		_log("Получено: металл +%d, данные +%d" % [bonus_metal, bonus_data])
	else:
		_log("Миссия провалена!")
	
	for bot in Game.bots:
		if bot["selected"]:
			bot["charged"] = false
	
	SaveSystem.save_game()
	
	EventBus.mission_finished.emit({"success": success, "metal": bonus_metal, "data": bonus_data})
	get_parent().get_parent().on_mission_finished({"success": success})

func _calculate_rewards():
	var base_metal = 20
	var selected = Game.get_selected_bots()
	
	var has_miner = false
	var has_sensor = false
	for bot in selected:
		var bot_type = Game.get_bot_type(bot)
		if bot_type.get("can_mine", false):
			has_miner = true
		if "ore_sensor" in bot["attachments"]:
			has_sensor = true
	
	if has_miner:
		base_metal += 10
	if has_sensor:
		base_metal += 10
	
	var final_metal = base_metal + bonus_metal
	if final_metal < 0:
		final_metal = 0
	
	if Game.has_tech("improved_sensor"):
		final_metal = int(final_metal * 1.3)
	
	var policy = GameData.POLICIES.get(Game.selected_policy_id, {})
	var mult = policy.get("metal_multiplier", 1.0)
	final_metal = int(final_metal * mult)
	
	var base_data = 0
	for bot in selected:
		if "manipulator" in bot["attachments"]:
			base_data += 5
	
	var final_data = base_data + bonus_data
	
	Game.add_metal(final_metal)
	Game.add_data(final_data)

func _log(message):
	EventBus.mission_log.emit(message)
	var current_log = log_label.text
	if current_log != "":
		current_log += "\n"
	log_label.text = current_log + message

func _update_ui():
	progress_bar.max_value = duration
	progress_bar.value = elapsed
	time_label.text = "Время: %d / %d сек" % [elapsed, duration]
	
	var status = ""
	for bot in Game.get_selected_bots():
		var bot_type = Game.get_bot_type(bot)
		var batt = bot_batteries.get(bot["instance_id"], 0)
		var lost_str = " [ПОТЕРЯН]" if bot["lost"] else ""
		status += "%s: %d/%d%s\n" % [bot_type["name"], batt, Game.get_bot_battery_capacity(bot), lost_str]
	bot_status_label.text = status
