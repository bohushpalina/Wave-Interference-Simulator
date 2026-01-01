from PySide6.QtCore import QObject, Signal, Slot, QTimer
from simulation import InterferenceSimulator
import numpy as np

class Backend(QObject):
    imageReady = Signal(list)
    phaseChanged = Signal(float)
    glowPhaseChanged = Signal(float)
    filterChanged = Signal(int)

    def __init__(self):
        super().__init__()
        self.sim = InterferenceSimulator(200, 200)
        self.s1 = [0.5 * self.sim.width, 0.5 * self.sim.height]
        self.s2 = [0.5 * self.sim.width, 0.5 * self.sim.height]
        self.wavelength1 = 20
        self.wavelength2 = 20
        self.simPhase = 0.0
        self.glowPhase = 0.0
        self.currentFilter = 0  # индекс фильтра

        self.timer = QTimer()
        self.timer.timeout.connect(self.recalculate)
        self.timer.start(33)

    @Slot(float, float)
    def setSource1(self, x, y):
        self.s1 = [x * self.sim.width, y * self.sim.height]

    @Slot(float, float)
    def setSource2(self, x, y):
        self.s2 = [x * self.sim.width, y * self.sim.height]

    @Slot(float)
    def setWavelength1(self, w):
        self.wavelength1 = w

    @Slot(float)
    def setWavelength2(self, w):
        self.wavelength2 = w

    @Slot(int)
    def setFilter(self, f):
        self.currentFilter = f
        self.filterChanged.emit(f)

    @Slot()
    def recalculate(self):
        data = self.sim.calculate(self.s1, self.s2, self.wavelength1, self.wavelength2)
        self.simPhase += 0.02
        if self.simPhase > 2*np.pi:
            self.simPhase -= 2*np.pi

        self.glowPhase += 0.1
        if self.glowPhase > 2*np.pi:
            self.glowPhase -= 2*np.pi

        self.phaseChanged.emit(self.simPhase)
        self.glowPhaseChanged.emit(self.glowPhase)
        self.imageReady.emit(data.flatten().tolist())
