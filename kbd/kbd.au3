#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=kbd.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#Include <Misc.au3>
#Include <Color.au3>
#include <AutoItConstants.au3>
#include <WinAPIGdiDC.au3>
#include <WinAPIGdi.au3>

Opt("PixelCoordMode", 2)
Opt("MouseCoordMode", 2)

; Константы
Global Const $ENGLISH_LAYOUT = 0x4090409
Global Const $RUSSIAN_LAYOUT = 0x4190419
Global Const $VK_NUMLOCK = 0x90
Global Const $BUTTON_COUNT = 120
Global Const $FRAME_X = 1
Global Const $FRAME_Y = 1
Global Const $SLEEP_MIN = 50
Global Const $SLEEP_MAX = 1000
Global Const $SLEEP_RANDOM = 150
Global Const $AOE_BUTTON = 1000 ; Номер кнопки для AoE-спеллов
Global Const $AOE_Y_OFFSET = 0.6 ; Смещение клика на 60% высоты экрана

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

    ; Панель 2 (13-24): num0..num9, num+, num-
    $keyMap[13] = "{NUMPAD0}"
    $keyMap[14] = "{NUMPAD1}"
    $keyMap[15] = "{NUMPAD2}"
    $keyMap[16] = "{NUMPAD3}"
    $keyMap[17] = "{NUMPAD4}"
    $keyMap[18] = "{NUMPAD5}"
    $keyMap[19] = "{NUMPAD6}"
    $keyMap[20] = "{NUMPAD7}"
    $keyMap[21] = "{NUMPAD8}"
    $keyMap[22] = "{NUMPAD9}"
    $keyMap[23] = "{NUMPADSUB}"
    $keyMap[24] = "{NUMPADADD}"

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

    ; Панель 4 (37-48): q|й, `|ё, e|у, r|к, t|е, f|а, Ctrl + F7..F12
    $keyMap[37] = "q|й"
    $keyMap[38] = "`|ё"
    $keyMap[39] = "e|у"
    $keyMap[40] = "r|к"
    $keyMap[41] = "t|е"
    $keyMap[42] = "f|а"
    $keyMap[43] = "^{F7}"
    $keyMap[44] = "^{F8}"
    $keyMap[45] = "^{F9}"
    $keyMap[46] = "^{F10}"
    $keyMap[47] = "^{F11}"
    $keyMap[48] = "^{F12}"

    ; Панель 5 (49-60): Ctrl + Numpad0..Numpad9, Numpad+, Numpad-
    $keyMap[49] = "^{NUMPAD0}"
    $keyMap[50] = "^{NUMPAD1}"
    $keyMap[51] = "^{NUMPAD2}"
    $keyMap[52] = "^{NUMPAD3}"
    $keyMap[53] = "^{NUMPAD4}"
    $keyMap[54] = "^{NUMPAD5}"
    $keyMap[55] = "^{NUMPAD6}"
    $keyMap[56] = "^{NUMPAD7}"
    $keyMap[57] = "^{NUMPAD8}"
    $keyMap[58] = "^{NUMPAD9}"
    $keyMap[59] = "^{NUMPADSUB}"
    $keyMap[60] = "^{NUMPADADD}"

    ; Панель 6 (61-72): Alt + Numpad0..Numpad9, Numpad+, Numpad-
    $keyMap[61] = "!{NUMPAD0}"
    $keyMap[62] = "!{NUMPAD1}"
    $keyMap[63] = "!{NUMPAD2}"
    $keyMap[64] = "!{NUMPAD3}"
    $keyMap[65] = "!{NUMPAD4}"
    $keyMap[66] = "!{NUMPAD5}"
    $keyMap[67] = "!{NUMPAD6}"
    $keyMap[68] = "!{NUMPAD7}"
    $keyMap[69] = "!{NUMPAD8}"
    $keyMap[70] = "!{NUMPAD9}"
    $keyMap[71] = "!{NUMPADSUB}"
    $keyMap[72] = "!{NUMPADADD}"

    ; Панель 7 (73-84): Ctrl+Shift + Numpad0..Numpad9, Numpad+, Numpad-
    $keyMap[73] = "^+{NUMPAD0}"
    $keyMap[74] = "^+{NUMPAD1}"
    $keyMap[75] = "^+{NUMPAD2}"
    $keyMap[76] = "^+{NUMPAD3}"
    $keyMap[77] = "^+{NUMPAD4}"
    $keyMap[78] = "^+{NUMPAD5}"
    $keyMap[79] = "^+{NUMPAD6}"
    $keyMap[80] = "^+{NUMPAD7}"
    $keyMap[81] = "^+{NUMPAD8}"
    $keyMap[82] = "^+{NUMPAD9}"
    $keyMap[83] = "^+{NUMPADSUB}"
    $keyMap[84] = "^+{NUMPADADD}"

    ; Панель 8 (85-96): Shift+Alt + Numpad0..Numpad9, Numpad+, Numpad-
    $keyMap[85] = "+!{NUMPAD0}"
    $keyMap[86] = "+!{NUMPAD1}"
    $keyMap[87] = "+!{NUMPAD2}"
    $keyMap[88] = "+!{NUMPAD3}"
    $keyMap[89] = "+!{NUMPAD4}"
    $keyMap[90] = "+!{NUMPAD5}"
    $keyMap[91] = "+!{NUMPAD6}"
    $keyMap[92] = "+!{NUMPAD7}"
    $keyMap[93] = "+!{NUMPAD8}"
    $keyMap[94] = "+!{NUMPAD9}"
    $keyMap[95] = "+!{NUMPADSUB}"
    $keyMap[96] = "+!{NUMPADADD}"

    ; Панель 9 (97-108): Ctrl+Alt + Numpad0..Numpad9, Numpad+, Numpad-
    $keyMap[97] = "^!{NUMPAD0}"
    $keyMap[98] = "^!{NUMPAD1}"
    $keyMap[99] = "^!{NUMPAD2}"
    $keyMap[100] = "^!{NUMPAD3}"
    $keyMap[101] = "^!{NUMPAD4}"
    $keyMap[102] = "^!{NUMPAD5}"
    $keyMap[103] = "^!{NUMPAD6}"
    $keyMap[104] = "^!{NUMPAD7}"
    $keyMap[105] = "^!{NUMPAD8}"
    $keyMap[106] = "^!{NUMPAD9}"
    $keyMap[107] = "^!{NUMPADSUB}"
    $keyMap[108] = "^!{NUMPADADD}"

    ; Панель 10 (109-120): Ctrl+Shift+Alt + Numpad0..Numpad9, Numpad+, Numpad-
    $keyMap[109] = "^+!{NUMPAD0}"
    $keyMap[110] = "^+!{NUMPAD1}"
    $keyMap[111] = "^+!{NUMPAD2}"
    $keyMap[112] = "^+!{NUMPAD3}"
    $keyMap[113] = "^+!{NUMPAD4}"
    $keyMap[114] = "^+!{NUMPAD5}"
    $keyMap[115] = "^+!{NUMPAD6}"
    $keyMap[116] = "^+!{NUMPAD7}"
    $keyMap[117] = "^+!{NUMPAD8}"
    $keyMap[118] = "^+!{NUMPAD9}"
    $keyMap[119] = "^+!{NUMPADSUB}"
    $keyMap[120] = "^+!{NUMPADADD}"
