<template>
  <div>
    <!-- Header -->
    <div style="margin-bottom: 24px">
      <h1 class="font-orbitron" style="font-size:18px; color:var(--cyan); letter-spacing:4px">RISK DASHBOARD</h1>
      <p class="font-mono" style="font-size:10px; color:var(--text-muted); margin-top:4px">
        MONITORAGGIO SISTEMA IN TEMPO REALE — aggiornamento ogni 5s
      </p>
    </div>

    <!-- Top stat cards -->
    <div class="stat-grid" v-if="overview">
      <!-- Risk score -->
      <div class="card card-cyan stat-card">
        <div class="font-mono" style="font-size:9px; color:var(--text-muted); letter-spacing:2px">RISK SCORE</div>
        <div class="font-orbitron" :class="`risk-${overview.risk_level}`" style="font-size:48px; font-weight:900; line-height:1.1; margin: 8px 0">
          {{ overview.risk_score }}
        </div>
        <div class="progress-bar">
          <div class="progress-fill" :class="`bg-${overview.risk_level}`" :style="{ width: overview.risk_score + '%' }" />
        </div>
        <div class="font-mono" :class="`risk-${overview.risk_level}`" style="font-size:10px; margin-top:6px; letter-spacing:2px">
          {{ overview.risk_level.toUpperCase() }}
        </div>
      </div>

      <!-- CPU -->
      <div class="card stat-card">
        <div class="font-mono" style="font-size:9px; color:var(--text-muted); letter-spacing:2px">CPU</div>
        <div class="font-orbitron" style="font-size:40px; color:var(--cyan); font-weight:700; margin: 8px 0">
          {{ overview.cpu_percent?.toFixed(0) }}<span style="font-size:16px">%</span>
        </div>
        <div class="progress-bar">
          <div class="progress-fill" style="background:var(--cyan)" :style="{ width: overview.cpu_percent + '%', 'box-shadow': '0 0 8px var(--cyan)' }" />
        </div>
      </div>

      <!-- RAM -->
      <div class="card stat-card">
        <div class="font-mono" style="font-size:9px; color:var(--text-muted); letter-spacing:2px">RAM</div>
        <div class="font-orbitron" style="font-size:40px; color:var(--cyan-dim); font-weight:700; margin: 8px 0">
          {{ overview.ram_used_gb }}<span style="font-size:14px"> GB</span>
        </div>
        <div class="font-mono" style="font-size:10px; color:var(--text-muted)">
          {{ overview.ram_percent?.toFixed(0) }}% di {{ overview.ram_total_gb }} GB
        </div>
        <div class="progress-bar" style="margin-top:8px">
          <div class="progress-fill" style="background:var(--cyan-dim)" :style="{ width: overview.ram_percent + '%' }" />
        </div>
      </div>

      <!-- Processes -->
      <div class="card stat-card">
        <div class="font-mono" style="font-size:9px; color:var(--text-muted); letter-spacing:2px">PROCESSI</div>
        <div class="font-orbitron" style="font-size:40px; color:var(--text); font-weight:700; margin: 8px 0">
          {{ overview.process_count }}
        </div>
        <div class="font-mono" :class="overview.suspicious_count > 0 ? 'risk-high' : 'risk-safe'" style="font-size:10px; letter-spacing:1px">
          {{ overview.suspicious_count }} ad alto CPU
        </div>
      </div>

      <!-- Network -->
      <div class="card stat-card">
        <div class="font-mono" style="font-size:9px; color:var(--text-muted); letter-spacing:2px">TRAFFICO</div>
        <div style="margin: 10px 0">
          <div class="font-mono" style="font-size:13px; color:var(--safe)">↑ {{ overview.bytes_sent_mb }} MB</div>
          <div class="font-mono" style="font-size:13px; color:var(--cyan); margin-top:4px">↓ {{ overview.bytes_recv_mb }} MB</div>
        </div>
        <div class="font-mono" style="font-size:10px; color:var(--text-muted)">da avvio sistema</div>
      </div>
    </div>

    <!-- Loading state -->
    <div v-else class="font-mono" style="color:var(--text-muted); padding:40px; text-align:center">
      > connessione al backend in corso...
    </div>

    <!-- Top processes table -->
    <div v-if="topProcs.length" style="margin-top: 28px">
      <div class="section-header">TOP PROCESSI PER CPU</div>
      <div class="card" style="margin-top: 10px; padding:0; overflow:hidden">
        <table>
          <thead>
            <tr>
              <th>NOME</th>
              <th>PID</th>
              <th>CPU %</th>
              <th>RAM MB</th>
              <th>STATO</th>
              <th>RISCHIO</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="p in topProcs" :key="p.pid">
              <td style="color:var(--text)">{{ p.name }}</td>
              <td>{{ p.pid }}</td>
              <td :class="`risk-${p.cpu > 30 ? 'high' : p.cpu > 10 ? 'moderate' : 'safe'}`">{{ p.cpu }}%</td>
              <td>{{ p.ram_mb }}</td>
              <td style="color:var(--text-muted)">{{ p.status }}</td>
              <td>
                <span class="badge" :class="`bg-risk-${p.risk_level}`" :style="{ color: riskColor(p.risk_level) }">
                  {{ p.risk_level.toUpperCase() }}
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Suspicious connections -->
    <div v-if="suspConn.length" style="margin-top: 28px">
      <div class="section-header" style="color:var(--critical)">⚠ CONNESSIONI SOSPETTE</div>
      <div style="margin-top:10px; display:flex; flex-direction:column; gap:8px">
        <div v-for="c in suspConn" :key="c.remote_ip + c.remote_port" class="card" :class="`bg-risk-${c.risk_level}`" style="border:1px solid">
          <div style="display:flex; justify-content:space-between; align-items:center">
            <div>
              <span class="font-orbitron" style="font-size:13px; color:var(--text)">{{ c.remote_ip }}</span>
              <span class="font-mono" style="font-size:10px; color:var(--text-muted)">:{{ c.remote_port }}</span>
              <span v-if="c.process !== 'unknown'" class="font-mono" style="font-size:10px; color:var(--text-muted); margin-left:12px">
                [{{ c.process }}]
              </span>
            </div>
            <span class="font-orbitron" :class="`risk-${c.risk_level}`" style="font-size:20px; font-weight:900">
              {{ c.suspicion_score }}
            </span>
          </div>
          <div v-if="c.flags.length" style="margin-top:6px">
            <span v-for="f in c.flags" :key="f" class="badge bg-risk-critical" style="color:var(--critical); margin-right:6px">{{ f }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'

const overview = ref(null)
const topProcs = ref([])
const suspConn = ref([])
let timer = null

const riskColor = (level) => ({
  safe: 'var(--safe)', low: 'var(--low)', moderate: 'var(--moderate)',
  high: 'var(--high)', critical: 'var(--critical)'
}[level] || 'var(--text-muted)')

async function load() {
  try {
    const [ov, pr, cn] = await Promise.all([
      fetch('/api/overview').then(r => r.json()),
      fetch('/api/processes').then(r => r.json()),
      fetch('/api/connections').then(r => r.json()),
    ])
    overview.value = ov
    topProcs.value = pr.slice(0, 8)
    suspConn.value = cn.filter(c => c.suspicion_score >= 20)
  } catch {}
}

onMounted(() => { load(); timer = setInterval(load, 5000) })
onUnmounted(() => clearInterval(timer))
</script>

<style scoped>
.stat-grid {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr 1fr 1fr;
  gap: 12px;
}
@media (max-width: 1100px) { .stat-grid { grid-template-columns: 1fr 1fr 1fr; } }
@media (max-width: 700px)  { .stat-grid { grid-template-columns: 1fr 1fr; } }

.stat-card { padding: 20px; }

.progress-bar {
  height: 3px;
  background: var(--border);
  width: 100%;
  margin-top: 4px;
}
.progress-fill {
  height: 3px;
  transition: width 0.5s ease;
  border: 1px solid transparent;
}
.bg-safe     { background: var(--safe);     box-shadow: 0 0 6px var(--safe); }
.bg-low      { background: var(--low);      box-shadow: 0 0 6px var(--low); }
.bg-moderate { background: var(--moderate); box-shadow: 0 0 6px var(--moderate); }
.bg-high     { background: var(--high);     box-shadow: 0 0 6px var(--high); }
.bg-critical { background: var(--critical); box-shadow: 0 0 6px var(--critical); }

.section-header {
  font-family: 'Share Tech Mono', monospace;
  font-size: 10px;
  color: var(--text-muted);
  letter-spacing: 3px;
  padding-left: 10px;
  border-left: 3px solid var(--cyan);
}
</style>
