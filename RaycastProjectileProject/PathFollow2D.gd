extends PathFollow2D

@onready var turret: Node2D = $Turret
@onready var enemy_origin: Marker2D = $"../../EnemyOrigin"

var speed: float = 0.1
var can_progress: bool = true


func _ready() -> void:
	turret.connect("see_player_signal", _stop_progress)
	turret.connect("lost_player_signal", _resume_progress)

func _process(delta: float) -> void:
	if can_progress:
		progress_ratio += delta * speed
	
	enemy_origin.position = position


func _stop_progress() -> void:
	can_progress = false


func _resume_progress() -> void:
	can_progress = true
