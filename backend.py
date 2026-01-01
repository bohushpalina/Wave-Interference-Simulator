from PySide6.QtCore import QObject, Signal, Slot, QTimer, Qt
from simulation import InterferenceSimulator
from PySide6.QtGui import QImage, QPainter, QColor, QFont, QRadialGradient
from PySide6.QtWidgets import QFileDialog
import numpy as np

class Backend(QObject):
    imageReady = Signal(list)
    phaseChanged = Signal(float)
    glowPhaseChanged = Signal(float)
    filterChanged = Signal(int)
    cursorPosChanged = Signal(float, float)

    def __init__(self):
        super().__init__()
        self.sim = InterferenceSimulator(200, 200)
        self.s1 = [0.5 * self.sim.width, 0.5 * self.sim.height]
        self.s2 = [0.5 * self.sim.width, 0.5 * self.sim.height]
        self.wavelength1 = 20
        self.wavelength2 = 20
        self.simPhase = 0.0
        self.glowPhase = 0.0
        self.currentFilter = 0
        self.imageData = None
        self.showGrid = True  # флаг сетки

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

    @Slot(bool)
    def setShowGrid(self, value):
        self.showGrid = value

    @Slot(float, float)
    def setCursorPos(self, x, y):
        self.cursorPosChanged.emit(x, y)

    @Slot()
    def recalculate(self):
        if self.sim is None:
            return
        data = self.sim.calculate(self.s1, self.s2, self.wavelength1, self.wavelength2)
        self.imageData = data.copy()

        # Анимация фаз
        self.simPhase += 0.02
        if self.simPhase > 2*np.pi:
            self.simPhase -= 2*np.pi

        self.glowPhase += 0.1
        if self.glowPhase > 2*np.pi:
            self.glowPhase -= 2*np.pi

        # Сигналы для QML
        self.phaseChanged.emit(self.simPhase)
        self.glowPhaseChanged.emit(self.glowPhase)
        self.imageReady.emit(data.flatten().tolist())

    @Slot()
    def saveImage(self):
        """Сохраняет скриншот с увеличенными пикселями интерференции и подписью"""
        if self.imageData is None:
            print("Нет данных для сохранения")
            return

        options = QFileDialog.Options()
        filePath, _ = QFileDialog.getSaveFileName(
            None,
            "Сохранить изображение",
            "interference.png",
            "PNG Files (*.png);;All Files (*)",
            options=options
        )
        if not filePath:
            return

        scale = 4  # увеличиваем пиксели в 4 раза
        width = self.sim.width * scale
        height = self.sim.height * scale + 60  # место для подписи

        img = QImage(width, height, QImage.Format_ARGB32)
        img.fill(QColor("black"))

        painter = QPainter(img)

        # --- Интерференция (каждый пиксель увеличен) ---
        flat = self.imageData.flatten()
        for y in range(self.sim.height):
            for x in range(self.sim.width):
                val = flat[y*self.sim.width + x]
                if self.currentFilter == 0:
                    r = int(val*255)
                    g = int(val*val*200)
                    b = int((1-val)*255)
                elif self.currentFilter == 1:
                    r = int((1-val)*255)
                    g = int(val*255)
                    b = int((1-val)*255)
                else:
                    r = int(val*255)
                    g = int(val*128)
                    b = int(val*64)
                painter.fillRect(x*scale, y*scale, scale, scale, QColor(r, g, b))

        # --- Сетка ---
        if self.showGrid:
            painter.setPen(QColor(255, 255, 255, 50))
            stepX = width // 10
            stepY = (height-60) // 10
            for i in range(11):
                painter.drawLine(i*stepX, 0, i*stepX, height-60)
                painter.drawLine(0, i*stepY, width, i*stepY)

        # --- Источники и свечение ---
        s1x = int(self.s1[0]/self.sim.width * width)
        s1y = int(self.s1[1]/self.sim.height * (height-60))
        s2x = int(self.s2[0]/self.sim.width * width)
        s2y = int(self.s2[1]/self.sim.height * (height-60))

        def drawGlow(x, y, color):
            grad = QRadialGradient(x, y, 12*scale)
            grad.setColorAt(0, QColor(*color, int(255*(0.4+0.3*np.sin(self.glowPhase)))))
            grad.setColorAt(1, QColor(0,0,0,0))
            painter.setBrush(grad)
            painter.setPen(Qt.NoPen)
            painter.drawEllipse(x-12*scale, y-12*scale, 24*scale, 24*scale)

        drawGlow(s1x, s1y, (0, 255, 255))
        drawGlow(s2x, s2y, (255, 0, 255))

        # Минимальные источники
        painter.setBrush(QColor("cyan"))
        painter.setPen(Qt.NoPen)
        painter.drawEllipse(s1x-2*scale, s1y-2*scale, 4*scale, 4*scale)

        painter.setBrush(QColor("magenta"))
        painter.drawEllipse(s2x-2*scale, s2y-2*scale, 4*scale, 4*scale)

        # --- Крутящиеся лучи ---
        painter.setPen(QColor(0,255,255,80))
        for i in range(12):
            angle = 2*np.pi/12*i + self.simPhase
            painter.drawLine(s1x, s1y,
                             int(s1x + np.cos(angle)*width),
                             int(s1y + np.sin(angle)*height))
        painter.setPen(QColor(255,0,255,80))
        for i in range(12):
            angle = 2*np.pi/12*i + self.simPhase
            painter.drawLine(s2x, s2y,
                             int(s2x + np.cos(angle)*width),
                             int(s2y + np.sin(angle)*height))

        # --- Подпись в два ряда ---
        painter.setPen(QColor("white"))
        font = QFont("Arial", 14)
        painter.setFont(font)
        text1 = f"Источник1: ({self.s1[0]/self.sim.width:.2f},{self.s1[1]/self.sim.height:.2f}) | " \
                f"Источник2: ({self.s2[0]/self.sim.width:.2f},{self.s2[1]/self.sim.height:.2f}) | " \
                f"Длина волны1: {self.wavelength1:.1f} | Длина волны2: {self.wavelength2:.1f}"
        text2 = f"Фаза: {self.simPhase:.2f} | Фильтр: {self.currentFilter+1}"
        painter.drawText(10, height-45, text1)
        painter.drawText(10, height-20, text2)

        painter.end()

        if img.save(filePath):
            print(f"Сохранено: {filePath}")
        else:
            print("Ошибка при сохранении файла")
