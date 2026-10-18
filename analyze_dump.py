"""Офлайн-анализатор дампа Recorder (SavedVariables/DrDamage.lua -> CoreDB.recorder.sessions).

Записи позиционные: { t, kind, ... }
  M: t, игрок, версия протокола
  P: t, спелл, слот, цель, source, reason, гкд_активен, гкд_остаток, лаг, FPS, FAILED-гейт
  A: t, событие UNIT_SPELLCAST_*, спелл
  C: t, CLEU-таймстемп, SPELL_CAST_*, спелл
  E: t, текст ошибки
  G: t, спелл, текст ошибки? (nil = 'FAILED:'-таймер взведён, иначе = наполнение буфера)
  R: t, reason

Запуск без аргументов: сводка по каждой сессии (метрики §6 RECORDER.md).
"""
import re
import bisect
from collections import Counter

F = r"D:/Games/World of Warcraft Sirus/WTF/Account/KLUORY/SavedVariables/DrDamage.lua"

# самая внутренняя запись: поля с маркерами -- [n], nil допустим
FIELD = re.compile(r'([\d.]+|true|false|nil|"[^"]*?"), -- \[\d+\]')
SESSION_REC = re.compile(r'\["records"\] = \{')
SESSION_T0 = re.compile(r'\["t0"\] = ([\d.]+)')
SESSION_T1 = re.compile(r'\["t1"\] = ([\d.]+)')


def parse_fields(block):
    fields = FIELD.findall(block)
    return [f[1:-1] if f.startswith('"') else f for f in fields]


def parse_sessions(src):
    """[(t0, t1, records)] в порядке следования сессий."""
    recs_pos = [m.start() for m in SESSION_REC.finditer(src)]
    t0s = list(SESSION_T0.finditer(src))
    t1s = list(SESSION_T1.finditer(src))
    assert len(recs_pos) == len(t0s) == len(t1s), "структура дампа не распознана"
    out = []
    for i, m in enumerate(t0s):
        # записи сессии лежат между её ["records"] = { и её ["t0"]
        block = src[recs_pos[i]:m.start()]
        records = []
        for b in re.findall(r'\{([^{}]*)\}', block):
            f = parse_fields(b)
            if len(f) >= 3:
                records.append(f)
        out.append((float(t0s[i].group(1)), float(t1s[i].group(1)), records))
    return out


def bursts(presses, gap=0.35):
    """Максимальные последовательности нажатий одного спелла с зазором <=gap.
    Возвращает (hist{размер: кол-во}, нажатий_в_сериях, одиночных, [(t, спелл, размер)])."""
    hist, firsts = Counter(), []
    in_series = singles = 0
    i = 0
    while i < len(presses):
        t, sp = float(presses[i][0]), presses[i][2]
        n, j = 1, i + 1
        while j < len(presses) and presses[j][2] == sp and \
                0 <= float(presses[j][0]) - float(presses[j - 1][0]) <= gap:
            n += 1
            j += 1
        if n == 1:
            singles += 1
        else:
            hist[n] += 1
            in_series += n
            firsts.append((t, sp, n))
        i = j
    assert in_series + singles == len(presses), "инвариант серий нарушен"
    return hist, in_series, singles, firsts


def pct(sorted_vals, p):
    return sorted_vals[min(int(len(sorted_vals) * p), len(sorted_vals) - 1)]


def press_acks(records):
    """(медиана, p90, max, n) press->ack: первый press спелла до ближайшего
    SUCCEEDED/SUCCESS того же спелла."""
    ack_sp = [(float(r[0]), r[-1]) for r in records if r[1] in ('A', 'C')
              and ('SUCCEEDED' in ' '.join(r) or r[3] == 'SPELL_CAST_SUCCESS')]
    ack_sp.sort()
    at = [t for t, _ in ack_sp]
    deltas = []
    for r in records:
        if r[1] != 'P' or r[2] == 'nil':
            continue
        i = bisect.bisect_left(at, float(r[0]))
        if i < len(ack_sp) and ack_sp[i][1] == r[2]:
            deltas.append((ack_sp[i][0] - float(r[0])) * 1000)
    if not deltas:
        return None
    deltas.sort()
    return deltas[len(deltas) // 2], pct(deltas, 0.9), deltas[-1], len(deltas)


def summarize(t0, t1, records):
    dur = t1 - t0
    print(f"\n=== сессия {t0:.0f}..{t1:.0f} ({dur:.0f}с), записей {len(records)} ===")
    kinds = Counter(r[1] for r in records)
    print("каналы:", dict(sorted(kinds.items())))

    presses = [r for r in records if r[1] == 'P' and r[2] != 'nil']
    acks = [r for r in records if r[1] in ('A', 'C')
            and ('SUCCEEDED' in ' '.join(r) or r[3] == 'SPELL_CAST_SUCCESS')]
    print(f"P-нажатий: {len(presses)}, подтверждений успеха: {len(acks)}, "
          f"press/cast: {len(presses) / max(len(acks), 1):.2f}")

    hist, in_series, singles, firsts = bursts(sorted(presses, key=lambda r: float(r[0])))
    print(f"одиночных: {singles} ({singles * 100 // max(len(presses), 1)}%), "
          f"серий: {sum(hist.values())} (нажатий в сериях: {in_series})")
    print("гистограмма серий:", dict(sorted(hist.items())))

    pa = press_acks(records)
    if pa:
        print(f"press->ack (мс): медиана {pa[0]:.0f}, p90 {pa[1]:.0f}, max {pa[2]:.0f}, n={pa[3]}")

    lat = sorted(float(r[9]) for r in presses if len(r) > 9 and r[9] != 'nil')
    fps = sorted(float(r[10]) for r in presses if len(r) > 10 and r[10] != 'nil')
    if lat:
        print(f"лаг в прессах (с): медиана {pct(lat, 0.5):.3f}, p95 {pct(lat, 0.95):.3f}, max {lat[-1]:.3f}")
    if fps:
        print(f"FPS в прессах: медиана {pct(fps, 0.5):.0f}, min {fps[0]:.0f}")

    errors = Counter(r[2] for r in records if r[1] == 'E')
    if errors:
        print("ошибки E:", dict(errors.most_common()))
    gated = sum(1 for r in presses if len(r) > 11 and r[11] == 'true')
    print(f"прессов при взведённом FAILED-гейте: {gated} (должно быть 0 — гейт запрещает пресс)")
    gate_timer = sum(1 for r in records if r[1] == 'G' and (len(r) < 4 or r[3] == 'nil'))
    gate_buf = sum(1 for r in records if r[1] == 'G' and len(r) > 3 and r[3] != 'nil')
    if gate_timer or gate_buf:
        print(f"G-гейт: 'FAILED:'-таймер взведён {gate_timer} раз, буфер наполнен {gate_buf} раз")
    ev = Counter(r[2] for r in records if r[1] == 'A')
    if ev:
        print("A-события:", dict(ev))
    print("топ спеллов:", Counter(r[2] for r in presses).most_common(8))


if __name__ == '__main__':
    src = open(F, encoding='utf-8').read()
    for t0, t1, records in parse_sessions(src):
        summarize(t0, t1, records)
