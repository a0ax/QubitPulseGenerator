"""Behavioral model for pulse_gen."""

from dataclasses import dataclass


@dataclass
class PulseGenModel:
    width_bits: int = 8
    period_bits: int = 16
    count: int = 0
    pulse: int = 0
    busy: int = 0

    @property
    def width_mask(self) -> int:
        return (1 << self.width_bits) - 1

    @property
    def period_mask(self) -> int:
        return (1 << self.period_bits) - 1

    def reset(self) -> None:
        self.count = 0
        self.pulse = 0
        self.busy = 0

    def step(self, enable: int, width: int, period: int) -> tuple[int, int]:
        width = width & self.width_mask
        period = period & self.period_mask

        if (not enable) or (period == 0) or (width == 0):
            self.reset()
            return self.pulse, self.busy

        width_eff = min(width, period)
        self.busy = 1
        self.pulse = 1 if self.count < width_eff else 0
        if self.count == period - 1:
            self.count = 0
        else:
            self.count += 1
        return self.pulse, self.busy