## 🧬 GladiatorData — esquema estático de um gladiador (auto chess).
##
## Skill: godot-data-driven-architecture
## Crie variações como .tres em res://data/resources/gladiators/ e
## arraste o ficheiro para o export `stats` do GladiatorFSM.
## Balanceamento em minutos, zero recompilação.
class_name GladiatorData
extends Resource

@export var id: StringName
@export var display_name: String = ""

@export_group("Economia")
@export_range(1, 5) var tier: int = 1
@export_range(1, 50) var purchase_cost: int = 2

@export_group("Combate")
@export var max_health: int = 100
@export var attack_damage: int = 12
@export var attack_speed: float = 1.0 ## golpes por segundo
@export var move_speed: float = 220.0
@export var attack_range_cells: float = 1.5

@export_group("Identidade / Sinergias")
## Ex.: [&"orc", &"guardiao"] para bônus de sinergia calculados pela UI.
@export var traits: Array[StringName] = []
@export var icon: Texture2D

@export_group("Feitiço")
## Cena instanciada na posição do alvo quando a mana enche.
@export var spell: PackedScene
