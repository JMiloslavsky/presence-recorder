# demo_flight.json — «полёт над лесом»

Это эталонная запись для тестирования PresenceRecorder.

## Что записано
- Длительность: 2 секунды
- Голова: поднимается с 1.6 м до 3.8 м, улетает на 10 м вперёд
- Руки: следуют за головой, вытянуты вперёд
- Поворот головы: лёгкий наклон вперёд (0 → 0.45 рад)

## Как пережить
1. Открой `examples/load_and_play.gd` в Godot.
2. Создай пустую сцену с `Node3D` → `GhostHead`, `GhostLeftHand`, `GhostRightHand`.
3. Повесь скрипт на `Node`, перетащи узлы.
4. Запусти — призрак полетит.

## Как проверить без Godot
```bash
python tools/inspect_presence.py examples/demo_flight.json