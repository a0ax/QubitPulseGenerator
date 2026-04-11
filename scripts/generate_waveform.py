#!/usr/bin/env python3
"""Generate a timing diagram for the multi-channel pulse generator."""

from pathlib import Path

import matplotlib.pyplot as plt


def min_u(a: int, b: int) -> int:
    return a if a < b else b


def simulate_channel(width: int, period: int, enable: list[int]) -> tuple[list[int], list[int]]:
    count = 0
    pulse = []
    busy = []

    for en in enable:
        if not en or width == 0 or period == 0:
            pulse.append(0)
            busy.append(0)
            count = 0
            continue

        width_eff = min_u(width, period)
        pulse.append(1 if count < width_eff else 0)
        busy.append(1)

        if count == period - 1:
            count = 0
        else:
            count += 1

    return pulse, busy


def square_clock(cycles: int) -> list[int]:
    return [1 if (cycle % 2) else 0 for cycle in range(cycles)]


def step_series(values: list[int]) -> tuple[list[int], list[int]]:
    xs = []
    ys = []
    for index, value in enumerate(values):
        xs.extend([index, index + 1])
        ys.extend([value, value])
    return xs[1:], ys[1:]


def main() -> None:
    cycles = 32
    x = list(range(cycles))
    enable = [1 if 2 <= cycle < 26 else 0 for cycle in range(cycles)]
    clk = square_clock(cycles)

    ch0, busy0 = simulate_channel(2, 8, enable)
    ch1, _ = simulate_channel(0, 8, enable)
    ch2, _ = simulate_channel(8, 8, enable)
    busy = [1 if (ch0[i] or ch1[i] or ch2[i]) else 0 for i in range(cycles)]

    fig, axes = plt.subplots(3, 1, sharex=True, figsize=(14, 8), gridspec_kw={"height_ratios": [1.1, 1.8, 0.9]})
    fig.patch.set_facecolor("#0b1020")
    for axis in axes:
        axis.set_facecolor("#10172a")
        axis.grid(True, axis="x", color="#26314f", alpha=0.35, linewidth=0.8)
        axis.grid(True, axis="y", color="#26314f", alpha=0.20, linewidth=0.6)
        axis.tick_params(colors="#d7def7")
        for spine in axis.spines.values():
            spine.set_color("#40527a")

    clock_x, clock_y = step_series(clk)
    enable_x, enable_y = step_series(enable)
    axes[0].step(clock_x, [value + 1.0 for value in clock_y], where="post", color="#7dd3fc", linewidth=2.0, label="clk")
    axes[0].step(enable_x, enable_y, where="post", color="#f59e0b", linewidth=2.0, label="enable")
    axes[0].set_ylim(-0.25, 2.35)
    axes[0].set_ylabel("Top", color="#d7def7")
    axes[0].legend(loc="upper right", frameon=False, labelcolor="#e8eefc")
    axes[0].set_title("Multi-Channel Pulse Generator Timing Diagram", color="#f4f7ff", fontsize=16, pad=12)

    ch0_x, ch0_y = step_series(ch0)
    ch1_x, ch1_y = step_series(ch1)
    ch2_x, ch2_y = step_series(ch2)
    axes[1].step(ch0_x, [value + 2.0 for value in ch0_y], where="post", color="#22c55e", linewidth=2.0, label="ch0 width=2 period=8")
    axes[1].step(ch1_x, [value + 1.0 for value in ch1_y], where="post", color="#ef4444", linewidth=2.0, label="ch1 width=0 period=8")
    axes[1].step(ch2_x, ch2_y, where="post", color="#a78bfa", linewidth=2.0, label="ch2 width=period=8")
    axes[1].set_ylim(-0.25, 3.35)
    axes[1].set_ylabel("Channels", color="#d7def7")
    axes[1].legend(loc="upper right", frameon=False, labelcolor="#e8eefc")

    busy_x, busy_y = step_series(busy)
    axes[2].step(busy_x, busy_y, where="post", color="#f97316", linewidth=2.4, label="busy OR")
    axes[2].set_ylim(-0.25, 1.35)
    axes[2].set_ylabel("Busy", color="#d7def7")
    axes[2].set_xlabel("Clock cycles", color="#d7def7")
    axes[2].legend(loc="upper right", frameon=False, labelcolor="#e8eefc")

    axes[2].set_xticks(range(0, cycles + 1, 2))
    axes[2].set_xlim(0, cycles)

    fig.text(0.02, 0.015, "ch0: 2/8  ch1: 0/8  ch2: 8/8", color="#b8c6ea", fontsize=10)
    fig.tight_layout(rect=[0, 0.03, 1, 0.98])

    output = Path(__file__).resolve().parent.parent / "docs" / "waveform.png"
    output.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output, dpi=600, facecolor=fig.get_facecolor(), bbox_inches="tight")
    plt.close(fig)
    print(f"Wrote {output}")


if __name__ == "__main__":
    main()