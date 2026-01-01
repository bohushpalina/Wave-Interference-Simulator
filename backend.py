from PySide6.QtCore import QObject, Signal, Slot, QTimer
from simulation import InterferenceSimulator

class Backend(QObject):
    imageReady = Signal(list)  # передаём маленький массив в QML

    def __init__(self):
        super().__init__()
        self.sim = InterferenceSimulator(200, 200)
        self.s1 = [0.5 * self.sim.width, 0.5 * self.sim.height]
        self.s2 = [0.5 * self.sim.width, 0.5 * self.sim.height]
        self.wavelength = 20

        self.timer = QTimer()
        self.timer.timeout.connect(self.recalculate)
        self.timer.start(33)  # ~30 FPS

    @Slot(float, float)
    def setSource1(self, x, y):
        self.s1 = [x * self.sim.width, y * self.sim.height]

    @Slot(float, float)
    def setSource2(self, x, y):
        self.s2 = [x * self.sim.width, y * self.sim.height]

    @Slot(float)
    def setWavelength(self, w):
        self.wavelength = w

    @Slot()
    def recalculate(self):
        data = self.sim.calculate(self.s1, self.s2, self.wavelength)
        self.imageReady.emit(data.flatten().tolist())
