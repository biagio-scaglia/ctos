<template>
  <div class="guardian-layout">
    <!-- Left: chat terminal -->
    <div class="terminal-panel card card-cyan">
      <div class="terminal-header">
        <i class="fa-solid fa-robot" style="color:var(--cyan); font-size:13px"></i>
        <span class="font-orbitron" style="font-size:11px; color:var(--cyan); letter-spacing:3px">GUARDIAN AI</span>
        <span class="font-mono" style="font-size:9px; color:var(--text-muted); margin-left:8px">gpt-oss:120b-cloud</span>
        <span class="font-mono" :class="online ? 'risk-safe' : 'risk-critical'"
          style="font-size:9px; letter-spacing:1px; margin-left:auto; display:flex; align-items:center; gap:5px">
          <i :class="online ? 'fa-solid fa-circle' : 'fa-regular fa-circle'" style="font-size:7px"></i>
          {{ online ? 'ONLINE' : 'OFFLINE' }}
        </span>
      </div>

      <div class="messages" ref="msgBox">
        <div v-if="!messages.length" class="font-mono" style="color:var(--text-muted); font-size:12px; line-height:2">
          <div><i class="fa-solid fa-shield-halved" style="margin-right:6px; color:var(--cyan)"></i>sistema di sicurezza CTOS attivo</div>
          <div><i class="fa-solid fa-plug" style="margin-right:6px; color:var(--cyan)"></i>connessione a Guardian AI stabilita</div>
          <div><i class="fa-solid fa-keyboard" style="margin-right:6px; color:var(--cyan)"></i>digita una domanda o seleziona un processo</div>
          <div style="margin-top:12px; color:var(--cyan)">_</div>
        </div>

        <div v-for="(msg, i) in messages" :key="i" class="msg" :class="msg.role">
          <span class="msg-prefix font-mono">{{ msg.role === 'user' ? '> ' : '' }}</span>
          <span class="msg-content font-mono">
            {{ msg.content }}<span v-if="msg.streaming" class="cursor">▌</span>
          </span>
        </div>
      </div>

      <div class="input-row">
        <span class="font-mono" style="color:var(--cyan); font-size:14px; padding-right:8px">></span>
        <input
          v-model="input"
          ref="inputEl"
          class="terminal-input font-mono"
          placeholder="chiedi al Guardian..."
          @keydown.enter="send"
          :disabled="streaming"
        />
        <button class="btn" style="white-space:nowrap" @click="send" :disabled="streaming || !input.trim()">
          <i class="fa-solid fa-paper-plane" style="margin-right:5px"></i>INVIA
        </button>
        <button class="btn" style="border-color:var(--text-muted);color:var(--text-muted);margin-left:4px" @click="clear">
          <i class="fa-solid fa-trash-can"></i>
        </button>
      </div>
    </div>

    <!-- Right: quick actions -->
    <div class="sidebar">
      <div class="card" style="padding:14px; margin-bottom:12px">
        <div class="section-label"><i class="fa-solid fa-bolt" style="margin-right:5px"></i>ANALISI RAPIDA</div>
        <div style="display:flex; flex-direction:column; gap:8px; margin-top:10px">
          <button class="btn" style="font-size:10px; text-align:left; gap:8px; display:flex; align-items:center" @click="askSystem">
            <i class="fa-solid fa-gauge-high"></i> Analizza il sistema
          </button>
          <button class="btn" style="font-size:10px; text-align:left; gap:8px; display:flex; align-items:center" @click="askConnections">
            <i class="fa-solid fa-network-wired"></i> Controlla connessioni
          </button>
          <button class="btn" style="font-size:10px; text-align:left; gap:8px; display:flex; align-items:center" @click="askTopProcess">
            <i class="fa-solid fa-fire"></i> Processo più pesante
          </button>
        </div>
      </div>

      <div class="card" style="padding:14px; flex:1; overflow:hidden; display:flex; flex-direction:column">
        <div class="section-label">
          <i class="fa-solid fa-microchip" style="margin-right:5px"></i>PROCESSI — clicca per analizzare
        </div>
        <div style="margin-top:10px; display:flex; flex-direction:column; gap:4px; overflow-y:auto; flex:1">
          <div
            v-for="p in topProcs" :key="p.pid"
            class="proc-row font-mono"
            :class="`risk-${p.risk_level}`"
            @click="askProcess(p)"
          >
            <span style="color:var(--text); overflow:hidden; text-overflow:ellipsis; white-space:nowrap; flex:1">{{ p.name }}</span>
            <span style="font-size:10px; opacity:0.7; flex-shrink:0">{{ p.cpu }}%</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, nextTick } from 'vue'

const messages  = ref([])
const input     = ref('')
const streaming = ref(false)
const online    = ref(false)
const topProcs  = ref([])
const msgBox    = ref(null)
const inputEl   = ref(null)
let timer       = null

async function load() {
  try {
    const [status, procs] = await Promise.all([
      fetch('/api/guardian/status').then(r => r.json()),
      fetch('/api/processes').then(r => r.json()),
    ])
    online.value   = status.online
    topProcs.value = procs.slice(0, 20)
  } catch {}
}

async function scrollBottom() {
  await nextTick()
  if (msgBox.value) msgBox.value.scrollTop = msgBox.value.scrollHeight
}

