extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -500.0
var down = false
var hop = 0
var silk = 100
@export var particle_texture = Texture
@export var BIND_PARTICLE = Texture
@onready var sprite = $Sprite2D
@onready var camera = $Camera2D
@onready var cameraLastPos = Vector2.ZERO
@onready var silkBar = $Camera2D/Control/ColorRect

var binding = 0.0
var bind_particles: CPUParticles2D

func _ready():
	bind_particles = CPUParticles2D.new()
	bind_particles.amount = 10
	bind_particles.initial_velocity_min = 800
	bind_particles.initial_velocity_max = 1000
	bind_particles.gravity.y = 0
	bind_particles.texture = BIND_PARTICLE
	bind_particles.spread = 360
	bind_particles.scale_amount_min = 0.5
	bind_particles.scale_amount_max = 0.5
	bind_particles.lifetime = 0.5
	bind_particles.emitting = false
	add_child(bind_particles)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("bind") and silk >= 100:
		silk -= 100
		binding = 0.01  # Start timer (non-zero so it counts)
		bind_particles.emitting = true
	silkBar.size.x = silk
	if binding > 0:
		velocity = Vector2.ZERO
		binding += delta
		if binding > 1.5:
			binding = 0
			bind_particles.emitting = false
		move_and_slide()
		return
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		sprite.position.y = 0
		sprite.rotation = 0
		
	if direction >= 1:
		sprite.flip_h = true
		if hop >= 10:
			hop = 0
			sprite.position.y -= 5
			sprite.rotation_degrees = 2
		else:
			hop += 1
			sprite.position.y = 0
			sprite.rotation_degrees = -2
	elif direction <= 0 and Input.is_action_pressed("move_left"):
		sprite.flip_h = false
		if hop >= 10:
			hop = 0
			sprite.position.y -= 5
			sprite.rotation_degrees = -2
		else:
			hop += 1
			sprite.position.y = 0
			sprite.rotation_degrees = 2
		
	if Input.is_action_just_pressed("attack"):
		var slash = Area2D.new()
		var hitbox = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		var particles = CPUParticles2D.new()

		# Shape setup
		shape.size = Vector2(200, 10)
		hitbox.shape = shape

		# Particle setup
		particles.amount = 1
		particles.initial_velocity_min = 800
		particles.initial_velocity_max = 1000
		particles.gravity.y = 0
		particles.texture = particle_texture
		particles.spread = 0
		particles.scale_amount_min = 0.5
		particles.scale_amount_max = 0.5
		particles.lifetime = 0.1
		particles.one_shot = true
		particles.emitting = true

		# Determine direction and offset
		var offset = Vector2(100, 0)
		if sprite.flip_h:  # Facing right
			particles.direction = Vector2(1, 0)
			particles.angle_min = 90
			particles.angle_max = 90
			particles.position -= offset
			slash.position = sprite.position + offset
		else:  # Facing left
			particles.direction = Vector2(-1, 0)
			particles.angle_min = -90
			particles.angle_max = -90
			particles.position += offset
			slash.position = sprite.position - offset

		# Add children to slash
		slash.add_child(hitbox)
		slash.add_child(particles)
		add_child(slash)

		# Enable collisions after adding to tree
		slash.call_deferred("set_deferred", "monitoring", true)

		# Remove slash after 0.2s
		await get_tree().create_timer(0.2).timeout
		slash.queue_free()

	
	if Input.is_action_just_pressed("ui_down"):
		cameraLastPos = camera.position      # Save current position
		down = true
		var tween = get_tree().create_tween()
		tween.tween_property(camera, "position:y", camera.position.y + 150, 0.1)

	elif down and Input.is_action_just_released("ui_down"):
		down = false
		var tween = get_tree().create_tween()
		tween.tween_property(camera, "position", cameraLastPos, 0.1)
		
	if Input.is_action_just_pressed("ui_up"):
		cameraLastPos = camera.position      # Save current position
		down = true
		var tween = get_tree().create_tween()
		tween.tween_property(camera, "position:y", camera.position.y - 150, 0.1)

	elif down and Input.is_action_just_released("ui_up"):
		down = false
		var tween = get_tree().create_tween()
		tween.tween_property(camera, "position", cameraLastPos, 0.1)
	
	move_and_slide()
