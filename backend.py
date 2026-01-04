from PySide6.QtCore import QObject, Signal, Slot, QTimer, Qt, Property
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
    timerChanged = Signal(bool)

    def __init__(self):
        """Инициализирует связи между UI и логикой симуляции."""
        super().__init__()
        self.sim = InterferenceSimulator(200, 200)
        self.s1 = [100.0, 100.0]
        self.s2 = [100.0, 100.0]
        self.wavelength1 = 20
        self.wavelength2 = 20
        self.simPhase = 0.0
        self.glowPhase = 0.0
        self.currentFilter = 0
        self.imageData = None
        self.showGrid = True
        self._timerRunning = True

        self.timer = QTimer()
        self.timer.timeout.connect(self.recalculate)
        self.timer.start(33)

    def getTimerRunning(self):
        """Возвращает текущий статус работы таймера."""
        return self._timerRunning

    def setTimerRunning(self, value):
        """Управляет состоянием таймера анимации."""
        if self._timerRunning != value:
            self._timerRunning = value
            if value: self.timer.start(33)
            else: self.timer.stop()
            self.timerChanged.emit(value)

    timerRunning = Property(bool, getTimerRunning, setTimerRunning, notify=timerChanged)

    @Slot(float, float)
    def setSource1(self, x, y):
        """Устанавливает координаты первого источника."""
        self.s1 = [x * self.sim.width, y * self.sim.height]

    @Slot(float, float)
    def setSource2(self, x, y):
        """Устанавливает координаты второго источника."""
        self.s2 = [x * self.sim.width, y * self.sim.height]

    @Slot(float)
    def setWavelength1(self, w):
        """Изменяет длину волны первого источника."""
        self.wavelength1 = w

    @Slot(float)
    def setWavelength2(self, w):
        """Изменяет длину волны второго источника."""
        self.wavelength2 = w

    @Slot(int)
    def setFilter(self, f):
        """Переключает активный цветовой фильтр."""
        self.currentFilter = f
        self.filterChanged.emit(f)

    @Slot(bool)
    def setShowGrid(self, value):
        """Включает или выключает отображение сетки."""
        self.showGrid = value

    @Slot(float, float)
    def setCursorPos(self, x, y):
        """Передает координаты курсора из UI."""
        self.cursorPosChanged.emit(x, y)

    @Slot()
    def pauseAnimation(self):
        """Останавливает цикл анимации."""
        self.timerRunning = False

    @Slot()
    def startAnimation(self):
        """Запускает цикл анимации."""
        self.timerRunning = True

    @Slot()
    def recalculate(self):
        """Выполняет расчет кадра и обновляет фазы анимации."""
        if self.sim is None: return
        data = self.sim.calculate(self.s1, self.s2, self.wavelength1, self.wavelength2)
        self.imageData = data.copy()

        if self._timerRunning:
            self.simPhase = (self.simPhase + 0.02) % (2 * np.pi)
            self.glowPhase = (self.glowPhase + 0.1) % (2 * np.pi)

        self.phaseChanged.emit(self.simPhase)
        self.glowPhaseChanged.emit(self.glowPhase)
        self.imageReady.emit(data.flatten().tolist())

    @Slot()
    def saveImage(self):
        """Отрисовывает текущий кадр со всеми графическими элементами и сохраняет в PNG."""
        if self.imageData is None: return

        filePath, _ = QFileDialog.getSaveFileName(None, "Сохранить", "interference.png", "PNG Files (*.png)")
        if not filePath: return

        scale = 4
        width, height = self.sim.width * scale, self.sim.height * scale + 60
        img = QImage(width, height, QImage.Format_ARGB32)
        img.fill(QColor("#111")) # Темный фон
        painter = QPainter(img)
        painter.setRenderHint(QPainter.Antialiasing)

        # 1. Отрисовка интерференции
        flat = self.imageData.flatten()
        for y in range(self.sim.height):
            for x in range(self.sim.width):
                val = flat[y*self.sim.width + x]
                if self.currentFilter == 0:
                    r, g, b = int(val*255), int(val*val*200), int((1-val)*255)
                elif self.currentFilter == 1:
                    r, g, b = int((1-val)*255), int(val*255), int((1-val)*255)
                else:
                    r, g, b = int(val*255), int(val*128), int(val*64)
                painter.fillRect(x*scale, y*scale, scale, scale, QColor(r, g, b))

        # 2. Отрисовка сетки
        if self.showGrid:
            painter.setPen(QColor(255, 255, 255, 40))
            for i in range(11):
                painter.drawLine(i*(width//10), 0, i*(width//10), height-60)
                painter.drawLine(0, i*((height-60)//10), width, i*((height-60)//10))

        s1x, s1y = int(self.s1[0]*scale), int(self.s1[1]*scale)
        s2x, s2y = int(self.s2[0]*scale), int(self.s2[1]*scale)

        # 3. Отрисовка вращающихся лучей (Rays)
        def draw_rays(x, y, color):
            painter.setPen(color)
            for i in range(12):
                angle = 2*np.pi/12*i + self.simPhase
                painter.drawLine(x, y, int(x + np.cos(angle)*width), int(y + np.sin(angle)*height))

        draw_rays(s1x, s1y, QColor(0, 255, 255, 60))
        draw_rays(s2x, s2y, QColor(255, 0, 0, 60))

        # 4. Отрисовка свечения (Glow)
        def draw_glow(x, y, color_tuple):
            grad = QRadialGradient(x, y, 15*scale)
            alpha = int(255*(0.4+0.3*np.sin(self.glowPhase)))
            grad.setColorAt(0, QColor(*color_tuple, alpha))
            grad.setColorAt(1, QColor(0,0,0,0))
            painter.setBrush(grad); painter.setPen(Qt.NoPen)
            painter.drawEllipse(x-15*scale, y-15*scale, 30*scale, 30*scale)

        draw_glow(s1x, s1y, (0, 255, 255))
        draw_glow(s2x, s2y, (255, 0, 0))

        # 5. Отрисовка самих источников (Dots)
        painter.setBrush(QColor("cyan")); painter.drawEllipse(s1x-4, s1y-4, 8, 8)
        painter.setBrush(QColor("red")); painter.drawEllipse(s2x-4, s2y-4, 8, 8)

        # 6. Текстовая панель
        painter.setPen(QColor("white"))
        painter.setFont(QFont("Arial", 12))
        info = f"S1:({self.s1[0]/200:.2f},{self.s1[1]/200:.2f}) | S2:({self.s2[0]/200:.2f},{self.s2[1]/200:.2f}) | W1:{self.wavelength1} | W2:{self.wavelength2}"
        painter.drawText(10, height-35, info)
        painter.drawText(10, height-15, f"Phase: {self.simPhase:.2f} | Filter: {self.currentFilter+1}")

        painter.end()
        img.save(filePath)
