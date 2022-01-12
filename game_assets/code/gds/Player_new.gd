extends KinematicBody

export var speed = 10
export var gravity = 20
export var jump = 10
export var hAccel = 6
export var mouseSensitivity = 0.03
export var airAccel = 1
export var normalAccel = 6

var fullContact = false

var hVelocity = Vector3()
var movement = Vector3()
var gravityVec = Vector3()
var direction = Vector3()

onready var head = $Head
onready var groundCheck = $GroundCheck

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouseSensitivity))
		head.rotate_x(deg2rad(-event.relative.y * mouseSensitivity))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-90), deg2rad(90))

func _physics_process(delta):
	direction = Vector3()
	
	if groundCheck.is_colliding():
		fullContact = true
	else:
		fullContact = false
	
	if not is_on_floor():
		gravityVec += Vector3.DOWN * gravity * delta
		hAccel = airAccel
	elif is_on_floor() and fullContact:
		gravityVec = -get_floor_normal() * gravity
		hAccel = normalAccel
	else:
		gravityVec = -get_floor_normal()
		hAccel = normalAccel

	if Input.is_action_just_pressed("jump") and (is_on_floor() or groundCheck.is_colliding()):
		gravityVec = Vector3.UP * jump
	
	if Input.is_action_pressed("move_forward"):
		direction -= transform.basis.z
	elif Input.is_action_pressed("move_backward"):
		direction += transform.basis.z
	
	if Input.is_action_pressed("move_left"):
		direction -= transform.basis.x
	elif Input.is_action_pressed("move_right"):
		direction += transform.basis.x
	
	direction = direction.normalized()
	hVelocity = hVelocity.linear_interpolate(direction * speed, hAccel * delta)
	movement.z = hVelocity.z + gravityVec.z
	movement.x = hVelocity.x + gravityVec.x
	movement.y = gravityVec.y
	
	move_and_slide(movement, Vector3.UP)
