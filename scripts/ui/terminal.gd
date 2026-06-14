extends Panel
## The in-game hacking terminal. A command-line minigame against fictional,
## locally simulated targets — no real networking happens anywhere in here.
## Mobile-friendly: quick-command buttons, and target names in the output are
## tappable links (inspect -> exploit -> install_bot).

const C_GREEN := "#7ee787"
const C_DIM := "#5a7a5a"
const C_RED := "#ff6b6b"
const C_YEL := "#ffd166"
const C_CYAN := "#7adfff"

var _output: RichTextLabel
var _cmd_input: LineEdit
var _stats_label: Label
var _booted := false


func _ready() -> void:
	theme = UITheme.theme()
	_build_ui()
	GameState.stats_changed.connect(_refresh_stats)
	_refresh_stats()


func open() -> void:
	visible = true
	GameState.lock_ui()
	if not _booted:
		_booted = true
		_banner()
	if not (OS.has_feature("android") or OS.has_feature("ios")):
		_cmd_input.grab_focus()


func close_terminal() -> void:
	_cmd_input.release_focus()
	visible = false
	GameState.unlock_ui()


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_terminal()
		get_viewport().set_input_as_handled()


# --- UI construction -------------------------------------------------------

func _build_ui() -> void:
	var mono := SystemFont.new()
	mono.font_names = PackedStringArray(["Menlo", "Consolas", "DejaVu Sans Mono", "Courier New"])

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("0a100b")
	add_theme_stylebox_override("panel", bg)

	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 14)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)

	var title := Label.new()
	title.text = "pwn-shell v0.1"
	title.add_theme_font_override("font", mono)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(C_CYAN))
	header.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_stats_label = Label.new()
	_stats_label.add_theme_font_override("font", mono)
	_stats_label.add_theme_font_size_override("font_size", 15)
	_stats_label.add_theme_color_override("font_color", Color(C_DIM))
	header.add_child(_stats_label)

	var exit_btn := Button.new()
	exit_btn.text = "EXIT"
	exit_btn.focus_mode = Control.FOCUS_NONE
	exit_btn.custom_minimum_size = Vector2(80, 44)
	exit_btn.pressed.connect(close_terminal)
	header.add_child(exit_btn)

	_output = RichTextLabel.new()
	_output.bbcode_enabled = true
	_output.scroll_following = true
	_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_output.add_theme_font_override("normal_font", mono)
	_output.add_theme_font_size_override("normal_font_size", 17)
	_output.add_theme_color_override("default_color", Color(C_GREEN))
	_output.meta_clicked.connect(_on_meta_clicked)
	vbox.add_child(_output)

	var quick := HBoxContainer.new()
	quick.add_theme_constant_override("separation", 8)
	vbox.add_child(quick)
	for cmd in ["help", "scan", "collect", "clear"]:
		var b := Button.new()
		b.text = cmd
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 52)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_on_submit.bind(cmd))
		quick.add_child(b)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	vbox.add_child(row)

	var prompt := Label.new()
	prompt.text = "$>"
	prompt.add_theme_font_override("font", mono)
	prompt.add_theme_color_override("font_color", Color(C_GREEN))
	row.add_child(prompt)

	_cmd_input = LineEdit.new()
	_cmd_input.placeholder_text = "type a command..."
	_cmd_input.custom_minimum_size = Vector2(0, 52)
	_cmd_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cmd_input.add_theme_font_override("font", mono)
	_cmd_input.text_submitted.connect(_on_submit)
	row.add_child(_cmd_input)

	var run := Button.new()
	run.text = "RUN"
	run.focus_mode = Control.FOCUS_NONE
	run.custom_minimum_size = Vector2(90, 52)
	run.pressed.connect(func() -> void: _on_submit(_cmd_input.text))
	row.add_child(run)


func _refresh_stats() -> void:
	var line := "CPU %d/%d  E %d/%d  HEAT %d[%s]  $%d" % [
		GameState.cpu, GameState.max_cpu, GameState.energy, GameState.max_energy,
		GameState.heat, GameState.heat_tier_name(), GameState.cash,
	]
	if GameState.is_fatigued():
		line += "  TIRED"
	_stats_label.text = line
	var alert := GameState.is_fatigued() or GameState.heat_penalty() > 0.0
	_stats_label.add_theme_color_override("font_color",
		Color(C_YEL) if alert else Color(C_DIM))


# --- Output helpers --------------------------------------------------------

func _say(text: String, color: String = C_GREEN) -> void:
	_output.append_text("[color=%s]%s[/color]\n" % [color, text])


func _link(action: String, target_id: String, label: String, color: String) -> String:
	return "[color=%s][url=%s:%s]%s[/url][/color]" % [color, action, target_id, label]


