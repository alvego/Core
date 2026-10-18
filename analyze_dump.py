import re, bisect
from collections import Counter

F = r"D:/Games/World of Warcraft Sirus/WTF/Account/KLUORY/SavedVariables/DrDamage.lua"
src = open(F, encoding='utf-8').read()

# записи — самые внутренние блоки { ... }, -- [n] (вложенных таблиц в записях нет)
val = r'([\d.]+|true|false|nil|"[^"]*?"), -- \[\d+\]'
recs = []
for block in re.findall(r'\{([^{}]*)\}', src):
    fields = re.findall(val, block)
    if len(fields) >= 3:
        recs.append([f[1:-1] if f.startswith('"') else f for f in fields])
print("всего записей распознано:", len(recs))

presses = sorted([(float(f[0]), f[2]) for f in recs if f[1] == 'P' and f[2] != 'nil'])
acks = sorted([(float(f[0]), f[-1]) for f in recs
               if f[1] in ('A', 'C') and
               ('SUCCEEDED' in ' '.join(f) or 'SUCCESS' in ' '.join(f))])
print(f"P-нажатий: {len(presses)}, подтверждений успеха: {len(acks)}")

# максимальные серии: подряд идущие нажатия одного спелла с зазором <=0.35с
# (легитимных повторов того же спелла внутри 0.35с не бывает — GCD >= 1с)
burst_hist = Counter()
series_first = []  # (t первого пресса серии, спелл, размер)
singles = 0
i = 0
while i < len(presses):
    t, sp = presses[i]
    n = 1
    j = i + 1
    while j < len(presses) and presses[j][1] == sp and 0 <= presses[j][0] - presses[j - 1][0] <= 0.35:
        n += 1
        j += 1
    if n == 1:
        singles += 1
    else:
        burst_hist[n] += 1
        series_first.append((t, sp, n))
    i = j
total_burst_presses = sum(n * c for n, c in burst_hist.items())
assert total_burst_presses + singles == len(presses), \
    f"инвариант нарушен: {total_burst_presses}+{singles} != {len(presses)}"
print(f"одиночных: {singles}, серий: {sum(burst_hist.values())} "
      f"(нажатий в сериях: {total_burst_presses} из {len(presses)})")
print("гистограмма максимальных серий:", dict(sorted(burst_hist.items())))

# press->ack: от ПЕРВОГО пресса серии до первого подтверждения того же спелла
at = [t for t, _ in acks]
deltas = []
for t, sp, _ in series_first:
    i = bisect.bisect_left(at, t)
    if i < len(at) and acks[i][1] == sp:
        deltas.append((at[i] - t) * 1000)
if deltas:
    deltas.sort()
    print(f"press->ack серий (мс): медиана {deltas[len(deltas)//2]:.0f}, "
          f"p90 {deltas[int(len(deltas)*0.9)]:.0f}, max {deltas[-1]:.0f}, n={len(deltas)}")

print("топ спеллов по нажатиям:", Counter(sp for _, sp in presses).most_common(8))
