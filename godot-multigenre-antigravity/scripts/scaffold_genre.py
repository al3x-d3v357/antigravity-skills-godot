"""
Scaffold Generator for Godot 4 Genres (Tower Defense, Turn-Based, Top-Down Antigravity Vehicle)
Generates complete runnable starter projects.
"""

import os
import sys
import argparse

def create_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content.strip() + "\n")
    print(f"  [+] Criado: {os.path.relpath(path)}")

def scaffold_topdown_vehicle(out_dir):
    print(f"[*] Gerando projeto Top-Down Antigravity Vehicle em {out_dir}...")
    
    # project.godot
    create_file(os.path.join(out_dir, "project.godot"), """
; Godot Project Config
config_version=5

[application]
config/name="Antigravity Top-Down Vehicle"
run/main_scene="res://scenes/arena.tscn"
config/features=PackedStringArray("4.3", "4.4", "4.7", "Forward Plus")

[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"

[input]
accelerate={"deadzone": 0.5, "events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194320,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]}
brake={"deadzone": 0.5, "events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194322,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]}
steer_left={"deadzone": 0.5, "events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194319,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]}
steer_right={"deadzone": 0.5, "events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194321,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]}
""")

    # scripts/antigravity_vehicle.gd
    create_file(os.path.join(out_dir, "scripts", "antigravity_vehicle.gd"), """
class_name AntigravityVehicle
extends RigidBody2D

@export var hover_height: float = 35.0
@export var spring_stiffness: float = 400.0
@export var damping: float = 25.0
@export var engine_thrust: float = 1100.0
@export var reverse_thrust: float = 500.0
@export var steering_torque: float = 7500.0
@export_range(0.0, 1.0) var drift_grip: float = 0.88

@onready var ground_ray: RayCast2D = $GroundRay

func _physics_process(delta: float) -> void:
    _apply_suspension()
    _apply_drive()
    _apply_lateral_friction()

func _apply_suspension() -> void:
    if ground_ray.is_colliding():
        var hit_point = ground_ray.get_collision_point()
        var distance = global_position.distance_to(hit_point)
        var compression = hover_height - distance
        
        # Spring-damper restorative force
        var spring_force = compression * spring_stiffness
        var normal = -transform.y
        var current_v_speed = linear_velocity.dot(normal)
        var damping_force = current_v_speed * damping
        
        var total_lift = (spring_force - damping_force) * normal
        apply_central_force(total_lift)

func _apply_drive() -> void:
    var throttle: float = 0.0
    if Input.is_action_pressed("accelerate") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        throttle += 1.0
    if Input.is_action_pressed("brake") or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        throttle -= 0.5
        
    var steer: float = 0.0
    if Input.is_action_pressed("steer_right") or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        steer += 1.0
    if Input.is_action_pressed("steer_left") or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        steer -= 1.0
        
    var forward_dir = transform.x
    var force_magnitude = engine_thrust if throttle >= 0.0 else reverse_thrust
    apply_central_force(forward_dir * throttle * force_magnitude)
    apply_torque(steer * steering_torque)

func _apply_lateral_friction() -> void:
    var lateral_dir = transform.y
    var lateral_velocity = lateral_dir * linear_velocity.dot(lateral_dir)
    var impulse = -lateral_velocity * mass * drift_grip
    apply_central_impulse(impulse)
""")

    # scenes/arena.tscn
    create_file(os.path.join(out_dir, "scenes", "arena.tscn"), """
[gd_scene load_steps=4 format=3 uid="uid://arena_scene_001"]

[ext_resource type="Script" path="res://scripts/antigravity_vehicle.gd" id="1_vehicle"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_hull"]
size = Vector2(60, 28)

[node name="Arena" type="Node2D"]

[node name="TrackGround" type="ColorRect" parent="."]
offset_left = -2000.0
offset_top = -2000.0
offset_right = 2000.0
offset_bottom = 2000.0
color = Color(0.08, 0.09, 0.12, 1)

[node name="Vehicle" type="RigidBody2D" parent="."]
position = Vector2(640, 360)
gravity_scale = 0.0
linear_damp = 1.2
angular_damp = 4.0
script = ExtResource("1_vehicle")

[node name="HullVisual" type="Polygon2D" parent="Vehicle"]
color = Color(0.12, 0.8, 1, 1)
polygon = PackedVector2Array(30, 0, 10, -14, -25, -12, -30, 0, -25, 12, 10, 14)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Vehicle"]
shape = SubResource("RectangleShape2D_hull")

[node name="GroundRay" type="RayCast2D" parent="Vehicle"]
target_position = Vector2(0, 45)
collide_with_areas = true

[node name="Camera2D" type="Camera2D" parent="Vehicle"]
position_smoothing_enabled = true
position_smoothing_speed = 8.0

[node name="UI" type="CanvasLayer" parent="."]

[node name="Label" type="Label" parent="UI"]
offset_left = 20.0
offset_top = 20.0
offset_right = 450.0
offset_bottom = 80.0
text = "Controles: W/S (Acelerar/Frear) | A/D (Virar)
Antigravity Suspension & Lateral Grip Ativos"
""")
    print("[+] Scaffold de Top-Down Antigravity Vehicle concluido com sucesso!")

