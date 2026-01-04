import numpy as np

class InterferenceSimulator:
    def __init__(self, width=200, height=200):
        """Инициализирует параметры симуляции и начальную фазу."""
        self.width = width
        self.height = height
        self.phase = 0.0

    def calculate(self, s1, s2, wavelength1, wavelength2):
        """Вычисляет итоговую интенсивность интерференции в каждой точке поля."""
        # Создаем сетку координат для расчетов
        x = np.linspace(0, self.width, self.width)
        y = np.linspace(0, self.height, self.height)
        X, Y = np.meshgrid(x, y)

        k1 = 2 * np.pi / wavelength1
        k2 = 2 * np.pi / wavelength2

        # Считаем расстояние от каждой точки до источников
        r1 = np.sqrt((X - s1[0])**2 + (Y - s1[1])**2)
        r2 = np.sqrt((X - s2[0])**2 + (Y - s2[1])**2)

        # Суммируем амплитуды волн и возводим в квадрат для получения интенсивности
        Z = (np.sin(k1 * r1 + self.phase) + np.sin(k2 * r2 + self.phase))**2
        Z /= Z.max() # Нормализация яркости

        self.phase += 0.05
        return Z
