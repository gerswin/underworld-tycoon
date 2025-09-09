extends Node

signal heat_changed(new_heat: float)
signal raid_triggered(targets: Array)
signal audit_triggered()
signal investigation_started()

var global_heat: float = 0.0
var heat_threshold_raid: float = 70.0
var heat_threshold_audit: float = 50.0
var heat_decay_rate: float = 1.0  # Decay más rápido para mejor balance

var heat_sources: Dictionary = {
	"business_operation": 0.1,
	"laundering": 0.3,
	"violence": 5.0,
	"scandal": 10.0,
	"overspending": 2.0
}

var active_investigations: Array = []

func _ready() -> void:
	print("RiskSystem initialized")
	set_process(true)

func _process(delta: float) -> void:
	if GameManager.current_state == GameManager.GameState.PLAYING:
		decay_heat(delta)
		check_heat_thresholds()

func add_heat(amount: float, source: String = "unknown") -> void:
	global_heat = min(100.0, global_heat + amount)
	heat_changed.emit(global_heat)
	
	if source in heat_sources:
		print("Heat increased by ", amount, " from ", source)

func reduce_heat(amount: float) -> void:
	global_heat = max(0.0, global_heat - amount)
	heat_changed.emit(global_heat)

func decay_heat(delta: float) -> void:
	if global_heat > 0:
		reduce_heat(heat_decay_rate * delta)

func check_heat_thresholds() -> void:
	if global_heat >= heat_threshold_raid:
		trigger_raid()
	elif global_heat >= heat_threshold_audit:
		if randf() < 0.01:  # 1% chance per frame when over audit threshold
			trigger_audit()

func trigger_raid() -> void:
	var businesses = ShadowOps.get_active_businesses()
	if businesses.is_empty():
		return
	
	var targets = []
	var num_targets = min(3, businesses.size())
	
	for i in range(num_targets):
		var random_business = businesses[randi() % businesses.size()]
		targets.append(random_business)
		ShadowOps.raid_business(random_business["id"])
	
	raid_triggered.emit(targets)
	reduce_heat(20.0)  # Las redadas reducen el heat
	print("RAID! ", num_targets, " businesses shut down")

func trigger_audit() -> void:
	audit_triggered.emit()
	print("AUDIT! Financial investigation started")
	
	var money_lost = Economy.clean_money * 0.1
	Economy.spend_clean_money(money_lost)
	add_heat(5.0, "scandal")

func bribe_officials(amount: float) -> bool:
	if Economy.spend_dirty_money(amount):
		var heat_reduction = amount / 1000.0  # $1000 = 1 point of heat
		reduce_heat(heat_reduction)
		return true
	return false

func start_investigation(target: String) -> void:
	active_investigations.append({
		"target": target,
		"progress": 0.0,
		"danger_level": randf_range(1.0, 5.0)
	})
	investigation_started.emit()

func calculate_district_heat_contribution(district_id: int) -> float:
	var district = CitySim.get_district_info(district_id)
	return district.get("heat", 0.0) * 0.1  # District heat contributes to global

func get_risk_assessment() -> Dictionary:
	return {
		"global_heat": global_heat,
		"raid_risk": (global_heat / heat_threshold_raid) * 100.0,
		"audit_risk": (global_heat / heat_threshold_audit) * 100.0,
		"active_investigations": active_investigations.size(),
		"status": get_risk_status()
	}

func get_risk_status() -> String:
	if global_heat < 30:
		return "Low"
	elif global_heat < 50:
		return "Moderate"
	elif global_heat < 70:
		return "High"
	else:
		return "Critical"

func get_save_data() -> Dictionary:
	return {
		"global_heat": global_heat,
		"active_investigations": active_investigations
	}

func load_save_data(data: Dictionary) -> void:
	global_heat = data.get("global_heat", 0.0)
	active_investigations = data.get("active_investigations", [])
	heat_changed.emit(global_heat)