<template>
  <div class="mhg-wrap">

    <!-- ── Header ─────────────────────────────────────────────────────────── -->
    <div class="mhg-header">
      <div>
        <h1 class="font-orbitron mhg-title">
          <i class="fa-solid fa-circle-half-stroke mhg-title-icon"></i>
          MAHORAGA
        </h1>
        <p class="font-mono mhg-sub">GENERALE DIVINO DELLE OTTO MANIGLIE — SISTEMA ADATTIVO AUTONOMO</p>
      </div>
      <div class="mhg-stats font-mono">
        <span class="stat-chip"><i class="fa-solid fa-bolt"></i> ADT <b class="risk-low">{{ st.adaptation_count }}</b></span>
        <span class="stat-chip"><i class="fa-solid fa-brain"></i> APPRESI <b class="risk-safe">{{ st.learned_count }}</b></span>
        <span class="stat-chip"><i class="fa-solid fa-shield-halved"></i> SOGLIA <b :class="st.base_threshold < 30 ? 'risk-safe' : 'risk-moderate'">{{ st.base_threshold }}</b></span>
        <span class="stat-chip"><i class="fa-solid fa-rotate"></i> GIRI <b style="color:var(--cyan)">{{ st.total_rotations }}</b></span>
      </div>
    </div>

    <!-- ── Main 3-col ─────────────────────────────────────────────────────── -->
    <div class="mhg-main">

      <!-- LEFT: threat feed -->
      <div class="threat-panel card">
        <div class="panel-hdr font-mono">
          <i class="fa-solid fa-satellite-dish" style="color:var(--high)"></i>
          RILEVAMENTI
          <button class="btn scan-btn" @click="doScan" :disabled="busy">
            <i class="fa-solid fa-magnifying-glass"></i> SCAN
          </button>
        </div>
        <div class="feed-list" ref="feedEl">
          <transition-group name="slide-in">
            <div
              v-for="t in displayThreats"
              :key="t.id"
              class="threat-card font-mono"
              :class="{ 'tc-active': t.id === activeId, 'tc-done': t.eliminated }"
            >
              <div class="tc-row1">
                <span class="tc-type" :class="scoreClass(t.score)">
                  <i :class="'fa-solid ' + typeIcon(t.type)"></i>
                  {{ t.type.replace(/_/g, ' ') }}
                </span>
                <span class="tc-score font-orbitron" :class="scoreClass(t.score)">{{ t.score }}</span>
              </div>
              <div class="tc-target">{{ t.target }}</div>
              <div class="tc-detail">{{ t.detail }}</div>
              <div class="tc-tags">
                <span v-for="f in t.flags" :key="f" class="tag-flag">{{ f }}</span>
                <span v-if="t.eliminated" class="tag-ok">
                  <i class="fa-solid fa-check"></i> ELIMINATA
                </span>
              </div>
            </div>
          </transition-group>
          <div v-if="!displayThreats.length" class="no-threats font-mono">
            <i class="fa-solid fa-shield-check"></i>
            <div>Nessuna minaccia</div>
            <div style="font-size:9px; color:var(--text-muted); margin-top:4px">sistema pulito</div>
          </div>
        </div>
      </div>

      <!-- CENTER: wheel -->
      <div class="wheel-col">
        <!-- Adapted overlay -->
        <transition name="pop">
          <div v-if="phase === 'adapted'" class="adapted-overlay">
            <div class="ao-title font-orbitron">MAHORAGA</div>
            <div class="ao-sub font-orbitron">SI È ADATTATO</div>
            <div class="ao-threat font-mono">{{ activeThreat?.type?.replace(/_/g, ' ') }}</div>
            <div class="ao-ok font-mono">
              <i class="fa-solid fa-check-double"></i> MINACCIA ELIMINATA
            </div>
          </div>
        </transition>

        <!-- SVG Wheel -->
        <svg
          class="wheel-svg"
          :class="'sp-' + phase"
          viewBox="0 0 320 320"
          xmlns="http://www.w3.org/2000/svg"
        >
          <defs>
            <filter id="glow">
              <feGaussianBlur stdDeviation="5" result="b"/>
              <feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
            </filter>
            <filter id="glow2">
              <feGaussianBlur stdDeviation="10" result="b"/>
              <feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
            </filter>
          </defs>

          <!-- Outer decorative rings -->
          <circle cx="160" cy="160" r="153" fill="none" stroke="rgba(0,245,255,0.05)" stroke-width="1"/>
          <circle cx="160" cy="160" r="145" fill="none" stroke="rgba(0,245,255,0.07)" stroke-width="1"/>
          <circle cx="160" cy="160" r="62"  fill="none" stroke="rgba(0,245,255,0.12)" stroke-width="1"/>

          <!-- 8 wheel segments -->
          <path
            v-for="(seg, i) in segments"
            :key="'s'+i"
            :d="seg.path"
            :fill="seg.lit ? 'var(--cyan)' : 'var(--surface-alt)'"
            :stroke="seg.lit ? 'var(--cyan)' : 'var(--border)'"
            :stroke-width="seg.lit ? 1.5 : 0.5"
            :opacity="seg.lit ? 0.92 : 0.28"
            :filter="seg.lit ? 'url(#glow)' : ''"
            class="w-seg"
            :class="{ 'seg-flash': wheelFlash }"
          />

          <!-- Handle tick marks -->
          <line
            v-for="i in 8" :key="'t'+i"
            :x1="160 + 141 * Math.cos((-90 + (i-1)*45) * Math.PI/180)"
            :y1="160 + 141 * Math.sin((-90 + (i-1)*45) * Math.PI/180)"
            :x2="160 + 153 * Math.cos((-90 + (i-1)*45) * Math.PI/180)"
            :y2="160 + 153 * Math.sin((-90 + (i-1)*45) * Math.PI/180)"
            stroke="rgba(0,245,255,0.35)"
            stroke-width="2"
          />

          <!-- Center -->
          <circle
            cx="160" cy="160" r="55"
            :fill="phase === 'adapting' ? 'rgba(0,245,255,0.06)' : 'var(--surface)'"
            stroke="rgba(0,245,255,0.15)"
            stroke-width="1"
          />
          <text
            x="160" y="154" text-anchor="middle"
            font-family="Orbitron,monospace" font-size="34" font-weight="900"
            :fill="phase === 'idle' ? 'var(--text-muted)' : 'var(--cyan)'"
            :filter="phase !== 'idle' ? 'url(#glow)' : ''"
          >{{ st.wheel_position }}</text>
          <text x="160" y="173" text-anchor="middle"
            font-family="Share Tech Mono,monospace" font-size="9"
            fill="var(--text-muted)" letter-spacing="2">/ 8</text>
        </svg>

        <!-- Phase label -->
        <div class="phase-lbl font-orbitron">
          <template v-if="phase === 'idle'">
            <i class="fa-solid fa-eye"></i> IN ASCOLTO
          </template>
          <template v-else-if="phase === 'scanning'">
            <i class="fa-solid fa-circle-notch fa-spin"></i> SCANSIONE...
          </template>
          <template v-else-if="phase === 'threat_detected'">
            <i class="fa-solid fa-triangle-exclamation blink"></i> MINACCIA RILEVATA
          </template>
          <template v-else-if="phase === 'adapting'">
            <i class="fa-solid fa-arrows-rotate fa-spin"></i> ADATTAMENTO IN CORSO
          </template>
          <template v-else-if="phase === 'adapted'">
            <i class="fa-solid fa-check-double"></i> ADATTAMENTO COMPLETATO
          </template>
        </div>

        <div v-if="st.total_rotations > 0" class="rot-badge font-mono">
          <i class="fa-solid fa-trophy"></i>
          {{ st.total_rotations }}x RUOTA COMPLETA
        </div>
      </div>

      <!-- RIGHT: voice -->
      <div class="voice-panel card card-cyan">
        <div class="panel-hdr font-mono">
          <i class="fa-solid fa-wave-square" style="color:var(--cyan)"></i>
          VOCE DI MAHORAGA
          <span style="margin-left:auto; font-size:8px; color:var(--text-muted)">gpt-oss:120b-cloud</span>
        </div>
        <div class="voice-body" ref="voiceEl">
          <div v-if="!voiceText && phase === 'idle'" class="voice-idle font-mono">
            <i class="fa-solid fa-hourglass-half" style="font-size:22px; color:var(--text-muted); display:block; margin-bottom:12px"></i>
            in attesa di una minaccia...
          </div>
          <div v-else class="voice-text font-orbitron">
            {{ voiceText }}<span v-if="phase === 'adapting'" class="cursor">▌</span>
          </div>
        </div>
        <div v-if="lastAdapt" class="adapt-meta font-mono">
          <i class="fa-solid fa-bolt" style="color:var(--cyan)"></i>
          ADT #{{ lastAdapt.adaptation_count }}
          <span v-if="lastAdapt.newly_learned" class="risk-safe">
            <i class="fa-solid fa-star"></i> PATTERN APPRESO
          </span>
          <span v-if="lastAdapt.wheel_completed" class="risk-low">
            <i class="fa-solid fa-rotate"></i> GIRO COMPLETATO
          </span>
        </div>
      </div>
    </div>

    <!-- ── Simulation bar ─────────────────────────────────────────────────── -->
    <div class="sim-bar">
      <span class="sim-label font-mono">
        <i class="fa-solid fa-flask" style="color:var(--amber)"></i> SIMULA:
      </span>
      <button
        v-for="s in scenarios"
        :key="s.key"
        class="sim-btn font-orbitron"
        :style="`--c:${scoreColor(s.score)}`"
        @click="simulate(s.key)"
        :disabled="busy"
        :title="s.detail"
      >
        <i :class="'fa-solid ' + s.icon"></i>
        <span class="sim-name">{{ s.label }}</span>
        <span class="sim-score font-mono">{{ s.score }}</span>
      </button>
    </div>

  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, nextTick } from 'vue'

