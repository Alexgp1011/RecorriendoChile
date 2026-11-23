
extends CharacterBody3D

# ==========================================
# REFERENCIAS DEL JUGADOR
# ==========================================

@onready var animated_sprite_2d: AnimatedSprite2D = $CanvasLayer/Gunbase/AnimatedSprite2D
@onready var ray_cast_3d: RayCast3D = $Camera3D/RayCast3D

# CORREGIDO: Tu nodo es AudioStreamPlayer3D
@onready var shoot_sound: AudioStreamPlayer3D = $Shootsound

@onready var death_screen: Control = $CanvasLayer/DeathScreen
@onready var restart_button: Button = $CanvasLayer/DeathScreen/Panel/Button
@onready var camera: Camera3D = $Camera3D


# ==========================================
# CONFIGURACION
# ==========================================

@export var mouse_sensitivity: float = 0.002

const SPEED: float = 5.0


# ==========================================
# VARIABLES
# ==========================================

var can_shoot: bool = true
var dead: bool = false
var tiene_arma: bool = false
var cartel_levantado: bool = false


# ==========================================
# INICIAR
# ==========================================

func _ready() -> void:

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	death_screen.hide()

	# Evitar que el sonido se reproduzca solo
	shoot_sound.autoplay = false
	shoot_sound.stop()

	# Conectar animacion de disparo
	animated_sprite_2d.animation_finished.connect(
		shoot_anim_done
	)

	# Conectar reinicio
	restart_button.pressed.connect(restart)

	# Actualizar la pistola al comenzar
	actualizar_estado_arma()

	print("JUGADOR: Sistema iniciado")


# ==========================================
# MOVIMIENTO DE CAMARA
# ==========================================

func _input(event: InputEvent) -> void:

	if dead:
		return

	if event is InputEventMouseMotion:

		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:

			# Movimiento horizontal
			rotate_y(
				-event.relative.x * mouse_sensitivity
			)

			# Movimiento vertical
			camera.rotate_x(
				-event.relative.y * mouse_sensitivity
			)

			camera.rotation.x = clamp(
				camera.rotation.x,
				deg_to_rad(-85),
				deg_to_rad(85)
			)


# ==========================================
# PROCESO PRINCIPAL
# ==========================================

func _process(_delta: float) -> void:

	if Input.is_action_just_pressed("exit"):

		get_tree().quit()
		return

	if Input.is_action_just_pressed("restart"):

		restart()
		return

	if dead:
		return

	actualizar_estado_arma()

	# Solo permitir disparar cuando:
	# 1. El arma ya fue comprada
	# 2. El cartel esta guardado
	# 3. El jugador puede disparar

	if Input.is_action_just_pressed("shoot"):

		if not tiene_arma:
			return

		if cartel_levantado:
			return

		if not can_shoot:
			return

		shoot()


# ==========================================
# ACTUALIZAR ESTADO DEL ARMA
# ==========================================

func actualizar_estado_arma() -> void:

	tiene_arma = GestorMisiones.tiene_pistola()

	cartel_levantado = EstadoJuego.cartel_visible

	var mostrar_arma: bool = (
		tiene_arma
		and not cartel_levantado
		and not dead
	)

	animated_sprite_2d.visible = mostrar_arma

	# Detener audio si ya no puede utilizar el arma
	if not tiene_arma or cartel_levantado or dead:

		if shoot_sound.playing:
			shoot_sound.stop()


# ==========================================
# MOVIMIENTO DEL JUGADOR
# ==========================================

func _physics_process(delta: float) -> void:

	if dead:
		return

	var input_dir: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_forwards",
        "move_backwards"
	)

	var direction: Vector3 = (
		transform.basis * Vector3(
			input_dir.x,
			0,
			input_dir.y
		)
	).normalized()

	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED

	if not is_on_floor():

		velocity += get_gravity() * delta

	else:

		velocity.y = 0.0

	move_and_slide()


# ==========================================
# DISPARAR
# ==========================================

func shoot() -> void:

	# Comprobar si el personaje puede disparar
	if dead:
		return

	# Comprobar la compra directamente
	# por si otro script llama a shoot()
	if not GestorMisiones.tiene_pistola():

		print("JUGADOR: No tienes la pistola")
		return

	if EstadoJuego.cartel_visible:

		print("JUGADOR: Guarda el cartel primero")
		return

	if not can_shoot:
		return

	can_shoot = false

	# Animar la pistola
	animated_sprite_2d.play("Shoot")

	# Reproducir sonido SOLO si esta autorizado
	shoot_sound.play()

	# Detectar impacto
	ray_cast_3d.force_raycast_update()

	if ray_cast_3d.is_colliding():

		var collider: Object = (
			ray_cast_3d.get_collider()
		)

		if collider != null:

			if collider is Node:

				print(
					"Disparo detecto: ",
					collider.name
				)

			if collider.has_method("kill"):

				collider.call("kill")

	else:

		print("Disparo sin impacto")


# ==========================================
# FINALIZAR ANIMACION
# ==========================================

func shoot_anim_done() -> void:

	if animated_sprite_2d.animation == "Shoot":

		can_shoot = true


# ==========================================
# MUERTE DEL JUGADOR
# ==========================================

func kill() -> void:

	if dead:
		return

	dead = true

	velocity = Vector3.ZERO

	shoot_sound.stop()

	animated_sprite_2d.hide()

	death_screen.show()

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	restart_button.grab_focus()


# ==========================================
# REINICIAR
# ==========================================

func restart() -> void:

	shoot_sound.stop()

	# Reiniciar deja todo como al empezar el capitulo (dinero, cartel,
	# pistola), igual que una detencion. Ver design/game-brief.md, B10.
	EstadoJuego.reiniciar_partida()

	get_tree().reload_current_scene()
