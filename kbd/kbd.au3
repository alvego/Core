#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=kbd.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#Include <Misc.au3>
#Include <Color.au3>
#include <AutoItConstants.au3>
#include <WinAPIGdiDC.au3>
#include <WinAPIGdi.au3>

Opt("PixelCoordMode", 1)
Opt("MouseCoordMode", 1)

Opt("SendKeyDelay", 75) ; изменяет продолжительность паузы между эмулированными нажатиями клавиш.
Opt("SendKeyDownDelay", 50) ; изменяет продолжительность нажатого состояния клавиши, перед тем как отпустить.

; Константы
Global Const $WINDOW_TITLE = "World of Warcraft"
Global Const $VK_NUMLOCK = 0x90
Global Const $ENGLISH_LAYOUT = 0x4090409
Global Const $RUSSIAN_LAYOUT = 0x4190419
Global Const $BUTTON_COUNT = 120
Global Const $FRAME_X = 1
Global Const $FRAME_Y = 1
Global Const $SLEEP_MIN = 50
Global Const $SLEEP_MAX = 1000
Global Const $SLEEP_RANDOM = 100
Global Const $AOE_BUTTON = 1000 ; Номер кнопки для AoE-спеллов (Просто клик)
Global Const $AOE_BUTTON_CENTER = 1001 ; Номер кнопки для AoE-спеллов (Клик в центре экрана)
Global Const $AFK_BUTTON = 2000 ; Сброс AFK
Global Const $AOE_Y_OFFSET = 0.5 ; Смещение клика на % высоты экрана

; Глобальные переменные
Global $hWnd
Global $keyMap[$BUTTON_COUNT + 1]

