; https://github.com/microsoft/Windows-classic-samples/blob/master/Samples/WinhttpWebsocket/cpp/WinhttpWebsocket.cpp

#include "WinHttp.au3"

Global Const $WINHTTP_OPTION_UPGRADE_TO_WEB_SOCKET = 114

Global Enum _
		$WINHTTP_WEB_SOCKET_BINARY_MESSAGE_BUFFER_TYPE = 0, _
		$WINHTTP_WEB_SOCKET_BINARY_FRAGMENT_BUFFER_TYPE,    _
		$WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE,    _
		$WINHTTP_WEB_SOCKET_UTF8_FRAGMENT_BUFFER_TYPE,    _
		$WINHTTP_WEB_SOCKET_CLOSE_BUFFER_TYPE

Global Enum _
		$WINHTTP_WEB_SOCKET_SUCCESS_CLOSE_STATUS = 1000, _
  		$WINHTTP_WEB_SOCKET_ENDPOINT_TERMINATED_CLOSE_STATUS, _
  		$WINHTTP_WEB_SOCKET_PROTOCOL_ERROR_CLOSE_STATUS, _
  		$WINHTTP_WEB_SOCKET_INVALID_DATA_TYPE_CLOSE_STATUS, _
  		$WINHTTP_WEB_SOCKET_EMPTY_CLOSE_STATUS, _
  		$WINHTTP_WEB_SOCKET_ABORTED_CLOSE_STATUS, _
  		$WINHTTP_WEB_SOCKET_INVALID_PAYLOAD_CLOSE_STATUS, _
  		$WINHTTP_WEB_SOCKET_POLICY_VIOLATION_CLOSE_STATUS, _
  		$WINHTTP_WEB_SOCKET_MESSAGE_TOO_BIG_CLOSE_STATUS, _
  		$WINHTTP_WEB_SOCKET_UNSUPPORTED_EXTENSIONS_CLOSE_STATUS, _
  		$WINHTTP_WEB_SOCKET_SERVER_ERROR_CLOSE_STATUS, _
  		$WINHTTP_WEB_SOCKET_SECURE_HANDSHAKE_ERROR_CLOSE_STATUS


Func _WinHttpSetOptionNoParams($hInternet, $iOption)
    Local $aCall = DllCall($hWINHTTPDLL__WINHTTP, "bool", "WinHttpSetOption", _
            "handle", $hInternet, "dword", $iOption, "ptr", 0, "dword", 0)
    If @error Or Not $aCall[0] Then Return SetError(4, 0, 0)
    Return 1
EndFunc   ;==>_WinHttpSetOptionNoParams

Func _WinHttpWebSocketCompleteUpgrade($hRequest, $pContext = 0)
    Local $aCall = DllCall($hWINHTTPDLL__WINHTTP, "handle", "WinHttpWebSocketCompleteUpgrade", _
            "handle", $hRequest, _
            "DWORD_PTR", $pContext)
    If @error Then Return SetError(@error, @extended, -1)
    Return $aCall[0]
EndFunc   ;==>_WinHttpWebSocketCompleteUpgrade

Func _WinHttpWebSocketSend($hWebSocket, $iBufferType, $vData)
    Local $tBuffer = 0, $iBufferLen = 0
    If $iBufferType = $WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE and IsBinary($vData) = 0 Then
		$vData = StringToBinary($vData)
		$iBufferLen = BinaryLen($vData)
	Else
		$iBufferLen = StringLen($vData)
	EndIf

    If $iBufferLen > 0 Then
        $tBuffer = DllStructCreate("byte[" & $iBufferLen & "]")
        DllStructSetData($tBuffer, 1, $vData)
    EndIf

    Local $aCall = DllCall($hWINHTTPDLL__WINHTTP, "DWORD", "WinHttpWebSocketSend", _
            "handle", $hWebSocket, _
            "int", $iBufferType, _
            "ptr", DllStructGetPtr($tBuffer), _
            "DWORD", $iBufferLen)
    If @error Then Return SetError(@error, @extended, -1)
    Return $aCall[0]
EndFunc   ;==>_WinHttpWebSocketSend

Func _WinHttpWebSocketReceive($hWebSocket, $tBuffer, ByRef $iBytesRead, ByRef $iBufferType)
    Local $aCall = DllCall($hWINHTTPDLL__WINHTTP, "handle", "WinHttpWebSocketReceive", _
            "handle", $hWebSocket, _
            "ptr", DllStructGetPtr($tBuffer), _
            "DWORD", DllStructGetSize($tBuffer), _
            "DWORD*", $iBytesRead, _
            "int*", $iBufferType)

    If @error Then Return SetError(@error, @extended, -1)

    $iBytesRead = $aCall[4]
    $iBufferType = $aCall[5]
    Return $aCall[0]
EndFunc   ;==>_WinHttpWebSocketReceive

Func _WinHttpWebSocketClose($hWebSocket, $iStatus, $tReason = 0)
    Local $aCall = DllCall($hWINHTTPDLL__WINHTTP, "handle", "WinHttpWebSocketClose", _
            "handle", $hWebSocket, _
            "USHORT", $iStatus, _
            "ptr", DllStructGetPtr($tReason), _
            "DWORD", DllStructGetSize($tReason))
    If @error Then Return SetError(@error, @extended, -1)
    Return $aCall[0]
EndFunc   ;==>_WinHttpWebSocketClose

Func _WinHttpWebSocketShutdown($hWebSocket, $iStatus, $tReason = 0)
    Local $aCall = DllCall($hWINHTTPDLL__WINHTTP, "handle", "WinHttpWebSocketShutdown", _
            "handle", $hWebSocket, _
            "USHORT", $iStatus, _
            "ptr", DllStructGetPtr($tReason), _
            "DWORD", DllStructGetSize($tReason))
    If @error Then Return SetError(@error, @extended, -1)
    Return $aCall[0]
EndFunc   ;==>_WinHttpWebSocketShutdown

Func _WinHttpWebSocketQueryCloseStatus($hWebSocket, ByRef $iStatus, ByRef $iReasonLengthConsumed, $tCloseReasonBuffer = 0)
    Local $aCall = DllCall($hWINHTTPDLL__WINHTTP, "handle", "WinHttpWebSocketQueryCloseStatus", _
            "handle", $hWebSocket, _
            "USHORT*", $iStatus, _
            "ptr", DllStructGetPtr($tCloseReasonBuffer), _
            "DWORD", DllStructGetSize($tCloseReasonBuffer), _
            "DWORD*", $iReasonLengthConsumed)
    If @error Then Return SetError(@error, @extended, -1)
    $iStatus = $aCall[2]
    $iReasonLengthConsumed = $aCall[5]
    Return $aCall[0]
EndFunc   ;==>_WinHttpWebSocketQueryCloseStatus