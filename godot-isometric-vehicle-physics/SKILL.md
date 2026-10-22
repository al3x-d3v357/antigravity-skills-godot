---
name: godot-isometric-vehicle-physics
description: Fisica arcade de veiculos para Godot 4 em perspetiva isometrica (2.5D/3D) com CharacterBody3D - decomposicao tangencial/lateral da velocidade, drift com atenacao de tracao lateral via lerp, rotacao vetorial de entrada a 45 graus (rotated(Vector3.UP, deg_to_rad(45.0))) e camara ortografica (PROJECTION_ORTHOGONAL) desacoplada sem jitter. Use sempre que o pedido envolver carro de corrida isometrico, drift arcade, camara ortografica de topo ou pistas no projeto Godot.
---

# 🏎️ Godot Isometric Vehicle Physics

Skill de controlo veicular arcade em perspetiva isométrica para **Godot 4** (engine local: `D:\epicgms\GodotEngine`).

---

## 🧭 Princípios de Física

1. **Nó base `CharacterBody3D`** — movimento ágil por vetores locais. *Nunca* `RigidBody3D` para carros arcade isométricos (a conservação de momento geraria deriva indesejada).
2. **Decomposição da velocidade** — a cada frame, a velocidade do corpo é projetada nos eixos locais do chassi:
   - Componente **longitudinal** (avanço/recuo) — controlada pelo motor.
   - Componente **lateral** (derrapagem) — atenuada por atrito artificial.
3. **Drift via `lerp`** — durante o travão de mão, a tração lateral é interpolada de `lateral_grip` para `drift_grip`, deixando a velocidade lateral "escapar" e o carro deslizar em curva.
4. **Rotação de entrada a 45°** — o vetor de input é girado no plano horizontal (`rotated(Vector3.UP, deg_to_rad(45.0))`) para alinhar as teclas direcionais com a diagonal visual da perspetiva isométrica.
5. **Câmara anti-jitter** — `Camera3D` com `PROJECTION_ORTHOGONAL` num nó **separado** (nunca filha do carro / da sua hierarquia de rotação), seguindo apenas a posição via `lerp` exponencial na `_physics_process`.

---

## 📦 Ficheiros da Skill

| Ficheiro | Função |
|---|---|
| `scripts/isometric_vehicle.gd` | Controlador arcade completo: motor, direção, drift e emissão do sinal global `drift_triggered`. |
| `scripts/isometric_camera.gd` | Rig de câmara ortográfica isométrica (isometria verdadeira ~35.26°, yaw 45°), segue só a posição. |

---

## ⚙️ Setup Rápido na Cena

```text
Track (Node3D)
├── Vehicle (CharacterBody3D + isometric_vehicle.gd)
│   └── CollisionShape3D          # chassi
└── CameraRig (Camera3D + isometric_camera.gd)
    # ⚠️ NÃO é filha do Vehicle — hierarquia independente obrigatória
```

1. Anexar `isometric_vehicle.gd` ao `CharacterBody3D` e definir o `CollisionShape3D` do chassi.
2. Colocar a `Camera3D` **fora** da hierarquia do carro, anexar `isometric_camera.gd` e atribuir o `target` (o carro).
3. Registar as ações no **Project Settings ➔ Input Map**: `move_left`, `move_right`, `move_up`, `move_down`, `handbrake` (os nomes são exportáveis no _Inspector_).
4. *(Opcional, recomendado)* Registar o autoload `EventBus` da skill `godot-data-driven-architecture` para que o início de drift emita `drift_triggered(vehicle, intensity)` — o script usa `get_node_or_null("/root/EventBus")`, logo funciona também sem o autoload.

---

## 🔗 Integração com as outras Skills

- **`godot-data-driven-architecture`** — aplique um `VehicleStats.tres` no carro com `DriverComponent.apply_to_stats()` para tuning por peças (motor, suspensão, pneus).
- **`godot-autochess-battle-logic`** — o `MatchManager` e o `EventBus` partilham os mesmos sinais globais, permitindo corridas e combates no mesmo ecosistema de eventos.

---

## 🔍 Validação Headless

```bash
# Sintaxe GDScript + import de assets, sem abrir janela:
python D:\GitHub\antigravity-skills\skills\godot-multigenre-antigravity\scripts\build_project.py --project-path "D:\caminho\do\projeto" --check-only

# Alternativa direta com o binário console:
D:\epicgms\GodotEngine\Godot_v4.7.2-stable_win64_console.exe --headless --path "D:\caminho\do\projeto" --quit
```
