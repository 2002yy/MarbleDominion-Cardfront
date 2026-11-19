extends SceneTree

const PanelScene = preload("res://scenes/ui/cardfront/CardfrontThreeChoicePanel.tscn")
const Manifest = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")

const VIEWPORTS: Array[Vector2] = [
	Vector2(1120.0, 720.0),
	Vector2(960.0, 600.0),
	Vector2(760.0, 540.0),
]
const LONG_DESCRIPTION_IDS: Array[String] = [
	Manifest.UPGRADE_HEAVY_CHARGE,
	Manifest.UPGRADE_SAPPER_UNIT,
	Manifest.UPGRADE_GATE_COLOSSUS,
]
const DIRECTOR_SIGNALS: Array[String] = [
	"countdown_updated", "draft_opened", "draft_time_updated",
	"strongholds_sampled", "choice_locked", "choices_revealed",
	"volley_launched", "director_stopped",
]

var _assert: TestAssert


class FakePhaseController:
	extends RefCounted
	var time_remaining: float = 4.0


class FakeDirector:
	extends Node

	signal countdown_updated(time_remaining, round_number, player_state)
	signal draft_opened(player_offer, ai_offer, timeout_seconds, round_number)
	signal draft_time_updated(time_remaining, timeout_seconds)
	signal strongholds_sampled(status_snapshot)
	signal choice_locked(owner_id, upgrade_id, automatic)
	signal choices_revealed(player_definition, ai_definition, resolution_results)
	signal volley_launched(plans, issued_intents)
	signal director_stopped

	var phase_controller := FakePhaseController.new()
	var round_number: int = 0
	var run_state = RunStateScript.new()

	func _ready() -> void:
		run_state.setup(CardfrontRules.PLAYER_FACTION)

	func get_run_state(_owner_id: int):
		return run_state

	func get_stronghold_status(_owner_id: int) -> Dictionary:
		return {}

	func select_player_upgrade(_upgrade_id: String) -> bool:
		return true


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontDraftViewportUsabilityTest] Checking real card and control bounds")
	await process_frame
	for viewport_size in VIEWPORTS:
		await _check_viewport(viewport_size)
	_assert.report("[CardfrontDraftViewportUsabilityTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _check_viewport(viewport_size: Vector2) -> void:
	var director := FakeDirector.new()
	root.add_child(director)
	var panel = PanelScene.instantiate()
	root.add_child(panel)
	await process_frame
	_assert.that(panel.setup(director, viewport_size), "%s: setup succeeds" % viewport_size)
	_assert.that(panel.setup(director, viewport_size), "%s: repeated setup succeeds" % viewport_size)

	var offers: Array = []
	for upgrade_id in LONG_DESCRIPTION_IDS:
		offers.append(Manifest.get_definition(upgrade_id))
	director.draft_opened.emit(offers, [], 8.0, 1)
	await process_frame
	await process_frame

	_assert_inside(panel.choice_shell.get_global_rect(), viewport_size, "choice shell")
	_assert_inside(panel._peek_button.get_global_rect(), viewport_size, "battlefield peek")
	_assert_inside(panel.upgrade_history_button.get_global_rect(), viewport_size, "upgrade history")
	_assert.that(
		not panel._peek_button.get_global_rect().intersects(panel.upgrade_history_button.get_global_rect()),
		"%s: peek and history buttons cannot block each other" % viewport_size
	)
	var cards: Array = panel.get_choice_cards()
	_assert.eq(cards.size(), 3, "%s: exactly three choices" % viewport_size)
	for index in range(cards.size()):
		var card = cards[index]
		_assert_inside(card.get_global_rect(), viewport_size, "choice %d" % index)
		_assert.that(
			card.description_label.get_global_rect().end.y <= card.lock_label.get_global_rect().position.y - 2.0,
			"%s: choice %d description cannot overlap its selected label" % [viewport_size, index]
		)
		_assert.that(
			card.description_label.get_global_rect().end.y < card.get_global_rect().end.y,
			"%s: choice %d description must stay inside the card" % [viewport_size, index]
		)
		if index > 0:
			_assert.that(
				not cards[index - 1].get_global_rect().intersects(card.get_global_rect()),
				"%s: choice cards must not overlap" % viewport_size
			)
	for signal_name in DIRECTOR_SIGNALS:
		_assert.eq(director.get_signal_connection_list(signal_name).size(), 1, "%s: %s connects once" % [viewport_size, signal_name])

	TestFixtures.cleanup_node(panel)
	TestFixtures.cleanup_node(director)
	await process_frame
	await process_frame


func _assert_inside(rect: Rect2, viewport_size: Vector2, label: String) -> void:
	_assert.that(
		rect.position.x >= -0.5 and rect.position.y >= -0.5
		and rect.end.x <= viewport_size.x + 0.5
		and rect.end.y <= viewport_size.y + 0.5,
		"%s: %s must fit the viewport, got %s" % [viewport_size, label, rect]
	)
