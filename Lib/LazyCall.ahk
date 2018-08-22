LazyCall(DllFile)
{
	return New LazyCall(DllFile)
}

class LazyCall
{
	__New(DllFile) {
		this.hModule := DllCall("LoadLibrary", "Str", DllFile, "Ptr")
		this.dll := RegExReplace(DllFile, ".*\\")
	}

	__Delete() {
		DllCall("FreeLibrary", "Ptr", this.hModule)
	}

	__Call(Name, Params*) {
		p := []
		for i, v in Params
		{
			if v is Number
				p.push( "int", v )
			else
				p.push( "str", v )
		}
		return DllCall(this.dll "\" Name, p*)
	}
}