; Настройка маппинга клавиш
Func SetupKeyMap()
    ; Панель 1 (1-12): 1..9, 0, -, =
    $keyMap[1] = "1"
    $keyMap[2] = "2"
    $keyMap[3] = "3"
    $keyMap[4] = "4"
    $keyMap[5] = "5"
    $keyMap[6] = "6"
    $keyMap[7] = "7"
    $keyMap[8] = "8"
    $keyMap[9] = "9"
    $keyMap[10] = "0"
    $keyMap[11] = "-"
    $keyMap[12] = "="

    ; Панель 2 (13-24): Shift + F1..F12
    $keyMap[13] = "+{F1}"
    $keyMap[14] = "+{F2}"
    $keyMap[15] = "+{F3}"
    $keyMap[16] = "+{F4}"
    $keyMap[17] = "+{F5}"
    $keyMap[18] = "+{F6}"
    $keyMap[19] = "+{F7}"
    $keyMap[20] = "+{F8}"
    $keyMap[21] = "+{F9}"
    $keyMap[22] = "+{F10}"
    $keyMap[23] = "+{F11}"
    $keyMap[24] = "+{F12}"

    ; Панель 3 (25-36): F1..F12
    $keyMap[25] = "{F1}"
    $keyMap[26] = "{F2}"
    $keyMap[27] = "{F3}"
    $keyMap[28] = "{F4}"
    $keyMap[29] = "{F5}"
    $keyMap[30] = "{F6}"
    $keyMap[31] = "{F7}"
    $keyMap[32] = "{F8}"
    $keyMap[33] = "{F9}"
    $keyMap[34] = "{F10}"
    $keyMap[35] = "{F11}"
    $keyMap[36] = "{F12}"

    ; Панель 4 (37-48): Ctrl + F1..F12
    $keyMap[37] = "^{F1}"
    $keyMap[38] = "^{F2}"
    $keyMap[39] = "^{F3}"
    $keyMap[40] = "^{F4}"
    $keyMap[41] = "^{F5}"
    $keyMap[42] = "^{F6}"
    $keyMap[43] = "^{F7}"
    $keyMap[44] = "^{F8}"
    $keyMap[45] = "^{F9}"
    $keyMap[46] = "^{F10}"
    $keyMap[47] = "^{F11}"
    $keyMap[48] = "^{F12}"

    ; Панель 5 (49-60): q|й, `|ё, e|у, r|к, t|е, f|а, g|п, Alt + F8..F12
    $keyMap[49] = "q|й"
    $keyMap[50] = "`|ё"
    $keyMap[51] = "e|у"
    $keyMap[52] = "r|к"
    $keyMap[53] = "t|е"
    $keyMap[54] = "f|а"
    $keyMap[55] = "g|п"
    $keyMap[56] = "^q|^й"
    $keyMap[57] = "^e|^у"
    $keyMap[58] = "^r|^к"
    $keyMap[59] = "^t|^е"
    $keyMap[60] = "^f|^а"

    ; Панель 6 (61-72):  num0..num9, num+, num-
    $keyMap[61] = "{NUMPAD0}"
    $keyMap[62] = "{NUMPAD1}"
    $keyMap[63] = "{NUMPAD2}"
    $keyMap[64] = "{NUMPAD3}"
    $keyMap[65] = "{NUMPAD4}"
    $keyMap[66] = "{NUMPAD5}"
    $keyMap[67] = "{NUMPAD6}"
    $keyMap[68] = "{NUMPAD7}"
    $keyMap[69] = "{NUMPAD8}"
    $keyMap[70] = "{NUMPAD9}"
    $keyMap[71] = "{NUMPADSUB}"
    $keyMap[72] = "{NUMPADADD}"

    ; Панель 7 (73-84): Ctrl + 1..9, Ctrl + 0, Ctrl + -, Ctrl + =
    $keyMap[73] = "^1"
    $keyMap[74] = "^2"
    $keyMap[75] = "^3"
    $keyMap[76] = "^4"
    $keyMap[77] = "^5"
    $keyMap[78] = "^6"
    $keyMap[79] = "^7"
    $keyMap[80] = "^8"
    $keyMap[81] = "^9"
    $keyMap[82] = "^0"
    $keyMap[83] = "^-"
    $keyMap[84] = "^="

    ; Панель 8 (85-96): Shift + 1..9, Shift + 0, Shift + -, Shift + =
    $keyMap[85] = "+1"
    $keyMap[86] = "+2"
    $keyMap[87] = "+3"
    $keyMap[88] = "+4"
    $keyMap[89] = "+5"
    $keyMap[90] = "+6"
    $keyMap[91] = "+7"
    $keyMap[92] = "+8"
    $keyMap[93] = "+9"
    $keyMap[94] = "+0"
    $keyMap[95] = "+-"
    $keyMap[96] = "+="

    ; Панель 9 (97-108): Ctrl + Shift + 1..9, Ctrl + Shift + 0, Ctrl + Shift + -, Ctrl + Shift + =
    $keyMap[97] = "^+1"
    $keyMap[98] = "^+2"
    $keyMap[99] = "^+3"
    $keyMap[100] ="^+4"
    $keyMap[101] ="^+5"
    $keyMap[102] ="^+6"
    $keyMap[103] ="^+7"
    $keyMap[104] ="^+8"
    $keyMap[105] ="^+9"
    $keyMap[106] ="^+0"
    $keyMap[107] ="^+-"
    $keyMap[108] ="^+="

    ; Панель 10 (109-120): Ctrl + Shift + F1..F12
    $keyMap[109] = "^+{F1}"
    $keyMap[110] = "^+{F2}"
    $keyMap[111] = "^+{F3}"
    $keyMap[112] = "^+{F4}"
    $keyMap[113] = "^+{F5}"
    $keyMap[114] = "^+{F6}"
    $keyMap[115] = "^+{F7}"
    $keyMap[116] = "^+{F8}"
    $keyMap[117] = "^+{F9}"
    $keyMap[118] = "^+{F10}"
    $keyMap[119] = "^+{F11}"
    $keyMap[120] = "^+{F12}"
EndFunc

; Проверка наличия окна WoW
Func CheckWindow()
    $hWnd = WinGetHandle($WINDOW_TITLE)
    If @error Then ; Окно World of Warcraft не найдено!
		ConsoleWrite("The World of Warcraft window has not been found!" & @CRLF)
		Return False
    EndIf
    Return True
