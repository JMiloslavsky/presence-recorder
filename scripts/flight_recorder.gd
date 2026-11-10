extends Node

# --- Состояния ---
var is_recording: bool = false
var is_playing: bool = false

# --- Данные записи ---
var recorded_frames: Array = []
var record_start_time: float = 0.0

# --- Воспроизведение ---
var play_start_time: float = 0.0
var play_index: int = 0

# --- Ссылки на узлы (Node3D — работает и с XRCamera3D, и с Camera3D) ---
@export var camera: Node3D
@export var left_controller: Node3D
@export var right_controller: Node3D
@export var ghost_head: Node3D
@export var ghost_left_hand: Node3D
@export var ghost_right_hand: Node3D

# --- Пути ---
const SAVE_PATH = "user://flight_001.json"
const DEMO_PATH = "res://examples/demo_flight.json"

func _ready():
    print("FlightRecorder v2 готов.")
    print("Space — запись/стоп, F5 — сохранить, F9 — загрузить+проиграть, F6 — проиграть.")

func _process(_delta):
    _handle_input()
    if is_recording:
        _record_frame()
    elif is_playing:
        _playback_frame()

func _handle_input():
    if Input.is_action_just_pressed("record_toggle"):
        if not is_recording and not is_playing:
            start_recording()
        elif is_recording:
            stop_recording()
    if Input.is_action_just_pressed("save_flight"):
        save_to_json()
    if Input.is_action_just_pressed("load_flight"):
        load_from_json()
    if Input.is_action_just_pressed("play_flight"):
        start_playback()

# --- Утилиты ---
func _node_to_dict(node: Node3D) -> Dictionary:
    var p = node.global_position
    var r = node.global_rotation
    return { "p": [p.x, p.y, p.z], "r": [r.x, r.y, r.z] }

func _empty_dict() -> Dictionary:
    return { "p": [0.0, 0.0, 0.0], "r": [0.0, 0.0, 0.0] }

func _apply_dict_to_node(d: Dictionary, node: Node3D):
    var p = d["p"]
    var r = d["r"]
    node.global_position = Vector3(p[0], p[1], p[2])
    node.global_rotation = Vector3(r[0], r[1], r[2])

# --- Запись ---
func start_recording():
    if camera == null:
        print("Нет camera — записывать нечего.")
        return
    recorded_frames.clear()
    is_recording = true
    is_playing = false
    record_start_time = Time.get_ticks_msec() / 1000.0
    print("Запись началась...")

func _record_frame():
    if camera == null:
        return
    var now = Time.get_ticks_msec() / 1000.0
    var t = now - record_start_time
    var frame = {
        "t": t,
        "h": _node_to_dict(camera),
        "l": _node_to_dict(left_controller) if left_controller else _empty_dict(),
        "r": _node_to_dict(right_controller) if right_controller else _empty_dict()
    }
    recorded_frames.append(frame)

func stop_recording():
    is_recording = false
    print("Запись остановлена. Кадров: ", recorded_frames.size())

# --- Сохранение ---
func save_to_json():
    if recorded_frames.is_empty():
        print("Нечего сохранять.")
        return
    var data = {
        "version": 2,
        "created_at": Time.get_datetime_string_from_system(),
        "fps": 60,
        "frames": recorded_frames
    }
    var json_string = JSON.stringify(data, "  ")
    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        print("Ошибка записи файла: ", FileAccess.get_open_error())
        return
    file.store_string(json_string)
    file.close()
    print("Сохранено: ", SAVE_PATH, " (", recorded_frames.size(), " кадров)")

# --- Загрузка с fallback на демо ---
func load_from_json():
    var path = ""
    if FileAccess.file_exists(SAVE_PATH):
        path = SAVE_PATH
    elif FileAccess.file_exists(DEMO_PATH):
        path = DEMO_PATH
        print("Личной записи нет — загружаю демо: ", DEMO_PATH)
    else:
        print("Нет ни ", SAVE_PATH, ", ни ", DEMO_PATH)
        return

    var file = FileAccess.open(path, FileAccess.READ)
    if file == null:
        print("Ошибка чтения: ", FileAccess.get_open_error())
        return
    var json_string = file.get_as_text()
    file.close()

    var json = JSON.new()
    if json.parse(json_string) != OK:
        print("Ошибка JSON: ", json.get_error_message())
        return

    var data = json.data
    if not data.has("frames"):
        print("Нет поля 'frames'.")
        return

    recorded_frames.clear()
    for f in data["frames"]:
        recorded_frames.append(f)
    print("Загружено кадров: ", recorded_frames.size(), " из ", path)
    start_playback()

# --- Воспроизведение с интерполяцией ---
func start_playback():
    if recorded_frames.is_empty():
        print("Нечего воспроизводить.")
        return
    is_playing = true
    is_recording = false
    play_index = 0
    play_start_time = Time.get_ticks_msec() / 1000.0
    print("Воспроизведение началось (интерполяция).")

func _lerp_dict(a: Dictionary, b: Dictionary, alpha: float) -> Dictionary:
    var pa = a["p"]; var pb = b["p"]
    var ra = a["r"]; var rb = b["r"]
    return {
        "p": [
            lerp(pa[0], pb[0], alpha),
            lerp(pa[1], pb[1], alpha),
            lerp(pa[2], pb[2], alpha)
        ],
        "r": [
            lerp(ra[0], rb[0], alpha),
            lerp(ra[1], rb[1], alpha),
            lerp(ra[2], rb[2], alpha)
        ]
    }

func _playback_frame():
    var now = Time.get_ticks_msec() / 1000.0
    var elapsed = now - play_start_time

    while play_index < recorded_frames.size() - 1:
        if recorded_frames[play_index + 1]["t"] <= elapsed:
            play_index += 1
        else:
            break

    if play_index >= recorded_frames.size() - 1:
        var last = recorded_frames[recorded_frames.size() - 1]
        _apply_dict_to_node(last["h"], ghost_head)
        _apply_dict_to_node(last["l"], ghost_left_hand)
        _apply_dict_to_node(last["r"], ghost_right_hand)
        is_playing = false
        print("Воспроизведение завершено.")
        return

    var f0 = recorded_frames[play_index]
    var f1 = recorded_frames[play_index + 1]
    var t0 = f0["t"]
    var t1 = f1["t"]
    var alpha = 0.0
    if t1 > t0:
        alpha = clamp((elapsed - t0) / (t1 - t0), 0.0, 1.0)

    _apply_dict_to_node(_lerp_dict(f0["h"], f1["h"], alpha), ghost_head)
    _apply_dict_to_node(_lerp_dict(f0["l"], f1["l"], alpha), ghost_left_hand)
    _apply_dict_to_node(_lerp_dict(f0["r"], f1["r"], alpha), ghost_right_hand)