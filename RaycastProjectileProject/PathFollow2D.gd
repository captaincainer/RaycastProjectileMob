extends PathFollow2D

var speed: float = 0.1

func _ready() -> void:
	progress_ratio = 0.22


func _process(delta: float) -> void:
	progress_ratio += delta * speed
