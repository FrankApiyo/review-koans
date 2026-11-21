import { createRequire } from "node:module"
import * as dgram from "node:dgram"
import * as dns from "node:dns"
import { lookup as lookupPromise } from "node:dns/promises"
import * as http from "node:http"
import * as http2 from "node:http2"
import { get as httpsGet } from "node:https"
import * as net from "node:net"
import { createConnection, Socket as NetSocket } from "node:net"
import * as tls from "node:tls"
import { test } from "vitest"

test("A TCP connect is refused.", () => {
  net.connect(9, "127.0.0.1")
})

test("A named createConnection is refused.", () => {
  createConnection({ host: "127.0.0.1", port: 9 })
})

test("A connect on a new Socket is refused.", () => {
  new NetSocket().connect(9, "127.0.0.1")
})

test("A TLS connect is refused.", () => {
  tls.connect(9, "127.0.0.1")
})

test("An HTTP request is refused.", () => {
  http.get("http://127.0.0.1:9/")
})

test("An HTTPS request is refused.", () => {
  httpsGet("https://127.0.0.1:9/")
})

test("An HTTP/2 session is refused.", () => {
  http2.connect("http://127.0.0.1:9")
})

test("Fetch is refused.", async () => {
  await fetch("http://127.0.0.1:9/")
})

test("A WebSocket is refused.", () => {
  new WebSocket("ws://127.0.0.1:9/")
})

test("A UDP send is refused.", () => {
  dgram.createSocket("udp4").send("x", 9, "127.0.0.1")
})

test("A DNS lookup is refused.", () => {
  dns.lookup("localhost", () => undefined)
})

test("A promised DNS lookup is refused.", async () => {
  await lookupPromise("localhost")
})

test("A DNS query on a resolver is refused.", () => {
  const resolver = new dns.Resolver()
  resolver.setServers(["127.0.0.1:9"])
  resolver.resolve4("localhost", () => undefined)
})

test("A required net is refused.", () => {
  const required: typeof net = createRequire(import.meta.url)("node:net")
  required.connect(9, "127.0.0.1")
})

test("A dynamically imported net is refused.", async () => {
  const imported = await import("node:net")
  imported.connect(9, "127.0.0.1")
})

test("A raw TCP binding is refused.", () => {
  ;(process as unknown as { binding(name: string): unknown }).binding("tcp_wrap")
})
