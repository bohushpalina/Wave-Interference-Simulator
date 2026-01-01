import numpy as np

class InterferenceSimulator:
    def __init__(self, width=200, height=200):
        self.width = width
        self.height = height
        self.phase = 0.0

    def calculate(self, s1, s2, wavelength):
        """
        Интерференция в уменьшенном разрешении для быстрой анимации
        s1, s2: координаты источников в пикселях (относительно width/height)
        """
        k = 2 * np.pi / wavelength

        x = np.linspace(0, self.width, self.width)
        y = np.linspace(0, self.height, self.height)
        X, Y = np.meshgrid(x, y)

        r1 = np.sqrt((X - s1[0])**2 + (Y - s1[1])**2)
        r2 = np.sqrt((X - s2[0])**2 + (Y - s2[1])**2)

        Z = (np.sin(k * r1 + self.phase) + np.sin(k * r2 + self.phase))**2
        Z /= Z.max()

        self.phase += 0.05  # медленнее → плавнее
        return Z
