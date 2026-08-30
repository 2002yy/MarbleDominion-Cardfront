extends SceneTree

const PanelScene = preload("res://scenes/ui/cardfront/CardfrontThreeChoicePanel.tscn")
const UpgradeManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")

const DESKTOP_VIEWPORT := Vector2(1120.0, 720.0)
const NARROW_VIEWPORT := Vector2(760.0, 540.0)
const OFFER_IDS: Array[String] = [
	UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5,
	UpgradeManifestScript.UPGRADE_ATTACK_LEVEL_PLUS_1,
	UpgradeManifestScript.UPGRADE_FRONTLINE_REPAIR,
]
const DIRECTOR_SIGNALS: Array[String] = [
	"countdown_updated",
	"draft_opened",
	"draft_time_updated",
	"strongholds_sampled",
	"choice_locked",
	"choices_revealed",
	"volley_launched",
	"director_stopped",
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
		run_state.selected_upgrade_levels[UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5] = 2
		run_state.selected_upgrade_levels[UpgradeManifestScript.UPGRADE_BUILDING_VOLLEY] = 1
		run_state.next_volley_bonus = 5

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
	print("[CardfrontDraftGeometrySnapshotTest] Starting P0-07A1 geometry snapshot")
	await process_frame

	await _test_geometry_snapshot(DESKTOP_VIEWPORT, Vector2(88.0, 116.0), "desktop")
	await _test_geometry_snapshot(NARROW_VIEWPORT, Vector2(-92.0, 116.0), "narrow")

	_assert.report("[CardfrontDraftGeometrySnapshotTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_geometry_snapshot(viewport_size: Vector2, expected_shell_position: Vector2, label: String) -> void:
	var director := FakeDirector.new()
	get_root().add_child(director)
	var panel = PanelScene.instantiate()
	get_root().add_child(panel)
	await process_frame

	_assert.that(panel.setup(director, viewport_size), "%s: panel setup succeeds" % label)
	# Repeating setup with the same production director is part of the audited lifecycle.
	_assert.that(panel.setup(director, viewport_size), "%s: repeated same-director setup succeeds" % label)
	var offer: Array = []
	for upgrade_id in OFFER_IDS:
		offer.append(UpgradeManifestScript.get_definition(upgrade_id))
	director.draft_opened.emit(offer, [], 8.0, 1)
	await process_frame
	await process_frame

	_assert.eq(panel.draft_root.position, Vector2.ZERO, "%s: DraftRoot position snapshot" % label)
	_assert.eq(panel.draft_root.size, viewport_size, "%s: DraftRoot size snapshot" % label)
	_assert.eq(_anchors(panel.draft_root), Vector4.ZERO, "%s: DraftRoot anchors snapshot" % label)
	_assert.eq(_offsets(panel.draft_root), Vector4(0.0, 0.0, viewport_size.x, viewport_size.y), "%s: DraftRoot offsets snapshot" % label)

	_assert.eq(panel.choice_shell.position, expected_shell_position, "%s: ChoiceShell position snapshot" % label)
	_assert.eq(panel.choice_shell.size, Vector2(944.0, 488.0), "%s: ChoiceShell size snapshot" % label)
	_assert.eq(_anchors(panel.choice_shell), Vector4.ZERO, "%s: ChoiceShell anchors snapshot" % label)
	_assert.eq(_offsets(panel.choice_shell), Vector4(expected_shell_position.x, 116.0, expected_shell_position.x + 944.0, 604.0), "%s: ChoiceShell offsets snapshot" % label)

	_assert.eq(panel.card_box.position, Vector2(18.0, 124.0), "%s: CardBox position snapshot" % label)
	_assert.eq(panel.card_box.size, Vector2(908.0, 266.0), "%s: CardBox size snapshot" % label)
	_assert.eq(_anchors(panel.card_box), Vector4.ZERO, "%s: CardBox anchors snapshot" % label)
	_assert.eq(_offsets(panel.card_box), Vector4(18.0, 124.0, 926.0, 390.0), "%s: CardBox offsets snapshot" % label)

	var cards: Array = panel.get_choice_cards()
	_assert.eq(cards.size(), 3, "%s: exactly three cards exist" % label)
	for index in range(mini(cards.size(), OFFER_IDS.size())):
		var card = cards[index]
		_assert.eq(str(card.upgrade_id), OFFER_IDS[index], "%s: card %d ID snapshot" % [label, index])
		_assert.eq(card.position, Vector2(14.0 + 300.0 * index, 0.0), "%s: card %d position snapshot" % [label, index])
		_assert.eq(card.size, Vector2(280.0, 266.0), "%s: card %d rect snapshot" % [label, index])

	var peek_button: Button = panel.get_node("DraftRoot/PeekChrome/PeekButton")
	_assert.eq(str(peek_button.get_parent().get_path()), str(panel.peek_chrome.get_path()), "%s: PeekButton stable parent path" % label)
	var expected_peek_x: float = minf(expected_shell_position.x + 812.0, viewport_size.x - 128.0)
	_assert.eq(peek_button.position, Vector2(expected_peek_x, 124.0), "%s: PeekButton position snapshot" % label)
	_assert.eq(peek_button.size, Vector2(120.0, 32.0), "%s: PeekButton size snapshot" % label)
	_assert.that(peek_button.get_global_rect().end.x <= viewport_size.x - 8.0, "%s: PeekButton stays inside the right viewport edge" % label)
	_assert.eq(panel.peek_chrome.position, Vector2.ZERO, "%s: PeekChrome position snapshot" % label)
	_assert.eq(panel.peek_chrome.size, viewport_size, "%s: PeekChrome size snapshot" % label)
	_assert.that(not panel.is_upgrade_history_open_for_test(), "%s: upgrade history starts collapsed" % label)
	_assert.eq(panel.upgrade_history_button.text, "本局强化 · 2", "%s: upgrade history edge control shows distinct selected count" % label)
	panel._toggle_upgrade_history()
	_assert.that(panel.is_upgrade_history_open_for_test(), "%s: upgrade history can open during Draft or battle" % label)
	var history_texts: Array[String] = panel.get_upgrade_history_texts_for_test()
	_assert.eq(history_texts.size(), 2, "%s: upgrade history lists every selected upgrade identity" % label)
	_assert.that(history_texts[0].contains("增援齐射  Lv2") and history_texts[0].contains("下轮待结算"), "%s: upgrade history uses Selected Level and pending state" % label)
	_assert.that(history_texts[1].contains("建筑齐射  Lv1") and history_texts[1].contains("本局生效"), "%s: upgrade history shows persistent building state" % label)
	panel._close_upgrade_history()

	_assert.eq(panel.dimmer.position, Vector2.ZERO, "%s: Dimmer position snapshot" % label)
	_assert.eq(panel.dimmer.size, viewport_size, "%s: Dimmer size snapshot" % label)
	_assert.eq(_anchors(panel.dimmer), Vector4.ZERO, "%s: Dimmer anchors snapshot" % label)
	_assert.eq(_offsets(panel.dimmer), Vector4(0.0, 0.0, viewport_size.x, viewport_size.y), "%s: Dimmer offsets snapshot" % label)

	for signal_name in DIRECTOR_SIGNALS:
		_assert.eq(director.get_signal_connection_list(signal_name).size(), 1, "%s: %s has one panel connection" % [label, signal_name])

	print("[CardfrontDraftGeometrySnapshotTest] %s viewport=%s root=%s shell=%s card_box=%s cards=%s peek_parent=%s peek_rect=%s dimmer=%s" % [
		label,
		str(viewport_size),
		str(Rect2(panel.draft_root.position, panel.draft_root.size)),
		str(Rect2(panel.choice_shell.position, panel.choice_shell.size)),
		str(Rect2(panel.card_box.position, panel.card_box.size)),
		str(OFFER_IDS),
		str(peek_button.get_parent().get_path()),
		str(Rect2(peek_button.position, peek_button.size)),
		str(Rect2(panel.dimmer.position, panel.dimmer.size)),
	])

	TestFixtures.cleanup_node(panel)
	TestFixtures.cleanup_node(director)
	await process_frame
	await process_frame


func _anchors(control: Control) -> Vector4:
	return Vector4(control.anchor_left, control.anchor_top, control.anchor_right, control.anchor_bottom)


func _offsets(control: Control) -> Vector4:
	return Vector4(control.offset_left, control.offset_top, control.offset_right, control.offset_bottom)
