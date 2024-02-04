extends CharacterBody2D

signal see_player_signal
signal lost_player_signal

@onready var ray_cast: RayCast2D = $RayCast2D
@onready var attack_timer: Timer = $Timer
@onready var player_detection: Timer = $PlayerDetection
@onready var player: CharacterBody2D = get_parent().get_parent().get_parent().find_child("Player")
@onready var path_follow_2d: PathFollow2D = get_parent()

@export var ammo: PackedScene

## This is for chasing down the player
@export var speed: int
@export var acceleration: int
@export var target: CharacterBody2D
@onready var navigation_agent_2d: NavigationAgent2D = $Navigation/NavigationAgent2D
var direction := Vector2.ZERO
var is_chasing: bool = false

## This is for helping debug that the enemy cannot see the player
var see_player: bool = false


func _physics_process(delta: float) -> void:
	_aim()
	_check_player_collision()
	
	if is_chasing:
		direction = navigation_agent_2d.get_next_path_position() - global_position
		direction = direction.normalized()
		
		velocity = velocity.lerp(direction * speed, acceleration * delta)
	
	move_and_slide()
	
	

## This aims the ray at the player and sets a target_position for the bullet
func _aim():
	ray_cast.target_position = to_local(player.position)


func _check_player_collision():
	## If the collider is the player and the timer is stopped
	if ray_cast.get_collider() == player and attack_timer.is_stopped():
		## Start the attack timer which is set to 0.4 for a little window the player could shoot at the enemy before the enemy attacks, and spacing between bullets 
		## A second timer could be implemented if the shot rate is different than the grace period, but for this, it works
		attack_timer.start()
		
		## Another debugging component to see if the turret sees the player
		see_player = true
		emit_signal("see_player_signal")
		print_debug(see_player)
		
		## This stops the player_detection timer if it sees the player
		if not player_detection.is_stopped():
			print_debug("I see the player, resuming attack")
			is_chasing = false
			player_detection.stop()
	## Else if the collider is not the player and the timer isn't stopped
	elif ray_cast.get_collider() != player and not attack_timer.is_stopped():
		## Start the timer
		attack_timer.stop()
		
		## Another debugging component to see if the turret does not see the player
		see_player = false
		print_debug(see_player)
		is_chasing = true
		
		## Start the timer until the enemy no longer follows the player
		if player_detection.is_stopped():
			player_detection.start()


## This timer timeout is for the interval shooting
func _on_timer_timeout() -> void:
	_shoot()


## Instantiate the ammo, assign the position and the direction baased on the raycast and Turret's position, and add's it to the scene
func _shoot():
	var bullet = ammo.instantiate()
	bullet.position = global_position
	bullet.direction = (ray_cast.target_position).normalized()
	get_tree().current_scene.add_child(bullet)


## This timer timeout stops the chase if it doesn't see the player, otherwise it loops back to check the player collision
func _on_player_detection_timeout() -> void:
	if ray_cast.get_collider() != player:
		is_chasing = false
		emit_signal("lost_player_signal")
		print_debug("Cease chasing")
	else:
		_check_player_collision()


func _on_nav_agent_timer_timeout() -> void:
	if is_chasing:
		navigation_agent_2d.target_position = target.global_position
