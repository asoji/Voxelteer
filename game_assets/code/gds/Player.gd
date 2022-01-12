extends KinematicBody

export var maxSpeed = 12
export var acceleration = 60
export var friction = 50
export var airFriction = 10
export var jumpImpulse = 15
export var gravity = -50

export var mouseSensitivity = .1
export var controllerSensitivity = 3
export var camera_tilt = 0.1

export (int, 0, 10) var push = 1

var velocity = Vector3.ZERO
var snapVector = Vector3.ZERO

onready var head = $Head
onready var headCamera = $Head/Camera

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event.is_action_pressed("click"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if event.is_action_pressed("toggle_mouse_mode"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(deg2rad(-event.relative.x * mouseSensitivity))
		head.rotate_x(deg2rad(-event.relative.y * mouseSensitivity))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-90), deg2rad(90))
		

func _process(_delta):
	if Input.is_action_pressed("move_left"):
		headCamera.rotate_z(deg2rad(camera_tilt))
	if Input.is_action_pressed("move_right"):
		headCamera.rotate_z(deg2rad(-camera_tilt))
	if Input.is_action_pressed("move_forward"):
		headCamera.rotate_x(deg2rad(-camera_tilt))
	if Input.is_action_pressed("move_backward"):
		headCamera.rotate_x(deg2rad(camera_tilt))
	
	if not Input.is_action_pressed("move_left"):
		if headCamera.rotation.z > 0:
			headCamera.rotate_z(deg2rad(-camera_tilt * 1.5))
	if not Input.is_action_pressed("move_right"):
		if headCamera.rotation.z < 0:
			headCamera.rotate_z(deg2rad(camera_tilt * 1.5))
	if not Input.is_action_pressed("move_forward"):
		if headCamera.rotation.x < 0:
			headCamera.rotate_x(deg2rad(camera_tilt * 1.5))
	if not Input.is_action_pressed("move_backward"):
		if headCamera.rotation.x > 0:
			headCamera.rotate_x(deg2rad(-camera_tilt * 1.5))
	
	headCamera.rotation.z = clamp(headCamera.rotation.z , -0.015, 0.015)
	headCamera.rotation.x = clamp(headCamera.rotation.x , -0.015, 0.015)

func _physics_process(delta):
	var inputVector = get_input_vector()
	var direction = get_direction(inputVector)
	apply_movement(direction, delta)
	apply_friction(direction, delta)
	apply_gravity(delta)
	update_snap_vector()
	jump()
	
	velocity = move_and_slide_with_snap(velocity, snapVector, Vector3.UP, true, 4, .7853, false)
	
	for idx in get_slide_count():
		var collision = get_slide_collision(idx)
		if collision.collider.is_in_group("bodies"):
			collision.collider.apply_central_impulse(-collision.normal * velocity.length() * push)
	
	

func get_input_vector():
	var inputVector = Vector3.ZERO
	inputVector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	inputVector.z = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	return inputVector.normalized() if inputVector.length() > 1 else inputVector

func get_direction(inputVector):
	var direction = Vector3.ZERO
	direction = (inputVector.x * transform.basis.x) + (inputVector.z * transform.basis.z)
	return direction

func apply_movement(direction, delta):
	if direction != Vector3.ZERO:
		velocity.x = velocity.move_toward(direction * maxSpeed, acceleration * delta).x
		velocity.z = velocity.move_toward(direction * maxSpeed, acceleration * delta).z

func apply_friction(direction, delta):
	if direction == Vector3.ZERO:
		if is_on_floor():
			velocity = velocity.move_toward(Vector3.ZERO, friction * delta)
		else:
			velocity.x = velocity.move_toward(direction * maxSpeed, airFriction * delta).x
			velocity.z = velocity.move_toward(direction * maxSpeed, airFriction * delta).z

func apply_gravity(delta):
	velocity.y += gravity * delta
	velocity.y = clamp(velocity.y, gravity, jumpImpulse)

func update_snap_vector():
	snapVector = -get_floor_normal() if is_on_floor() else Vector3.DOWN

func jump():
	if Input.is_action_just_pressed("jump") and is_on_floor():
		snapVector = Vector3.ZERO
		velocity.y = jumpImpulse
	if Input.is_action_just_released("jump") and velocity.y > jumpImpulse / 2:
		velocity.y = jumpImpulse / 2