// ── reactive state ──────────────────────────────────────────────────────────
const st            = ref({ wheel_position: 0, total_rotations: 0, adaptation_count: 0, learned_count: 0, base_threshold: 40, learned: [], recent_threats: [] })
const phase         = ref('idle')
const displayThreats = ref([])
const activeThreat  = ref(null)
const activeId      = ref(null)
const voiceText     = ref('')
const lastAdapt     = ref(null)
const wheelFlash    = ref(false)
const scenarios     = ref([])
const voiceEl       = ref(null)
const feedEl        = ref(null)
let   autoTimer     = null

const busy = computed(() => phase.value !== 'idle')

// ── wheel segment geometry ──────────────────────────────────────────────────
function segPath(cx, cy, ri, ro, a1, a2) {
  const r  = d => d * Math.PI / 180
  const x1 = cx + ri * Math.cos(r(a1)), y1 = cy + ri * Math.sin(r(a1))
  const x2 = cx + ri * Math.cos(r(a2)), y2 = cy + ri * Math.sin(r(a2))
  const x3 = cx + ro * Math.cos(r(a2)), y3 = cy + ro * Math.sin(r(a2))
  const x4 = cx + ro * Math.cos(r(a1)), y4 = cy + ro * Math.sin(r(a1))
  return `M ${x1} ${y1} A ${ri} ${ri} 0 0 1 ${x2} ${y2} L ${x3} ${y3} A ${ro} ${ro} 0 0 0 ${x4} ${y4} Z`
}

