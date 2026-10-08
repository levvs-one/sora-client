package engine

// init enables core-managed Xray TUN routes only on Linux. Other platforms use
// sing-box or mihomo to install routes.
func init() { Catalog[KindXray].Features[FeatureTun] = true }
