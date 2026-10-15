class_name TtStampFlash
extends Control
## Grote stempel die over het scherm vliegt (bv. "Figuur 14 ✓" in 1-2): slaat neer met squash, blijft even, vervaagt.

var text := ""
var s := 3.0
var a := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween()
	tw.tween_property(self, "a", 1.0, 0.12)
	tw.parallel().tween_property(self, "s", 1.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): _scene_shake(5.0, 0.2))
	tw.tween_interval(1.1)
	tw.tween_property(self, "a", 0.0, 0.4)
	tw.tween_callback(queue_free)


func _process(_d: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2(960, 420), -0.12, Vector2(s, s))
	var w := TtPal.UI_BOLD.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 72).x + 80
	draw_style_box(TtPal.sb(Color(TtPal.PAPER, 0.85 * a), 24), Rect2(-w / 2.0, -70, w, 140))
	var col := Color(TtPal.STAMP, 0.95 * a)
	TtPal.ring(self, Rect2(-w / 2.0 + 10, -60, w - 20, 120), 20, col, 6)
	TtPal.ring(self, Rect2(-w / 2.0 + 20, -50, w - 40, 100), 14, col, 2)
	TtPal.text_c(self, TtPal.UI_BOLD, Vector2.ZERO, text, 72, col)


func _scene_shake(px: float, dur: float) -> void:
	var sc := get_tree().current_scene
	if sc and sc.has_method("shake"):
		sc.shake(px, dur)
