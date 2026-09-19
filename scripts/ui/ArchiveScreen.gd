extends Control

@onready var title: Label = $VBox/Title
@onready var archive_list: VBoxContainer = $VBox/ArchiveList
@onready var text_label: Label = $VBox/TextLabel

func _ready():
	_update_archive()
	EventBus.archive_updated.connect(_update_archive)

func _update_archive():
	for child in archive_list.get_children():
		child.queue_free()
	
	for archive_id in Game.unlocked_archive:
		var archive = GameData.ARCHIVE.get(archive_id, {})
		if archive.is_empty():
			continue
		
		var button = Button.new()
		button.text = archive["title"]
		button.pressed.connect(func(): _show_entry(archive_id))
		archive_list.add_child(button)

func _show_entry(archive_id):
	var archive = GameData.ARCHIVE.get(archive_id, {})
	if archive.is_empty():
		return
	
	text_label.text = archive["title"] + "\n\n" + archive["text"]
