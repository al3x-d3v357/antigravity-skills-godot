## 🩸 HurtboxComponent — zona que RECEBE dano de qualquer HitboxComponent.
##
## Skill: godot-data-driven-architecture
## Compõe com um HealthComponent irmão ou do pai (auto-descoberto em _ready).
class_name HurtboxComponent
extends Area2D

@export var team: int = 0
@export var health: HealthComponent ## opcional: auto-descobre em _ready()


func _ready() -> void:
	if health == null:
		var container := get_parent() as Node
		for child in container.get_children():
			if child is HealthComponent:
				health = child
				break


## Ponto de entrada único de dano nesta entidade.
func receive_hit(amount: int, _source: Node = null) -> void:
	if health:
		health.take_damage(amount)
	var victim := owner if owner else get_parent()
	var bus := get_node_or_null("/root/EventBus")
	if bus and victim:
		bus.gladiator_damaged.emit(victim, amount)
