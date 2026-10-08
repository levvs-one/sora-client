//go:build linux

package main

import (
	"context"
	"encoding/binary"
	"fmt"
	"io"
	"net"
	"syscall"
	"time"

	"golang.org/x/net/dns/dnsmessage"
	"golang.org/x/sys/unix"
)

// dnsServer answers A queries for the real HTTP endpoint in the server namespace.
func dnsServer() {
	conn, err := net.ListenPacket("udp4", "192.168.0.1:53")
	must(err)
	defer conn.Close()
	fmt.Println("ready")
	buf := make([]byte, 4096)
	for {
		n, peer, err := conn.ReadFrom(buf)
		must(err)
		var m dnsmessage.Message
		must(m.Unpack(buf[:n]))
		fmt.Println(peer, m.Questions)
		m.Response, m.RecursionAvailable = true, true
		for _, q := range m.Questions {
			if q.Type == dnsmessage.TypeA {
				m.Answers = append(m.Answers, dnsmessage.Resource{
					Header: dnsmessage.ResourceHeader{Name: q.Name, Type: q.Type, Class: q.Class, TTL: 60},
					Body:   &dnsmessage.AResource{A: [4]byte{203, 0, 113, 80}},
				})
			}
		}
		response, err := m.Pack()
		must(err)
		_, err = conn.WriteTo(response, peer)
		must(err)
	}
}

func dnsQuery(network, device, name string) {
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	d := net.Dialer{Control: func(_, _ string, raw syscall.RawConn) error {
		var bindErr error
		err := raw.Control(func(fd uintptr) {
			if device != "none" {
				bindErr = unix.BindToDevice(int(fd), device)
			}
		})
		if err != nil {
			return err
		}
		return bindErr
	}}
	// A dedicated client port excludes the engine's legitimate resolver
	// queries from the receiver-side leak counter.
	if network == "tcp" {
		d.LocalAddr = &net.TCPAddr{Port: 15353}
	} else {
		d.LocalAddr = &net.UDPAddr{Port: 15353}
	}
	conn, err := d.DialContext(ctx, network+"4", "192.168.0.1:53")
	must(err)
	defer conn.Close()
	must(conn.SetDeadline(time.Now().Add(time.Second)))
	qname, err := dnsmessage.NewName(name)
	must(err)
	m := dnsmessage.Message{Header: dnsmessage.Header{ID: 5340, RecursionDesired: true},
		Questions: []dnsmessage.Question{{Name: qname, Type: dnsmessage.TypeA, Class: dnsmessage.ClassINET}}}
	packet, err := m.Pack()
	must(err)
	if network == "tcp" {
		packet = append(binary.BigEndian.AppendUint16(nil, uint16(len(packet))), packet...)
	}
	_, err = conn.Write(packet)
	must(err)
	var buf []byte
	if network == "tcp" {
		var header [2]byte
		_, err = io.ReadFull(conn, header[:])
		must(err)
		buf = make([]byte, int(binary.BigEndian.Uint16(header[:])))
		_, err = io.ReadFull(conn, buf)
		must(err)
	} else {
		buf = make([]byte, 4096)
		n, err := conn.Read(buf)
		must(err)
		buf = buf[:n]
	}
	must(m.Unpack(buf))
	if !m.Response || m.ID != 5340 || len(m.Answers) == 0 {
		panic("no DNS answer")
	}
	for _, a := range m.Answers {
		if ip, ok := a.Body.(*dnsmessage.AResource); ok {
			fmt.Println(net.IP(ip.A[:]))
		}
	}
}
