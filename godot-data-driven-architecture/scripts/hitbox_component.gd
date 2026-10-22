## 💥 HitboxComponent — zona que INFLIGE dano (arma / ataque ativo).
##
## Skill: godot-data-driven-architecture
## Colida apenas com HurtboxComponent de outra equipa (team masking).
## Ciclo típico: arm() no início do ataque ➔ contato ➔ receive_hit no alvo ➔ deactivate().
class_name HitboxComponent
extends Area2D

@export var damage: int = 10
@export var team: int = 0
## Deixe true apenas nos frames de vantagem do ataque.
@export var active: bool = false

var _source: Node


func _ready() -> void:
	set_deferred(&"monitoring", active)
	area_entered.connect(_on_area_entered)


## Ativa a hitbox com contexto de ataque (fonte de dano manual opcional).
func arm(source: Node, damage_value: int, team_value: int = -1) -> void:
	_source = source
	damage = damage_value
	if team_value >= 0:
		team = team_value
	active = true
	set_deferred(&"monitoring", true)


func deactivate() -> void:
	active = false
	set_deferred(&"monitoring", false)


func _on_area_entered(area: Area2D) -> void:
	if not active:
		return
	var hurtbox := area as HurtboxComponent
	if hurtbox == null or hurtbox.team == team:
		return
	hurtbox.receive_hit(damage, _source if _source else owner)
