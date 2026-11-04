class_name UITheme
## Shared modern city interface theme. Terminal surfaces explicitly retain mono.
## Dark rounded surfaces, clear text hierarchy and restrained semantic accents.
## Built once and inherited by HUD, shop, character creation and dialogs.

const GREEN := Color("7ee787")
const CYAN := Color("7adfff")
const MAGENTA := Color("ff3ec8")
const INK := Color(0.008, 0.022, 0.04)   # near-black blue
const TEXT := Color("d8e2ec")

static var _theme: Theme
static var _mono: SystemFont
static var _ui: SystemFont


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


static func ui_font() -> SystemFont:
	if _ui == null:
		_ui = SystemFont.new()
		_ui.font_weight = 400
		_ui.font_names = PackedStringArray(["Helvetica Neue", "Helvetica", "Arial", "Segoe UI", "Noto Sans", "sans-serif"])
	return _ui


static func surface(radius := 18, color := Color("142035")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_border_width_all(1)
	style.border_color = Color(1, 1, 1, 0.07)
	style.set_content_margin_all(16)
	style.shadow_color = Color(0, 0, 0, 0.22)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	return style


static func _build() -> Theme:
	var t := Theme.new()
	t.default_font = ui_font()
	t.default_font_size = 17
	t.set_stylebox("normal", "Button", _btn(Color("24344c"), Color(1, 1, 1, 0.06)))
	t.set_stylebox("hover", "Button", _btn(Color("304761"), Color(CYAN, 0.35)))
	t.set_stylebox("pressed", "Button", _btn(Color("315c62"), Color("82efd3")))
	t.set_stylebox("disabled", "Button", _btn(Color("172236"), Color(1, 1, 1, 0.03)))
	t.set_stylebox("focus", "Button", _btn(Color(0, 0, 0, 0), CYAN))
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color("708097"))
	t.set_font_size("font_size", "Button", 17)
	t.set_stylebox("panel", "PanelContainer", surface())
	t.set_color("font_color", "Label", TEXT)
	var edit := surface(12, Color("0d1728"))
	edit.shadow_size = 0
	t.set_stylebox("normal", "LineEdit", edit)
	var focused := edit.duplicate()
	focused.border_color = Color("82efd3")
	t.set_stylebox("focus", "LineEdit", focused)
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("caret_color", "LineEdit", Color("82efd3"))
	return t


static func _btn(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(12)
	sb.set_border_width_all(1)
	sb.border_color = border
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb
