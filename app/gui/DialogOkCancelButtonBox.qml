import QtQuick 2.0
import QtQuick.Controls 2.5

DialogButtonBox {
    id: buttonBox

    property var targetDialog
    property var validationCallback: function() { return true }

    Button {
        text: qsTr("OK")
        DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
        enabled: buttonBox.validationCallback()
        flat: true
        contentItem: Text {
            text: parent.text
            font: parent.font
            color: parent.enabled ? "white" : "#808080"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: 3
            color: parent.enabled ? (parent.down ? "#505050" : (parent.hovered ? "#484848" : "transparent")) : "transparent"
        }
        Keys.onReturnPressed: if (buttonBox.targetDialog) buttonBox.targetDialog.accept()
        Keys.onEnterPressed: if (buttonBox.targetDialog) buttonBox.targetDialog.accept()
    }
    Button {
        text: qsTr("Cancel")
        DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
        flat: true
        contentItem: Text {
            text: parent.text
            font: parent.font
            color: "white"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: 3
            color: parent.down ? "#505050" : (parent.hovered ? "#484848" : "transparent")
        }
        Keys.onReturnPressed: if (buttonBox.targetDialog) buttonBox.targetDialog.reject()
        Keys.onEnterPressed: if (buttonBox.targetDialog) buttonBox.targetDialog.reject()
    }
    onAccepted: if (buttonBox.targetDialog) buttonBox.targetDialog.accept()
    onRejected: if (buttonBox.targetDialog) buttonBox.targetDialog.reject()
}