async function stream(userContent) {
  if (streaming.value) return
  messages.value.push({ role: 'user', content: userContent })
  const assistantMsg = { role: 'assistant', content: '', streaming: true }
  messages.value.push(assistantMsg)
  streaming.value = true
  await scrollBottom()

  try {
    const history = messages.value
      .filter(m => !m.streaming)
      .map(m => ({ role: m.role, content: m.content }))

    const res = await fetch('/api/guardian/chat', {
      method:  'POST',
      headers: { 'Content-Type': 'application/json' },
      body:    JSON.stringify({ messages: history }),
    })
    const reader = res.body.getReader()
    const dec    = new TextDecoder()

    while (true) {
      const { done, value } = await reader.read()
      if (done) break
      for (const line of dec.decode(value).split('\n').filter(Boolean)) {
        try {
          const j = JSON.parse(line)
          if (j.message?.content) { assistantMsg.content += j.message.content; await scrollBottom() }
          if (j.done) { assistantMsg.streaming = false; break }
        } catch {}
      }
    }
  } catch {
    assistantMsg.content = '[Errore: Guardian non raggiungibile — verifica che Ollama sia attivo]'
  }

  assistantMsg.streaming = false
  streaming.value = false
  await scrollBottom()
  inputEl.value?.focus()
}

function send() {
  const q = input.value.trim()
  if (!q || streaming.value) return
  input.value = ''
  stream(q)
}

function clear() { messages.value = []; input.value = '' }

async function askSystem() {
  try {
    const ov = await fetch('/api/overview').then(r => r.json())
    stream(
      `Analizza lo stato del sistema:\n` +
      `CPU: ${ov.cpu_percent}%  RAM: ${ov.ram_percent}%  Disco: ${ov.disk_percent}%\n` +
      `Risk score: ${ov.risk_score}/100 (${ov.risk_level})\n` +
      `Processi totali: ${ov.process_count}  Sospetti: ${ov.suspicious_count}\n` +
      `Connessioni sospette: ${ov.suspicious_connections}\n\nCome valuti la sicurezza?`
    )
  } catch { stream('Analizza lo stato generale della sicurezza del sistema.') }
}

async function askConnections() {
  try {
    const conns = await fetch('/api/connections').then(r => r.json())
    const sus   = conns.filter(c => c.suspicion_score >= 20)
    const list  = sus.slice(0, 5).map(c =>
      `• ${c.remote_ip}:${c.remote_port} [${c.process}] score=${c.suspicion_score} flags=${c.flags.join(',') || 'nessuna'}`
    ).join('\n')
    stream(`Connessioni sospette (${sus.length} totali):\n${list || 'nessuna'}\n\nValuta il rischio.`)
  } catch { stream('Controlla le connessioni di rete attive e valuta il rischio.') }
}

async function askTopProcess() {
  try {
    const procs = await fetch('/api/processes').then(r => r.json())
    const top   = procs[0]
    if (top) stream(
      `Il processo più pesante è "${top.name}" (PID ${top.pid}):\n` +
      `CPU: ${top.cpu}%  RAM: ${top.ram_mb} MB  Thread: ${top.threads}\n` +
      `Score: ${top.suspicion_score}/100\n\nÈ normale?`
    )
  } catch {}
}

function askProcess(p) {
  stream(
    `Analizza il processo "${p.name}" (PID ${p.pid}):\n` +
    `CPU: ${p.cpu}%  RAM: ${p.ram_mb} MB  Thread: ${p.threads}\n` +
    `Utente: ${p.user}  Score: ${p.suspicion_score}/100 (${p.risk_level})\n\nDevo preoccuparmi?`
  )
}

onMounted(() => {
  load()
  timer = setInterval(load, 10000)
  nextTick(() => inputEl.value?.focus())
})
onUnmounted(() => clearInterval(timer))
</script>

<style scoped>
.guardian-layout {
  display: grid;
  grid-template-columns: 1fr 280px;
  gap: 16px;
  height: calc(100vh - 110px);
  min-height: 500px;
}
.terminal-panel { display:flex; flex-direction:column; overflow:hidden; padding:0; }
.terminal-header {
  display:flex; align-items:center; gap:8px; padding:10px 16px;
  border-bottom:1px solid var(--cyan-dark); background:var(--surface); flex-shrink:0;
}
.messages {
  flex:1; overflow-y:auto; padding:16px;
  display:flex; flex-direction:column; gap:10px; scroll-behavior:smooth;
}
.msg { display:flex; gap:4px; }
.msg.user .msg-content      { color:var(--cyan); }
.msg.assistant .msg-content { color:var(--text-secondary); line-height:1.7; white-space:pre-wrap; }
.msg-prefix  { color:var(--cyan); font-size:13px; flex-shrink:0; }
.msg-content { font-size:12px; }
.input-row {
  display:flex; align-items:center; padding:10px 16px;
  border-top:1px solid var(--cyan-dark); background:var(--surface); flex-shrink:0; gap:8px;
}
.terminal-input { flex:1; background:transparent; border:none; outline:none; color:var(--cyan); font-size:13px; caret-color:var(--cyan); min-width:0; }
.terminal-input::placeholder { color:var(--text-muted); }
.sidebar { display:flex; flex-direction:column; overflow:hidden; }
.section-label { font-family:'Share Tech Mono',monospace; font-size:9px; color:var(--text-muted); letter-spacing:2px; display:flex; align-items:center; }
.proc-row {
  display:flex; justify-content:space-between; align-items:center;
  font-size:11px; padding:5px 8px; cursor:pointer;
  border:1px solid transparent; transition:all 0.1s; gap:8px;
}
.proc-row:hover { border-color:var(--cyan-dark); background:var(--cyan-glow); color:var(--cyan) !important; }
.cursor { animation:blink 1s step-end infinite; }
@keyframes blink { 50% { opacity:0; } }

@media (max-width: 900px) {
  .guardian-layout {
    grid-template-columns: 1fr;
    height: auto;
  }
  .terminal-panel { height: 60vh; min-height: 400px; }
  .sidebar { max-height: 60vh; overflow-y: auto; }
}
</style>
