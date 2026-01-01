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
            anchors.fill: parent
            spacing: 0

            // Левая панель
            Rectangle {
                width: 240
                color: "#222"
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left

                Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    // Данные источников
                    Text { text: "Источник 1: (" + src1.relX.toFixed(2) + "," + src1.relY.toFixed(2) + ")" ; color:"white" }
                    Text { text: "Источник 2: (" + src2.relX.toFixed(2) + "," + src2.relY.toFixed(2) + ")" ; color:"white" }

                    // Длины волн
                    Text { text: "Длина волны 1: " + wave1.value.toFixed(1) ; color:"white" }
                    Text { text: "Длина волны 2: " + wave2.value.toFixed(1) ; color:"white" }

                    // Фаза и фильтр
                    Text { text: "Фаза: " + simPhase.toFixed(2) ; color:"white" }
                    Text { text: "Фильтр: " + (currentFilter + 1) ; color:"white" }

                    // Координаты курсора
                    Text { text: "Курсор: (" + canvas.cursorRelX.toFixed(2) + "," + canvas.cursorRelY.toFixed(2) + ")" ; color:"white" }

                    // Кнопка для сетки
                    Button {
                        text: !showGrid ? "Сетка: Вкл" : "Сетка: Выкл"
                        onClicked: {
                            showGrid = !showGrid
                            canvas.requestPaint()
                            backend.setShowGrid(showGrid)
                        }
                    }

                    // Ползунки
                    Text { text: "Длина волны 1"; color:"white" }
                    Slider {
                        id: wave1
                        from: 10
                        to: 60
                        width: parent.width - 20
                        onValueChanged: backend.setWavelength1(value)
                    }

                    Text { text: "Длина волны 2"; color:"white" }
                    Slider {
                        id: wave2
                        from: 10
                        to: 60
                        width: parent.width - 20
                        onValueChanged: backend.setWavelength2(value)
                    }

                    // Кнопки фильтров
                    Text { text: "Фильтры"; color:"white" }
                    Column {
                        spacing: 10
                        width: parent.width - 20
                        Button { text: "Фильтр 1"; height: 40; onClicked: backend.setFilter(0) }
                        Button { text: "Фильтр 2"; height: 40; onClicked: backend.setFilter(1) }
                        Button { text: "Фильтр 3"; height: 40; onClicked: backend.setFilter(2) }
                    }

                    // Кнопка сохранения изображения
                    Button {
                        text: "Сохранить картинку интерференции"
                        onClicked: backend.saveImage()
                        width: parent.width - 20
                        height: 40
                    }
                }
            }

            // Основной Canvas
            Item {
                id: view
                anchors.fill: parent
                anchors.leftMargin: 240

                Canvas {
                    id: canvas
                    anchors.fill: parent

                    property real cursorRelX: 0
                    property real cursorRelY: 0

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onPositionChanged: function(event) {
                            canvas.cursorRelX = event.x / canvas.width
                            canvas.cursorRelY = event.y / canvas.height
                            canvas.requestPaint()
                            backend.setCursorPos(canvas.cursorRelX, canvas.cursorRelY)
                        }
                    }

                    onPaint: {
                        if (!imageData || imageData.length === 0) return
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        // Интерференция
                        var img = ctx.createImageData(simWidth, simHeight)
                        for (var i = 0; i < imageData.length; i++) {
                            var val = imageData[i]
                            var r, g, b
                            if (currentFilter === 0) {
                                r = Math.floor(val * 255)
                                g = Math.floor(val * val * 200)
                                b = Math.floor((1 - val) * 255)
                            } else if (currentFilter === 1) {
                                r = Math.floor((1 - val) * 255)
                                g = Math.floor(val * 255)
                                b = Math.floor((1 - val) * 255)
                            } else if (currentFilter === 2) {
                                r = Math.floor(val * 255)
                                g = Math.floor(val * 128)
                                b = Math.floor(val * 64)
                            }
                            img.data[i * 4] = r
                            img.data[i * 4 + 1] = g
                            img.data[i * 4 + 2] = b
                            img.data[i * 4 + 3] = 255
                        }

                        ctx.putImageData(img, 0, 0)
                        ctx.drawImage(img, 0, 0, simWidth, simHeight, 0, 0, width, height)

                        // Сетка после интерференции
                        if (showGrid) {
                            ctx.strokeStyle = "rgba(255,255,255,0.2)"
                            ctx.lineWidth = 1
                            var stepX = width / 10
                            var stepY = height / 10
                            for (var i = 0; i <= 10; i++) {
                                ctx.beginPath()
                                ctx.moveTo(i * stepX, 0)
                                ctx.lineTo(i * stepX, height)
                                ctx.stroke()
                                ctx.beginPath()
                                ctx.moveTo(0, i * stepY)
                                ctx.lineTo(width, i * stepY)
                                ctx.stroke()
                            }
                        }

                        // Пульсирующее свечение
                        function drawGlow(x, y, baseColor) {
                            var intensity = 0.4 + 0.3 * Math.sin(glowPhase)
                            var color = baseColor.replace("0.5", intensity.toString())
                            var grd = ctx.createRadialGradient(x, y, 0, x, y, 50)
                            grd.addColorStop(0, color)
                            grd.addColorStop(1, "transparent")
                            ctx.fillStyle = grd
                            ctx.beginPath()
                            ctx.arc(x, y, 50, 0, 2 * Math.PI)
                            ctx.fill()
                        }
                        drawGlow(width * src1.relX, height * src1.relY, "rgba(0,255,255,0.5)")
                        drawGlow(width * src2.relX, height * src2.relY, "rgba(255,0,255,0.5)")

                        // Источники
                        ctx.fillStyle = "cyan"
                        ctx.beginPath()
                        ctx.arc(width * src1.relX, height * src1.relY, 10, 0, 2 * Math.PI)
                        ctx.fill()
                        ctx.fillStyle = "magenta"
                        ctx.beginPath()
                        ctx.arc(width * src2.relX, height * src2.relY, 10, 0, 2 * Math.PI)
                        ctx.fill()

                        // Крутящиеся лучи
                        function drawRays(x, y, color) {
                            ctx.strokeStyle = color
                            ctx.lineWidth = 1
                            var numRays = 12
                            for (var i = 0; i < numRays; i++) {
                                var angle = 2 * Math.PI / numRays * i + simPhase
                                var endX = x + Math.cos(angle) * width
                                var endY = y + Math.sin(angle) * height
                                ctx.beginPath()
                                ctx.moveTo(x, y)
                                ctx.lineTo(endX, endY)
                                ctx.stroke()
                            }
                        }
                        drawRays(width * src1.relX, height * src1.relY, "rgba(0,255,255,0.3)")
                        drawRays(width * src2.relX, height * src2.relY, "rgba(255,0,255,0.3)")
                    }
                }

                // Источник 1
                Rectangle {
                    id: src1
                    width: 20; height: 20
                    radius: 10
                    color: "transparent"
                    property real relX: 0.5
                    property real relY: 0.5
                    x: view.width * relX - width / 2
                    y: view.height * relY - height / 2

                    MouseArea {
                        anchors.fill: parent
                        drag.target: parent
                        onPositionChanged: function(event) {
                            src1.relX = (parent.x + parent.width / 2) / view.width
                            src1.relY = (parent.y + parent.height / 2) / view.height
                            backend.setSource1(src1.relX, src1.relY)
                            canvas.requestPaint()
                        }
                    }
                }

                // Источник 2
                Rectangle {
                    id: src2
                    width: 20; height: 20
                    radius: 10
                    color: "transparent"
                    property real relX: 0.5
                    property real relY: 0.5
                    x: view.width * relX - width / 2
                    y: view.height * relY - height / 2

                    MouseArea {
                        anchors.fill: parent
                        drag.target: parent
                        onPositionChanged: function(event) {
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
        interval: 33
        running: true
        repeat: true
        onTriggered: canvas.requestPaint()
    }

    Connections {
        target: backend
        function onPhaseChanged(phase) { simPhase = phase }
        function onGlowPhaseChanged(phase) { glowPhase = phase }
        function onFilterChanged(f) { currentFilter = f }
        function onCursorPosChanged(x, y) {}
        function onImageReady(data) { imageData = data }
    }
}