def scaffold_tower_defense(out_dir):
    print(f"[*] Gerando projeto Tower Defense em {out_dir}...")
    
    create_file(os.path.join(out_dir, "project.godot"), """
; Godot Project Config
config_version=5

[application]
config/name="Antigravity Tower Defense"
run/main_scene="res://scenes/main_game.tscn"
config/features=PackedStringArray("4.3", "4.4", "4.7", "Forward Plus")

[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"
""")

    create_file(os.path.join(out_dir, "scripts", "hitbox_component.gd"), """
class_name HitboxComponent
extends Area2D

@export var damage: float = 15.0
@export var damage_type: String = "energy"
""")

    create_file(os.path.join(out_dir, "scripts", "hurtbox_component.gd"), """
class_name HurtboxComponent
extends Area2D

signal damage_received(amount: float, type: String)

@export var defense_multiplier: float = 1.0

func _ready() -> void:
    area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
    if area is HitboxComponent:
        var net_damage = area.damage * defense_multiplier
        damage_received.emit(net_damage, area.damage_type)
""")

    create_file(os.path.join(out_dir, "scripts", "enemy_creep.gd"), """
class_name EnemyCreep
extends PathFollow2D

@export var move_speed: float = 120.0
@export var max_health: float = 50.0
var current_health: float

@onready var hurtbox: HurtboxComponent = $HurtboxComponent

func _ready() -> void:
    current_health = max_health
    if hurtbox:
        hurtbox.damage_received.connect(_on_damaged)

func _process(delta: float) -> void:
    progress += move_speed * delta
    if progress_ratio >= 1.0:
        queue_free()

func _on_damaged(amount: float, _type: String) -> void:
    current_health -= amount
    if current_health <= 0:
        queue_free()
""")

    create_file(os.path.join(out_dir, "scenes", "main_game.tscn"), """
[gd_scene format=3 uid="uid://td_main_001"]

[node name="MainGame" type="Node2D"]

[node name="Background" type="ColorRect" parent="."]
offset_right = 1280.0
offset_bottom = 720.0
color = Color(0.06, 0.08, 0.1, 1)

[node name="EnemyPath" type="Path2D" parent="."]

[node name="UI" type="CanvasLayer" parent="."]

[node name="InfoLabel" type="Label" parent="UI"]
offset_left = 24.0
offset_top = 24.0
offset_right = 400.0
offset_bottom = 70.0
text = "Antigravity Tower Defense Framework
Path2D + Decoupled Hitbox/Hurtbox"
""")
    print("[+] Scaffold de Tower Defense concluido com sucesso!")

def scaffold_turn_based(out_dir):
    print(f"[*] Gerando projeto Turn-Based Tactics em {out_dir}...")
    
    create_file(os.path.join(out_dir, "project.godot"), """
; Godot Project Config
config_version=5

[application]
config/name="Antigravity Turn-Based Tactics"
run/main_scene="res://scenes/tactics_board.tscn"
config/features=PackedStringArray("4.3", "4.4", "4.7", "Forward Plus")

[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"
""")

    create_file(os.path.join(out_dir, "scripts", "turn_manager.gd"), """
class_name TurnManager
extends Node

enum TurnState { ROUND_START, PLAYER_TURN, ENEMY_TURN, RESOLVING, ROUND_END }

var current_state: TurnState = TurnState.ROUND_START
var round_count: int = 1

signal turn_changed(new_state: TurnState)
signal round_started(number: int)

func _ready() -> void:
    start_new_round()

func start_new_round() -> void:
    current_state = TurnState.ROUND_START
    round_started.emit(round_count)
    transition_to(TurnState.PLAYER_TURN)

func transition_to(new_state: TurnState) -> void:
    current_state = new_state
    turn_changed.emit(current_state)
    
    match current_state:
        TurnState.PLAYER_TURN:
            print("[TurnManager] Fase do Jogador iniciada.")
        TurnState.ENEMY_TURN:
            print("[TurnManager] Fase dos Inimigos iniciada.")
            _process_ai_turns()
        TurnState.ROUND_END:
            round_count += 1
            start_new_round()

func end_player_turn() -> void:
    if current_state == TurnState.PLAYER_TURN:
        transition_to(TurnState.ENEMY_TURN)

func _process_ai_turns() -> void:
    await get_tree().create_timer(1.0).timeout
    transition_to(TurnState.ROUND_END)
""")

    create_file(os.path.join(out_dir, "scenes", "tactics_board.tscn"), """
[gd_scene load_steps=2 format=3 uid="uid://tactics_board_001"]

[ext_resource type="Script" path="res://scripts/turn_manager.gd" id="1_turn_mgr"]

[node name="TacticsBoard" type="Node2D"]

[node name="TurnManager" type="Node" parent="."]
script = ExtResource("1_turn_mgr")

[node name="UI" type="CanvasLayer" parent="."]

[node name="StateLabel" type="Label" parent="UI"]
offset_left = 24.0
offset_top = 24.0
offset_right = 400.0
offset_bottom = 70.0
text = "Antigravity Tactics - FSM Turn Manager"
""")
    print("[+] Scaffold de Turn-Based Tactics concluido com sucesso!")

def main():
    parser = argparse.ArgumentParser(description="Godot 4 Genre Scaffolder")
    parser.add_argument("--genre", choices=["topdown_vehicle", "tower_defense", "turn_based"], required=True)
    parser.add_argument("--output-dir", "-o", required=True)
    
    args = parser.parse_args()
    out = os.path.abspath(args.output_dir)
    
    if args.genre == "topdown_vehicle":
        scaffold_topdown_vehicle(out)
    elif args.genre == "tower_defense":
        scaffold_tower_defense(out)
    elif args.genre == "turn_based":
        scaffold_turn_based(out)

if __name__ == "__main__":
    main()
