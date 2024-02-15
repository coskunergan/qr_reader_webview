import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import QtWebView

import QZXing

ApplicationWindow
{
    id: window
    visible: true
    x: initialX
    y: initialY
    width: initialWidth
    height: initialHeight
    title: "QR Reader"

    property int detectedTags: 0
    property string lastTag: ""

    menuBar: ToolBar {
        id: navigationBar
        visible:false
        RowLayout {
            anchors.fill: parent
            spacing: 0

            ToolButton {
                id: backButton
                icon.source: "qrc:/icons/left-32.png"
                onClicked:
                {
                    webView.visible=false;
                    navigationBar.visible=false;
                    camera.active = true;
                    videoOutput.visible=true;
                }
                Layout.preferredWidth: navigationBar.height
            }

            Item { Layout.preferredWidth: 5 }

            ToolButton {
                id: reloadButton
                icon.source: webView.loading ? "qrc:/icons/stop-32.png" : "qrc:/icons/refresh-32.png"
                onClicked: webView.loading ? webView.stop() : webView.reload()
                Layout.preferredWidth: navigationBar.height
            }

            Item { Layout.preferredWidth: 10 }
         }
         ProgressBar {
             id: progress
             anchors {
                left: parent.left
                top: parent.bottom
                right: parent.right
                leftMargin: parent.leftMargin
                rightMargin: parent.rightMargin
             }
             height:3
             z: Qt.platform.os === "android" ? -1 : -2
             background: Item {}
             visible: Qt.platform.os !== "ios" && Qt.platform.os !== "winrt"
             from: 0
             to: 100
             value: webView.loadProgress < 100 ? webView.loadProgress : 0
        }
    }

    WebView {
        id: webView
        visible: false
        url: initialUrl
        anchors.right: parent.right
        anchors.left: parent.left
        height: parent.height
        onLoadingChanged: function(loadRequest) {
            if (loadRequest.errorString)
                console.error(loadRequest.errorString);
        }
    }

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
        anchors.top: text1.bottom
        anchors.bottom: parent.bottom
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
                camera.active = true;
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
                camera.active = false;
                videoOutput.visible=false;                
                webView.url = utils.fromUserInput(tag);
                webView.visible=true;
                navigationBar.visible=true;
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
}
