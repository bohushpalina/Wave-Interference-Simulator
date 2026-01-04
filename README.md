# Wave Interference Simulator

An interactive wave interference simulator implemented in **Python**, **NumPy**, and **PySide6 (Qt/QML)**.  
The application visualizes the interference pattern produced by two point wave sources in real time.

---

## Features

- Two movable wave sources  
- Independent wavelength control  
- Real-time numerical simulation  
- Multiple color filters  
- Phase animation  
- Optional coordinate grid  
- Screenshot export to PNG  

---

## Mathematical Model

The interference intensity is computed as:

\[
I(x, y) = \left( \sin(k_1 r_1 + \varphi) + \sin(k_2 r_2 + \varphi) \right)^2
\]

where:
- \( r_1, r_2 \) are distances to the sources  
- \( k = \frac{2\pi}{\lambda} \) is the wave number  
- \( \lambda \) is the wavelength  
- \( \varphi \) is the phase shift  

The result is normalized for visualization.

---

## Project Structure

```

Interferention/
├── main.py
├── simulation.py
├── backend.py
├── main.qml
├── requirements.txt
└── README.md

````

---

## Installation and Run

```bash
git clone https://github.com/bohushpalina/Wave-Interference-Simulator.git
cd Wave-Interference-Simulator
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python main.py
````

---

## Dependencies

* Python 3.10+
* NumPy
* PySide6 (Qt 6)

---

## Purpose

This project is intended for educational and demonstration purposes, including the study of wave interference, numerical simulation, and Qt-based graphical interfaces.
