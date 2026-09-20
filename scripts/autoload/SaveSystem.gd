extends Node

const SAVE_PATH := "user://save.json"

func save_game() -> bool:
	var data = {
		"version": 1,
		"energy": Game.energy,
		"metal": Game.metal,
		"data": Game.data,
		"researched_techs": Game.researched_techs,
		"unlocked_archive": Game.unlocked_archive,
		"mission_count": Game.mission_count,
		"bots": Game.bots
	}
	
	var json_string = JSON.stringify(data)
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		EventBus.save_finished.emit(false)
		return false
	
	file.store_string(json_string)
	file.close()
	EventBus.save_finished.emit(true)
	return true

func load_game() -> bool:
	if not has_save():
		EventBus.load_finished.emit(false)
		return false
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		EventBus.load_finished.emit(false)
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var result = JSON.parse_string(json_string)
	if result == null:
		EventBus.load_finished.emit(false)
		return false
	
	Game.energy = result.get("energy", GameData.START_ENERGY)
	Game.metal = result.get("metal", GameData.START_METAL)
	Game.data = result.get("data", GameData.START_DATA)
	Game.researched_techs = result.get("researched_techs", [])
	Game.unlocked_archive = result.get("unlocked_archive", ["awakening"])
	Game.mission_count = result.get("mission_count", 0)
	Game.bots = result.get("bots", [])
	
	EventBus.resources_changed.emit()
	EventBus.squad_changed.emit()
	EventBus.archive_updated.emit()
	EventBus.load_finished.emit(true)
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
