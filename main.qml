import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15

Window {
    visible: true
    width: 900
    height: 650
    title: "Симулятор интерференции"
    flags: Qt.Window

    property var imageData: []
    property int simWidth: 200
    property int simHeight: 200
    property real simPhase: 0.0
    property real glowPhase: 0.0
    property int currentFilter: 0
    property bool showGrid: true

    Rectangle {
        anchors.fill: parent
        color: "#111"

        Row {
            width: parent.width
            height: parent.height
            spacing: 0

            Rectangle {
                width: 240
                height: parent.height
                color: "#222"

                Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Text { text: "Источник 1: (" + src1.relX.toFixed(2) + "," + src1.relY.toFixed(2) + ")" ; color:"white" }
                    Text { text: "Источник 2: (" + src2.relX.toFixed(2) + "," + src2.relY.toFixed(2) + ")" ; color:"white" }
                    Text { text: "Длина волны 1: " + wave1.value.toFixed(1) ; color:"white" }
                    Text { text: "Длина волны 2: " + wave2.value.toFixed(1) ; color:"white" }
                    Text { text: "Фаза: " + simPhase.toFixed(2) ; color:"white" }
                    Text { text: "Фильтр: " + (currentFilter + 1) ; color:"white" }
                    Text { text: "Курсор: (" + canvas.cursorRelX.toFixed(2) + "," + canvas.cursorRelY.toFixed(2) + ")" ; color:"white" }

                    Button {
                        text: !showGrid ? "Сетка: Вкл" : "Сетка: Выкл"
                        onClicked: {
                            showGrid = !showGrid
                            canvas.requestPaint()
                            backend.setShowGrid(showGrid)
                        }
                    }

                    Button {
                        id: pauseButton
                        text: backend.timerRunning ? "Пауза" : "Старт"
                        onClicked: {
                            // Переключение состояния анимации через бэкенд
                            if (backend.timerRunning) {
                                backend.pauseAnimation()
                            } else {
                                backend.startAnimation()
                            }
                        }

                        Connections {
                            target: backend
                            onTimerChanged: pauseButton.text = backend.timerRunning ? "Пауза" : "Старт"
                        }
                    }

                    Text { text: "Длина волны 1"; color:"white" }
                    Slider {
                        id: wave1
                        from: 10; to: 60
                        width: parent.width - 20
                        onValueChanged: backend.setWavelength1(value)
                    }

                    Text { text: "Длина волны 2"; color:"white" }
                    Slider {
                        id: wave2
                        from: 10; to: 60
                        width: parent.width - 20
                        onValueChanged: backend.setWavelength2(value)
                    }

                    Text { text: "Фильтры"; color:"white" }
                    Column {
                        spacing: 10
                        width: parent.width - 20
                        Button { text: "Фильтр 1"; height: 40; onClicked: backend.setFilter(0) }
                        Button { text: "Фильтр 2"; height: 40; onClicked: backend.setFilter(1) }
                        Button { text: "Фильтр 3"; height: 40; onClicked: backend.setFilter(2) }
                    }

                    Button {
                        text: "Сделать скриншот"
                        onClicked: backend.saveImage()
                        width: parent.width - 20; height: 40
                    }
                }
            }

            Item {
                id: view
                width: parent.width - 240
                height: parent.height

                Canvas {
                    id: canvas
                    anchors.fill: parent
                    property real cursorRelX: 0
                    property real cursorRelY: 0

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onPositionChanged: function(event) {
                            // Обновление координат курсора для передачи в Python
                            canvas.cursorRelX = event.x / canvas.width
                            canvas.cursorRelY = event.y / canvas.height
                            canvas.requestPaint()
                            backend.setCursorPos(canvas.cursorRelX, canvas.cursorRelY)
                        }
                    }

                    onPaint: {
                        //Основной цикл отрисовки графики на холсте.
                        if (!imageData || imageData.length === 0) return
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        var img = ctx.createImageData(simWidth, simHeight)
                        for (var i = 0; i < imageData.length; i++) {
                            var val = imageData[i]
                            var r, g, b
                            // Применение выбранной цветовой схемы
                            if (currentFilter === 0) {
                                r = Math.floor(val * 255); g = Math.floor(val * val * 200); b = Math.floor((1 - val) * 255)
                            } else if (currentFilter === 1) {
                                r = Math.floor((1 - val) * 255); g = Math.floor(val * 255); b = Math.floor((1 - val) * 255)
                            } else if (currentFilter === 2) {
                                r = Math.floor(val * 255); g = Math.floor(val * 128); b = Math.floor(val * 64)
                            }
                            img.data[i * 4] = r; img.data[i * 4 + 1] = g; img.data[i * 4 + 2] = b; img.data[i * 4 + 3] = 255
                        }

                        ctx.putImageData(img, 0, 0)
                        ctx.drawImage(img, 0, 0, simWidth, simHeight, 0, 0, width, height)

                        if (showGrid) {
                            // Рисование направляющей сетки
                            ctx.strokeStyle = "rgba(255,255,255,0.2)"; ctx.lineWidth = 3
                            var stepX = width / 10; var stepY = height / 10
                            for (var i = 0; i <= 10; i++) {
                                ctx.beginPath(); ctx.moveTo(i * stepX, 0); ctx.lineTo(i * stepX, height); ctx.stroke()
                                ctx.beginPath(); ctx.moveTo(0, i * stepY); ctx.lineTo(width, i * stepY); ctx.stroke()
                            }
                        }

                        function drawGlow(x, y, color) {
                            //Создает эффект пульсирующего свечения вокруг источника.
                            var intensity = 0.4 + 0.3 * Math.sin(glowPhase)
                            var rgbaColor = color.replace("0.5", intensity.toString())
                            var grd = ctx.createRadialGradient(x, y, 0, x, y, 50)
                            grd.addColorStop(0, rgbaColor); grd.addColorStop(1, "transparent")
                            ctx.fillStyle = grd; ctx.beginPath(); ctx.arc(x, y, 50, 0, 2 * Math.PI); ctx.fill()
                        }

                        drawGlow(width * src1.relX, height * src1.relY, "rgba(0,255,255,0.5)")
                        drawGlow(width * src2.relX, height * src2.relY, "rgba(255,0,0,0.5)")

                        ctx.fillStyle = "cyan"; ctx.beginPath(); ctx.arc(width * src1.relX, height * src1.relY, 10, 0, 2 * Math.PI); ctx.fill()
                        ctx.fillStyle = "red"; ctx.beginPath(); ctx.arc(width * src2.relX, height * src2.relY, 10, 0, 2 * Math.PI); ctx.fill()

                        function drawRays(x, y, color) {
                            //Рисует вращающиеся лучи от источников.
                            ctx.strokeStyle = color; ctx.lineWidth = 1
                            var numRays = 12
                            for (var i = 0; i < numRays; i++) {
                                var angle = 2 * Math.PI / numRays * i + simPhase
                                ctx.beginPath(); ctx.moveTo(x, y)
                                ctx.lineTo(x + Math.cos(angle) * width, y + Math.sin(angle) * height); ctx.stroke()
                            }
                        }
                        drawRays(width * src1.relX, height * src1.relY, "rgba(0,255,255,0.3)")
                        drawRays(width * src2.relX, height * src2.relY, "rgba(255,0,255,0.3)")
                    }
                }

                Rectangle {
                    id: src1
                    width: 20; height: 20; radius: 10; color: "transparent"
                    property real relX: 0.5; property real relY: 0.5
                    x: view.width * relX - width / 2; y: view.height * relY - height / 2
                    MouseArea {
                        anchors.fill: parent; drag.target: parent
                        onPositionChanged: function(event) {
                            // Синхронизация позиции источника 1 с бэкендом
                            src1.relX = (parent.x + parent.width / 2) / view.width
                            src1.relY = (parent.y + parent.height / 2) / view.height
                            backend.setSource1(src1.relX, src1.relY)
                            canvas.requestPaint()
                        }
                    }
                }

                Rectangle {
                    id: src2
                    width: 20; height: 20; radius: 10; color: "transparent"
                    property real relX: 0.5; property real relY: 0.5
                    x: view.width * relX - width / 2; y: view.height * relY - height / 2
                    MouseArea {
                        anchors.fill: parent; drag.target: parent
                        onPositionChanged: function(event) {
                            // Синхронизация позиции источника 2 с бэкендом
                            src2.relX = (parent.x + parent.width / 2) / view.width
                            src2.relY = (parent.y + parent.height / 2) / view.height
                            backend.setSource2(src2.relX, src2.relY)
                            canvas.requestPaint()
                        }
                    }
                }
            }
        }
    }

    Timer {
        interval: 33; running: true; repeat: true
        onTriggered: canvas.requestPaint()
    }

    Connections {
        target: backend
        function onPhaseChanged(phase) { simPhase = phase }
        function onGlowPhaseChanged(phase) { glowPhase = phase }
        function onFilterChanged(f) { currentFilter = f }
        function onImageReady(data) { imageData = data }
    }
}
