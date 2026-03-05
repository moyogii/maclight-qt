import QtQuick 2.0
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2

NavigableDialog {
    id: dialog

    property alias text: dialogLabel.dialogText
    property alias showSpinner: dialogSpinner.visible
    property alias imageSrc: dialogImage.source

    property string helpText
    property string helpUrl : "https://github.com/moonlight-stream/moonlight-docs/wiki/Troubleshooting"
    property string helpTextSeparator : " "

    onOpened: {
        // Force keyboard focus on the label so keyboard navigation works
        if (dialogButtonBox.count > 0) {
            dialogButtonBox.itemAt(dialogButtonBox.count - 1).forceActiveFocus(Qt.TabFocus)
        }
    }

    contentItem: Item {
        implicitWidth: rowLayout.implicitWidth
        implicitHeight: rowLayout.implicitHeight

        RowLayout {
            id: rowLayout
            anchors.fill: parent
            spacing: 10

            BusyIndicator {
                id: dialogSpinner
                visible: false
                running: visible
            }

            Image {
                id: dialogImage
                source: (standardButtons & Dialog.Yes) ?
                            "image://sfsymbol/questionmark.circle" :
                            "image://sfsymbol/exclamationmark.circle"
                sourceSize {
                    width: 50
                    height: 50
                }
                visible: !showSpinner
            }

            Label {
                property string dialogText

                id: dialogLabel
                text: dialogText + ((helpText && (standardButtons & Dialog.Help)) ? (helpTextSeparator + helpText) : "")
                wrapMode: Text.Wrap
                elide: Label.ElideRight

                Layout.maximumWidth: 400
                Layout.maximumHeight: 400
            }
        }
    }

    footer: DialogButtonBox {
        id: dialogButtonBox
        standardButtons: dialog.standardButtons

        delegate: Button {
            id: dialogButton
            flat: true
            contentItem: Text {
                text: dialogButton.text
                font: dialogButton.font
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                radius: 3
                color: dialogButton.down ? "#505050" : (dialogButton.hovered ? "#484848" : "transparent")
            }

            Keys.onReturnPressed: clicked()
            Keys.onEnterPressed: clicked()
            Keys.onRightPressed: nextItemInFocusChain(true).forceActiveFocus(Qt.TabFocus)
            Keys.onLeftPressed: nextItemInFocusChain(false).forceActiveFocus(Qt.TabFocus)
        }

        onHelpRequested: {
            Qt.openUrlExternally(helpUrl)
            close()
        }
    }
}