EndFunc

; Проверка состояния NumLock
Func IsNumLockOn()
    Local $aRet = DllCall("user32.dll", "int", "GetKeyState", "int", $VK_NUMLOCK)
    Return BitAND($aRet[0], 0x01) = 0x01
EndFunc

; Включение NumLock
Func EnableNumLock()
    If Not IsNumLockOn() Then
        DllCall("user32.dll", "int", "keybd_event", "int", $VK_NUMLOCK, "int", 0x45, "int", 0, "int", 0)
        DllCall("user32.dll", "int", "keybd_event", "int", $VK_NUMLOCK, "int", 0x45, "int", 0x02, "int", 0)
        ConsoleWrite("NumLock is enabled" & @CRLF) ; NumLock включён
    EndIf
EndFunc

; Получение текущей раскладки клавиатуры
Func GetCurrentLayout()
    Local $hDLL = DllOpen("user32.dll")
    Local $aRet = DllCall($hDLL, "int", "GetKeyboardLayout", "int", 0)
    DllClose($hDLL)
    Return $aRet[0]
EndFunc

; Чтение цвета пикселя из неактивного окна
Func GetPixelColorFromWindow($x, $y)
    Local $hDC = _WinAPI_GetDC($hWnd)
    If $hDC = 0 Then Return -1
    Local $color = _WinAPI_GetPixel($hDC, $x, $y)
    _WinAPI_ReleaseDC($hWnd, $hDC)
    Return $color
EndFunc

; Конвертация цвета в номер кнопки
Func ReadButtonNumber()
	return GetPixelColorFromWindow($FRAME_X, $FRAME_Y)
    ;~ Local $color = GetPixelColorFromWindow($FRAME_X, $FRAME_Y)
    ;~ If $color = -1 Then Return -1
    ;~ Local $r = BitShift(BitAND($color, 0xFF0000), 16)
    ;~ Local $g = BitShift(BitAND($color, 0x00FF00), 8)
    ;~ Local $b = BitAND($color, 0x0000FF)
    ;~ Return $r * 65536 + $g * 256 + $b
EndFunc

; Проверка, что модификаторы не нажаты пользователем
Func AreModifiersReleased()
    Return Not _IsPressed("10") And Not _IsPressed("11") And Not _IsPressed("12") ; Shift, Ctrl, Alt
EndFunc

; Отправка клавиши с учётом модификаторов и раскладки
Func SendKeyWithModifiers($key)

    Local $baseKey = $key

    ; Проверяем наличие eng|rus (например, "q|й")
    Local $isLangDependent = StringInStr($key, "|")
    If $isLangDependent Then
        Local $parts = StringSplit($key, "|")
        Local $engKey = $parts[1]
        Local $rusKey = $parts[2]
        Local $layout = GetCurrentLayout()
        $baseKey = ($layout = $RUSSIAN_LAYOUT) ? $rusKey : $engKey
    EndIf

    if StringInStr($baseKey, "{NUMPAD") Then
        EnableNumLock()
    EndIf

	;ToolTip($baseKey, 10,0)
    ControlSend($hWnd, "", "", $baseKey, 0)
	Sleep(10) ; Небольшая задержка для обработки
EndFunc


; Нажать кнопку мыши в указанном окне
Func MouseDownInWindow($hWnd, $button = "left")
    Local $msg = 0
    Switch $button
        Case "left"
            $msg = 0x0201 ; WM_LBUTTONDOWN
        Case "right"
            $msg = 0x0204 ; WM_RBUTTONDOWN
        Case "middle"
            $msg = 0x0207 ; WM_MBUTTONDOWN
    EndSwitch

    ; Без координат - отправляем сообщение без позиции
	DllCall("user32.dll", "bool", "PostMessage", "hwnd", $hWnd, "int", $msg, "wparam", 0, "lparam", 0)
EndFunc