func _banner() -> void:
	_say("pwn-shell v0.1 — borrowed wifi, borrowed time", C_CYAN)
	_say("type 'help' or tap the buttons below", C_DIM)
	_say("")


func _on_meta_clicked(meta: Variant) -> void:
	var parts := str(meta).split(":")
	if parts.size() != 2:
		return
	match parts[0]:
		"inspect":
			_on_submit("inspect " + parts[1])
		"exploit":
			_on_submit("exploit " + parts[1])
		"bot":
			_on_submit("install_bot " + parts[1])


# --- Command handling ------------------------------------------------------

func _on_submit(cmd: String) -> void:
	cmd = cmd.strip_edges().to_lower()
	_cmd_input.text = ""
	if cmd == "":
		return
	_output.append_text("[color=%s]$> %s[/color]\n" % [C_DIM, cmd])
	_execute(cmd)


func _execute(cmd: String) -> void:
	var parts := cmd.split(" ", false)
	var name: String = parts[0]
	var arg: String = parts[1] if parts.size() > 1 else ""
	match name:
		"help":
			_cmd_help()
		"scan":
			_cmd_scan()
		"inspect":
			_cmd_inspect(arg)
		"exploit":
			_cmd_exploit(arg)
		"install_bot", "bot":
			_cmd_install_bot(arg)
		"collect":
			_cmd_collect()
		"news":
			_cmd_news()
		"clear":
			_output.clear()
			_banner()
		"exit", "quit":
			close_terminal()
		_:
			_say("sh: command not found: %s — try 'help'" % name, C_RED)


func _cmd_help() -> void:
	_say("commands:", C_CYAN)
	_say("  help                 this list")
	_say("  scan                 find nearby targets")
	_say("  inspect <target>     difficulty, payout, costs")
	_say("  exploit <target>     attempt the hack (costs CPU + Energy, adds HEAT)")
	_say("  install_bot <target> enslave a pwned box (+botnet)")
	_say("  collect              skim cash from your botnet")
	_say("  news                 tap the CITY WIRE feed")
	_say("  clear / exit")
	_say("HEAT at 100 = traced. Higher wanted tiers cut your odds.", C_DIM)
	_say("Sleeping cools HEAT — but notoriety slows it; Stealth/VPN speed it up.", C_DIM)
	_say("Low Energy = worse hack odds. Eat/drink from your BAG or sleep.", C_DIM)


func _cmd_scan() -> void:
	_say("scanning local subnets...", C_DIM)
	for id in GameData.TARGETS:
		var t: Dictionary = GameData.TARGETS[id]
		if GameState.reputation < t.rep_req:
			_say("  ░░░ encrypted node — REP %d required" % t.rep_req, C_DIM)
			continue
		var status := ""
		if GameState.botted.has(id):
			status = "  [BOTTED]"
		elif GameState.exploited.has(id):
			status = "  [PWNED]"
		var stars := "*".repeat(t.difficulty)
		_say("  %s  diff %s%s" % [_link("inspect", id, id, C_CYAN), stars, status])
	_say("tap a target (or 'inspect <target>') for details", C_DIM)


func _cmd_inspect(arg: String) -> void:
	if arg == "":
		_say("usage: inspect <target>", C_YEL)
		return
	if not GameData.TARGETS.has(arg):
		_say("no such target: %s" % arg, C_RED)
		return
	var t: Dictionary = GameData.TARGETS[arg]
	if GameState.reputation < t.rep_req:
		_say("this node is beyond you. REP %d required." % t.rep_req, C_YEL)
		return
	_say("── %s ──" % arg, C_CYAN)
	_say(t.desc, C_DIM)
	_say("  difficulty : %d/5" % t.difficulty)
	_say("  success    : ~%d%%" % int(_chance(t) * 100))
	_say("  payout     : $%d-$%d" % [t.payout_min, t.payout_max])
	_say("  CPU cost   : %d (you have %d)" % [t.cpu_cost, GameState.cpu])
	_say("  heat gain  : +%d" % t.heat)
	_say("  botnet val : +%d" % t.botnet_value)
	if GameState.botted.has(arg):
		_say("bot already installed on this box.", C_DIM)
	elif GameState.exploited.has(arg):
		_say("pwned. %s" % _link("bot", arg, "▶ tap to INSTALL_BOT", C_YEL))
	else:
		_say(_link("exploit", arg, "▶ tap to EXPLOIT", C_YEL))


const EXPLOIT_ENERGY := 1  # soft energy cost per exploit attempt


func _chance(t: Dictionary) -> float:
	var base: float = 0.95 - t.difficulty * 0.12 + GameState.reputation * 0.015 + GameState.gear_hack_bonus()
	return clampf(base - GameState.fatigue_penalty() - GameState.heat_penalty(), 0.05, 0.95)


