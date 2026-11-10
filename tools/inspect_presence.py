#!/usr/bin/env python3
"""Просмотр .presence файла без Godot. Показывает, что формат открытый."""
import json
import sys

def inspect(path):
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    frames = data.get("frames", [])
    version = data.get("version", "?")
    print(f"Файл: {path}")
    print(f"Версия: {version}")
    print(f"Создан: {data.get('created_at', '?')}")
    print(f"FPS (справочно): {data.get('fps', '?')}")
    print(f"Кадров: {len(frames)}")
    if not frames:
        return
    first = frames[0]
    last = frames[-1]
    print(f"Длительность: {last['t'] - first['t']:.2f} сек")
    h0 = first["h"]["p"]
    h1 = last["h"]["p"]
    dx = h1[0] - h0[0]; dy = h1[1] - h0[1]; dz = h1[2] - h0[2]
    dist = (dx*dx + dy*dy + dz*dz) ** 0.5
    print(f"Путь головы: {dist:.2f} м")
    print(f"  от {h0} до {h1}")
    print(f"Руки в первом кадре: L={first['l']['p']} R={first['r']['p']}")
    print("OK: формат читается любым JSON-парсером.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Использование: python inspect_presence.py <file.json>")
        sys.exit(1)
    inspect(sys.argv[1])