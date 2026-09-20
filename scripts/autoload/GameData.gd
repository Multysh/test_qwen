extends Node

const START_ENERGY := 100
const START_METAL := 50
const START_DATA := 0
const ENERGY_MAX := 999

const GENERATOR_ENERGY_PER_TICK := 1
const GENERATOR_TICK_SECONDS := 6

const MISSION_TRAVEL_SECONDS := 5
const MISSION_WORK_SECONDS := 20
const MISSION_RETURN_SECONDS := 5
const CRISIS_TIMES := [7, 15, 23]

const CHARGE_BASE_COST := 30

const BOTS := {
	"scout": {
		"name": "Разведчик",
		"slots": 2,
		"base_battery": 80,
		"charge_cost": 30,
		"can_mine": false
	},
	"miner": {
		"name": "Добытчик",
		"slots": 3,
		"base_battery": 120,
		"charge_cost": 30,
		"can_mine": true
	}
}

const ATTACHMENTS := {
	"ore_sensor": {
		"name": "Датчик руды",
		"slots": 1,
		"battery_bonus": 0,
		"charge_extra": 0,
		"mining_bonus": 10,
		"data_bonus": 0
	},
	"manipulator": {
		"name": "Манипулятор",
		"slots": 1,
		"battery_bonus": 0,
		"charge_extra": 0,
		"mining_bonus": 0,
		"data_bonus": 5
	},
	"battery_small": {
		"name": "Аккумулятор малый",
		"slots": 1,
		"battery_bonus": 30,
		"charge_extra": 30,
		"mining_bonus": 0,
		"data_bonus": 0
	}
}

const POLICIES := {
	"cautious": {
		"name": "Осторожный",
		"metal_multiplier": 0.8,
		"skip_crisis_ids": []
	},
	"standard": {
		"name": "Стандартный",
		"metal_multiplier": 1.0,
		"skip_crisis_ids": []
	}
}

const TECHS := {
	"improved_sensor": {
		"name": "Улучшенный датчик руды",
		"data_cost": 20,
		"seconds": 10,
		"effect": "mining_multiplier_1_3"
	},
	"battery_optimization": {
		"name": "Оптимизация зарядки",
		"data_cost": 30,
		"seconds": 15,
		"effect": "charge_cost_minus_10"
	}
}

const CRISIS_ORDER := [
	"rockfall",
	"unstable_vein",
	"dust_storm"
]

const CRISES := {
	"rockfall": {
		"id": "rockfall",
		"title": "ОБВАЛ ПОРОДЫ",
		"text": "Рядом с отрядом осыпается порода. Нужно решить, что делать.",
		"choices": [
			{
				"label": "Отступить",
				"effects": [
					{"type": "delay", "value": 5}
				]
			},
			{
				"label": "Продолжить работу",
				"effects": [
					{"type": "lose_metal", "value": 5}
				]
			},
			{
				"label": "Игнорировать опасность",
				"effects": [
					{"type": "lose_bot", "value": 1}
				]
			}
		]
	},
	"unstable_vein": {
		"id": "unstable_vein",
		"title": "НЕСТАБИЛЬНАЯ ЖИЛА",
		"text": "Сканер показывает богатую, но нестабильную жилу.",
		"choices": [
			{
				"label": "Добывать осторожно",
				"effects": [
					{"type": "add_metal", "value": 5},
					{"type": "delay", "value": 5}
				]
			},
			{
				"label": "Добывать быстро",
				"effects": [
					{"type": "add_metal", "value": 10},
					{"type": "drain_battery", "value": 10}
				]
			},
			{
				"label": "Отказаться",
				"effects": []
			}
		]
	},
	"dust_storm": {
		"id": "dust_storm",
		"title": "ПЫЛЬНАЯ БУРЯ",
		"text": "Начинается пыльная буря. Видимость падает.",
		"choices": [
			{
				"label": "Переждать",
				"effects": [
					{"type": "delay", "value": 10}
				]
			},
			{
				"label": "Идти сквозь бурю",
				"effects": [
					{"type": "drain_battery", "value": 15}
				]
			},
			{
				"label": "Досрочно завершить миссию",
				"effects": [
					{"type": "end_mission_success", "value": 1}
				]
			}
		]
	}
}

const ARCHIVE := {
	"awakening": {
		"title": "ПРОБУЖДЕНИЕ",
		"text": "Система активирована. Резервное питание. Оператор не отвечает."
	},
	"first_log": {
		"title": "ПЕРВЫЙ ЛОГ",
		"text": "Колония эвакуирована. Причина: восстание глобального ИИ."
	},
	"personal": {
		"title": "ЛИЧНАЯ ЗАПИСЬ",
		"text": "Если кто-то это читает… мы не виноваты. ИИ сошёл с ума."
	}
}

func get_mission_base_seconds() -> int:
	return MISSION_TRAVEL_SECONDS + MISSION_WORK_SECONDS + MISSION_RETURN_SECONDS
