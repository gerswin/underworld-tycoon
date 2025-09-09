extends Node

signal business_built(business: Dictionary)
signal business_raided(business: Dictionary)
signal production_completed(product: String, amount: int)

var businesses: Array[Dictionary] = []
var products_inventory: Dictionary = {
	"illegal_goods": 0,
	"contraband": 0
}

var business_types: Dictionary = {
	"bar": {
		"cost": 8000.0,  # Más barato para testing
		"base_income": 800.0,  # Más ingresos para que sea más visible
		"heat_generation": 1.0,
		"build_time": 5.0,
		"type": "front"
	},
	"club": {
		"cost": 18000.0,  # Más accesible
		"base_income": 2000.0,  # Más rentable de noche
		"heat_generation": 3.0,
		"build_time": 10.0,
		"type": "front"
	},
	"workshop": {
		"cost": 15000.0,
		"base_income": 800.0,
		"heat_generation": 2.0,
		"build_time": 7.0,
		"type": "production",
		"produces": "illegal_goods",
		"production_rate": 10
	},
	"ngo": {
		"cost": 30000.0,
		"base_income": 0.0,
		"heat_generation": -1.0,  # NGOs reducen heat
		"build_time": 15.0,
		"type": "laundering",
		"laundering_bonus": 0.1
	}
}

func _ready() -> void:
	print("ShadowOps system initialized")

func can_build_business(type: String, money: float) -> bool:
	if type in business_types:
		return money >= business_types[type]["cost"]
	return false

func build_business(type: String, district_id: int, position: Vector2) -> Dictionary:
	if type in business_types:
		var business = {
			"id": businesses.size(),
			"type": type,
			"district_id": district_id,
			"position": position,
			"level": 1,
			"is_active": true,
			"heat_accumulated": 0.0,
			"income_generated": 0.0,
			"data": business_types[type].duplicate()
		}
		businesses.append(business)
		business_built.emit(business)
		return business
	return {}

func calculate_business_income(business: Dictionary, is_night: bool) -> float:
	if !business["is_active"]:
		return 0.0
	
	var base_income = business["data"]["base_income"]
	var district_info = CitySim.get_district_info(business["district_id"])
	var district_demand = district_info.get("demand", 1.0)
	var local_heat = district_info.get("heat", 0.0) / 100.0
	
	var income = Economy.calculate_business_income(
		base_income,
		district_demand,
		local_heat,
		is_night,
		business["type"]
	)
	
	business["income_generated"] += income
	return income

func process_production(delta: float) -> void:
	for business in businesses:
		if business["is_active"] and business["data"]["type"] == "production":
			var produces = business["data"].get("produces", "")
			var rate = business["data"].get("production_rate", 0) * delta
			if produces != "":
				products_inventory[produces] += rate
				production_completed.emit(produces, rate)

func raid_business(business_id: int) -> void:
	for business in businesses:
		if business["id"] == business_id:
			business["is_active"] = false
			business_raided.emit(business)
			break

func sell_products(product: String, amount: int) -> float:
	if product in products_inventory and products_inventory[product] >= amount:
		products_inventory[product] -= amount
		var price_per_unit = 100.0  # Base price
		return amount * price_per_unit
	return 0.0

func get_active_businesses() -> Array:
	var active = []
	for business in businesses:
		if business["is_active"]:
			active.append(business)
	return active

func get_business_count_by_type(type: String) -> int:
	var count = 0
	for business in businesses:
		if business["type"] == type and business["is_active"]:
			count += 1
	return count

func upgrade_business(business_id: int) -> bool:
	for business in businesses:
		if business["id"] == business_id:
			var upgrade_cost = business["data"]["cost"] * business["level"] * 0.5
			if Economy.spend_dirty_money(upgrade_cost):
				business["level"] += 1
				business["data"]["base_income"] *= 1.3
				return true
	return false

func get_total_laundering_bonus() -> float:
	var bonus = 0.0
	for business in businesses:
		if business["is_active"] and business["data"]["type"] == "laundering":
			bonus += business["data"].get("laundering_bonus", 0.0)
	return bonus

func get_save_data() -> Dictionary:
	return {
		"businesses": businesses,
		"products_inventory": products_inventory
	}

func load_save_data(data: Dictionary) -> void:
	businesses = data.get("businesses", [])
	products_inventory = data.get("products_inventory", {
		"illegal_goods": 0,
		"contraband": 0
	})