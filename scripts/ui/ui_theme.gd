class_name UITheme
## One shared cyberpunk-terminal theme so every button, panel and label looks
## consistent. Design language: neon-on-black — monospace type, near-black
## translucent fills, 1px neon borders, squared corners. One accent color per
## meaning: GREEN = actions/primary, CYAN = info/secondary, MAGENTA = alerts.
## Built once in code, applied to each UI root (children inherit).

const GREEN := Color("7ee787")
const CYAN := Color("7adfff")
const MAGENTA := Color("ff3ec8")
const INK := Color(0.008, 0.022, 0.04)   # near-black blue
const TEXT := Color("d8e2ec")

static var _theme: Theme
static var _mono: SystemFont


# Monospace stack — resolves to whatever the OS has (Menlo on macOS/iOS,
# Consolas on Windows, a droid mono on Android). The terminal look for free.
static func mono_font() -> SystemFont:
	if _mono == null:
		_mono = SystemFont.new()
		_mono.font_names = PackedStringArray(
			["Menlo", "Consolas", "JetBrains Mono", "Courier New", "monospace"])
	return _mono


static func theme() -> Theme:
	if _theme == null:
		_theme = _build()
	return _theme


static func _build() -> Theme:
	var t := Theme.new()
	t.default_font = mono_font()
	t.default_font_size = 15

	t.set_stylebox("normal", "Button", _btn(Color(GREEN, 0.05), Color(GREEN, 0.5)))
	t.set_stylebox("hover", "Button", _btn(Color(GREEN, 0.13), Color(GREEN, 0.85)))
	t.set_stylebox("pressed", "Button", _btn(Color(GREEN, 0.28), GREEN))
	t.set_stylebox("disabled", "Button", _btn(Color(1, 1, 1, 0.02), Color(0.4, 0.45, 0.55, 0.3)))
	t.set_color("font_color", "Button", GREEN)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(0.4, 0.45, 0.55))
	t.set_font_size("font_size", "Button", 16)

	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(INK, 0.95)
	panel.set_corner_radius_all(3)
	panel.set_border_width_all(1)
	panel.border_color = Color(CYAN, 0.22)
	panel.set_content_margin_all(14)
	t.set_stylebox("panel", "PanelContainer", panel)

	t.set_color("font_color", "Label", TEXT)

	var edit := StyleBoxFlat.new()
	edit.bg_color = Color(INK, 0.9)
	edit.set_corner_radius_all(3)
	edit.set_border_width_all(1)
	edit.border_color = Color(GREEN, 0.4)
	edit.set_content_margin_all(10)
	t.set_stylebox("normal", "LineEdit", edit)
	t.set_color("font_color", "LineEdit", GREEN)
	t.set_color("caret_color", "LineEdit", GREEN)

	return t


static func _btn(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(3)
	sb.set_border_width_all(1)
	sb.border_color = border
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb
