extends RefCounted
class_name SupportCaptureAggregator

const TuningScript = preload("res://scripts/cardfront/support/capture/SupportCaptureTuning.gd")


static func aggregate(contributors: Array) -> Dictionary:
	var weights: Array[float] = []
	for contributor in contributors:
		if contributor == null or not contributor.has_method("effective_weight"):
			continue
		var weight: float = maxf(0.0, float(contributor.effective_weight()))
		if weight > 0.0:
			weights.append(weight)
	weights.sort()
	weights.reverse()

	var raw_weight: float = 0.0
	var diminished_power: float = 0.0
	for index in weights.size():
		var weight: float = weights[index]
		raw_weight += weight
		diminished_power += weight * TuningScript.contributor_multiplier(index)

	var resolved_power: float = minf(diminished_power, TuningScript.MAX_CAPTURE_POWER)
	return {
		"raw_weight": raw_weight,
		"resolved_capture_power": resolved_power,
		"contributor_count": weights.size(),
		"capped_or_diminished": weights.size() > 1 or resolved_power < raw_weight,
	}