func _cmd_exploit(arg: String) -> void:
	if arg == "" or not GameData.TARGETS.has(arg):
		_say("usage: exploit <target> — run 'scan' to find targets", C_YEL)
		return
	var t: Dictionary = GameData.TARGETS[arg]
	if GameState.reputation < t.rep_req:
		_say("access vector unknown. REP %d required." % t.rep_req, C_YEL)
		return
	if GameState.exploited.has(arg):
		_say("already pwned today. install_bot or come back tomorrow.", C_YEL)
		return
	if GameState.cpu < t.cpu_cost:
		_say("not enough CPU (%d needed, %d left). sleep to recharge." % [t.cpu_cost, GameState.cpu], C_RED)
		return
	if GameState.is_fatigued():
		_say("you're running on fumes — focus slipping, odds down %d%%." % int(GameState.fatigue_penalty() * 100), C_YEL)
	if GameState.heat_penalty() > 0.0:
		_say("%s: they're watching — odds down %d%%. lie low (sleep) to cool off." % [GameState.heat_tier_name().to_upper(), int(GameState.heat_penalty() * 100)], C_YEL)
	GameState.spend_cpu(t.cpu_cost)
	GameState.drain_energy(EXPLOIT_ENERGY)
	_say("running exploit against %s ..." % arg, C_DIM)
	if randf() < _chance(t):
		Audio.sfx("hack_ok")
		var payout := randi_range(t.payout_min, t.payout_max)
		GameState.exploited[arg] = true
		GameState.add_cash(payout)
		GameState.add_rep(1)
		GameState.add_heat(t.heat)
		var dropped := GameState.register_hack(arg, t.difficulty)
		_say("ACCESS GRANTED — siphoned $%d  (+1 REP, +%d XP, +%d HEAT, -%d CPU, -%d Energy)" % [payout, 10 * t.difficulty, t.heat, t.cpu_cost, EXPLOIT_ENERGY], C_CYAN)
		if dropped:
			_say("exfiltrated 1x Stolen Data — sell it at the pawn shop", C_YEL)
		if not GameState.botted.has(arg):
			_say(_link("bot", arg, "▶ tap to INSTALL_BOT", C_YEL))
	else:
		Audio.sfx("hack_fail")
		var fail_heat := GameState.apply_failed_hack_heat(t.heat)
		if GameState.trace_active:
			_say("ACCESS DENIED — TRACE LOCKED  (HEAT MAX, -%d CPU, -%d Energy)" % [t.cpu_cost, EXPLOIT_ENERGY], C_RED)
			_say("RUN. leave the district before the countdown hits zero.", C_YEL)
		else:
			_say("ACCESS DENIED — IDS tripped  (+%d HEAT, -%d CPU, -%d Energy)" % [fail_heat, t.cpu_cost, EXPLOIT_ENERGY], C_RED)
	if GameState.energy == 0:
		_say("EXHAUSTED. eat, drink, or sleep before you slip up.", C_RED)


func _cmd_install_bot(arg: String) -> void:
	if arg == "" or not GameData.TARGETS.has(arg):
		_say("usage: install_bot <target>", C_YEL)
		return
	var t: Dictionary = GameData.TARGETS[arg]
	if GameState.botted.has(arg):
		_say("bot already running on %s." % arg, C_YEL)
		return
	if not GameState.exploited.has(arg):
		_say("you need access first. exploit %s" % arg, C_YEL)
		return
	if GameState.cpu < 1:
		_say("not enough CPU (1 needed). sleep to recharge.", C_RED)
		return
	GameState.spend_cpu(1)
	GameState.botnet_size += t.botnet_value
	GameState.add_heat(2)
	GameState.add_xp(8)
	GameState.stats_changed.emit()
	_say("bot deployed on %s  (+%d botnet, +8 XP, +2 HEAT)" % [arg, t.botnet_value], C_CYAN)
	_say("your botnet earns while you sleep. 'collect' skims it now.", C_DIM)


func _cmd_collect() -> void:
	if GameState.botnet_size <= 0:
		_say("no bots installed. exploit a box, then install_bot.", C_YEL)
		return
	if GameState.cpu < 1:
		_say("not enough CPU (1 needed). sleep to recharge.", C_RED)
		return
	GameState.spend_cpu(1)
	var income := GameState.botnet_size * 2
	if GameState.owned("desk_setup"):
		income = int(income * 1.5)
	var heat_gain := maxi(1, GameState.botnet_size / 3)
	GameState.add_cash(income)
	GameState.add_heat(heat_gain)
	_say("skimmed $%d from %d bots  (+%d HEAT, -1 CPU)" % [income, GameState.botnet_size, heat_gain], C_CYAN)


func _cmd_news() -> void:
	_say("// CITY WIRE — live feed", C_CYAN)
	for h in NewsFeed.headlines(4):
		_say("  · " + h)
	_say("the wire never sleeps.", C_DIM)
