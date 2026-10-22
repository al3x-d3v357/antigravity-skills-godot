---
name: godot-multigenre-antigravity
description: Especialista em arquitetura, geracao de codigo e automacao para Godot Engine 4 (localizado em D:\epicgms\GodotEngine). Especializado em Tower Defense, jogos taticos por Turnos (Turn-Based) e corridas/combate de Veiculos Antigravitacionais Top-Down (2D e 3D) com fisica de amortecimento e suspensao por raycast. Use sempre que o usuario solicitar desenvolvimento de jogos na Godot, scaffolding de generos, scripts GDScript, fisica de levitacao, state machines de combate ou execucao headless.
---

# 🚀 Godot Multi-Genre Antigravity Specialist

Especialista avançado na **Godot Engine 4** focado em três gêneros mecânicos de alta fidelidade e na automação direta da engine instalada no ambiente local (`D:\epicgms\GodotEngine`).

---

## 🛠️ Ambiente Local & Executáveis da Engine

- **Caminho da Engine**: `D:\epicgms\GodotEngine`
- **Binário Console (CLI / Headless)**: `D:\epicgms\GodotEngine\Godot_v4.7.2-stable_win64_console.exe`
- **Binário Alternativo**: `D:\epicgms\GodotEngine\Godot_v4.7.1-stable_win64_console.exe`
- **Binário Gráfico (Editor UI)**: `D:\epicgms\GodotEngine\Godot_v4.7.2-stable_win64.exe`

> **Regra de Execução**: Em automações, testes de sintaxe e headless pelo Antigravity IDE, utilize sempre os executáveis `*_console.exe` ou a flag `--headless` para evitar janelas presas e travamentos de processo.

---

## 🧭 Diretrizes de Arquitetura por Gênero

### 1. 🛡️ Tower Defense (TD)
- **Navegação de Inimigos**: Utilize nós nativos `Path2D` e `PathFollow2D` para caminhos pré-determinados com atualização via `progress_ratio`. Para mapas abertos com colocação de labirintos, use `NavigationServer2D` com baking de malha em tempo real.
- **Grid & Validação de Construção**: Utilize `TileMapLayer` do Godot 4. Valide células de construção verificando células navegáveis, recursos do jogador e ausência de torres pré-existentes.
- **Pipeline Desacoplado de Combate**:
  - `HitboxComponent` (Area2D): Carrega atributos de dano, tipo de elemento e máscara de colisão dos alvos.
  - `HurtboxComponent` (Area2D): Recebe o impacto, calcula resistências e emite o sinal `took_damage(amount, damage_type)`.
- **Targeting das Torres**: Implemente modos de mira configuráveis via enum (`FIRST`, `LAST`, `STRONGEST`, `CLOSEST`).
- 📖 *Documentação completa: consulte `references/tower_defense.md`.*

---

### 2. ♟️ Tático por Turnos (Turn-Based Tactics)
- **State Machine de Fases**: Estruture o ciclo de combate em fases previsíveis:
  `SETUP` ➔ `ROUND_START` ➔ `PLAYER_PHASE` ➔ `ENEMY_PHASE` ➔ `RESOLVE_ACTIONS` ➔ `ROUND_END`
- **Command Pattern para Ações**: Todas as movimentações, ataques e conjurações de habilidades devem encapsular uma classe derivada de `Command`:
  - `execute()`: Realiza a ação e aciona animações assíncronas (`await`).
  - `undo()`: Reverte o estado caso o jogador cancele o movimento antes de confirmar.
- **Ordem de Iniciativa & AP**: Combatentes ordenados por velocidade em fila de prioridade (`initiative_queue`). Cada unidade possui `ActionPoints (AP)` consumidos por passo ou custo da habilidade.
- 📖 *Documentação completa: consulte `references/turn_based.md`.*

---

### 3. 🛸 Veículos Antigravitacionais Top-Down (2D & 3D)
- **Modelo de Física**: Sempre utilize `RigidBody2D` ou `RigidBody3D`. Não utilize `CharacterBody` para corridas onde conservação de momento, peso e derrapagem conferem a sensação de gravidade zero.
- **Suspensão por Raycast (Spring-Damper)**:
  - Projetores de raios (`RayCast2D` em 2D ou 4 `RayCast3D` nos vértices do chassi em 3D) calculam a distância da superfície.
  - Aplicação de força elástica proporcional à compressão, amortecida pela velocidade linear projetada:
    ```text
    compressao = hover_height - distancia_colisao
    forca_mola = compressao * spring_stiffness
    forca_amortecimento = velocidade_vertical * damping
    impulso_total = (forca_mola - forca_amortecimento) * normal_superficie
    ```
- **Controle de Derrapagem (Lateral Friction)**: Calcule o vetor de derrapagem lateral e aplique resistência configurável (`drift_factor`), permitindo curvas com deslize controlado (*powerslide*) estilo Wipeout / F-Zero.
- 📖 *Documentação completa: consulte `references/topdown_vehicle.md`.*

---

## ⚡ Automação & Ferramental Incluso na Skill

### 1. Automação Headless e Execução de Projetos (`scripts/build_project.py`)
Localizado na pasta de scripts da skill, detecta automaticamente o Godot 4 no ambiente do Alex:

```bash
# Validar sintaxe GDScript e importar assets sem abrir janela
python scripts/build_project.py --project-path "D:\caminho\do\projeto" --check-only

# Executar uma cena de teste específica
python scripts/build_project.py --project-path "D:\caminho\do\projeto" --run-scene "res://scenes/test_arena.tscn"

# Executar projeto completo no modo gráfico
python scripts/build_project.py --project-path "D:\caminho\do\projeto" --run
```

### 2. Gerador Rápido de Esqueleto (Scaffolding) (`scripts/scaffold_genre.py`)
Cria um projeto Godot 4 completo, com `project.godot`, cenas `.tscn` e scripts `.gd` pré-configurados:

```bash
# Criar projeto de Veículo Antigravitacional
python scripts/scaffold_genre.py --genre topdown_vehicle --output-dir "D:\GitHub\antigravity_racing"

# Criar projeto de Tower Defense
python scripts/scaffold_genre.py --genre tower_defense --output-dir "D:\GitHub\antigravity_td"

# Criar projeto Tático por Turnos
python scripts/scaffold_genre.py --genre turn_based --output-dir "D:\GitHub\antigravity_tactics"
```

---

## 📂 Padrão de Nomenclatura & Estrutura de Arquivos

```text
res://
├── scenes/
│   ├── actors/            # Personagens, naves, torres, projéteis
│   ├── levels/            # Pistas, tabuleiros, mapas
│   └── ui/                # HUDs, indicadores de turno, inventário
├── scripts/
│   ├── components/        # HitboxComponent.gd, HurtboxComponent.gd, HoverSuspension2D.gd
│   ├── core/              # StateMachine.gd, Command.gd, SignalBus.gd
│   └── managers/          # TurnManager.gd, WaveManager.gd, ProjectilePool.gd
└── resources/             # .tres para balanceamento de dados (Stats, Waves, Units)
```
