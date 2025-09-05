#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=kbd.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#Include <Misc.au3>
#Include <Color.au3>
#include <AutoItConstants.au3>

Opt("PixelCoordMode", 2)
Opt("MouseCoordMode", 2)

HotKeySet("{MEDIA_STOP}", "quit")
Func quit()
   exit
EndFunc

local $wow = "World of Warcraft"
local $keys = StringSplit("1 2 3 4 5 6 7 8 9 0 - = {NUMPAD1} {NUMPAD2} {NUMPAD3} {NUMPAD4} {NUMPAD5} {NUMPAD6} {NUMPAD7} {NUMPAD8} {NUMPAD9} {NUMPAD0} {NUMPADSUB} {NUMPADADD} {F1} {F2} {F3} {F4} {F5} {F6} {F7} {F8} {F9} {F10} {F11} {F12} ", " ", 2)
local $len = UBound($keys)
While 1
	if WinActive($wow) Then
		$flag = PixelGetColor(1,1)
		if $flag == 1000 Then
			MouseClick($MOUSE_CLICK_LEFT)
			Sleep(125)
		EndIf
		if $flag > 0 and $flag < $len Then
			;ToolTip($keys[$flag - 1] & ' ' & $flag, 10,0)
			Send($keys[$flag - 1])
			Sleep(125)
		EndIf
	EndIf
	Sleep(50)
WEnd