EndFunc

; Проверка наличия окна WoW
Func CheckWindow()
    $hWnd = WinGetHandle("World of Warcraft")
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
	;return GetPixelColorFromWindow($FRAME_X, $FRAME_Y)
    Local $color = GetPixelColorFromWindow($FRAME_X, $FRAME_Y)
    If $color = -1 Then Return -1
    Local $r = BitShift(BitAND($color, 0xFF0000), 16)
    Local $g = BitShift(BitAND($color, 0x00FF00), 8)
    Local $b = BitAND($color, 0x0000FF)
    Return $r * 65536 + $g * 256 + $b
EndFunc

; Проверка, что модификаторы не нажаты пользователем
Func AreModifiersReleased()
    Return Not _IsPressed("10") And Not _IsPressed("11") And Not _IsPressed("12") ; Shift, Ctrl, Alt
EndFunc

; Отправка клавиши с учётом модификаторов и раскладки
Func SendKeyWithModifiers($key)
    Local $modifiers = ""
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

    ; Разбираем модификаторы
    If StringLeft($baseKey, 1) = "+" Then
        $modifiers &= "{SHIFT down}"
        $baseKey = StringTrimLeft($baseKey, 1)
    EndIf
    If StringLeft($baseKey, 1) = "^" Then
        $modifiers &= "{CTRL down}"
        $baseKey = StringTrimLeft($baseKey, 1)
    EndIf
    If StringLeft($baseKey, 1) = "!" Then
        $modifiers &= "{ALT down}"
        $baseKey = StringTrimLeft($baseKey, 1)
    EndIf

    ; Фильтр для предотвращения Alt+F4
    If $modifiers & "{ALT down}" And $baseKey = "{F4}" Then
        ConsoleWrite("Alt+F4 sending is prevented" & @CRLF) ;Предотвращена отправка Alt+F4
        Return
    EndIf

    ; Отправляем модификаторы, клавишу, отпускаем
    If $modifiers <> "" Then
        ControlSend($hWnd, "", "", $modifiers, 1)
		Sleep(10) ; Небольшая задержка для обработки
    EndIf
    ControlSend($hWnd, "", "", $baseKey, 1)
	Sleep(10) ; Небольшая задержка для обработки
    If $modifiers <> "" Then
        ControlSend($hWnd, "", "", StringReplace($modifiers, "down", "up"), 1)
		Sleep(10) ; Небольшая задержка для обработки
    EndIf
