extends Control

@onready var title: Label = $VBox/Title
@onready var tech_list: VBoxContainer = $VBox/TechList
@onready var status_label: Label = $VBox/StatusLabel

var researching := false
var current_tech := ""
var research_timer: Timer

func _ready():
	research_timer = Timer.new()
	research_timer.autostart = false
	research_timer.timeout.connect(_on_research_finished)
	add_child(research_timer)
	
	_setup_techs()
	EventBus.research_finished.connect(_on_tech_finished)

func _setup_techs():
	for child in tech_list.get_children():
		child.queue_free()
	
	for tech_id in GameData.TECHS:
		var tech = GameData.TECHS[tech_id]
		var hbox = HBoxContainer.new()
		
		var name_label = Label.new()
		name_label.text = tech["name"]
		name_label.custom_minimum_size.x = 200
		hbox.add_child(name_label)
		
		var cost_label = Label.new()
		cost_label.text = "%d данных, %d сек" % [tech["data_cost"], tech["seconds"]]
		hbox.add_child(cost_label)
		
		var button = Button.new()
		button.text = "Исследовать"
		var has_tech = Game.has_tech(tech_id)
		var can_afford = Game.data >= tech["data_cost"]
		button.disabled = has_tech or (not can_afford) or researching
		
		if has_tech:
			button.text = "Изучено"
			button.disabled = true
		else:
			button.pressed.connect(_start_research.bind(tech_id))
		
		hbox.add_child(button)
		
		tech_list.add_child(hbox)

func _start_research(tech_id):
	if researching:
		return
	
	var tech = GameData.TECHS[tech_id]
	if Game.data < tech["data_cost"]:
		return
	
	Game.spend_data(tech["data_cost"])
	researching = true
	current_tech = tech_id
	status_label.text = "Исследование: " + tech["name"]
	
	research_timer.wait_time = tech["seconds"]
	research_timer.start()
	
	EventBus.research_started.emit(tech_id)

func _on_research_finished():
	if current_tech != "":
		Game.unlock_tech(current_tech)
		EventBus.research_finished.emit(current_tech)
		researching = false
		current_tech = ""
		status_label.text = "Готово к исследованию."
		_setup_techs()

func _on_tech_finished(tech_id):
	pass
