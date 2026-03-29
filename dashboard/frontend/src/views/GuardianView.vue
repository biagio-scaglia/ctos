<template>
  <div style="max-width: 800px; margin: 0 auto">
    <div style="margin-bottom:24px">
      <h1 class="font-orbitron" style="font-size:16px; color:var(--cyan); letter-spacing:4px">GUARDIAN AI</h1>
      <p class="font-mono" style="font-size:10px; color:var(--text-muted); margin-top:4px">
        Chat con il motore di analisi AI — modello: {{ model }}
      </p>
    </div>

    <!-- Chat history -->
    <div class="chat-window card" ref="chatEl">
      <div v-if="!messages.length" class="font-mono" style="color:var(--text-muted); font-size:12px; text-align:center; padding:40px 0">
        <div style="margin-bottom:12px; font-size:18px">⚡</div>
        GUARDIAN AI PRONTO<br/>
        <span style="font-size:10px">Chiedi tutto ciò che vuoi sulla sicurezza del tuo sistema</span>
      </div>

      <div v-for="(msg, i) in messages" :key="i" class="message" :class="msg.role">
        <div class="message-label font-mono">
          {{ msg.role === 'user' ? '> tu' : '⚡ guardian' }}
        </div>
        <div class="message-content font-mono" style="white-space:pre-wrap; line-height:1.7">
          {{ msg.content }}<span v-if="i === messages.length - 1 && loading" class="cursor">▌</span>
        </div>
      </div>
    </div>

    <!-- Quick prompts -->
    <div style="display:flex; gap:8px; flex-wrap:wrap; margin-top:12px">
      <button
        v-for="q in quickPrompts" :key="q"
        class="quick-btn font-mono"
        @click="send(q)"
        :disabled="loading"
      >{{ q }}</button>
    </div>

    <!-- Input -->
    <div class="input-row" style="margin-top:12px">
      <span class="font-mono" style="color:var(--cyan); font-size:14px; flex-shrink:0">&gt;&nbsp;</span>
      <input
        v-model="input"
        class="chat-input font-mono"
        placeholder="chiedi al guardian..."
        @keydown.enter="send(input)"
        :disabled="loading"
        ref="inputEl"
      />
      <button class="btn" @click="send(input)" :disabled="loading || !input.trim()">
        {{ loading ? '...' : 'INVIA' }}
      </button>
      <button class="btn" style="border-color:var(--text-muted); color:var(--text-muted)" @click="clear">CLR</button>
    </div>
  </div>
</template>

<script setup>
import { ref, nextTick, onMounted } from 'vue'

const model = 'gpt-oss:120b-cloud'
const messages = ref([])
const input = ref('')
const loading = ref(false)
const chatEl = ref(null)
const inputEl = ref(null)

const quickPrompts = [
  'Analizza i processi più rischiosi',
  'Il mio PC è sicuro?',
  'Cosa sono i port 9001 e 9030?',
  'Come riduco il rischio del sistema?',
]

const systemPrompt = {
  role: 'system',
  content: `Sei GUARDIAN, il motore AI di CTOS Companion Desktop.
Analizzi la sicurezza di un PC Windows.
Rispondi SEMPRE in italiano. Sii diretto e conciso (max 5 frasi).
Usa terminologia tecnica ma spiega sempre in modo comprensibile.
Dai sempre un consiglio pratico alla fine.`
}

function scrollDown() {
  nextTick(() => {
    if (chatEl.value) chatEl.value.scrollTop = chatEl.value.scrollHeight
  })
}

async function send(text) {
  if (!text?.trim() || loading.value) return
  input.value = ''
  messages.value.push({ role: 'user', content: text.trim() })
  messages.value.push({ role: 'assistant', content: '' })
  loading.value = true
  scrollDown()

  const history = messages.value
    .slice(0, -1)
    .map(m => ({ role: m.role, content: m.content }))

  try {
    const res = await fetch('/api/guardian/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ messages: history }),
    })
    const reader = res.body.getReader()
    const dec = new TextDecoder()
    const last = messages.value[messages.value.length - 1]

    while (true) {
      const { done, value } = await reader.read()
      if (done) break
      const lines = dec.decode(value).split('\n').filter(Boolean)
      for (const line of lines) {
        try {
          const j = JSON.parse(line)
          if (j.message?.content) {
            last.content += j.message.content
            scrollDown()
          }
          if (j.done) break
        } catch {}
      }
    }
  } catch {
    messages.value[messages.value.length - 1].content = '[Errore: Guardian non raggiungibile]'
  }

  loading.value = false
  scrollDown()
  inputEl.value?.focus()
}

function clear() {
  messages.value = []
}

onMounted(() => inputEl.value?.focus())
</script>

<style scoped>
.chat-window {
  height: 420px;
  overflow-y: auto;
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  border-color: var(--cyan-dark);
  box-shadow: 0 0 20px var(--cyan-glow);
}

.message { display: flex; flex-direction: column; gap: 4px; }
.message.user .message-label { color: var(--cyan); }
.message.assistant .message-label { color: var(--safe); }
.message-label { font-size: 9px; letter-spacing: 2px; }
.message.user .message-content { color: var(--text); }
.message.assistant .message-content { color: var(--text-secondary); font-size: 12px; }

.quick-btn {
  font-size: 10px;
  padding: 5px 10px;
  border: 1px solid var(--border);
  background: transparent;
  color: var(--text-muted);
  cursor: pointer;
  transition: all 0.15s;
  letter-spacing: 0.5px;
}
.quick-btn:hover:not(:disabled) { border-color: var(--cyan-dark); color: var(--cyan); }
.quick-btn:disabled { opacity: 0.4; cursor: not-allowed; }

.input-row {
  display: flex;
  align-items: center;
  gap: 8px;
  background: var(--surface);
  border: 1px solid var(--cyan-dark);
  padding: 8px 12px;
}

.chat-input {
  flex: 1;
  background: transparent;
  border: none;
  outline: none;
  color: var(--text);
  font-size: 13px;
  caret-color: var(--cyan);
}
.chat-input::placeholder { color: var(--text-muted); }
.chat-input:disabled { opacity: 0.5; }

.cursor { animation: blink 1s step-end infinite; color: var(--cyan); }
@keyframes blink { 50% { opacity: 0; } }
</style>