const segments = computed(() =>
  Array.from({ length: 8 }, (_, i) => ({
    path: segPath(160, 160, 68, 137, -90 + i * 45 + 3, -90 + (i + 1) * 45 - 3),
    lit:  i < st.value.wheel_position,
  }))
)

// ── colors / icons ──────────────────────────────────────────────────────────
function scoreColor(s) {
  if (s >= 80) return 'var(--critical)'
  if (s >= 60) return 'var(--high)'
  if (s >= 40) return 'var(--moderate)'
  if (s >= 20) return 'var(--low)'
  return 'var(--safe)'
}
function scoreClass(s) {
  if (s >= 80) return 'risk-critical'
  if (s >= 60) return 'risk-high'
  if (s >= 40) return 'risk-moderate'
  if (s >= 20) return 'risk-low'
  return 'risk-safe'
}
function typeIcon(type) {
  return ({
    PORT_SCAN:           'fa-binoculars',
    C2_BEACON:           'fa-tower-broadcast',
    PROCESS_INJECTION:   'fa-syringe',
    DATA_EXFILTRATION:   'fa-file-export',
    RANSOMWARE:          'fa-skull',
    PROCESSO_SOSPETTO:   'fa-microchip',
    CONNESSIONE_ANOMALA: 'fa-network-wired',
  }[type] || 'fa-triangle-exclamation')
}

// ── API ──────────────────────────────────────────────────────────────────────
async function loadState() {
  try { st.value = await fetch('/api/mahoraga/state').then(r => r.json()) } catch {}
}
async function loadScenarios() {
  try { scenarios.value = await fetch('/api/mahoraga/scenarios').then(r => r.json()) } catch {}
}

