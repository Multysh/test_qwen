extends Node

signal resources_changed
signal squad_changed
signal mission_log(message)
signal crisis_started(crisis_data)
signal crisis_finished
signal mission_started
signal mission_finished(result)
signal research_started(tech_id)
signal research_finished(tech_id)
signal archive_updated
signal save_finished(success)
signal load_finished(success)
