import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15

Window {
    visible: true
    width: 600
    height: 650
    title: "Interference Simulator"
    flags: Qt.Window

    property var imageData: []
    property int simWidth: 200
    property int simHeight: 200
    property real simPhase: 0.0
    property real glowPhase: 0.0
    property int currentFilter: 0

    Rectangle {
        anchors.fill: parent
        color: "#111"

        Item {
            id: view
            anchors.fill: parent

            Canvas {
                id: canvas
                anchors.fill: parent

                onPaint: {
                    if (!imageData || imageData.length === 0) return
                    var ctx = getContext("2d")
                    ctx.clearRect(0,0,width,height)

                    var img = ctx.createImageData(simWidth, simHeight)
                    for (var i=0; i<imageData.length; i++){
                        var val = imageData[i]

                        // фильтры
                        var r,g,b
                        if (currentFilter === 0){ // cyan-magenta
                            r = Math.floor(val*255)
                            g = Math.floor(val*val*200)
                            b = Math.floor((1-val)*255)
                        } else if (currentFilter === 1){ // зеленый
                            r = Math.floor((1-val)*255)
                            g = Math.floor(val*255)
                            b = Math.floor((1-val)*255)
                        } else if (currentFilter === 2){ // оранжевый
                            r = Math.floor(val*255)
                            g = Math.floor(val*128)
                            b = Math.floor(val*64)
                        }

                        img.data[i*4] = r
                        img.data[i*4+1] = g
                        img.data[i*4+2] = b
                        img.data[i*4+3] = 255
                    }
                    ctx.putImageData(img,0,0)
                    ctx.drawImage(img,0,0,simWidth,simHeight,0,0,width,height)

                    // пульсирующее свечение (radius 50)
                    function drawGlow(x, y, baseColor){
                        var intensity = 0.4 + 0.3 * Math.sin(glowPhase)
                        var color = baseColor.replace("0.5", intensity.toString())
                        var grd = ctx.createRadialGradient(x, y, 0, x, y, 50)
                        grd.addColorStop(0, color)
                        grd.addColorStop(1, "transparent")
                        ctx.fillStyle = grd
                        ctx.beginPath()
                        ctx.arc(x,y,50,0,2*Math.PI)
                        ctx.fill()
                    }
                    drawGlow(view.width*src1.relX, view.height*src1.relY, "rgba(0,255,255,0.5)")
                    drawGlow(view.width*src2.relX, view.height*src2.relY, "rgba(255,0,255,0.5)")

                    // Источники
                    ctx.fillStyle = "cyan"
                    ctx.beginPath()
                    ctx.arc(view.width*src1.relX, view.height*src1.relY, 10,0,2*Math.PI)
                    ctx.fill()

                    ctx.fillStyle = "magenta"
                    ctx.beginPath()
                    ctx.arc(view.width*src2.relX, view.height*src2.relY,10,0,2*Math.PI)
                    ctx.fill()

                    // Лучи
                    function drawRays(x, y, color){
                        ctx.strokeStyle = color
                        ctx.lineWidth = 1
                        var numRays = 12
                        for (var i=0;i<numRays;i++){
                            var angle = 2*Math.PI/numRays*i + simPhase
                            var endX = x + Math.cos(angle)*width
                            var endY = y + Math.sin(angle)*height
                            ctx.beginPath()
                            ctx.moveTo(x,y)
                            ctx.lineTo(endX,endY)
                            ctx.stroke()
                        }
                    }
                    drawRays(view.width*src1.relX, view.height*src1.relY, "rgba(0,255,255,0.3)")
                    drawRays(view.width*src2.relX, view.height*src2.relY, "rgba(255,0,255,0.3)")
                }
            }

            // Источники
            Rectangle {
                id: src1; width: 20; height: 20; radius: 10; color: "transparent"
                property real relX: 0.5; property real relY: 0.5
                x: view.width*relX - width/2
                y: view.height*relY - height/2
                MouseArea { anchors.fill: parent; drag.target: parent
                    onPositionChanged: { src1.relX=(parent.x+parent.width/2)/view.width; src1.relY=(parent.y+parent.height/2)/view.height; backend.setSource1(src1.relX, src1.relY) }
                }
            }
            Rectangle {
                id: src2; width: 20; height: 20; radius: 10; color: "transparent"
                property real relX: 0.5; property real relY: 0.5
                x: view.width*relX - width/2
                y: view.height*relY - height/2
                MouseArea { anchors.fill: parent; drag.target: parent
                    onPositionChanged: { src2.relX=(parent.x+parent.width/2)/view.width; src2.relY=(parent.y+parent.height/2)/view.height; backend.setSource2(src2.relX, src2.relY) }
                }
            }
        }

        // Ползунки
        Slider { id: wave1; from: 10; to: 60; anchors.horizontalCenter: parent.horizontalCenter; width: parent.width*0.6; anchors.bottom: parent.bottom; anchors.bottomMargin: 55; onValueChanged: backend.setWavelength1(value) }
        Slider { id: wave2; from: 10; to: 60; anchors.horizontalCenter: parent.horizontalCenter; width: parent.width*0.6; anchors.bottom: parent.bottom; anchors.bottomMargin: 20; onValueChanged: backend.setWavelength2(value) }

        // Кнопки фильтров
        Row {
            spacing: 10
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 90
            Button { text: "Filter 1"; onClicked: backend.setFilter(0) }
            Button { text: "Filter 2"; onClicked: backend.setFilter(1) }
            Button { text: "Filter 3"; onClicked: backend.setFilter(2) }
        }
    }

    Timer { interval: 33; running: true; repeat: true; onTriggered: canvas.requestPaint() }

    Connections {
        target: backend
        function onPhaseChanged(phase){ simPhase = phase }
        function onGlowPhaseChanged(phase){ glowPhase = phase }
        function onFilterChanged(f){ currentFilter=f }
        function onImageReady(data){ imageData = data }
    }
}
