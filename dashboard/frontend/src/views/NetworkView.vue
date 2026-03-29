<template>
  <div>
    <div class="page-header">
      <div>
        <h1 class="font-orbitron" style="font-size:16px; color:var(--cyan); letter-spacing:4px">
          <i class="fa-solid fa-network-wired" style="margin-right:10px"></i>MONITOR DI RETE
        </h1>
        <p class="font-mono" style="font-size:10px; color:var(--text-muted); margin-top:4px">
          {{ conns.length }} connessioni attive
          <span v-if="suspiciousCount > 0" class="risk-high">
            · <i class="fa-solid fa-triangle-exclamation"></i> {{ suspiciousCount }} sospette
          </span>
        </p>
      </div>
      <button class="btn" @click="load">
        <i class="fa-solid fa-rotate" style="margin-right:6px"></i>AGGIORNA
      </button>
    </div>

    <!-- Filter chips -->
    <div style="display:flex; gap:10px; margin-bottom:16px; flex-wrap:wrap">
      <div
        v-for="f in filterOpts" :key="f.key"
        class="filter-chip" :class="{ active: filter === f.key }"
        :style="filter === f.key ? `border-color:${f.color}; color:${f.color}; background:${f.color}18` : ''"
        @click="filter = f.key"
      >
        <i :class="f.icon" style="margin-right:5px"></i>{{ f.label }}
        <span style="opacity:0.6"> ({{ f.count }})</span>
      </div>
    </div>

    <div v-if="filtered.length" class="card" style="padding:0; overflow:hidden">
      <div class="table-scroll">
        <table>
          <thead>
            <tr>
              <th><i class="fa-solid fa-globe" style="margin-right:4px"></i>IP REMOTO</th>
              <th>PORTA</th>
              <th><i class="fa-solid fa-terminal" style="margin-right:4px"></i>PROCESSO</th>
              <th class="hide-sm">IP LOCALE</th>
              <th>FLAG</th>
              <th @click="sortBy('suspicion_score')" style="cursor:pointer">
                <i class="fa-solid fa-shield-halved" style="margin-right:4px"></i>SCORE {{ sortIcon('suspicion_score') }}
              </th>
              <th>RISCHIO</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="c in sorted" :key="c.remote_ip + c.remote_port">
              <td style="color:var(--text); font-weight:600">{{ c.remote_ip }}</td>
              <td class="font-mono" style="font-size:10px">{{ c.remote_port }}</td>
              <td style="color:var(--cyan-dim)">{{ c.process }}</td>
              <td class="hide-sm" style="color:var(--text-muted)">{{ c.local }}</td>
              <td>
                <span v-for="f in c.flags" :key="f" class="badge" style="border-color:var(--critical); color:var(--critical); background:rgba(255,23,68,0.1); margin-right:4px; font-size:8px">
                  <i class="fa-solid fa-flag" style="margin-right:2px; font-size:7px"></i>{{ f }}
                </span>
              </td>
              <td :class="`risk-${c.risk_level}`" style="font-weight:700; font-size:13px">{{ c.suspicion_score }}</td>
              <td>
                <span class="badge" :style="`border-color:${riskColor(c.risk_level)}; color:${riskColor(c.risk_level)}; background:${riskColor(c.risk_level)}18`">
                  {{ c.risk_level.toUpperCase() }}
                </span>
              </td>
              <td>
                <button class="btn" style="padding:3px 8px; font-size:9px; white-space:nowrap" @click="askGuardian(c)">
                  <i class="fa-solid fa-robot" style="margin-right:3px"></i>AI
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <div v-else class="card font-mono" style="padding:32px; text-align:center; color:var(--text-muted)">
      <span v-if="loading">
        <i class="fa-solid fa-circle-notch fa-spin" style="margin-right:8px"></i>scansione connessioni...
      </span>
      <span v-else>
        <i class="fa-solid fa-circle-check" style="margin-right:8px; color:var(--safe)"></i>Nessuna connessione esterna rilevata.
      </span>
    </div>

    <!-- AI panel -->
    <div v-if="aiTarget" class="card card-cyan" style="margin-top:16px; padding:16px">
      <div class="font-mono" style="font-size:10px; color:var(--cyan); margin-bottom:10px">
        <i class="fa-solid fa-robot" style="margin-right:6px"></i>guardian ai — {{ aiTarget.remote_ip }}:{{ aiTarget.remote_port }}
      </div>
      <div class="font-mono" style="font-size:12px; color:var(--text-secondary); line-height:1.7; white-space:pre-wrap; min-height:40px">
        {{ aiResponse }}<span v-if="aiLoading" class="cursor">▌</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'

