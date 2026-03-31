<template>
  <div class="scanline">
    <!-- Top bar -->
    <header class="topbar">
      <div class="topbar-brand">
        <i class="fa-bolt fa-solid topbar-logo"></i>
        <span class="font-orbitron topbar-title">CTOS</span>
        <span class="font-mono topbar-sub">COMPANION DESKTOP</span>
      </div>

      <!-- Desktop nav -->
      <nav class="topbar-nav desktop-nav">
        <router-link to="/" class="nav-link">
          <i class="fa-solid fa-gauge-high nav-icon"></i>
          <span class="nav-label">DASHBOARD</span>
        </router-link>
        <router-link to="/processes" class="nav-link">
          <i class="fa-solid fa-microchip nav-icon"></i>
          <span class="nav-label">PROCESSI</span>
        </router-link>
        <router-link to="/network" class="nav-link">
          <i class="fa-solid fa-network-wired nav-icon"></i>
          <span class="nav-label">RETE</span>
        </router-link>
        <router-link to="/guardian" class="nav-link">
          <i class="fa-solid fa-robot nav-icon"></i>
          <span class="nav-label">GUARDIAN AI</span>
        </router-link>
        <router-link to="/mahoraga" class="nav-link nav-link-mhg">
          <i class="fa-solid fa-circle-half-stroke nav-icon"></i>
          <span class="nav-label">MAHORAGA</span>
        </router-link>
      </nav>

      <div class="topbar-right">
        <span class="font-mono guardian-badge" :class="guardianOnline ? 'risk-safe' : 'risk-critical'">
          <i :class="guardianOnline ? 'fa-solid fa-circle' : 'fa-regular fa-circle'" style="font-size:7px"></i>
          <span class="guardian-label">{{ guardianOnline ? 'GUARDIAN ONLINE' : 'GUARDIAN OFFLINE' }}</span>
        </span>

        <!-- Hamburger -->
        <button class="hamburger" @click="mobileOpen = !mobileOpen" aria-label="Menu">
          <i :class="mobileOpen ? 'fa-solid fa-xmark' : 'fa-solid fa-bars'"></i>
        </button>
      </div>
    </header>

    <!-- Mobile nav overlay -->
    <nav v-if="mobileOpen" class="mobile-nav" @click.self="mobileOpen = false">
      <router-link to="/" class="mobile-link" @click="mobileOpen = false">
        <i class="fa-solid fa-gauge-high"></i> DASHBOARD
      </router-link>
      <router-link to="/processes" class="mobile-link" @click="mobileOpen = false">
        <i class="fa-solid fa-microchip"></i> PROCESSI
      </router-link>
      <router-link to="/network" class="mobile-link" @click="mobileOpen = false">
        <i class="fa-solid fa-network-wired"></i> RETE
      </router-link>
      <router-link to="/guardian" class="mobile-link" @click="mobileOpen = false">
        <i class="fa-solid fa-robot"></i> GUARDIAN AI
      </router-link>
      <router-link to="/mahoraga" class="mobile-link mobile-link-mhg" @click="mobileOpen = false">
        <i class="fa-solid fa-circle-half-stroke"></i> MAHORAGA
      </router-link>
    </nav>

    <!-- Main content -->
    <main class="main-content">
      <router-view />
    </main>

    <!-- Footer -->
    <footer class="footer font-mono">
      <i class="fa-solid fa-bolt" style="color:var(--cyan)"></i>
      CTOS COMPANION v1.0
      <span class="footer-sep">|</span>
      <i class="fa-solid fa-server" style="color:var(--cyan-dim); font-size:9px"></i>
      <span style="color:var(--cyan)">192.168.1.12:11434</span>
      <span class="footer-sep">|</span>
      <i class="fa-regular fa-clock" style="font-size:9px"></i>
      {{ now }}
    </footer>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'

const guardianOnline = ref(false)
const now = ref('')
const mobileOpen = ref(false)

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
  gap: 20px;
  padding: 10px 20px;
  background: var(--surface);
  border-bottom: 1px solid var(--cyan-dark);
  position: sticky;
  top: 0;
  z-index: 100;
}

.topbar-brand { display: flex; align-items: center; gap: 10px; flex-shrink: 0; }
.topbar-logo { font-size: 18px; color: var(--cyan); }
.topbar-title { font-size: 16px; color: var(--cyan); letter-spacing: 3px; }
.topbar-sub { font-size: 9px; color: var(--text-muted); letter-spacing: 2px; }

.desktop-nav { display: flex; gap: 4px; flex: 1; justify-content: center; }
.nav-link {
  font-family: 'Orbitron', monospace;
  font-size: 10px;
  letter-spacing: 2px;
  color: var(--text-muted);
  text-decoration: none;
  padding: 6px 12px;
  border: 1px solid transparent;
  transition: all 0.15s;
  display: flex;
  align-items: center;
  gap: 7px;
}
.nav-icon { font-size: 11px; }
.nav-link:hover, .nav-link.router-link-active {
  color: var(--cyan);
  border-color: var(--cyan-dark);
  background: var(--cyan-glow);
}

.topbar-right {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-left: auto;
  flex-shrink: 0;
}
.guardian-badge {
  font-size: 10px;
  letter-spacing: 1px;
  display: flex;
  align-items: center;
  gap: 5px;
}

.hamburger {
  display: none;
  background: none;
  border: 1px solid var(--border);
  color: var(--cyan);
  padding: 6px 10px;
  cursor: pointer;
  font-size: 16px;
  line-height: 1;
}
.hamburger:hover { border-color: var(--cyan-dark); background: var(--cyan-glow); }

/* Mobile nav */
.mobile-nav {
  position: fixed;
  top: 0; left: 0; right: 0; bottom: 0;
  background: rgba(5, 10, 14, 0.96);
  z-index: 200;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 8px;
}
.mobile-link {
  font-family: 'Orbitron', monospace;
  font-size: 14px;
  letter-spacing: 3px;
  color: var(--text-muted);
  text-decoration: none;
  padding: 14px 40px;
  border: 1px solid var(--border);
  width: 260px;
  text-align: center;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  transition: all 0.15s;
}
.mobile-link:hover, .mobile-link.router-link-active {
  color: var(--cyan);
  border-color: var(--cyan-dark);
  background: var(--cyan-glow);
}

.main-content {
  flex: 1;
  padding: 20px;
  max-width: 1400px;
  margin: 0 auto;
  width: 100%;
}

.footer {
  padding: 8px 24px;
  border-top: 1px solid var(--border);
  font-size: 10px;
  color: var(--text-muted);
  letter-spacing: 1px;
  text-align: center;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  flex-wrap: wrap;
}
.footer-sep { color: var(--border); margin: 0 2px; }

/* Mahoraga special link */
.nav-link-mhg { border-color: rgba(0,245,255,0.15) !important; }
.nav-link-mhg:hover,
.nav-link-mhg.router-link-active {
  color: var(--cyan) !important;
  border-color: var(--cyan) !important;
  box-shadow: 0 0 12px rgba(0,245,255,0.3);
}
.mobile-link-mhg.router-link-active { color: var(--cyan); border-color: var(--cyan); }

/* ── Responsive ─────────────────────────────────────────────────── */
@media (max-width: 900px) {
  .desktop-nav { display: none; }
  .hamburger { display: block; }
  .guardian-label { display: none; }
  .topbar-sub { display: none; }
  .main-content { padding: 14px; }
}

@media (max-width: 480px) {
  .topbar-title { font-size: 13px; letter-spacing: 2px; }
  .topbar { padding: 8px 14px; gap: 10px; }
}
</style>
