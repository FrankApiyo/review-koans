import { createRequire, syncBuiltinESMExports } from "node:module"

const OFFLINE = "koans are offline"
const NO_PROCESSES = "koans start no processes"
const DNS_QUERY = /^(lookup|lookupService|resolve\w*|reverse)$/

const REFUSED_BINDINGS: Readonly<Record<string, string>> = {
  spawn_sync: NO_PROCESSES,
  process_wrap: NO_PROCESSES,
  tcp_wrap: OFFLINE,
  pipe_wrap: OFFLINE,
  udp_wrap: OFFLINE,
  tls_wrap: OFFLINE,
  cares_wrap: OFFLINE,
}

type Host = object
type Callable = (...args: unknown[]) => unknown
type Refusal = (args: unknown[]) => string | undefined

const require = createRequire(import.meta.url)
const state = { installed: false, armed: false }

function refusing(original: Callable, refusal: Refusal): Callable {
  const check = (args: unknown[]): void => {
    const message = state.armed ? refusal(args) : undefined
    if (message !== undefined) throw new Error(message)
  }
  return new Proxy(original, {
    apply(target, self, args: unknown[]) {
      check(args)
      return Reflect.apply(target, self, args)
    },
    construct(target, args: unknown[], newTarget) {
      check(args)
      return Reflect.construct(target, args, newTarget)
    },
  })
}

function replace(host: Host, name: string, refusal: Refusal): void {
  const descriptor = Object.getOwnPropertyDescriptor(host, name)
  if (typeof descriptor?.value !== "function") return
  Object.defineProperty(host, name, { ...descriptor, value: refusing(descriptor.value as Callable, refusal) })
}

function refuseAll(host: Host, names: readonly string[], message: string): void {
  for (const name of names) replace(host, name, () => message)
}

function builtin(name: string): Record<string, unknown> {
  return require(name) as Record<string, unknown>
}

function prototypeOf(module: Record<string, unknown>, name: string): Host {
  return (module[name] as { prototype: Host }).prototype
}

function guardProcesses(): void {
  const childProcess = builtin("node:child_process")
  const spawns = ["spawn", "exec", "execFile", "fork", "spawnSync", "execSync", "execFileSync"]
  refuseAll(childProcess, spawns, NO_PROCESSES)
  refuseAll(prototypeOf(childProcess, "ChildProcess"), ["spawn"], NO_PROCESSES)
  refuseAll(builtin("node:worker_threads"), ["Worker"], NO_PROCESSES)
  refuseAll(process, ["dlopen", "execve"], NO_PROCESSES)
  replace(process, "binding", ([name]) => REFUSED_BINDINGS[String(name)])
}

function guardDns(dns: Record<string, unknown>): void {
  const queries = (host: Host): string[] => Object.getOwnPropertyNames(host).filter((name) => DNS_QUERY.test(name))
  const resolver = prototypeOf(dns, "Resolver")
  refuseAll(dns, queries(dns), OFFLINE)
  refuseAll(resolver, queries(resolver), OFFLINE)
}

function guardNetwork(): void {
  const net = builtin("node:net")
  refuseAll(net, ["connect", "createConnection"], OFFLINE)
  refuseAll(prototypeOf(net, "Socket"), ["connect"], OFFLINE)
  refuseAll(builtin("node:tls"), ["connect"], OFFLINE)
  refuseAll(builtin("node:http"), ["request", "get"], OFFLINE)
  refuseAll(builtin("node:https"), ["request", "get"], OFFLINE)
  refuseAll(builtin("node:http2"), ["connect"], OFFLINE)
  refuseAll(prototypeOf(builtin("node:dgram"), "Socket"), ["send", "connect"], OFFLINE)
  guardDns(builtin("node:dns"))
  guardDns(builtin("node:dns/promises"))
  refuseAll(globalThis, ["fetch", "WebSocket", "EventSource"], OFFLINE)
}

/**
 * Patches the builtin module objects, which every import style shares, so each
 * way to reach the network or start a process refuses while the guard is armed
 * and passes through otherwise. Loopback is refused too.
 */
export function installGuard(): void {
  if (state.installed) return
  guardProcesses()
  guardNetwork()
  syncBuiltinESMExports()
  state.installed = true
}

export function armGuard(): void {
  state.armed = true
}

export function disarmGuard(): void {
  state.armed = false
}
