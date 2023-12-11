extends CharacterBody2D

class_name Player

signal healthChanged
signal on_hit(node : Node, damage_taken : int, knockback_direction : Vector2)
signal player_died

@export var maxHealth = 4
@onready var currentHealth: int = maxHealth
@export var speed : float = 120.0
@onready var facing : int = 1 #1 for right, 0 for left.

#Variables regarding player health and damage.
@export var invincible : bool = false
@onready var playerhit : bool = false
@onready var isdead : bool = false
@export var hurtbox : Area2D

#Controlled jumping variables
@export var maxJumpForceinWater = -60
@export var maxJumpForce = -110
@export var jumpForceDefault : float = -85
@onready var jumpForce = jumpForceDefault
@export var jump_control : bool = false
@export var jumpmultiplier : float = 1.2
@export var jumptimer : Timer 
@export var jumping = false

#Game specific variables
@export var vspeedlimit : int = 500

#Animation variables
@onready var jump : String = "jump"
@onready var fall : String = "fall"
@onready var run : String = "run"
@onready var idle : String = "idle"
@onready var glide : String = "glide"
@onready var attack : String = "attack"
@onready var death : String = "death"

#Sound effects
@onready var jumpsnd = $jumpsnd

# Setting up animations.
@export var animated_sprite : AnimatedSprite2D

#Setting up state machine.
@onready var state = "idle"

#Character Specific Variables
var bashdamage : float = 20
var eljay_bash : bool = false
var meso_specials : bool = false
var var_gun : bool = false
var has_shield : bool = false
@export var sword : bool = false
var assymetry : bool = false
var boostjump : bool = false
@export var summon_able : bool = false
var can_glide : bool = false
@onready var bashtimer : Timer = $BashTimer
@onready var game_control_timer : Timer = $GCTimer

@onready var sprite_ref = 0

signal facing_direction_changed(facing_right : bool)

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var lockmovement : bool = false
var animation_locked : bool = false
var direction : Vector2 = Vector2.ZERO
var in_air : bool = false
var attack_done : bool = false
var gliding : bool = false
@export var inactive : bool = false
@onready var running_start : bool = false

@onready var camera : Camera2D = %Camera2D

func _process(delta):
	
	#Falling off screen
	if position.y > camera.limit_bottom:
		die()
	
	#Jump Code
	if jumptimer.is_stopped():
		jumping = false
	if jumping == true:
		velocity.y += jumpForce
		if velocity.y < maxJumpForce:
				velocity.y = maxJumpForce
		if is_on_floor() && velocity.y == 0:
			jumptimer.stop()
			jumping = false
			jumpForce = jumpForceDefault
	if Input.is_action_just_released("jump"):
		jumping = false
func jump_control_execute():
		jumping = true
		jumptimer.start()

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
		in_air = true
	else:
		if in_air == true:
			in_air = false
	
	#Locks the vertical speed
	if velocity.y > vspeedlimit:
		velocity.y = vspeedlimit
	
	# Control whether to move or not to move
	if lockmovement == false:
		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		direction = Input.get_vector("left", "right", "up", "down")
		if direction.x != 0:
			velocity.x = direction.x * speed
		elif playerhit == false:
			velocity.x = move_toward(velocity.x, 0, speed)
		move_and_slide()
	
	update_animation()
	handleCollision()

func update_animation():
	if state == "air":
		if velocity.y > 0:
			animated_sprite.play(fall)
		elif velocity.y < 0:
			animated_sprite.play(jump)
	#If player is on the floor.
	elif is_on_floor():
		if state == "run":
			animated_sprite.play(run)
		elif state == "idle":
			animated_sprite.play(idle)

func handleCollision():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

#Update the facing direction of the sprites.
func update_facing_direction():
	if direction.x > 0:
		animated_sprite.flip_h = false #Stay to the right
		facing = 1
	elif direction.x < 0:
		animated_sprite.flip_h = true #Flip to the left
		facing = -1
	#Updates the facing value for attack states
	emit_signal("facing_direction_changed", !animated_sprite.flip_h)

func _on_hurt_box_area_entered(area):
	#Bustable Walls
	if (area.is_in_group("spikes") && area.monitoring == true && invincible == false):
		hurt_player(maxHealth,0)

func hurt_player(damage : int, knockback_direction):
	if playerhit ==false && invincible == false:
		currentHealth -= damage
		# Local signal for subscribers that only care about this specific
		# damageable object
		playerhit = true
		healthChanged.emit(currentHealth)
		emit_signal("on_hit", get_parent(), damage, knockback_direction)
		
func die():
	emit_signal("player_died")
	set_collision_layer_value(2, false)
	set_collision_mask_value(2, false)
