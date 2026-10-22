---
name: godot-autochess-battle-logic
description: Logica de combate automatico em grelha para Godot 4 (estilo Auto Chess / Teamfight Tactics) - gestao de celulas ocupadas e rotas com AStarGrid2D, maquina de estados finitos para gladiadores (IDLE, SEARCH_TARGET, MOVE_TO_TARGET, ATTACK, CAST_SPELL, DEAD) e game loop por fases (PREPARACAO com drag-and-drop livre, COMBATE com UI travada e IA simultanea, RESOLUCAO com vencedor e dano ao lider). Use sempre que o pedido envolver arena auto chess, combate tatico em grelha, FSM de unidades ou fases de partida.
---

# ⚔️ Godot Auto Chess Battle Logic

Skill de combate automático em grelha e ciclo de jogo por fases para **Godot 4** (engine local: `D:\epicgms\GodotEngine`).

---

## 🧭 Pipeline de Combate

### 1. 🗺️ Grelha e Navegação (`BattleGrid`)
- Nó `Node2D` que encapsula um `AStarGrid2D` (`region` = tamanho da grelha, células bloqueadas = ocupadas).
- Ocupação: `occupy_cell()` / `free_cell()` marcam as células como sólidas; unidades avançam célula a célula trocando a ocupação antes de cada passo.
- Rotas: `get_path_cells(from, to)` devolve o caminho de ids (`Array[Vector2i]`); conversões `cell_to_position()` / `position_to_cell()`.
- Zonas de colocação: `can_place(cell, team)` valida as linhas de deploy por equipa durante a fase de **Preparação**.

### 2. 🤖 Máquina de Estados Finitos (`GladiatorFSM`)
Cada gladiador é autónomo e roda a sua FSM em `_physics_process`:

```text
IDLE ──▶ SEARCH_TARGET ──▶ MOVE_TO_TARGET ──▶ ATTACK ──▶ CAST_SPELL
                ▲                │                │            │
                └───── alvo morto / perdido ◀─────┴────────────┘
                                              ↓ quando mana cheia
DEAD (final, libera célula e emite gladiator_died)
```

- **Mana**: acumulada a cada ataque com sucesso; a `mana >= 1.0` entra em `CAST_SPELL` (instancia a cena de feitiço no alvo, depois regressa a `ATTACK`).
- **Dano desacoplado**: os ataque usam *duck typing* (`has_method("take_damage")`), por isso funciona tanto com `HealthComponent` da skill `godot-data-driven-architecture` como com qualquer nó que expoña o método.

### 3. 🎮 Game Loop por Fases (`MatchManager`)
| Fase | UI | IA das Unidades | Ações |
|---|---|---|---|
| **PREPARAÇÃO** | Drag-and-drop livre (`can_place` validado) | Desativada (estado `IDLE`) | Posicionamento estratégico, loja |
| **COMBATE** | Travada | Ativada simultaneamente via `begin_combat()` | Monitorização de equipas (`alive[0/1]`) |
| **RESOLUÇÃO** | Resultado | Desativada | Vencedor, dano ao líder, retorno ao banco, nova preparação |

---

## 📦 Ficheiros da Skill

| Ficheiro | Função |
|---|---|
| `scripts/battle_grid.gd` | `AStarGrid2D` + ocupação de células + zonas de deploy por equipa. |
| `scripts/gladiator_fsm.gd` | FSM completa do gladiador (busca de alvo, rotas, ataques, mana, feitiço, morte). |
| `scripts/match_manager.gd` | Fases da partida, monitorização de equipas, dano ao líder e fim de jogo. |

---

## ⚙️ Setup Rápido na Cena

```text
Arena (Node2D)
├── BattleGrid (Node2D + battle_grid.gd)      # grelha 8x8 padrão
├── GladiatorBlue (Node2D + gladiator_fsm.gd)
│   └── HealthComponent (Node)                # da skill godot-data-driven-architecture
└── MatchManager (Node + match_manager.gd)
```

1. Anexar `battle_grid.gd` ao nó de grelha e definir `grid_size` (ex.: `Vector2i(8, 8)`) e `deployment_rows`.
2. Nos gladiadores: anexar `gladiator_fsm.gd`, arrastar o `BattleGrid` para `grid` e definir `team` (0 = azul em baixo, 1 = vermelho em cima). Chamar `place_on_grid(cell)` ao instanciar.
3. Anexar `match_manager.gd`, arrastar o `BattleGrid` e definir `leader_max_health` (ex.: 10 vidas do líder).
4. UI chama `match_manager.begin_combat()` quando o jogador confirma a equipa.

---

## 🔗 Integração com as outras Skills

- **`godot-data-driven-architecture`** — os gladiadores recebem `GladiatorData.tres`; a morte, os ataques e as fases emitem sinais no autoload `EventBus` (`phase_changed`, `gladiator_died`, `gladiator_attacked`, `spell_cast`, `leader_damaged`) para UI/áudio desacoplados.
- **`godot-isometric-vehicle-physics`** — partilham o mesmo `EventBus`: uma partida de corrida e uma ronda de arena podem coexistir no mesmo ecosistema de eventos globais.

---

## 🔍 Validação Headless

```bash
python D:\GitHub\antigravity-skills\skills\godot-multigenre-antigravity\scripts\build_project.py --project-path "D:\caminho\do\projeto" --check-only
```