// ── scan ─────────────────────────────────────────────────────────────────────
async function doScan() {
  if (busy.value) return
  phase.value = 'scanning'
  try {
    const res = await fetch('/api/mahoraga/scan', { method: 'POST' }).then(r => r.json())
    if (!res.detections.length) { phase.value = 'idle'; return }
    const { threat, adaptation } = res.detections[0]
    await runSequence(threat, adaptation)
    st.value = res.state
  } catch { phase.value = 'idle' }
}

// ── simulate ─────────────────────────────────────────────────────────────────
async function simulate(key) {
  if (busy.value) return
  phase.value = 'scanning'
  try {
    const res = await fetch('/api/mahoraga/simulate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ scenario: key }),
    }).then(r => r.json())
    await runSequence(res.threat, res.adaptation)
    st.value = res.state
  } catch { phase.value = 'idle' }
}

// ── main sequence ─────────────────────────────────────────────────────────────
async function runSequence(threat, adaptation) {
  // Show threat card
  activeThreat.value = threat
  activeId.value     = threat.id
  displayThreats.value.unshift({ ...threat, eliminated: false })
  if (displayThreats.value.length > 6) displayThreats.value.pop()

  phase.value = 'threat_detected'
  await sleep(700)

  // Stream narration from Ollama
  phase.value    = 'adapting'
  voiceText.value = ''
  lastAdapt.value = adaptation
  await streamNarrate(threat, adaptation)

  // Mark eliminated
  const idx = displayThreats.value.findIndex(t => t.id === threat.id)
  if (idx !== -1) displayThreats.value[idx].eliminated = true

  // Wheel flash on full rotation
  if (adaptation.wheel_completed) {
    wheelFlash.value = true
    setTimeout(() => { wheelFlash.value = false }, 900)
  }

  // ADAPTED overlay
  phase.value = 'adapted'
  await sleep(2600)
  phase.value   = 'idle'
  activeId.value = null
}

// ── stream narrate ────────────────────────────────────────────────────────────
async function streamNarrate(threat, adaptation) {
  try {
    const res = await fetch('/api/mahoraga/narrate', {
      method:  'POST',
      headers: { 'Content-Type': 'application/json' },
      body:    JSON.stringify({
        threat,
        adaptation_count: adaptation.adaptation_count,
        total_rotations:  adaptation.total_rotations,
      }),
    })
    const reader = res.body.getReader()
    const dec    = new TextDecoder()
    while (true) {
      const { done, value } = await reader.read()
      if (done) break
      for (const line of dec.decode(value).split('\n').filter(Boolean)) {
        try {
          const j = JSON.parse(line)
          if (j.message?.content) {
            voiceText.value += j.message.content
            await nextTick()
            if (voiceEl.value) voiceEl.value.scrollTop = voiceEl.value.scrollHeight
          }
          if (j.done) return
        } catch {}
      }
    }
  } catch {
    voiceText.value = '[Mahoraga non raggiungibile — verifica che Ollama sia attivo]'
  }
}

function sleep(ms) { return new Promise(r => setTimeout(r, ms)) }

onMounted(async () => {
  await Promise.all([loadState(), loadScenarios()])
  autoTimer = setInterval(() => { if (!busy.value) loadState() }, 7000)
})
onUnmounted(() => clearInterval(autoTimer))
</script>

<style scoped>
/* ── Layout ──────────────────────────────────────────────────────────────── */
.mhg-wrap {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.mhg-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 12px;
}
.mhg-title {
  font-size: 22px;
  color: var(--cyan);
  letter-spacing: 6px;
  display: flex;
  align-items: center;
  gap: 12px;
}
.mhg-title-icon { color: var(--cyan); font-size: 18px; }
.mhg-sub { font-size: 9px; color: var(--text-muted); letter-spacing: 2px; margin-top: 4px; }

.mhg-stats {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
  align-items: center;
}
.stat-chip {
  font-size: 10px;
  color: var(--text-muted);
  letter-spacing: 1px;
  display: flex;
  align-items: center;
  gap: 5px;
  background: var(--surface);
  border: 1px solid var(--border);
  padding: 4px 10px;
}
.stat-chip b { margin-left: 3px; }