; Отпустить кнопку мыши в указанном окне
Func MouseUpInWindow($hWnd, $button = "left")
    Local $msg = 0
    Switch $button
        Case "left"
            $msg = 0x0202 ; WM_LBUTTONUP
        Case "right"
            $msg = 0x0205 ; WM_RBUTTONUP
        Case "middle"
            $msg = 0x0208 ; WM_MBUTTONUP
    EndSwitch

   	; Без координат - отправляем сообщение без позиции
	DllCall("user32.dll", "bool", "PostMessage", "hwnd", $hWnd, "int", $msg, "wparam", 0, "lparam", 0)
EndFunc

; Клик в указанном окне
Func MouseClickInWindow($hWnd, $button = "left")
    MouseDownInWindow($hWnd, $button)
	Sleep(10)
	MouseUpInWindow($hWnd, $button)
	Sleep(10)
EndFunc

; Перемещение камеры в стороны для сброса AFK статуса
Func SkipAFK()
    SendKeyWithModifiers("{s}")
    Sleep(100)
    SendKeyWithModifiers("{w}")
    Sleep(100)
    SendKeyWithModifiers("{s}")
EndFunc

; Обработка AoE-спелла (клик в центре экрана)
Func HandleAoESpell($inCenter = False)
    Local $isRButtonDown = _IsPressed("02") ; Правая кнопка мыши

    ; Сохраняем текущую позицию курсора
    Local $mousePos = MouseGetPos()
    If @error Then ; Не удалось получить позицию курсора
        ConsoleWrite("Couldn't get cursor position" & @CRLF)
        Return
    EndIf

	; Получаем размеры окна WoW
    Local $winPos = WinGetPos($hWnd)
    If @error Then ;Не удалось получить размеры окна
        ConsoleWrite("Couldn't get the window dimensions" & @CRLF)
        Return
    EndIf

    ; Вычисляем абсолютные координаты центра экрана (чуть ниже, 60% высоты)
    Local $centerX = $winPos[0] + Int($winPos[2] / 2)
    Local $centerY = $winPos[1] + Int($winPos[3] * $AOE_Y_OFFSET)

    ; Проверяем, удерживается ли правая кнопка мыши
    If $isRButtonDown Then
        MouseUpInWindow($hWnd, "right")
        Sleep(10)
    EndIf

    If $inCenter Then
        ; Перемещаем курсор в центр экрана
        MouseMove($centerX, $centerY, 1)
        Sleep(10) ; Задержка для обработки перемещения
    EndIf

    ; Кликаем в центр экрана
    MouseClickInWindow($hWnd, "left")
    Sleep(10)

    If $inCenter Then
        ; Возвращаем курсор в исходную позицию
        MouseMove($mousePos[0], $mousePos[1], 1)
        Sleep(10) ; Задержка для обработки перемещения
    EndIf

    ; Восстанавливаем правую кнопку, если она была нажата
    If $isRButtonDown Then
        MouseDownInWindow($hWnd, "right")
        Sleep(10)
    EndIf
EndFunc

; Основной цикл
Func MainLoop()
    While 1
		if Not CheckWindow() Then
			Sleep($SLEEP_MAX)
			ContinueLoop
		EndIf

		Local $num = ReadButtonNumber()
		If $num = -1 Then
			Sleep($SLEEP_MIN)
			ContinueLoop
		EndIf

		If $num = $AOE_BUTTON Then
			HandleAoESpell(False)
        ElseIf $num = $AOE_BUTTON_CENTER Then
			HandleAoESpell(True)
        ElseIf $num = $AFK_BUTTON Then
            SkipAFK()
		ElseIf $num >= 1 And $num <= $BUTTON_COUNT And AreModifiersReleased() Then
			SendKeyWithModifiers($keyMap[$num])
		EndIf

        Sleep($SLEEP_MIN + Random(0, $SLEEP_RANDOM))
    WEnd
EndFunc

; Инициализация комбинации клавиш
SetupKeyMap()
; Запуск программы
MainLoop()
