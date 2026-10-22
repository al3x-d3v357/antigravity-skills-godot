---
name: godot-data-driven-architecture
description: Estrutura desacoplada baseada em dados para Godot 4 - Custom Resources (.tres) para gladiadores, veiculos e balanceamento, Event Bus global via autoload com sinais (phase_changed, gladiator_died, drift_triggered) eliminando acoplamento entre UI, logica e audio, e composicao modular com nos utilitarios independentes (HealthComponent, HitboxComponent, HurtboxComponent, DriverComponent). Use sempre que o pedido envolver esquemas de dados .tres, Event Bus, sinais globais entre cenas, ou componentes modulares de vida/dano.
---

# 📦 Godot Data-Driven Architecture

Skill de desacoplamento estrutural para **Godot 4** (engine local: `D:\epicgms\GodotEngine`): dados estáticos, comunicação global por eventos e composição modular de nós.

---

## 🧭 Pilares

### 1. 🧬 Recursos Personalizados (`Resource`)
Esquemas estáticos em `.tres` — *zero balanceamento hardcoded*:
- `GladiatorData` — stats de gladiadores do auto chess (vida, dano, feitiço, traits, custo).
- `VehicleStats` — tuning de veículos isométricos (espelha os exports de `isometric_vehicle.gd`).
- Fluxo: criar `data/resources/gladiators/x.tres`, arrastar para o export `stats` do gladiador. Mudar balanceamento **sem tocar em código**.

### 2. 📡 Event Bus (Autoload `EventBus`)
Centralização de sinais globais — a UI, a lógica e o áudio **nunca** se referenciam diretamente:
- **Emissor**: `EventBus.gladiator_died.emit(self, team)` em qualquer nó de lógica.
- **Consumidor**: `EventBus.gladiator_died.connect(_on_gladiator_died)` no HUD/áudio, comunique o que precisa, nada mais.
- Sinais principais: `phase_changed`, `gladiator_died`, `gladiator_attacked`, `spell_cast`, `leader_damaged`, `combat_started`, `combat_ended`, `match_ended`, `unit_deployed`, `units_repositioned`, `drift_triggered`, `lap_completed`, `race_finished`, `screen_shake_requested`, `sfx_requested`, `toast_requested`.

### 3. 🧩 Composição Modular
Nós utilitários independentes, reutilizáveis em gladiadores E veículos:
- `HealthComponent` — única fonte de verdade de vida; emite `died`, `damaged`, `healed`, `health_changed`.
- `HitboxComponent` (Area2D) — infligir dano; colide apenas com `HurtboxComponent` de outra equipa.
- `HurtboxComponent` (Area2D) — receber dano; encaminha para o `HealthComponent` do dono.
- `DriverComponent` — gladiador condutor: aplica um `VehicleStats.tres` ao carro via `set()` (composição sem herança).

---

## 📦 Ficheiros da Skill

| Ficheiro | Função |
|---|---|
| `scripts/event_bus.gd` | Autoload global completo com todos os sinais dos dois jogos. |
| `scripts/gladiator_data.gd` | Esquema `Resource` de gladiadores. |
| `scripts/vehicle_stats.gd` | Esquema `Resource` de tuning veicular. |
| `scripts/health_component.gd` | Vida modular (fonte de verdade). |
| `scripts/hitbox_component.gd` | Área que inflige dano (com team-masking). |
| `scripts/hurtbox_component.gd` | Área que recebe dano (compõe com HealthComponent). |
| `scripts/driver_component.gd` | Ponte gladiador ↔ veículo via `VehicleStats`. |

---

## ⚙️ Instalação do Autoload

1. Copiar `scripts/event_bus.gd` para `res://core/autoload/event_bus.gd` no projeto.
2. **Project ➔ Project Settings ➔ Autoload**: nome `EventBus`, path `*res://core/autoload/event_bus.gd` (* = singleton).
3. Todos os scripts desta skill e das skills irmãs usam `get_node_or_null("/root/EventBus")` — o projeto **compila mesmo sem** o autoload (apenas não emite eventos).

---

## ⚙️ Estrutura de Cena Recomendada (Gladiador)

```text
GladiatorFSM (Node2D)
├── HealthComponent (Node)
├── HitboxComponent (Area2D + CollisionShape2D)
└── HurtboxComponent (Area2D + CollisionShape2D)  # health auto-descoberto como irmão/pai
```

## 🔗 Integração com as outras Skills

- **`godot-autochess-battle-logic`** — `GladiatorFSM` consome `GladiatorData.tres` e emite os eventos de partida no `EventBus`.
- **`godot-isometric-vehicle-physics`** — `IsometricVehicle` emite `drift_triggered`; o `DriverComponent` injeta os `.tres` de tuning no carro.

---

## 🔍 Validação Headless

```bash
python D:\GitHub\antigravity-skills\skills\godot-multigenre-antigravity\scripts\build_project.py --project-path "D:\caminho\do\projeto" --check-only
```