/* ── 3-col ────────────────────────────────────────────────────────────────── */
.mhg-main {
  display: grid;
  grid-template-columns: 260px 1fr 260px;
  gap: 14px;
  align-items: start;
}

/* ── Panel header ─────────────────────────────────────────────────────────── */
.panel-hdr {
  font-size: 9px;
  color: var(--text-muted);
  letter-spacing: 2px;
  padding: 10px 14px;
  border-bottom: 1px solid var(--border);
  display: flex;
  align-items: center;
  gap: 8px;
  background: var(--surface);
}
.scan-btn {
  margin-left: auto;
  font-size: 9px;
  padding: 3px 10px;
}

/* ── Threat feed ──────────────────────────────────────────────────────────── */
.threat-panel { padding: 0; overflow: hidden; }
.feed-list {
  padding: 10px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  max-height: calc(100vh - 340px);
  overflow-y: auto;
  min-height: 200px;
}
.threat-card {
  padding: 10px 12px;
  border: 1px solid var(--border);
  background: var(--surface-alt);
  font-size: 10px;
  transition: border-color 0.2s, background 0.2s;
}
.threat-card.tc-active { border-color: var(--high); box-shadow: 0 0 10px rgba(255,109,0,0.2); }
.threat-card.tc-done   { border-color: var(--safe); opacity: 0.65; }

.tc-row1 { display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px; }
.tc-type { font-size: 9px; letter-spacing: 1px; display: flex; align-items: center; gap: 5px; }
.tc-score { font-size: 18px; font-weight: 900; }
.tc-target { color: var(--text); font-size: 10px; margin-bottom: 2px; word-break: break-all; }
.tc-detail { color: var(--text-muted); font-size: 9px; line-height: 1.4; margin-bottom: 6px; }
.tc-tags { display: flex; flex-wrap: wrap; gap: 4px; }
.tag-flag { font-size: 8px; padding: 1px 5px; border: 1px solid var(--critical); color: var(--critical); background: rgba(255,23,68,0.08); letter-spacing: 0.5px; }
.tag-ok   { font-size: 8px; padding: 1px 6px; border: 1px solid var(--safe);     color: var(--safe);     background: rgba(0,230,118,0.08); letter-spacing: 0.5px; }

.no-threats {
  text-align: center;
  padding: 40px 0;
  color: var(--text-muted);
  font-size: 11px;
  line-height: 2;
}
.no-threats i { font-size: 28px; color: var(--safe); display: block; margin-bottom: 8px; }

/* ── Wheel column ─────────────────────────────────────────────────────────── */
.wheel-col {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 14px;
  position: relative;
}

.wheel-svg {
  width: 100%;
  max-width: 320px;
  height: auto;
  transform-origin: center center;
}

/* Spin speeds per phase */
@keyframes spin-slow   { to { transform: rotate(360deg); } }
@keyframes spin-medium { to { transform: rotate(360deg); } }
@keyframes spin-fast   { to { transform: rotate(360deg); } }

.sp-idle            { animation: spin-slow   30s linear infinite; }
.sp-scanning        { animation: spin-medium  3s linear infinite; }
.sp-threat_detected { animation: none; }
.sp-adapting        { animation: spin-fast   1.4s linear infinite; }
.sp-adapted         { animation: spin-fast   0.9s linear infinite; }

/* Segment flash when wheel completes */
@keyframes seg-flash-anim { 0%, 100% { fill: var(--cyan); } 50% { fill: white; opacity: 1; } }
.w-seg { transition: fill 0.3s, opacity 0.3s; }
.seg-flash { animation: seg-flash-anim 0.45s ease 2; }

.phase-lbl {
  font-size: 10px;
  letter-spacing: 3px;
  color: var(--text-muted);
  text-align: center;
  display: flex;
  align-items: center;
  gap: 7px;
}
.phase-lbl .risk-safe  { color: var(--safe); }
.sp-adapting + .phase-lbl,
.phase-lbl:has(.fa-spin) { color: var(--cyan); }

.rot-badge {
  font-size: 9px;
  color: var(--low);
  letter-spacing: 1px;
  border: 1px solid var(--low);
  padding: 3px 10px;
  background: rgba(118,255,3,0.06);
  display: flex;
  align-items: center;
  gap: 6px;
}

@keyframes blink-anim { 50% { opacity: 0.2; } }
.blink { animation: blink-anim 0.7s step-end infinite; color: var(--critical); }

