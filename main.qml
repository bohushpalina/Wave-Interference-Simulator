import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15

Window {
    visible: true
    width: 600
    height: 600
    title: "Interference Simulator"
    flags: Qt.Window

    property var imageData: []
    property int simWidth: 200
    property int simHeight: 200

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

                    // создаём ImageData только один раз
                    var img = ctx.createImageData(simWidth, simHeight)
                    for (var i=0; i<imageData.length; i++){
                        var v = Math.floor(imageData[i]*255)
                        img.data[i*4] = v
                        img.data[i*4+1] = 0
                        img.data[i*4+2] = 255-v
                        img.data[i*4+3] = 255
                    }
                    // растягиваем на весь Canvas
                    ctx.putImageData(img, 0,0)
                    ctx.drawImage(img,0,0,simWidth,simHeight,0,0,width,height)

                    // Свечение источников
                    function drawGlow(x, y, color){
                        var grd = ctx.createRadialGradient(x, y, 0, x, y, 30)
                        grd.addColorStop(0, color)
                        grd.addColorStop(1, "transparent")
                        ctx.fillStyle = grd
                        ctx.beginPath()
                        ctx.arc(x,y,30,0,2*Math.PI)
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

        // Ползунок длины волны
        Slider {
            from: 10
            to: 60
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width*0.6
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20
            onValueChanged: backend.setWavelength(value)
        }
    }

    // Плавное обновление Canvas
    Timer {
        interval: 33
        running: true
        repeat: true
        onTriggered: canvas.requestPaint()
    }

    Connections {
        target: backend
        function onImageReady(data){
            imageData = data
        }
    }
}
