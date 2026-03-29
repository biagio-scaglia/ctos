<template>
  <div class="scanline">
    <!-- Top bar -->
    <header class="topbar">
      <div class="topbar-brand">
        <span class="topbar-logo">⚡</span>
        <span class="font-orbitron topbar-title">CTOS</span>
        <span class="font-mono topbar-sub">COMPANION DESKTOP</span>
      </div>

      <nav class="topbar-nav">
        <router-link to="/" class="nav-link">DASHBOARD</router-link>
        <router-link to="/processes" class="nav-link">PROCESSI</router-link>
        <router-link to="/network" class="nav-link">RETE</router-link>
        <router-link to="/guardian" class="nav-link">GUARDIAN AI</router-link>
      </nav>

      <div class="topbar-status">
        <span class="font-mono" :class="guardianOnline ? 'risk-safe' : 'risk-critical'" style="font-size:10px; letter-spacing:1px">
          {{ guardianOnline ? '● GUARDIAN ONLINE' : '○ GUARDIAN OFFLINE' }}
        </span>
      </div>
    </header>

    <!-- Main content -->
    <main style="flex:1; padding: 20px; max-width: 1400px; margin: 0 auto; width: 100%">
      <router-view />
    </main>

    <!-- Footer -->
    <footer class="footer font-mono">
      CTOS COMPANION v1.0 &nbsp;|&nbsp; <span style="color:var(--cyan)">192.168.1.12:11434</span> &nbsp;|&nbsp; {{ now }}
    </footer>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'

const guardianOnline = ref(false)
const now = ref('')

let timer = null

async function checkGuardian() {
  try {
    const r = await fetch('/api/guardian/status')
    const d = await r.json()
    guardianOnline.value = d.online
  } catch {
    guardianOnline.value = false
  }
}

function tick() {
  now.value = new Date().toLocaleTimeString('it-IT')
}

onMounted(() => {
  checkGuardian()
  tick()
  timer = setInterval(() => { checkGuardian(); tick() }, 5000)
})
onUnmounted(() => clearInterval(timer))
</script>

<style scoped>
.topbar {
  display: flex;
  align-items: center;
  gap: 32px;
  padding: 12px 24px;
  background: var(--surface);
  border-bottom: 1px solid var(--cyan-dark);
  position: sticky;
  top: 0;
  z-index: 100;
}

.topbar-brand { display: flex; align-items: center; gap: 10px; }
.topbar-logo { font-size: 20px; }
.topbar-title { font-size: 16px; color: var(--cyan); letter-spacing: 3px; }
.topbar-sub { font-size: 9px; color: var(--text-muted); letter-spacing: 2px; }

.topbar-nav { display: flex; gap: 4px; flex: 1; justify-content: center; }
.nav-link {
  font-family: 'Orbitron', monospace;
  font-size: 10px;
  letter-spacing: 2px;
  color: var(--text-muted);
  text-decoration: none;
  padding: 6px 14px;
  border: 1px solid transparent;
  transition: all 0.15s;
}
.nav-link:hover, .nav-link.router-link-active {
  color: var(--cyan);
  border-color: var(--cyan-dark);
  background: var(--cyan-glow);
}

.topbar-status { margin-left: auto; }

.footer {
  padding: 8px 24px;
  border-top: 1px solid var(--border);
  font-size: 10px;
  color: var(--text-muted);
  letter-spacing: 1px;
  text-align: center;
}
</style>