/* ── Adapted overlay ──────────────────────────────────────────────────────── */
.adapted-overlay {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  z-index: 20;
  background: rgba(5, 10, 14, 0.92);
  border: 1px solid var(--cyan);
  box-shadow: 0 0 30px rgba(0,245,255,0.25);
  padding: 24px 32px;
  text-align: center;
  min-width: 240px;
  pointer-events: none;
}
.ao-title  { font-size: 28px; color: var(--cyan); letter-spacing: 6px; font-weight: 900; text-shadow: 0 0 20px var(--cyan); }
.ao-sub    { font-size: 16px; color: var(--text);  letter-spacing: 4px; margin: 4px 0 12px; }
.ao-threat { font-size: 10px; color: var(--high);  letter-spacing: 2px; }
.ao-ok     { font-size: 10px; color: var(--safe);  letter-spacing: 2px; margin-top: 6px; }

/* ── Voice panel ──────────────────────────────────────────────────────────── */
.voice-panel { padding: 0; overflow: hidden; display: flex; flex-direction: column; }
.voice-body {
  flex: 1;
  padding: 14px;
  overflow-y: auto;
  min-height: 200px;
  max-height: calc(100vh - 340px);
  scroll-behavior: smooth;
}
.voice-idle {
  color: var(--text-muted);
  font-size: 11px;
  text-align: center;
  padding-top: 40px;
}
.voice-text {
  font-size: 12px;
  color: var(--text-secondary);
  line-height: 1.9;
  white-space: pre-wrap;
  text-shadow: 0 0 8px rgba(0,245,255,0.1);
}
.adapt-meta {
  font-size: 9px;
  color: var(--text-muted);
  letter-spacing: 1px;
  padding: 8px 14px;
  border-top: 1px solid var(--border);
  background: var(--surface);
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

.cursor { animation: cur-blink 1s step-end infinite; }
@keyframes cur-blink { 50% { opacity: 0; } }

/* ── Simulation bar ───────────────────────────────────────────────────────── */
.sim-bar {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
  padding: 12px 16px;
  background: var(--surface);
  border: 1px solid var(--border);
}
.sim-label { font-size: 9px; color: var(--text-muted); letter-spacing: 2px; white-space: nowrap; }
.sim-btn {
  font-size: 9px;
  letter-spacing: 1px;
  padding: 7px 14px;
  border: 1px solid var(--c, var(--cyan));
  color: var(--c, var(--cyan));
  background: color-mix(in srgb, var(--c, var(--cyan)) 10%, transparent);
  cursor: pointer;
  transition: all 0.15s;
  display: flex;
  align-items: center;
  gap: 7px;
}
.sim-btn:hover:not(:disabled) { background: color-mix(in srgb, var(--c, var(--cyan)) 22%, transparent); }
.sim-btn:disabled { opacity: 0.35; cursor: not-allowed; }
.sim-name { }
.sim-score { font-size: 9px; opacity: 0.7; border: 1px solid currentColor; padding: 0 4px; }

/* ── Transitions ──────────────────────────────────────────────────────────── */
.slide-in-enter-active { animation: slide-in-kf 0.35s ease; }
.slide-in-leave-active { animation: slide-in-kf 0.2s ease reverse; }
@keyframes slide-in-kf {
  from { opacity: 0; transform: translateX(-20px); }
  to   { opacity: 1; transform: translateX(0); }
}

.pop-enter-active { animation: pop-kf 0.4s cubic-bezier(0.34, 1.56, 0.64, 1); }
.pop-leave-active { animation: pop-kf 0.25s ease reverse; }
@keyframes pop-kf {
  from { opacity: 0; transform: translate(-50%, -50%) scale(0.6); }
  to   { opacity: 1; transform: translate(-50%, -50%) scale(1); }
}

/* ── Responsive ──────────────────────────────────────────────────────────── */
@media (max-width: 1100px) {
  .mhg-main { grid-template-columns: 1fr 1fr; }
  .wheel-col { grid-column: 1 / -1; order: -1; }
  .wheel-svg { max-width: 260px; }
}
@media (max-width: 700px) {
  .mhg-main { grid-template-columns: 1fr; }
  .mhg-title { font-size: 16px; letter-spacing: 3px; }
  .sim-btn .sim-name { display: none; }
  .feed-list, .voice-body { max-height: 260px; }
}
</style>
