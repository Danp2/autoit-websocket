;http://code.msdn.microsoft.com/windowsdesktop/WinHTTP-WebSocket-sample-50a140b5/sourcecode?fileId=51199&pathId=1032775223
#include "WinHttp_WebSocket.au3"
#include <WinAPI.au3> ;_WinAPI_GetLastError

Global $hOpen = 0, $hConnect = 0, $hRequest = 0, $hWebSocket = 0
Global $iError = 0

Example()
Exit quit()

Func Example()
    Local $sServerName = "echo.websocket.org"
    Local $sPath = ""

    Local $sMessage = "Hello world"

    ; Create session, connection and request handles.

    $hOpen = _WinHttpOpen("WebSocket sample", $WINHTTP_ACCESS_TYPE_DEFAULT_PROXY)
    If $hOpen = 0 Then
        $iError = _WinAPI_GetLastError()
        ConsoleWrite("Open error" & @CRLF)
        Return False
    EndIf

    $hConnect = _WinHttpConnect($hOpen, $sServerName, $INTERNET_DEFAULT_HTTP_PORT)
    If $hConnect = 0 Then
        $iError = _WinAPI_GetLastError()
        ConsoleWrite("Connect error" & @CRLF)
        Return False
    EndIf

    $hRequest = _WinHttpOpenRequest($hConnect, "GET", $sPath, "")
    If $hRequest = 0 Then
        $iError = _WinAPI_GetLastError()
        ConsoleWrite("OpenRequest error" & @CRLF)
        Return False
    EndIf

    ; Request protocol upgrade from http to websocket.

    Local $fStatus = _WinHttpSetOptionNoParams($hRequest, $WINHTTP_OPTION_UPGRADE_TO_WEB_SOCKET)
    If Not $fStatus Then
        $iError = _WinAPI_GetLastError()
        ConsoleWrite("SetOption error" & @CRLF)
        Return False
    EndIf

    ; Perform websocket handshake by sending a request and receiving server's response.
    ; Application may specify additional headers if needed.

    $fStatus = _WinHttpSendRequest($hRequest)
    If Not $fStatus Then
        $iError = _WinAPI_GetLastError()
        ConsoleWrite("SendRequest error" & @CRLF)
        Return False
    EndIf

    $fStatus = _WinHttpReceiveResponse($hRequest)
    If Not $fStatus Then
        $iError = _WinAPI_GetLastError()
        ConsoleWrite("SendRequest error" & @CRLF)
        Return False
    EndIf

    ; Application should check what is the HTTP status code returned by the server and behave accordingly.
    ; WinHttpWebSocketCompleteUpgrade will fail if the HTTP status code is different than 101.

    $hWebSocket = _WinHttpWebSocketCompleteUpgrade($hRequest, 0)
    If $hWebSocket = 0 Then
        $iError = _WinAPI_GetLastError()
        ConsoleWrite("WebSocketCompleteUpgrade error" & @CRLF)
        Return False
    EndIf

    _WinHttpCloseHandle($hRequest)
    $hRequestHandle = 0

    ConsoleWrite("Succesfully upgraded to websocket protocol" & @CRLF)

    ; Send and receive data on the websocket protocol.

    $iError = _WinHttpWebSocketSend($hWebSocket, _
            $WINHTTP_WEB_SOCKET_BINARY_MESSAGE_BUFFER_TYPE, _
            $sMessage)
    If @error Or $iError <> 0 Then
        ConsoleWrite("WebSocketSend error" & @CRLF)
        Return False
    EndIf

    ConsoleWrite("Sent message to the server: " & $sMessage & @CRLF)

    Local $iBufferLen = 1024
    Local $tBuffer = 0, $bRecv = Binary("")

    Local $iBytesRead = 0, $iBufferType = 0
    Do
        If $iBufferLen = 0 Then
            $iError = $ERROR_NOT_ENOUGH_MEMORY
            Return False
        EndIf

        $tBuffer = DllStructCreate("byte[" & $iBufferLen & "]")

        $iError = _WinHttpWebSocketReceive($hWebSocket, _
                $tBuffer, _
                $iBytesRead, _
                $iBufferType)
        If @error Or $iError <> 0 Then
            ConsoleWrite("WebSocketReceive error" & @CRLF)
            Return False
        EndIf

        ; If we receive just part of the message restart the receive operation.

        $bRecv &= BinaryMid(DllStructGetData($tBuffer, 1), 1, $iBytesRead)
        $tBuffer = 0

        $iBufferLen -= $iBytesRead
    Until $iBufferType <> $WINHTTP_WEB_SOCKET_BINARY_FRAGMENT_BUFFER_TYPE

    ; We expected server just to echo single binary message.

    If $iBufferType <> $WINHTTP_WEB_SOCKET_BINARY_MESSAGE_BUFFER_TYPE Then
        ConsoleWrite("Unexpected buffer type" & @CRLF)
        $iError = $ERROR_INVALID_PARAMETER
        Return False
    EndIf

    ConsoleWrite("Received message from the server: '" & BinaryToString($bRecv) & "'" & @CRLF)

    ; Gracefully close the connection.

    $iError = _WinHttpWebSocketClose($hWebSocket, _
            $WINHTTP_WEB_SOCKET_SUCCESS_CLOSE_STATUS)
    If @error Or $iError <> 0 Then
        ConsoleWrite("WebSocketClose error" & @CRLF)
        Return False
    EndIf

    ; Check close status returned by the server.

    Local $iStatus = 0, $iReasonLengthConsumed = 0
    Local $tCloseReasonBuffer = DllStructCreate("byte[123]")

    $iError = _WinHttpWebSocketQueryCloseStatus($hWebSocket, _
            $iStatus, _
            $iReasonLengthConsumed, _
            $tCloseReasonBuffer)
    If @error Or $iError <> 0 Then
        ConsoleWrite("QueryCloseStatus error" & @CRLF)
        Return False
    EndIf

    ConsoleWrite("The server closed the connection with status code: '" & $iStatus & "' and reason: '" & _
            BinaryToString(BinaryMid(DllStructGetData($tCloseReasonBuffer, 1), 1, $iReasonLengthConsumed)) & "'" & @CRLF)
EndFunc   ;==>Example

Func quit()
    If $hRequest <> 0 Then
        _WinHttpCloseHandle($hRequest)
        $hRequest = 0
    EndIf

    If $hWebSocket <> 0 Then
        _WinHttpCloseHandle($hWebSocket)
        $hWebSocket = 0
    EndIf

    If $hConnect <> 0 Then
        _WinHttpCloseHandle($hConnect)
        $hConnect = 0
    EndIf

    If $iError <> 0 Then
        ConsoleWrite("Application failed with error: " & $iError & @CRLF)
        Return -1
    EndIf

    Return 0
EndFunc