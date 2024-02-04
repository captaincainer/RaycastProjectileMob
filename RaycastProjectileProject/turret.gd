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

## This is for returning to the patrol path
@onready var enemy_origin: Marker2D = $"../../../EnemyOrigin"
@onready var nav_agent_timer: Timer = $Navigation/NavAgentTimer
var is_returning: bool = false
var current_position: Vector2
var distance_threshold: float = 10.0

## This is for helping debug that the enemy cannot see the player
var see_player: bool = false


func _ready() -> void:
	enemy_origin.position = global_position


func _physics_process(delta: float) -> void:
	_aim()
	_check_player_collision()
	
	## Sets the current_position to the global_position constantly while the game runs
	current_position = global_position
	
	## If chasing or returning, use the navigation agent to move
	if is_chasing or is_returning:
		direction = navigation_agent_2d.get_next_path_position() - global_position
		direction = direction.normalized()
		
		velocity = velocity.lerp(direction * speed, acceleration * delta)
	
	## If the distance between the enemy and the start position is within a certain threshold and they're returning 
	## Then assign the direction to global_position, stop the movement, send a signal to the pathfollow to start patrolling, and make the enemy no longer returning
	if current_position.distance_to(enemy_origin.position) < distance_threshold and is_returning:
		direction = global_position
		velocity = Vector2.ZERO
		emit_signal("lost_player_signal")
		is_returning = false
		
	
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
		
		## Sets the state to see_player and emits a signal to the pathfollow2D script to stop patrolling
		see_player = true
		emit_signal("see_player_signal")
		
		## This stops the player_detection timer if it sees the player in time before the timeout
		if not player_detection.is_stopped():
			## Sets the chasing state to false and stops the timer so that the enemy will shoot at the player
			is_chasing = false
			player_detection.stop()
			
	## Else if the collider is not the player and the timer isn't stopped
	elif ray_cast.get_collider() != player and not attack_timer.is_stopped():
		## Stops the attack timer
		attack_timer.stop()
		
		## Changes the state from seeing the player to chasing after the player
		see_player = false
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
		## Change the state from chasing the player to returning to the patrol
		is_chasing = false
		is_returning = true
	else:
		_check_player_collision()

## This controls where the enemy is going to be moving at the end of the timer's timeout depending on if it is chasing or returning
func _on_nav_agent_timer_timeout() -> void:
	if is_chasing:
		## Sets the navigation_agent_2D's target position to the target's global position
		navigation_agent_2d.target_position = target.global_position
	elif is_returning:
		## Sets the navigation_agent_2D's target position to the marker2D that is along the patrol route
		navigation_agent_2d.target_position = enemy_origin.position

