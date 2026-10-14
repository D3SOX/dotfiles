#!/usr/bin/env node
import { readFile } from 'node:fs/promises'
import { randomUUID } from 'node:crypto'

const args = process.argv.slice(2)
let file, targetId, endpoint = 'http://127.0.0.1:9331', userGesture = false
for (let i = 0; i < args.length; i++) {
  const arg = args[i]
  if (arg === '--user-gesture') userGesture = true
  else if (arg === '--endpoint' || arg === '--target') {
    const value = args[++i]
    if (!value || value.startsWith('--')) throw new Error(`Missing value for ${arg}`)
    if (arg === '--endpoint') endpoint = value
    else targetId = value
  } else if (arg === '--help') {
    console.log('Usage: evaluate-webview.mjs FILE [--endpoint URL] [--target ID] [--user-gesture]')
    process.exit(0)
  } else if (arg.startsWith('--') || file) throw new Error(`Unexpected argument: ${arg}`)
  else file = arg
}
if (!file) throw new Error('Provide a file containing a JavaScript expression or async IIFE. Use --help.')

async function main() {
  const expression = (await readFile(file, 'utf8')).trim().replace(/;$/, '')
  const response = await fetch(`${endpoint.replace(/\/$/, '')}/json/list`, { signal: AbortSignal.timeout(5000) })
  if (!response.ok) throw new Error(`Target discovery failed: HTTP ${response.status}`)
  const targets = await response.json()
  const candidates = targets.filter(target => {
    if (targetId) return target.id === targetId
    try { return new URL(target.url).hostname === 'localhost' } catch { return false }
  })
  if (candidates.length !== 1) {
    throw new Error(`Expected one app WebView, found ${candidates.length}. Check foreground/inspection state or select --target ID from /json/list.`)
  }
  const target = candidates[0]
  if (!target.webSocketDebuggerUrl) throw new Error('Target has no debugger WebSocket URL')
  const ws = new WebSocket(target.webSocketDebuggerUrl)
  const pending = new Map()
  const key = `__iosLab_${randomUUID().replaceAll('-', '')}`
  let nextId = 0, stopped = false, installed = false
  let rejectOpen
  const opened = new Promise((resolve, reject) => {
    rejectOpen = reject
    ws.addEventListener('open', resolve, { once: true })
  })
  function fail(error) {
    stopped = true
    rejectOpen(error)
    for (const entry of pending.values()) entry.reject(error)
    pending.clear()
  }
  const timer = setTimeout(() => {
    fail(new Error('Inspector evaluation timed out after 30 seconds; the expression may still be running.'))
    ws.close()
  }, 30_000)
  ws.addEventListener('error', () => fail(new Error('Inspector WebSocket failed')))
  ws.addEventListener('close', () => fail(new Error('Inspector disconnected')))
  ws.addEventListener('message', event => {
    let message
    try { message = JSON.parse(event.data) } catch { return }
    const entry = pending.get(message.id)
    if (!entry) return
    pending.delete(message.id)
    const result = message.result
    if (message.error || result?.wasThrown || result?.exceptionDetails) {
      entry.reject(new Error(JSON.stringify(message.error ?? result)))
    } else entry.resolve(result?.result?.value)
  })
  function evaluate(source) {
    if (stopped || ws.readyState !== WebSocket.OPEN) return Promise.reject(new Error('Inspector is not connected'))
    return new Promise((resolve, reject) => {
      const id = ++nextId
      pending.set(id, { resolve, reject })
      ws.send(JSON.stringify({ id, method: 'Runtime.evaluate', params: {
        expression: source, returnByValue: true, userGesture
      } }))
    })
  }
  try {
    await opened
    await evaluate(`(() => {
      Promise.resolve().then(() => (${expression})).then(
        value => window[${JSON.stringify(key)}] = { done: true, value },
        error => window[${JSON.stringify(key)}] = { done: true, error: String(error) + (error?.stack ? '\\n' + error.stack : '') }
      ); return true;
    })()`)
    installed = true
    for (;;) {
      const result = await evaluate(`window[${JSON.stringify(key)}]`)
      if (result?.done) {
        if ('error' in result) throw new Error(result.error)
        console.log(JSON.stringify(result.value ?? null, null, 2))
        break
      }
      await new Promise(resolve => setTimeout(resolve, 200))
    }
  } finally {
    if (installed && !stopped && ws.readyState === WebSocket.OPEN) {
      await evaluate(`delete window[${JSON.stringify(key)}]`).catch(() => {})
    }
    clearTimeout(timer)
    ws.close()
  }
}
main().catch(error => { console.error(error.message); process.exitCode = 1 })
