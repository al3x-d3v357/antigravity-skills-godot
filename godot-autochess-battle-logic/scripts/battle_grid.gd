## 🗺️ BattleGrid — gestão de células de grelha e rotas AStarGrid2D.
##
## Skill: godot-autochess-battle-logic
## Encapsula um AStarGrid2D para navegação, ocupa/liberta células e
## valida zones de colocação (drag-and-drop) por equipa.
class_name BattleGrid
extends Node2D

signal cell_occupied(cell: Vector2i, occupant: Node2D)
signal cell_freed(cell: Vector2i)

@export var grid_size := Vector2i(8, 8)
@export var cell_size := Vector2i(64, 64)
## Linhas de colocação de cada equipa nas extremidades (0 = topo azul? ver docs).
@export var deployment_rows := 2
## Células bloqueadas permanentemente (paredes/lagostas do mapa).
@export var blocked_cells: Array[Vector2i] = []

var _astar := AStarGrid2D.new()
var _occupants := {} # Vector2i -> Node2D


func _ready() -> void:
	_astar.region = Rect2i(Vector2i.ZERO, grid_size)
	_astar.cell_size = Vector2(cell_size)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	for cell in blocked_cells:
		_astar.set_point_solid(cell, true)
	_astar.update()


func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size.x and cell.y < grid_size.y


func is_free(cell: Vector2i) -> bool:
	return is_in_bounds(cell) and not _astar.is_point_solid(cell)


func occupant_of(cell: Vector2i) -> Node2D:
	return _occupants.get(cell)


# ---------- Colocação (fase de PREPARAÇÃO) ----------

## Equipa 0 coloca nas linhas do fundo; equipa 1 nas linhas do topo.
func is_in_deployment_zone(cell: Vector2i, team: int) -> bool:
	if not is_in_bounds(cell):
		return false
	return cell.y >= grid_size.y - deployment_rows if team == 0 else cell.y < deployment_rows


func can_place(cell: Vector2i, team: int) -> bool:
	return is_free(cell) and is_in_deployment_zone(cell, team)


# ---------- Ocupação ----------

func occupy_cell(cell: Vector2i, occupant: Node2D) -> bool:
	if not is_free(cell):
		return false
	_astar.set_point_solid(cell, true)
	_occupants[cell] = occupant
	cell_occupied.emit(cell, occupant)
	return true


func free_cell(cell: Vector2i) -> void:
	if not is_in_bounds(cell):
		return
	_astar.set_point_solid(cell, false)
	_occupants.erase(cell)
	cell_freed.emit(cell)


func swap_occupancy(from_cell: Vector2i, to_cell: Vector2i, occupant: Node2D) -> bool:
	free_cell(from_cell)
	return occupy_cell(to_cell, occupant)


# ---------- Rotas ----------

## Caminho de células (ids) de `from` até `to`; vazio se inválido/bloqueado.
func get_path_cells(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	if not is_in_bounds(from) or not is_in_bounds(to):
		return []
	if _astar.is_point_solid(to):
		return []
	return _astar.get_id_path(from, to)


# ---------- Conversões de coordenadas ----------

func cell_to_position(cell: Vector2i) -> Vector2:
	return Vector2(cell) * Vector2(cell_size) + Vector2(cell_size) * 0.5


func position_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / cell_size.x), floori(pos.y / cell_size.y))


func clamp_to_grid(cell: Vector2i) -> Vector2i:
	return Vector2i(
		clampi(cell.x, 0, grid_size.x - 1),
		clampi(cell.y, 0, grid_size.y - 1)
	)


# ---------- Debug ----------

func _draw() -> void:
	for y in grid_size.y:
		for x in grid_size.x:
			var cell := Vector2i(x, y)
			var rect := Rect2(
				Vector2(cell) * Vector2(cell_size),
				Vector2(cell_size)
			)
			if _astar.is_point_solid(cell):
				draw_rect(rect, Color(1.0, 0.2, 0.2, 0.25), true)
			else:
				draw_rect(rect, Color(1, 1, 1, 0.08), false, 1.0)
