// Package core is the root of libsora, the Sora network core.
//
// libsora supervises a forwarding engine as a child process, owns the system
// settings a tunnel needs, and answers the control plane the interface talks to.
// It is hosted by the desktop core service on Windows and Linux and by the
// Android tunnel service.
//
// The engine today is mihomo, driven through its own control interface; the
// boundary in core/engine is what allows another engine to take its place. A plan
// holds only references to credentials, and the material behind them lives in
// core/secret.
package core
