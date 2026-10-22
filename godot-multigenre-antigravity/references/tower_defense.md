# 🛡️ Godot 4 Tower Defense Architecture Guide

## 1. Grid & Células de Construção (`TileMapLayer`)
No Godot 4, utilize `TileMapLayer` para posicionamento em grade discreta.

```gdscript
class_name GridBuildingValidator
extends Node2D

@export var tilemap: TileMapLayer
var occupied_cells: Dictionary = {}

func can_place_tower(grid_pos: Vector2i) -> bool:
    if occupied_cells.has(grid_pos):
        return false
    var tile_data = tilemap.get_cell_tile_data(grid_pos)
    if not tile_data:
        return false
    return tile_data.get_custom_data("buildable") == true

func place_tower(grid_pos: Vector2i, tower_scene: PackedScene) -> Node2D:
    if not can_place_tower(grid_pos):
        return null
    var world_pos = tilemap.map_to_local(grid_pos)
    var tower = tower_scene.instantiate()
    tower.global_position = world_pos
    add_child(tower)
    occupied_cells[grid_pos] = tower
    return tower
```

---

## 2. Pathing & Progress com `Path2D` / `PathFollow2D`
- Mantenha a velocidade no `EnemyCreep`:
```gdscript
func _physics_process(delta: float) -> void:
    progress += move_speed * delta
    if progress_ratio >= 1.0:
        base_reached.emit()
        queue_free()
```
- Para calcular prioridade de alvo da torre (`FIRST`), basta ordenar inimigos por maior `progress`.

---

## 3. Modos de Mira das Torres
```gdscript
enum TargetPriority { FIRST, LAST, STRONGEST, WEAKEST, CLOSEST }

func get_best_target(enemies: Array[EnemyCreep], priority: TargetPriority) -> EnemyCreep:
    if enemies.is_empty():
        return null
    match priority:
        TargetPriority.FIRST:
            return enemies.reduce(func(best, e): return e if e.progress > best.progress else best)
        TargetPriority.STRONGEST:
            return enemies.reduce(func(best, e): return e if e.current_health > best.current_health else best)
        TargetPriority.CLOSEST:
            return enemies.reduce(func(best, e):
                return e if global_position.distance_to(e.global_position) < global_position.distance_to(best.global_position) else best
            )
    return enemies.front()
```

---

## 4. Wave Controller & Eventos
Estruture o gerador de ondas usando `Timer` e `Resource` dedicado (`WaveData.tres`) contendo tipo de monstro, quantidade e intervalo de spawn.
