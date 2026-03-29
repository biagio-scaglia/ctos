<template>
  <div>
    <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:20px">
      <div>
        <h1 class="font-orbitron" style="font-size:16px; color:var(--cyan); letter-spacing:4px">PROCESSI ATTIVI</h1>
        <p class="font-mono" style="font-size:10px; color:var(--text-muted); margin-top:4px">{{ procs.length }} processi trovati</p>
      </div>
      <div style="display:flex; gap:8px; align-items:center">
        <!-- Filter chips -->
        <button
          v-for="f in filters" :key="f.key"
          class="filter-chip"
          :class="{ active: filter === f.key }"
          :style="filter === f.key ? `border-color:${f.color}; color:${f.color}; background:${f.color}18` : ''"
          @click="filter = f.key"
        >{{ f.label }}</button>
        <!-- Search -->
        <input v-model="search" class="search-input font-mono" placeholder="> cerca processo..." />
      </div>
    </div>

    <div class="card" style="padding:0; overflow:hidden">
      <table>
        <thead>
          <tr>
            <th @click="sortBy('name')">NOME {{ sortIcon('name') }}</th>
            <th @click="sortBy('pid')">PID {{ sortIcon('pid') }}</th>
            <th @click="sortBy('cpu')">CPU % {{ sortIcon('cpu') }}</th>
            <th @click="sortBy('ram_mb')">RAM MB {{ sortIcon('ram_mb') }}</th>
            <th @click="sortBy('threads')">THREAD {{ sortIcon('threads') }}</th>
            <th @click="sortBy('suspicion_score')">SCORE {{ sortIcon('suspicion_score') }}</th>
            <th>RISCHIO</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="p in sorted" :key="p.pid" @click="selected = p" style="cursor:pointer">
            <td style="color:var(--text); max-width:200px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap">
              {{ p.name }}
            </td>
            <td>{{ p.pid }}</td>
            <td :class="p.cpu > 30 ? 'risk-high' : p.cpu > 10 ? 'risk-moderate' : ''">{{ p.cpu }}%</td>
            <td>{{ p.ram_mb }}</td>
            <td>{{ p.threads }}</td>
            <td :class="`risk-${p.risk_level}`" style="font-weight:700">{{ p.suspicion_score }}</td>
            <td>
              <span class="badge" :style="`border-color:${riskColor(p.risk_level)}; color:${riskColor(p.risk_level)}; background:${riskColor(p.risk_level)}18`">
                {{ p.risk_level.toUpperCase() }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>
      <div v-if="!sorted.length" class="font-mono" style="padding:32px; text-align:center; color:var(--text-muted)">
        Nessun processo trovato
      </div>
    </div>

    <!-- Detail panel -->
    <div v-if="selected" class="detail-panel card card-cyan" style="margin-top:16px">
      <div style="display:flex; justify-content:space-between; align-items:flex-start">
        <div>
          <div class="font-orbitron" style="font-size:14px; color:var(--cyan)">{{ selected.name }}</div>
          <div class="font-mono" style="font-size:10px; color:var(--text-muted); margin-top:4px">PID: {{ selected.pid }} · Stato: {{ selected.status }}</div>
        </div>
        <button class="btn" @click="askGuardian(selected)">🤖 CHIEDI AL GUARDIAN</button>
      </div>
      <div style="display:grid; grid-template-columns: repeat(4,1fr); gap:12px; margin-top:16px">
        <div class="stat-mini"><span class="label">CPU</span><span :class="`risk-${selected.cpu > 30 ? 'high' : 'safe'}`">{{ selected.cpu }}%</span></div>
        <div class="stat-mini"><span class="label">RAM</span><span>{{ selected.ram_mb }} MB</span></div>
        <div class="stat-mini"><span class="label">THREAD</span><span>{{ selected.threads }}</span></div>
        <div class="stat-mini"><span class="label">SCORE</span><span :class="`risk-${selected.risk_level}`">{{ selected.suspicion_score }}</span></div>
      </div>

      <!-- AI Response -->
      <div v-if="aiResponse || aiLoading" style="margin-top:16px; border-top:1px solid var(--cyan-dark); padding-top:14px">
        <div class="font-mono" style="font-size:10px; color:var(--cyan); margin-bottom:8px">> guardian ai</div>
        <div class="font-mono" style="font-size:12px; color:var(--text-secondary); line-height:1.7; white-space:pre-wrap">
          {{ aiResponse }}<span v-if="aiLoading" class="cursor">▌</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'

const procs = ref([])
const filter = ref('all')
const search = ref('')
const sortKey = ref('cpu')
const sortDir = ref(-1)
const selected = ref(null)
const aiResponse = ref('')
const aiLoading = ref(false)
let timer = null

const filters = [
  { key: 'all', label: 'ALL', color: 'var(--cyan)' },
  { key: 'suspicious', label: 'SOSPETTI', color: 'var(--high)' },
]

const riskColor = (l) => ({ safe:'var(--safe)', low:'var(--low)', moderate:'var(--moderate)', high:'var(--high)', critical:'var(--critical)' }[l] || 'var(--text-muted)')

function sortBy(key) {
  if (sortKey.value === key) sortDir.value *= -1
  else { sortKey.value = key; sortDir.value = -1 }
}
function sortIcon(key) { return sortKey.value === key ? (sortDir.value > 0 ? '↑' : '↓') : '' }

const sorted = computed(() => {
  let list = procs.value
  if (filter.value === 'suspicious') list = list.filter(p => p.suspicion_score >= 20)
  if (search.value) list = list.filter(p => p.name.toLowerCase().includes(search.value.toLowerCase()))
  return [...list].sort((a, b) => (a[sortKey.value] > b[sortKey.value] ? 1 : -1) * sortDir.value)
})

async function load() {
  try {
    const url = filter.value === 'suspicious' ? '/api/processes?filter=suspicious' : '/api/processes'
    procs.value = await fetch('/api/processes').then(r => r.json())
  } catch {}
}

async function askGuardian(proc) {
  aiResponse.value = ''
  aiLoading.value = true
  const question = `Il processo "${proc.name}" (PID ${proc.pid}) usa ${proc.cpu}% CPU e ${proc.ram_mb} MB RAM. Devo preoccuparmi?`
  try {
    const res = await fetch('/api/guardian/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ messages: [{ role: 'user', content: question }] }),
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

onMounted(() => { load(); timer = setInterval(load, 5000) })
onUnmounted(() => clearInterval(timer))
</script>

<style scoped>
.filter-chip {
  font-family: 'Share Tech Mono', monospace;
  font-size: 10px;
  letter-spacing: 1px;
  padding: 5px 10px;
  border: 1px solid var(--border);
  background: transparent;
  color: var(--text-muted);
  cursor: pointer;
  transition: all 0.15s;
}
.filter-chip:hover { border-color: var(--cyan-dark); color: var(--cyan); }

.search-input {
  background: var(--surface);
  border: 1px solid var(--border);
  color: var(--text);
  font-size: 11px;
  padding: 5px 10px;
  width: 200px;
  outline: none;
}
.search-input:focus { border-color: var(--cyan-dark); }

.detail-panel { padding: 16px; }
.stat-mini { display:flex; flex-direction:column; gap:4px; }
.stat-mini .label { font-family:'Share Tech Mono',monospace; font-size:9px; color:var(--text-muted); letter-spacing:1px; }
.stat-mini span:last-child { font-family:'Orbitron',monospace; font-size:16px; font-weight:700; color:var(--text); }

.cursor { animation: blink 1s step-end infinite; }
@keyframes blink { 50% { opacity: 0; } }
</style>