EndFunc


; Обработка AoE-спелла (клик в центре экрана)
Func HandleAoESpell()
    Local $isRButtonDown = _IsPressed("02") ; Правая кнопка мыши

	; Не используется управление камерой и нажат модификатор
	if Not $isRButtonDown And Not AreModifiersReleased() Then
		; Ситуация с контролируемой позицией спела
		; Например AoE по Ctrl у мага в указанную облать
		; Тогда просто кликаем мышкой по текущим координатам и выходим
		ControlSend($hWnd, "", "", "{LButton down}", 1)
        Sleep(10) ; Небольшая задержка для обработки
		ControlSend($hWnd, "", "", "{LButton up}", 1)
		Sleep(10) ; Небольшая задержка для обработки
		Return
	EndIf

	; Сохраняем текущую позицию курсора
    Local $mousePos = MouseGetPos()
    If @error Then ; Не удалось получить позицию курсора
        ConsoleWrite("Couldn't get cursor position" & @CRLF)
        Return
    EndIf

	; Проверяем, удерживается ли правая кнопка мыши
    If $isRButtonDown Then
        ControlSend($hWnd, "", "", "{RButton up}", 1)
        Sleep(10) ; Небольшая задержка для обработки
    EndIf

    ; Получаем размеры окна WoW
    Local $winPos = WinGetPos($hWnd)
    If @error Then ;Не удалось получить размеры окна
        ConsoleWrite("Couldn't get the window dimensions" & @CRLF)
        Return
    EndIf
    Local $winX = $winPos[0]
    Local $winY = $winPos[1]
    Local $winWidth = $winPos[2]
    Local $winHeight = $winPos[3]

    ; Вычисляем центр экрана (чуть ниже, 60% высоты)
    Local $centerX = $winX + $winWidth / 2
    Local $centerY = $winY + $winHeight * $AOE_Y_OFFSET

    ; Перемещаем курсор и кликаем
    ControlClick($hWnd, "", "", "left", 1, $centerX - $winX, $centerY - $winY)
    Sleep(10) ; Задержка для обработки клика

    ; Возвращаем курсор в исходную позицию
    MouseMove($mousePos[0], $mousePos[1], 0)

    ; Восстанавливаем правую кнопку, если она была нажата
    If $isRButtonDown Then
        ControlSend($hWnd, "", "", "{RButton down}", 1)
		Sleep(10) ; Задержка для обработки клика
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
			HandleAoESpell()
		ElseIf $num >= 1 And $num <= $BUTTON_COUNT And AreModifiersReleased() Then
			EnableNumLock()
			ToolTip($keyMap[$num], 10,0)
			SendKeyWithModifiers($keyMap[$num])
		EndIf

        Sleep($SLEEP_MIN + Random(0, $SLEEP_RANDOM))
    WEnd
EndFunc

; Инициализация комбинации клавиш
SetupKeyMap()
; Запуск программы
MainLoop()
