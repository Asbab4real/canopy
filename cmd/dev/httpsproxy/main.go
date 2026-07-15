package main

import (
	"crypto/tls"
	"flag"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"time"
)

func main() {
	listenAddr := flag.String("listen", "127.0.0.1:8443", "HTTPS listen address")
	upstreamAddr := flag.String("upstream", "http://127.0.0.1:50002", "HTTP upstream base URL")
	certFile := flag.String("cert", "./.local/certs/canopy.rpc.pem", "TLS certificate path")
	keyFile := flag.String("key", "./.local/certs/canopy.rpc-key.pem", "TLS private key path")
	flag.Parse()

	if err := requireFile(*certFile); err != nil {
		log.Fatal(err)
	}
	if err := requireFile(*keyFile); err != nil {
		log.Fatal(err)
	}

	target, err := url.Parse(*upstreamAddr)
	if err != nil {
		log.Fatalf("invalid upstream URL %q: %v", *upstreamAddr, err)
	}

	proxy := httputil.NewSingleHostReverseProxy(target)
	originalDirector := proxy.Director
	proxy.Director = func(req *http.Request) {
		originalHost := req.Host
		originalDirector(req)
		req.Host = target.Host
		req.Header.Set("X-Forwarded-Host", originalHost)
		if req.TLS != nil {
			req.Header.Set("X-Forwarded-Proto", "https")
		}
	}
	proxy.ErrorLog = log.New(os.Stderr, "httpsproxy: ", log.LstdFlags)

	server := &http.Server{
		Addr:              *listenAddr,
		Handler:           proxy,
		ReadHeaderTimeout: 10 * time.Second,
		TLSConfig: &tls.Config{
			MinVersion: tls.VersionTLS12,
		},
	}

	log.Printf("HTTPS proxy listening on https://%s -> %s", *listenAddr, target.String())
	if err := server.ListenAndServeTLS(*certFile, *keyFile); err != nil && err != http.ErrServerClosed {
		log.Fatal(err)
	}
}

func requireFile(path string) error {
	if _, err := os.Stat(path); err != nil {
		return err
	}
	return nil
}
