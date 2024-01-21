extends Node2D

@onready var ray_cast: RayCast2D = $RayCast2D
@onready var attack_timer: Timer = $Timer
@onready var player_detection: Timer = $PlayerDetection

@export var ammo: PackedScene

var player
var see_player: bool = false

func _ready() -> void:
	player = get_parent().find_child("Player")


func _physics_process(delta: float) -> void:
	_aim()
	_check_player_collision()


func _aim():
	ray_cast.target_position = to_local(player.position)


func _check_player_collision():
	if ray_cast.get_collider() == player and attack_timer.is_stopped():
		attack_timer.start()
		see_player = true
		print_debug(see_player)
		if not player_detection.is_stopped():
			player_detection.stop()
	elif ray_cast.get_collider() != player and not attack_timer.is_stopped():
		attack_timer.stop()
		see_player = false
		print_debug(see_player)
		if player_detection.is_stopped():
			player_detection.start()


func _on_timer_timeout() -> void:
	_shoot()


func _shoot():
	var bullet = ammo.instantiate()
	bullet.position = position
	bullet.direction = (ray_cast.target_position).normalized()
	get_tree().current_scene.add_child(bullet)


func _on_player_detection_timeout() -> void:
	if ray_cast.get_collider() != player:
		print_debug("Cease chasing")
	else:
		_check_player_collision()
