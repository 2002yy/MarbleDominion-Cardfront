extends RefCounted
class_name CardfrontResourceState

var energy: int = 0
var parts: int = 0


func add_energy(value: int) -> void:
	energy = maxi(0, energy + int(value))


func add_parts(value: int) -> void:
	parts = maxi(0, parts + int(value))


func can_pay(energy_cost: int, parts_cost: int) -> bool:
	var safe_energy_cost: int = maxi(0, int(energy_cost))
	var safe_parts_cost: int = maxi(0, int(parts_cost))
	return energy >= safe_energy_cost and parts >= safe_parts_cost


func pay(energy_cost: int, parts_cost: int) -> bool:
	var safe_energy_cost: int = maxi(0, int(energy_cost))
	var safe_parts_cost: int = maxi(0, int(parts_cost))
	if not can_pay(safe_energy_cost, safe_parts_cost):
		return false
	energy -= safe_energy_cost
	parts -= safe_parts_cost
	return true


func snapshot() -> Dictionary:
	return {
		"energy": energy,
		"parts": parts,
	}


func restore(data: Dictionary) -> void:
	energy = maxi(0, int(data.get("energy", 0)))
	parts = maxi(0, int(data.get("parts", 0)))
