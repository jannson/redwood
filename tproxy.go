package main

import (
	"errors"
	"log"
	"net"
	"net/http"
	"strings"
	"time"

	"github.com/elico/go-linux-tproxy"
)

func runTproxyTlsServer(addr string) error {
	ln, err := tproxy.TcpListen(addr)
	if err != nil {
		return err
	}
	go func() {
		<-shutdownChan
		ln.Close()
	}()

	var tempDelay time.Duration

	for {
		conn, err := ln.Accept()
		if err != nil {
			if ne, ok := err.(net.Error); ok && ne.Temporary() {
				if tempDelay == 0 {
					tempDelay = 5 * time.Millisecond
				} else {
					tempDelay *= 2
				}
				if max := 1 * time.Second; tempDelay > max {
					tempDelay = max
				}
				log.Printf("Accept error: %v; retrying in %v", err, tempDelay)
				time.Sleep(tempDelay)
				continue
			}
			return err
		}

		go func() {
			serverAddr := conn.LocalAddr()
			log.Println("serverAddr", serverAddr)
			user, _, _ := net.SplitHostPort(conn.RemoteAddr().String())

			if isLocalAddress(serverAddr) {
				// This is not an intercepted connection; it is a direct connection to
				// our transparent port. If we bump it, we will end up with an infinite
				// loop of redirects.
				logTLS(user, serverAddr.String(), "", errors.New("infinite redirect loop"), false)
				conn.Close()
				return
			}

			SSLBump(conn, serverAddr.String(), user, "", nil)
		}()
	}

	panic("unreachable")
}

func runTproxyHttpServer(addr string) error {
	proxyListener, err := tproxy.TcpListen(addr)
	if err != nil {
		return err
	}
	if err != nil {
		log.Fatalf("error listening for connections on %s: %s", addr, err)
	}
	go func() {
		<-shutdownChan
		proxyListener.Close()
	}()
	server := http.Server{Handler: proxyHandler{}}
	go func() {
		err := server.Serve(tcpKeepAliveListener{proxyListener.(*net.TCPListener)})
		if err != nil && !strings.Contains(err.Error(), "use of closed") {
			log.Fatalln("Error running HTTP proxy:", err)
		}
	}()

	return nil
}
