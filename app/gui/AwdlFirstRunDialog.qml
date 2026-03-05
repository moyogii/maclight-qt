import QtQuick 2.0
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2

import StreamingPreferences 1.0

NavigableDialog {
    id: dialog

    // No standard buttons - we use custom ones
    standardButtons: Dialog.NoButton

    // Reduce padding between content and footer
    bottomPadding: 0


    RowLayout {
        spacing: 10

        Image {
            id: dialogImage
            source: "image://sfsymbol/questionmark.circle"
            sourceSize {
                width: 50
                height: 50
            }
        }

        ColumnLayout {
            spacing: 10

            Label {
                id: titleLabel
                text: qsTr("AWDL Network Control")
                font.bold: true
                font.pointSize: 14
            }

            Label {
                id: dialogLabel
                text: qsTr("Would you like to enable AWDL (Apple Wireless Direct Link) management?\n\n" +
                          "AWDL is used by AirDrop and other Apple services, but can interfere with " +
                          "streaming performance on some networks.\n\n" +
                          "If enabled, Maclight will temporarily disable AWDL during streaming sessions " +
                          "to improve network stability. This requires administrator privileges.")
                wrapMode: Text.Wrap
                Layout.maximumWidth: 400
            }
        }
    }

    footer: Item {
        implicitHeight: buttonRow.implicitHeight + 16
        implicitWidth: buttonRow.implicitWidth

        RowLayout {
            id: buttonRow
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 8
            spacing: 10

            Button {
                id: yesButton
                text: qsTr("Yes")
                flat: true
                background: Rectangle {
                    radius: 3
                    color: yesButton.down ? "#505050" : (yesButton.hovered ? "#484848" : "transparent")
                }

                Keys.onReturnPressed: clicked()
                Keys.onEnterPressed: clicked()
                Keys.onRightPressed: noButton.forceActiveFocus(Qt.TabFocus)
                Keys.onLeftPressed: noButton.forceActiveFocus(Qt.TabFocus)

                onClicked: {
                    StreamingPreferences.awdlEnabled = true
                    StreamingPreferences.awdlFirstRunShown = true
                    StreamingPreferences.save()
                    StreamingPreferences.requestAwdlAuthorization()
                    dialog.close()
                }
            }

            Button {
                id: noButton
                text: qsTr("No")
                flat: true
                background: Rectangle {
                    radius: 3
                    color: noButton.down ? "#505050" : (noButton.hovered ? "#484848" : "transparent")
                }

                Keys.onReturnPressed: clicked()
                Keys.onEnterPressed: clicked()
                Keys.onRightPressed: yesButton.forceActiveFocus(Qt.TabFocus)
                Keys.onLeftPressed: yesButton.forceActiveFocus(Qt.TabFocus)

                onClicked: {
                    StreamingPreferences.awdlEnabled = false
                    StreamingPreferences.awdlFirstRunShown = true
                    StreamingPreferences.save()
                    dialog.close()
                }
            }
        }
    }
}
