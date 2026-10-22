## 📡 EventBus — autoload global de comunicação por eventos (Pub/Sub).
##
## Skill: godot-data-driven-architecture
## Centraliza TODOS os sinais globais do projeto (arena auto chess +
## corrida de veículos), eliminando o acoplamento rígido entre
## UI, lógica de gameplay e áudio.
##
## INSTALAÇÃO (obrigatório para o evento fluir):
##   Project ➔ Project Settings ➔ Autoload
##   Nome: EventBus   Path: *res://core/autoload/event_bus.gd
##
## REGRAS DE USO:
##   1. EMITA da lógica de gameplay (gladiadores, carros, MatchManager).
##   2. CONSUMA da UI, áudio e VFX — nunca o inverso.
##   3. Payloads são referências a nós ou valores primitivos:
##      quem subscreve busca detalhes no nó recebido, não no emissor.
extends Node

# ═══════════════════════════════════════════
# 🎮 FASES DA PARTIDA (auto chess)
# ═══════════════════════════════════════════

## Mudança de fase (MatchManager.MatchPhase → int).
signal phase_changed(new_phase: int)

## Jogador confirmou a equipa: UI travada, IA ativada.
signal combat_started

## A ronda terminou (winner_team = -1 em caso de empate impróprio).
signal combat_ended(winner_team: int)

## Unidades regressaram ao banco para nova preparação.
signal units_repositioned

## Fim de jogo absoluto (líder de uma equipa sem vidas).
signal match_ended(winner_team: int)

# ═══════════════════════════════════════════
# ⚔️ COMBATE (gladiadores)
# ═══════════════════════════════════════════

## Drag-and-drop concluído com sucesso no tabuleiro.
signal unit_deployed(unit: Node, cell: Vector2i)

## Golpe corpo a corpo consumado (para combos de VFX/áudio).
signal gladiator_attacked(attacker: Node, target: Node, amount: int)

## Dano recebido por um gladiador (via HurtboxComponent).
signal gladiator_damaged(victim: Node, amount: int)

## Morte de um gladiador (equipa 0/1) — HUD, contadores de equipa e log de partida.
signal gladiator_died(gladiator: Node, team: int)

## Feitiço conjurado na posição do alvo.
signal spell_cast(caster: Node, spell: PackedScene)

## O líder de uma equipa perdeu uma vida após uma ronda perdida.
signal leader_damaged(team: int, remaining_health: int)

# ═══════════════════════════════════════════
# 🏎️ VEÍCULOS / CORRIDA (isométrico)
# ═══════════════════════════════════════════

## Derrapagem iniciada (IsometricVehicle; intensity 0.0–1.0) — VFX pneus/áudio.
signal drift_triggered(vehicle: Node, intensity: float)

## Volta concluída por um veículo.
signal lap_completed(vehicle: Node, lap: int)

## Corrida terminou (placement 1 = vencedor).
signal race_finished(vehicle: Node, placement: int)

# ═══════════════════════════════════════════
# 💰 ECONOMIA / LOJA
# ═══════════════════════════════════════════

signal gold_changed(current_gold: int)
signal gladiator_purchased(gladiator_data: GladiatorData)

# ═══════════════════════════════════════════
# 📺 UI / ÁUDIO / FEEDBACK
# ═══════════════════════════════════════════

signal screen_shake_requested(strength: float)
signal sfx_requested(sfx_name: String)
signal toast_requested(message: String)


# ---------- Utilitários de consumo defensivo ----------

## Conecta um consumidor só se o sinal existir (proteção de versões antigas).
func try_connect(signal_name: StringName, callable: Callable) -> bool:
	if has_signal(signal_name):
		if not is_connected(signal_name, callable):
			connect(signal_name, callable)
		return true
	push_warning("EventBus: sinal '%s' não existe." % signal_name)
	return false


## Desconecta de forma idempotente.
func try_disconnect(signal_name: StringName, callable: Callable) -> void:
	if has_signal(signal_name) and is_connected(signal_name, callable):
		disconnect(signal_name, callable)
