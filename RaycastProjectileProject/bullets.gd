extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 300

## Controls the bullet movement
func _physics_process(delta: float) -> void:
	position += direction * speed * delta


## Clears the bullet to avoid memory leaks
func _on_screen_exited() -> void:
	queue_free()
