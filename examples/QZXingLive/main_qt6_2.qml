import QtQuick 2.5
import QtQuick.Window 2.0
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.1
import QtMultimedia

import QZXing 3.3

ApplicationWindow
{
    id: window
    visible: true
    width: 640
    height: 480
    title: "Qt QZXing Filter Test"

    property int detectedTags: 0
    property string lastTag: ""

    Rectangle
    {       
        id: bgRect
        color: "white"
        anchors.fill: videoOutput
    }

    Text
    {
        id: text1
        wrapMode: Text.Wrap
        font.pixelSize: 20
        anchors.top: parent.top
        anchors.left: parent.left
        z: 50
        text: "Tags detected: " + detectedTags
    }
    Text
    {
        id: fps
        font.pixelSize: 20
        anchors.top: parent.top
        anchors.right: parent.right
        z: 50
        text: (1000 / zxingFilter.timePerFrameDecode).toFixed(0) + "fps"
    }

    Camera
    {
        id:camera
        active: false
        focusMode: Camera.FocusModeAutoNear
    }

    CaptureSession {
        camera: camera
        videoOutput: videoOutput
    }

    VideoOutput
    {
        id: videoOutput
        //width: 480
        //height: 385
        //anchors.centerIn: parent
        anchors.top: text1.bottom
        anchors.bottom: text2.top
        anchors.left: parent.left
        anchors.right: parent.right
        //fillMode: VideoOutput.Stretch

        property double captureRectStartFactorX: 0.25
        property double captureRectStartFactorY: 0.25
        property double captureRectFactorWidth: 0.5
        property double captureRectFactorHeight: 0.5

        MouseArea {
            anchors.fill: parent
            onClicked: {
                //camera.active = true;
                camera.customFocusPoint = Qt.point(mouseX / width,  mouseY / height);
                camera.focusMode = Camera.FocusModeManual;
            }
        }

        Rectangle {
            id: captureZone
            color: "green"
            opacity: 0.2
            width: parent.width * parent.captureRectFactorWidth
            height: parent.height * parent.captureRectFactorHeight
            x: parent.width * parent.captureRectStartFactorX
            y: parent.height * parent.captureRectStartFactorY
        }

         Component.onCompleted: { camera.active = false; camera.active = true; }
    }

    QZXingFilter
    {
        id: zxingFilter
        videoSink: videoOutput.videoSink
        orientation: videoOutput.orientation

        captureRect: {
            videoOutput.sourceRect;
            return Qt.rect(videoOutput.sourceRect.width * videoOutput.captureRectStartFactorX,
                           videoOutput.sourceRect.height * videoOutput.captureRectStartFactorY,
                           videoOutput.sourceRect.width * videoOutput.captureRectFactorWidth,
                           videoOutput.sourceRect.height * videoOutput.captureRectFactorHeight)
        }

        decoder {
            enabledDecoders: QZXing.DecoderFormat_QR_CODE | QZXing.DecoderFormat_DATA_MATRIX |
                           QZXing.DecoderFormat_UPC_E |
                           QZXing.DecoderFormat_UPC_A |
                           QZXing.DecoderFormat_UPC_EAN_EXTENSION |
                           QZXing.DecoderFormat_RSS_14 |
                           QZXing.DecoderFormat_RSS_EXPANDED |
                           QZXing.DecoderFormat_PDF_417 |
                           QZXing.DecoderFormat_MAXICODE |
                           QZXing.DecoderFormat_EAN_8 |
                           QZXing.DecoderFormat_EAN_13 |
                           QZXing.DecoderFormat_CODE_128 |
                           QZXing.DecoderFormat_CODE_93 |
                           QZXing.DecoderFormat_CODE_39 |
                           QZXing.DecoderFormat_CODABAR |
                           QZXing.DecoderFormat_ITF |
                           QZXing.DecoderFormat_Aztec
            onTagFound: {
                console.log(tag + " | " + decoder.foundedFormat() + " | " + decoder.charSet());

                window.detectedTags++;
                window.lastTag = tag;
            }

            tryHarder: false
        }

        onDecodingStarted:
        {
//            console.log("started");
        }

        property int framesDecoded: 0
        property real timePerFrameDecode: 0

        onDecodingFinished:
        {
           timePerFrameDecode = (decodeTime + framesDecoded * timePerFrameDecode) / (framesDecoded + 1);
           framesDecoded++;
           if(succeeded)
            console.log("frame finished: " + succeeded, decodeTime, timePerFrameDecode, framesDecoded);
        }
    }

    Text
    {
        id: text2
        wrapMode: Text.Wrap
        font.pixelSize: 20
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        z: 50
        text: "Last tag: " + lastTag
    }
    Switch {
        text: "Autofocus"
        checked: camera.focusMode === Camera.FocusModeAutoNear
        anchors {
            right: parent.right
            bottom: parent.bottom
        }
        onCheckedChanged: {
            if (checked) {
                camera.focusMode = Camera.FocusModeAutoNear
            } else {
                camera.focusMode = Camera.FocusModeManual
                camera.customFocusPoint = Qt.point(0.5,  0.5)
            }
        }
        font.family: Qt.platform.os === 'android' ? 'Droid Sans Mono' : 'Monospace'
        font.pixelSize: Screen.pixelDensity * 5
    }
}
