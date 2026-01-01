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

                    // Интерференция
                    var img = ctx.createImageData(simWidth, simHeight)
                    for (var i=0; i<imageData.length; i++){
                        var val = imageData[i]
                        var r = Math.floor(val * 255)
                        var g = Math.floor(val * val * 200)
                        var b = Math.floor((1-val) * 255)
                        img.data[i*4] = r
                        img.data[i*4+1] = g
                        img.data[i*4+2] = b
                        img.data[i*4+3] = 255
                    }
                    ctx.putImageData(img,0,0)
                    ctx.drawImage(img,0,0,simWidth,simHeight,0,0,width,height)

                    // Свечение источников
                    function drawGlow(x, y, color){
                        var grd = ctx.createRadialGradient(x, y, 0, x, y, 25)
                        grd.addColorStop(0, color)
                        grd.addColorStop(1, "transparent")
                        ctx.fillStyle = grd
                        ctx.beginPath()
                        ctx.arc(x,y,25,0,2*Math.PI)
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

            // Источник 1
            Rectangle {
                id: src1
                width: 20; height: 20
                radius: 10
                color: "transparent"
                property real relX: 0.5
                property real relY: 0.5
                x: view.width*relX - width/2
                y: view.height*relY - height/2

                MouseArea {
                    anchors.fill: parent
                    drag.target: parent
                    onPositionChanged: {
                        src1.relX = (parent.x+parent.width/2)/view.width
                        src1.relY = (parent.y+parent.height/2)/view.height
                        backend.setSource1(src1.relX, src1.relY)
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
                x: view.width*relX - width/2
                y: view.height*relY - height/2

                MouseArea {
                    anchors.fill: parent
                    drag.target: parent
                    onPositionChanged: {
                        src2.relX = (parent.x+parent.width/2)/view.width
                        src2.relY = (parent.y+parent.height/2)/view.height
                        backend.setSource2(src2.relX, src2.relY)
                    }
                }
            }
        }

        // Ползунки для длины волн
        Slider {
            id: wave1
            from: 10
            to: 60
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width*0.6
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 55
            onValueChanged: backend.setWavelength1(value)
        }

        Slider {
            id: wave2
            from: 10
            to: 60
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width*0.6
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20
            onValueChanged: backend.setWavelength2(value)
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
        function onPhaseChanged(phase){
            simPhase = phase
        }
        function onImageReady(data){
            imageData = data
        }
    }
}
