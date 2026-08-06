class_name UiTheme

## Visual compartilhado do MVP — tom dungeon/ouro, sem cinza default.

const BG_DARK := Color(0.08, 0.07, 0.1, 0.94)
const BG_CARD := Color(0.14, 0.12, 0.16, 0.98)
const BG_CARD_HOVER := Color(0.22, 0.17, 0.12, 1.0)
const BORDER_GOLD := Color(0.78, 0.62, 0.28, 0.95)
const BORDER_DIM := Color(0.45, 0.38, 0.28, 0.7)
const TEXT_TITLE := Color(1.0, 0.9, 0.55, 1.0)
const TEXT_BODY := Color(0.9, 0.88, 0.82, 1.0)
const TEXT_MUTED := Color(0.7, 0.66, 0.58, 1.0)
const ACCENT_RED := Color(0.85, 0.25, 0.22, 1.0)

const FONT_TITLE_PATH := "res://assets/fonts/Cinzel-Bold.ttf"
const FONT_BODY_PATH := "res://assets/fonts/PixelifySans-Regular.ttf"

static var _title_font: Font
static var _body_font: Font


static func title_font() -> Font:
	if _title_font == null:
		_title_font = load(FONT_TITLE_PATH) as Font
	return _title_font


static func body_font() -> Font:
	if _body_font == null:
		_body_font = load(FONT_BODY_PATH) as Font
	return _body_font


static func apply_label(label: Label, size: int, color: Color = TEXT_BODY, use_title_font: bool = false) -> void:
	var font := title_font() if use_title_font else body_font()
	if font:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)


static func panel_style(fill: Color = BG_DARK, border: Color = BORDER_GOLD, radius: float = 10.0, border_w: int = 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.set_corner_radius_all(int(radius))
	s.set_border_width_all(border_w)
	s.border_color = border
	s.content_margin_left = 16
	s.content_margin_top = 14
	s.content_margin_right = 16
	s.content_margin_bottom = 14
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 4)
	return s


static func button_styles() -> Dictionary:
	var normal := panel_style(BG_CARD, BORDER_DIM, 8.0, 2)
	var hover := panel_style(BG_CARD_HOVER, BORDER_GOLD, 8.0, 2)
	var pressed := panel_style(Color(0.18, 0.14, 0.1, 1.0), BORDER_GOLD, 8.0, 3)
	var focus := hover.duplicate()
	return {
		"normal": normal,
		"hover": hover,
		"pressed": pressed,
		"focus": focus,
		"disabled": panel_style(Color(0.1, 0.1, 0.12, 0.7), Color(0.3, 0.3, 0.32, 0.5), 8.0, 1),
	}


static func apply_button(btn: Button, font_size: int = 22) -> void:
	var styles := button_styles()
	for key in styles.keys():
		btn.add_theme_stylebox_override(str(key), styles[key])
	var font := body_font()
	if font:
		btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", TEXT_BODY)
	btn.add_theme_color_override("font_hover_color", TEXT_TITLE)
	btn.add_theme_color_override("font_pressed_color", TEXT_TITLE)
	btn.add_theme_color_override("font_focus_color", TEXT_TITLE)


static func apply_panel(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", panel_style())
