package engine

// The core routes into Xray's tun adapter on Linux only (engine/tunroute);
// elsewhere a tun plan goes to sing-box or mihomo, which route themselves.
func init() { Catalog[KindXray].Features[FeatureTun] = true }
