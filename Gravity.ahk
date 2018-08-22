﻿#NoEnv
#SingleInstance Force
#KeyHistory 0
SetWorkingDir %A_ScriptDir%
SetBatchLines -1
ListLines Off

;ClearDebugViewPP()

global xc := LazyCall("XCGUI.dll")
global g_hListBox, g_kw
global g_hFontxBold, g_hFontx
global g_fullList := ["Alan Wake", "DARK SOULS™: Prepare To Die Edition", "Hellblade: Senua's Sacrifice", "Metro 2033 Redux", "Metro: Last Light Redux", "INSIDE", "LIMBO", "Tomb Raider", "Verdun", "Hitman: Absolution™"]
global g_hAdapter

xc.XInitXCGUI()
xc.XC_EnableDebugFile(false)
xc.XC_LoadResource("Gravity\资源文件\resource.res")
hWindow := xc.XC_LoadLayout("Gravity\布局文件\layout.xml", 0)

g_hFontxBold := xc.XFont_Create2("Consolas", 12, xc_fontStyle_bold:=1)
xc.XFont_EnableAutoDestroy(g_hFontxBold, false)

g_hFontx := xc.XFont_Create2("Consolas", 12, xc_fontStyle_regular:=0)
xc.XFont_EnableAutoDestroy(g_hFontx, false)

hEdit := xc.XC_GetObjectByName("input")
	xc.XRichEdit_SetSelectBkColor(hEdit, 0x4C4C4C, 255)
	xc.XRichEdit_SetDefaultTextColor(hEdit, 0x4E4D4D, 255)
	xc.XRichEdit_SetRowHeight(hEdit, 26)

	addr := RegisterCallback("RichEdit_OnKeyDown", "F")
	xc.XEle_RegEventC2(hEdit, XE_KEYDOWN:=39, addr)

	addr := RegisterCallback("RichEdit_OnChange", "F")
	xc.XEle_RegEventC2(hEdit, XE_RICHEDIT_CHANGE:=161, addr)
	xc.XRichEdit_EnableEvent_XE_RICHEDIT_CHANGE(hEdit, true)

InitListBox()
xc.XWnd_SetFocusEle(hWindow, hEdit)
xc.XWnd_AdjustLayout(hWindow)
xc.XWnd_ShowWindow(hWindow, 5)

xc.XRunXCGUI()
xc.XExitXCGUI()
ExitApp

InitListBox() {
	hListBox := g_hListBox := xc.XC_GetObjectByName("listbox1")
	xc.XListBox_SetItemTemplateXML(hListBox, "Gravity\ListBox.xml")
	xc.XListBox_SetItemHeightDefault(hListBox, 39, 39)

	hSBV := xc.XSView_GetScrollBarV(hListBox)
	xc.XSBar_ShowButton(hSBV, false)

	g_hAdapter := xc.XListBox_CreateAdapter(hListBox)

	for i, v in g_fullList
		xc.XAdTable_AddItemTextEx(g_hAdapter, "name", v)

	xc.XListBox_SetSelectItem(hListBox, 0)

	addr := RegisterCallback("Listbox_OnSelect", "F")
	xc.XEle_RegEventC2(hListBox, XE_LISTBOX_SELECT:=86, addr)

	addr := RegisterCallback("Listbox_OnTempCreateEnd", "F")
	xc.XEle_RegEventC2(hListBox, XE_LISTBOX_TEMP_CREATE_END:=82, addr)
}

Listbox_OnSelect(hEle, hEventEle, idx, pbHandled) {
	_XListBox_Reload(g_hListBox)
}

Listbox_OnTempCreateEnd(hEle, hEventEle, pItem, pbHandled) {
	Critical
	nState := NumGet(pItem+16, "int")
	idx := NumGet(pItem+0, "int")

	hEdit := xc.XListBox_GetTemplateObject(hEle, idx, 100)
	_XRichEdit_SetTextFont(hEdit, g_hFontx)

	if (nState = 2) ; list_item_state_select
		ChangeItemColor(hEle, idx, 0xffffff)
	if (g_kw != "")
		HighlightMatch(hEdit)
}

ChangeItemColor(hListBox, idx, color) {
	if hRichEdit := xc.XListBox_GetTemplateObject(hListBox, idx, 100)
		_XRichEdit_SetTextColor(hRichEdit, color)
}

RichEdit_OnKeyDown(hEle, hEventEle, wParam, lParam, pbHandled) {
	if wParam in 38,40 ; {Up},{Down} keys
		xc.XEle_PostEvent(g_hListBox, hEle, XE_KEYDOWN:=39, wParam, lParam)
}

RichEdit_OnChange(hEle, hEventEle, pbHandled) {
	g_kw := _XRichEdit_GetText(hEle)
	FilterXAdTable()
	_XListBox_Reload(g_hListBox)
}

_XListBox_Reload(hListBox) {
	xc.XListBox_RefreshData(hListBox)
	xc.XEle_RedrawEle(hListBox, false)
}

_XRichEdit_SetTextColor(hEdit, color, alpha := 255) {
	endColumn := StrLen( _XRichEdit_GetText(hEdit) )
	xc.XRichEdit_SetItemColorEx(hEdit, 0, 0, 0, endColumn, color, alpha)
}

_XRichEdit_SetTextFont(hEdit, hFontx) {
	endColumn := StrLen( _XRichEdit_GetText(hEdit) )
	xc.XRichEdit_SetItemFontEx(hEdit, 0, 0, 0, endColumn, hFontx)
}

_XRichEdit_GetText(hEdit, len := 300) {
	VarSetCapacity(out, len, 0)
	xc.XRichEdit_GetText(hEdit, &out, len)
	return StrGet(&out)
}

HighlightMatch(hEdit) {
	str := _XRichEdit_GetText(hEdit)
	for i, pos in FindMatch(str, g_kw)
	{
		xc.XRichEdit_SetItemColorEx(hEdit, 0, pos, 0, pos+1, 0xF6C35C, 255)
		xc.XRichEdit_SetItemFontEx(hEdit, 0, pos, 0, pos+1, g_hFontxBold)
	}
}

FindMatch(ByRef str, ByRef key) {
	startPos := 1, ret := []
	Loop, Parse, key
	{
		if foundPos := InStr(str, A_LoopField,, startPos)
		{
			startPos := foundPos + 1
			ret.push(foundPos-1)
		}
		else
		{
			ret := []
			Break
		}
	}
	return ret.MaxIndex() ? ret : ""
}

FilterXAdTable() {
	xc.XAdTable_DeleteItemAll(g_hAdapter)
	for i, v in FindAllMatches() {
		xc.XAdTable_AddItemTextEx(g_hAdapter, "name", v)
	}
	xc.XListBox_SetSelectItem(g_hListBox, 0)
	_XListBox_Reload(g_hListBox)
}

FindAllMatches() {
	ret := []
	for i, item in g_fullList
	{
		if IsMatch(item, g_kw)
			ret.push(item)
	}
	return ret
}

IsMatch(ByRef str, ByRef key) {
	startPos := 1, ret := []
	Loop, Parse, key
	{
		if foundPos := InStr(str, A_LoopField,, startPos)
			startPos := foundPos + 1
		else
			return false
	}
	return true
}