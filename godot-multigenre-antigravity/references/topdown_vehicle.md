# 🛸 Antigravity Vehicle Physics Guide (2D & 3D)

## 1. Princípios da Física Antigravitacional
Diferente de carros tradicionais que usam rodas com atrito longitudinal/lateral estático, o veículo antigravitacional:
1. **Flutua sem atrito de solo:** Sustentado por um campo magnético/repulsivo modelado por mola e amortecedor (*Spring-Damper*).
2. **Impulsão por propulsores (Thrusters):** Força direta aplicada no chassi (`apply_central_force`).
3. **Tração Lateral Ajustável:** Resistência artificial contra derrapagem que pode ser atenuada para simular drift orbital.

---

## 2. Modelo 2D Spring-Damper (GDScript)

```gdscript
class_name HoverModule2D
extends Node2D

@export var rest_height: float = 30.0
@export var spring_stiffness: float = 450.0
@export var damping: float = 25.0

@onready var ray: RayCast2D = $RayCast2D
@onready var body: RigidBody2D = get_parent()

func apply_hover_force() -> void:
    if ray.is_colliding():
        var hit_dist = global_position.distance_to(ray.get_collision_point())
        var compression = rest_height - hit_dist
        
        var spring_force = compression * spring_stiffness
        var vertical_vel = body.linear_velocity.dot(-transform.y)
        var damping_force = vertical_vel * damping
        
        var net_force = (spring_force - damping_force) * -transform.y
        body.apply_force(net_force, position)
```

---

## 3. Modelo 3D Multiponto (4 Suspensões em `RigidBody3D`)

Em 3D, posicione 4 nós `RayCast3D` (FrontLeft, FrontRight, RearLeft, RearRight):

```gdscript
class_name HoverCraft3D
extends RigidBody3D

@export var hover_distance: float = 1.2
@export var spring_strength: float = 85.0
@export var spring_damper: float = 12.0
@export var forward_thrust: float = 2500.0
@export var turn_torque: float = 800.0

@onready var hover_rays = [$Rays/FL, $Rays/FR, $Rays/RL, $Rays/RR]

func _physics_process(delta: float) -> void:
    for ray in hover_rays:
        if ray.is_colliding():
            var hit_point = ray.get_collision_point()
            var distance = ray.global_position.distance_to(hit_point)
            var compression = hover_distance - distance
            
            var point_vel = _get_point_velocity(ray.global_position)
            var normal = ray.get_collision_normal()
            var vertical_speed = point_vel.dot(normal)
            
            var force_mag = (compression * spring_strength) - (vertical_speed * spring_damper)
            force_mag = max(0.0, force_mag)
            
            apply_force(normal * force_mag, ray.global_position - global_position)

func _get_point_velocity(world_point: Vector3) -> Vector3:
    return linear_velocity + angular_velocity.cross(world_point - global_position)
```

---

## 4. Curva de Derrapagem e Fator de Aderência
Para obter a sensação clássica de Wipeout / F-Zero:
```gdscript
func _apply_lateral_grip(drift_factor: float = 0.85) -> void:
    var lateral_dir = transform.basis.x
    var lateral_speed = linear_velocity.dot(lateral_dir)
    var counter_force = -lateral_dir * lateral_speed * mass * drift_factor
    apply_central_force(counter_force)
```
