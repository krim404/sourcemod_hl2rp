public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("rp_alcohol", none);
	CreateNative("rp_drugs", none);
	return APLRes_Success;
}

public none(Handle:plugin, numParams)
{

}