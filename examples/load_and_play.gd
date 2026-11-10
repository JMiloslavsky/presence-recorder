extends Node
# Минимальный загрузчик .presence — «пережить чужой полёт» без VR.
# Повесь на Node в пустой сцене и запусти.

@export var ghost_head: Node3D
@export var ghost_left_hand: Node3D
@export var ghost_right_hand: Node3D

const DEMO_PATH = "res://examples/demo_flight.json"

var frames: Array = []
var start_time: float = 0.0
var index: int = 0
var playing: bool = false

func _ready():
    _load_demo()
    start_time = Time.get_ticks_msec() / 1000.0
    playing = true
    print("Демо-полёт загружен. Кадров: ", frames.size())

func _load_demo():
    var file = FileAccess.open(DEMO_PATH, FileAccess.READ)
    if file == null:
        print("Не найден: ", DEMO_PATH)
        return
    var data = JSON.parse_string(file.get_as_text())
    file.close()
    if data == null or not data.has("frames"):
        print("Ошибка парсинга.")
        return
    frames = data["frames"]

func _process(_delta):
    if not playing or frames.is_empty():
        return
    var elapsed = Time.get_ticks_msec() / 1000.0 - start_time
    while index < frames.size() - 1 and frames[index + 1]["t"] <= elapsed:
        index += 1
    if index >= frames.size() - 1:
        playing = false
        print("Полёт завершён.")
        return
    var f0 = frames[index]
    var f1 = frames[index + 1]
    var alpha = clamp((elapsed - f0["t"]) / (f1["t"] - f0["t"]), 0.0, 1.0)
    _apply(f0["h"], f1["h"], alpha, ghost_head)
    _apply(f0["l"], f1["l"], alpha, ghost_left_hand)
    _apply(f0["r"], f1["r"], alpha, ghost_right_hand)

func _apply(a: Dictionary, b: Dictionary, alpha: float, node: Node3D):
    var pa = a["p"]; var pb = b["p"]
    var ra = a["r"]; var rb = b["r"]
    node.global_position = Vector3(
        lerp(pa[0], pb[0], alpha),
        lerp(pa[1], pb[1], alpha),
        lerp(pa[2], pb[2], alpha)
    )
    node.global_rotation = Vector3(
        lerp(ra[0], rb[0], alpha),
        lerp(ra[1], rb[1], alpha),
        lerp(ra[2], rb[2], alpha)
    )