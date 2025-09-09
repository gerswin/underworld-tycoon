extends Node

signal money_changed(clean: float, dirty: float)
signal transaction_completed(amount: float, is_clean: bool)
signal laundering_completed(amount: float)

var clean_money: float = 75000.0  # Presupuesto inicial más alto para testing
var dirty_money: float = 20000.0  # Dinero inicial sucio para empezar construyendo
var laundering_rate: float = 0.3  # 30% de eficiencia de lavado
var max_laundering_per_cycle: float = 10000.0

var income_multipliers: Dictionary = {
	"festival": 1.5,
	"crisis": 0.7,
	"normal": 1.0
}

func _ready() -> void:
	print("Economy system initialized")
	print("Starting funds - Clean: $", clean_money, " Dirty: $", dirty_money)

func add_clean_money(amount: float) -> void:
	clean_money += amount
	money_changed.emit(clean_money, dirty_money)
	transaction_completed.emit(amount, true)

func add_dirty_money(amount: float) -> void:
	dirty_money += amount
	money_changed.emit(clean_money, dirty_money)
	transaction_completed.emit(amount, false)

func spend_clean_money(amount: float) -> bool:
	if clean_money >= amount:
		clean_money -= amount
		money_changed.emit(clean_money, dirty_money)
		return true
	return false

func spend_dirty_money(amount: float) -> bool:
	if dirty_money >= amount:
		dirty_money -= amount
		money_changed.emit(clean_money, dirty_money)
		return true
	return false

func launder_money(amount: float) -> float:
	var to_launder = min(amount, dirty_money, max_laundering_per_cycle)
	if to_launder > 0:
		var laundered = to_launder * laundering_rate
		dirty_money -= to_launder
		clean_money += laundered
		money_changed.emit(clean_money, dirty_money)
		laundering_completed.emit(laundered)
		return laundered
	return 0.0

func calculate_business_income(base_income: float, district_demand: float, local_heat: float, is_night: bool = false, business_type: String = "bar") -> float:
	var income = base_income * district_demand * (1.0 - local_heat * 0.1)
	
	match business_type:
		"club":
			if is_night:
				income *= 2.0
		"workshop":
			income *= 1.5  # Talleres generan más pero son más riesgosos
	
	var current_multiplier = income_multipliers.get("normal", 1.0)
	income *= current_multiplier
	
	return income

func apply_event_multiplier(event_type: String) -> void:
	if event_type in income_multipliers:
		income_multipliers["current"] = income_multipliers[event_type]

func get_total_wealth() -> float:
	return clean_money + dirty_money

func get_financial_report() -> Dictionary:
	return {
		"clean_money": clean_money,
		"dirty_money": dirty_money,
		"total_wealth": get_total_wealth(),
		"laundering_efficiency": laundering_rate * 100,
		"max_laundering": max_laundering_per_cycle
	}

func set_laundering_capacity(ngo_level: int) -> void:
	laundering_rate = 0.3 + (ngo_level * 0.1)
	max_laundering_per_cycle = 10000.0 + (ngo_level * 5000.0)

func get_save_data() -> Dictionary:
	return {
		"clean_money": clean_money,
		"dirty_money": dirty_money,
		"laundering_rate": laundering_rate,
		"max_laundering_per_cycle": max_laundering_per_cycle
	}

func load_save_data(data: Dictionary) -> void:
	clean_money = data.get("clean_money", 50000.0)
	dirty_money = data.get("dirty_money", 0.0)
	laundering_rate = data.get("laundering_rate", 0.3)
	max_laundering_per_cycle = data.get("max_laundering_per_cycle", 10000.0)
	money_changed.emit(clean_money, dirty_money)