const conns = ref([])
const filter = ref('all')
const sortKey = ref('suspicion_score')
const sortDir = ref(-1)
const loading = ref(true)
const aiTarget = ref(null)
const aiResponse = ref('')
const aiLoading = ref(false)
let timer = null

const riskColor = (l) => ({ safe:'var(--safe)', low:'var(--low)', moderate:'var(--moderate)', high:'var(--high)', critical:'var(--critical)' }[l] || 'var(--text-muted)')

const suspiciousCount = computed(() => conns.value.filter(c => c.suspicion_score >= 20).length)

const filterOpts = computed(() => [
  { key: 'all',        label: 'TUTTE',    color: 'var(--cyan)',     icon: 'fa-solid fa-list',               count: conns.value.length },
  { key: 'suspicious', label: 'SOSPETTE', color: 'var(--high)',     icon: 'fa-solid fa-triangle-exclamation', count: conns.value.filter(c => c.suspicion_score >= 20).length },
  { key: 'flagged',    label: 'FLAG',     color: 'var(--critical)', icon: 'fa-solid fa-flag',               count: conns.value.filter(c => c.flags.length > 0).length },
])

const filtered = computed(() => {
  let list = conns.value
  if (filter.value === 'suspicious') list = list.filter(c => c.suspicion_score >= 20)
  if (filter.value === 'flagged') list = list.filter(c => c.flags.length > 0)
  return list
})

function sortBy(key) {
  if (sortKey.value === key) sortDir.value *= -1
  else { sortKey.value = key; sortDir.value = -1 }
}
function sortIcon(key) { return sortKey.value === key ? (sortDir.value > 0 ? '↑' : '↓') : '' }

const sorted = computed(() =>
  [...filtered.value].sort((a, b) => (a[sortKey.value] > b[sortKey.value] ? 1 : -1) * sortDir.value)
)

async function load() {
  try {
    conns.value = await fetch('/api/connections').then(r => r.json())
  } catch {}
  loading.value = false
}

async function askGuardian(conn) {
  aiTarget.value = conn
  aiResponse.value = ''
  aiLoading.value = true
  const q = `Connessione verso ${conn.remote_ip}:${conn.remote_port} dal processo "${conn.process}". Flag: ${conn.flags.join(', ') || 'nessuna'}. Score: ${conn.suspicion_score}/100. È pericolosa?`
  try {
    const res = await fetch('/api/guardian/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ messages: [{ role: 'user', content: q }] }),
    })
    const reader = res.body.getReader()
    const dec = new TextDecoder()
    while (true) {
      const { done, value } = await reader.read()
      if (done) break
      const lines = dec.decode(value).split('\n').filter(Boolean)
      for (const line of lines) {
        try {
          const j = JSON.parse(line)
          if (j.message?.content) aiResponse.value += j.message.content
          if (j.done) { aiLoading.value = false; return }
        } catch {}
      }
    }
  } catch { aiResponse.value = '[Errore connessione Guardian]' }
  aiLoading.value = false
}

onMounted(() => { load(); timer = setInterval(load, 8000) })
onUnmounted(() => clearInterval(timer))
</script>

<style scoped>
.page-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  margin-bottom: 20px;
  gap: 16px;
  flex-wrap: wrap;
}

.filter-chip {
  font-family: 'Share Tech Mono', monospace;
  font-size: 10px;
  letter-spacing: 1px;
  padding: 5px 12px;
  border: 1px solid var(--border);
  background: transparent;
  color: var(--text-muted);
  cursor: pointer;
  transition: all 0.15s;
  user-select: none;
  display: flex;
  align-items: center;
}
.filter-chip:hover { border-color: var(--cyan-dark); color: var(--cyan); }

.table-scroll { overflow-x: auto; }

.cursor { animation: blink 1s step-end infinite; }
@keyframes blink { 50% { opacity: 0; } }

@media (max-width: 700px) {
  .hide-sm { display: none; }
}
</style>
