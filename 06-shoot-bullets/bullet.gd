extends Area2D

@export var speed := 400.0

func _physics_process(delta: float) -> void:
	position += transform.x * speed * delta

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(1.5).timeout.connect(queue_free)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("hit"):
		body.hit()
	queue_free()
