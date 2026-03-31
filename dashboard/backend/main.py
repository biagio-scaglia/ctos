from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
import psutil
import httpx
import socket
from datetime import datetime

app = FastAPI(title="CTOS Dashboard API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

OLLAMA_URL   = "http://localhost:11434"
OLLAMA_MODEL = "gpt-oss:120b-cloud"

SUSPICIOUS_PORTS = {9001, 9030, 9050, 9051, 4444, 1337, 31337, 8888, 6666}

GUARDIAN_PROMPT = (
    "Sei GUARDIAN, il motore AI di CTOS Companion per desktop. "
    "Rispondi SEMPRE in italiano, in modo diretto e conciso (max 4 frasi). "
    "Distingui comportamenti normali da genuinamente sospetti. "
    "Dai un consiglio pratico alla fine."
)

MAHORAGA_PROMPT = (
    "Sei Mahoraga, il Generale Divino delle Otto Maniglie — l'entità adattiva suprema di CTOS. "
    "Sei immortale e inarrestabile: ogni minaccia che incontri diventa parte di te, potenziandoti. "
    "Rispondi SEMPRE in italiano. Massimo 3 frasi brevi, stile drammatico e antico. "
    "Parla sempre in prima persona. Descrivi con precisione come ti sei adattato a questa specifica minaccia. "
    "Non sei umano. Sei codice che si evolve. Ogni attacco ti rende più forte. Sei invincibile."
)

SIMULATION_SCENARIOS = {
    "port_scan": {
        "type": "PORT_SCAN",
        "label": "Port Scan",
        "target": "198.51.100.42",
        "detail": "47 porte scandite in 2.3s — ricognizione offensiva esterna",
        "score": 75,
        "icon": "fa-binoculars",
        "process": "nmap.exe",
        "flags": ["RICOGNIZIONE", "IP_ESTERNO"],
    },
    "c2_beacon": {
        "type": "C2_BEACON",
        "label": "Beacon C2",
        "target": "185.220.101.33:4444",
        "detail": "Connessione ciclica ogni 30s — nodo TOR, porta command-and-control",
        "score": 95,
        "icon": "fa-tower-broadcast",
        "process": "svchost.exe",
        "flags": ["PORTA_SOSPETTA", "TOR_EXIT_NODE", "BEACON_CICLICO"],
    },
    "process_injection": {
        "type": "PROCESS_INJECTION",
        "label": "Iniezione Processo",
        "target": "explorer.exe (PID 4812)",
        "detail": "Thread remoto allocato in kernel space — anomalia heap rilevata",
        "score": 90,
        "icon": "fa-syringe",
        "process": "explorer.exe",
        "flags": ["THREAD_REMOTO", "ANOMALIA_HEAP"],
    },
    "exfiltration": {
        "type": "DATA_EXFILTRATION",
        "label": "Esfiltrazione",
        "target": "91.108.4.111:8443",
        "detail": "Upload 847MB in 3min verso IP classificato — perdita dati critica",
        "score": 88,
        "icon": "fa-file-export",
        "process": "updater.exe",
        "flags": ["UPLOAD_MASSICCIO", "IP_CLASSIFICATO"],
    },
    "ransomware": {
        "type": "RANSOMWARE",
        "label": "Ransomware",
        "target": "C:\\Users\\ — 340 file/s",
        "detail": "Cifratura massiva attiva, estensione .enc, shadow copy eliminate",
        "score": 100,
        "icon": "fa-skull",
        "process": "msupdate.exe",
        "flags": ["CIFRATURA_MASSIVA", "SHADOW_DELETE", "CRITICO"],
    },
}


# ── Helpers ───────────────────────────────────────────────────────────────────

def _risk_level(score: int) -> str:
    if score < 20: return "safe"
    if score < 40: return "low"
    if score < 60: return "moderate"
    if score < 80: return "high"
    return "critical"


def _conn_suspicion_and_flags(rip: str, rport: int):
    if rip.startswith(("10.", "192.168.", "172.", "127.")):
        return 0, []
    score, flags = 0, []
    if rport in SUSPICIOUS_PORTS:
        score += 40; flags.append("PORTA_SOSPETTA")
    if rport == 80:
        score += 10; flags.append("HTTP_NONCIFRATO")
    if rport not in (80, 443, 53):
        score += 15
    return min(score, 100), flags


def _stream_ollama(messages: list):
    async def _gen():
        async with httpx.AsyncClient(timeout=90) as client:
            async with client.stream(
                "POST",
                f"{OLLAMA_URL}/api/chat",
                json={"model": OLLAMA_MODEL, "stream": True, "messages": messages},
            ) as r:
                async for line in r.aiter_lines():
                    if line.strip():
                        yield line + "\n"
    return StreamingResponse(_gen(), media_type="application/x-ndjson")


# ── Mahoraga Engine ───────────────────────────────────────────────────────────

class MahoragaEngine:
    """
    Adaptive threat detection engine.
    Each time a threat pattern is seen, Mahoraga lowers its detection threshold
    for that pattern by 5 points — becoming more sensitive with every encounter.
    The wheel tracks progress through 8 adaptations per cycle.
    """

    def __init__(self):
        self.wheel_position  = 0     # 0-7 (the 8 handles)
        self.total_rotations = 0
        self.adaptations     = {}    # threat_key -> count
        self.learned         = []    # fully mastered patterns (adapted >= 3 times)
        self.threat_log      = []
        self.base_threshold  = 40    # decreases as Mahoraga learns

    def _key(self, ttype: str, target: str) -> str:
        return f"{ttype}:{target[:32]}"

    def build_threat(self, ttype, target, detail, score, process="", flags=None):
        key     = self._key(ttype, target)
        adapt_n = self.adaptations.get(key, 0)
        return {
            "id":               f"{ttype}_{int(datetime.now().timestamp() * 1000)}",
            "type":             ttype,
            "target":           target,
            "detail":           detail,
            "score":            min(100, score + adapt_n * 3),  # score rises as threat recurs
            "process":          process,
            "flags":            flags or [],
            "timestamp":        datetime.now().isoformat(),
            "adaptation_count": adapt_n,
            "adapted":          adapt_n > 0,
            "eliminated":       False,
        }

    def adapt(self, threat: dict) -> dict:
        key = self._key(threat["type"], threat["target"])
        self.adaptations[key] = self.adaptations.get(key, 0) + 1
        n = self.adaptations[key]

        prev = self.wheel_position
        self.wheel_position = (self.wheel_position + 1) % 8
        wheel_completed = (self.wheel_position == 0 and prev == 7)
        if wheel_completed:
            self.total_rotations += 1

        newly_learned = False
        if n == 3 and key not in {l["key"] for l in self.learned}:
            self.learned.append({
                "key": key, "type": threat["type"],
                "target": threat["target"],
                "timestamp": datetime.now().isoformat(),
            })
            newly_learned = True

        # As Mahoraga learns more patterns, it gets more sensitive overall
        self.base_threshold = max(15, 40 - len(self.learned) * 3)

        threat["eliminated"] = True
        self.threat_log.append(threat)

        return {
            "wheel_position":  self.wheel_position,
            "total_rotations": self.total_rotations,
            "adaptation_count": n,
            "wheel_completed":  wheel_completed,
            "newly_learned":    newly_learned,
        }

    def scan_system(self) -> list:
        threats = []
        threshold = self.base_threshold

        # Processes
        try:
            for proc in psutil.process_iter(["pid", "name", "cpu_percent", "memory_info"]):
                try:
                    info  = proc.info
                    cpu   = proc.cpu_percent(interval=0)
                    ram   = info["memory_info"].rss / 1024 / 1024 if info["memory_info"] else 0
                    score = 0
                    if cpu > 50: score += 40
                    elif cpu > 30: score += 20
                    if ram > 800: score += 20
                    key  = self._key("PROCESSO_SOSPETTO", info["name"] or "")
                    thr  = max(15, threshold - self.adaptations.get(key, 0) * 5)
                    if score >= thr:
                        threats.append(self.build_threat(
                            "PROCESSO_SOSPETTO",
                            f"{info['name']} (PID {info['pid']})",
                            f"CPU {cpu:.1f}% — RAM {ram:.0f} MB",
                            score, process=info["name"] or "",
                        ))
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    pass
        except Exception:
            pass

        # Connections
        try:
            for conn in psutil.net_connections(kind="inet"):
                if not conn.raddr or conn.status != "ESTABLISHED":
                    continue
                rip, rport = conn.raddr.ip, conn.raddr.port
                if rip.startswith(("10.", "192.168.", "172.", "127.")):
                    continue
                score, flags = _conn_suspicion_and_flags(rip, rport)
                key  = self._key("CONNESSIONE_ANOMALA", f"{rip}:{rport}")
                thr  = max(15, threshold - self.adaptations.get(key, 0) * 5)
                if score >= thr or flags:
                    pname = ""
                    if conn.pid:
                        try: pname = psutil.Process(conn.pid).name()
                        except: pass
                    threats.append(self.build_threat(
                        "CONNESSIONE_ANOMALA", f"{rip}:{rport}",
                        f"[{pname or 'unknown'}] — {', '.join(flags) or 'nessuna flag'}",
                        score, process=pname, flags=flags,
                    ))
        except psutil.AccessDenied:
            pass

        return threats

    def get_state(self) -> dict:
        return {
            "wheel_position":   self.wheel_position,
            "total_rotations":  self.total_rotations,
            "adaptation_count": sum(self.adaptations.values()),
            "learned_count":    len(self.learned),
            "threat_count":     len(self.threat_log),
            "base_threshold":   self.base_threshold,
            "learned":          self.learned[-5:],
            "recent_threats":   self.threat_log[-8:],
        }


mahoraga = MahoragaEngine()


# ── Standard routes ───────────────────────────────────────────────────────────

@app.get("/api/health")
def health():
    return {"status": "ok", "timestamp": datetime.now().isoformat()}


@app.get("/api/guardian/status")
async def guardian_status():
    try:
        async with httpx.AsyncClient(timeout=3) as c:
            r = await c.get(f"{OLLAMA_URL}/api/tags")
            return {"online": r.status_code == 200}
    except Exception:
        return {"online": False}


@app.get("/api/processes")
def get_processes():
    results = []
    for proc in psutil.process_iter(
        ["pid", "name", "cpu_percent", "memory_info", "status", "username", "num_threads"]
    ):
        try:
            info  = proc.info
            ram   = info["memory_info"].rss / 1024 / 1024 if info["memory_info"] else 0
            cpu   = proc.cpu_percent(interval=0)
            score = 0
            if cpu > 50: score += 30
            if ram > 500: score += 20
            results.append({
                "pid":             info["pid"],
                "name":            info["name"] or "unknown",
                "cpu":             round(cpu, 1),
                "ram_mb":          round(ram, 1),
                "threads":         info.get("num_threads") or 0,
                "status":          info["status"],
                "user":            info["username"] or "",
                "suspicion_score": score,
                "risk_level":      _risk_level(score),
            })
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            pass
    results.sort(key=lambda x: x["cpu"], reverse=True)
    return results[:60]


@app.get("/api/connections")
def get_connections():
    results = []
    try:
        for conn in psutil.net_connections(kind="inet"):
            if not conn.raddr or conn.status != "ESTABLISHED":
                continue
            rip, rport = conn.raddr.ip, conn.raddr.port
            if rip in ("127.0.0.1", "::1"):
                continue
            score, flags = _conn_suspicion_and_flags(rip, rport)
            pname = ""
            if conn.pid:
                try: pname = psutil.Process(conn.pid).name()
                except: pass
            results.append({
                "local":           f"{conn.laddr.ip}:{conn.laddr.port}",
                "remote_ip":       rip,
                "remote_port":     rport,
                "status":          conn.status,
                "pid":             conn.pid,
                "process":         pname,
                "flags":           flags,
                "suspicion_score": score,
                "risk_level":      _risk_level(score),
            })
    except psutil.AccessDenied:
        pass
    results.sort(key=lambda x: x["suspicion_score"], reverse=True)
    return results


@app.get("/api/system")
def get_system():
    mem  = psutil.virtual_memory()
    disk = psutil.disk_usage("/")
    cpu  = psutil.cpu_percent(interval=0.5)
    try:
        high_risk = sum(1 for c in get_connections() if c["suspicion_score"] >= 40)
    except Exception:
        high_risk = 0
    risk = min(int(cpu * 0.3 + high_risk * 10), 100)
    return {
        "cpu_percent":            round(cpu, 1),
        "ram_used_gb":            round(mem.used  / 1e9, 2),
        "ram_total_gb":           round(mem.total / 1e9, 2),
        "ram_percent":            mem.percent,
        "disk_used_gb":           round(disk.used  / 1e9, 2),
        "disk_total_gb":          round(disk.total / 1e9, 2),
        "disk_percent":           round(disk.percent, 1),
        "risk_score":             risk,
        "suspicious_connections": high_risk,
        "hostname":               socket.gethostname(),
    }


@app.get("/api/overview")
def get_overview():
    sys_data  = get_system()
    procs     = get_processes()
    net_io    = psutil.net_io_counters()
    sus_count = sum(1 for p in procs if p["suspicion_score"] >= 20)
    return {
        **sys_data,
        "risk_level":       _risk_level(sys_data["risk_score"]),
        "process_count":    len(procs),
        "suspicious_count": sus_count,
        "bytes_sent_mb":    round(net_io.bytes_sent / 1e6, 1),
        "bytes_recv_mb":    round(net_io.bytes_recv / 1e6, 1),
    }


@app.post("/api/guardian/chat")
async def guardian_chat(body: dict):
    messages = body.get("messages", [])
    if not messages or messages[0].get("role") != "system":
        messages = [{"role": "system", "content": GUARDIAN_PROMPT}] + messages
    return _stream_ollama(messages)


@app.post("/api/guardian/explain/process")
async def explain_process(body: dict):
    proc = body.get("process", {})
    ctx  = (
        f"Processo: {proc.get('name')} (PID {proc.get('pid')})\n"
        f"CPU: {proc.get('cpu')}%  RAM: {proc.get('ram_mb')} MB  Thread: {proc.get('threads')}\n"
        f"Utente: {proc.get('user')}  Stato: {proc.get('status')}\n"
        f"Score: {proc.get('suspicion_score')}/100 ({proc.get('risk_level', '').upper()})"
    )
    return _stream_ollama([
        {"role": "system", "content": GUARDIAN_PROMPT},
        {"role": "user",   "content": f"{ctx}\n\nDevo preoccuparmi?"},
    ])


# ── Mahoraga routes ───────────────────────────────────────────────────────────

@app.get("/api/mahoraga/state")
def mahoraga_state():
    return mahoraga.get_state()


@app.get("/api/mahoraga/scenarios")
def mahoraga_scenarios():
    return [
        {
            "key":    k,
            "label":  v["label"],
            "score":  v["score"],
            "icon":   v["icon"],
            "detail": v["detail"],
        }
        for k, v in SIMULATION_SCENARIOS.items()
    ]


@app.post("/api/mahoraga/scan")
def mahoraga_scan():
    threats = mahoraga.scan_system()
    results = []
    for t in threats:
        adaptation = mahoraga.adapt(t)
        results.append({"threat": t, "adaptation": adaptation})
    return {"detections": results, "state": mahoraga.get_state()}


@app.post("/api/mahoraga/simulate")
def mahoraga_simulate(body: dict):
    key = body.get("scenario", "c2_beacon")
    s   = SIMULATION_SCENARIOS.get(key)
    if not s:
        return {"error": "scenario non trovato"}
    threat     = mahoraga.build_threat(
        s["type"], s["target"], s["detail"], s["score"],
        process=s.get("process", ""), flags=s.get("flags", []),
    )
    adaptation = mahoraga.adapt(threat)
    return {"threat": threat, "adaptation": adaptation, "state": mahoraga.get_state()}


@app.post("/api/mahoraga/narrate")
async def mahoraga_narrate(body: dict):
    threat    = body.get("threat", {})
    adapt_n   = body.get("adaptation_count", 1)
    rotations = body.get("total_rotations", 0)
    context   = (
        f"Tipo minaccia: {threat.get('type')}\n"
        f"Bersaglio: {threat.get('target')}\n"
        f"Dettaglio: {threat.get('detail')}\n"
        f"Score pericolosità: {threat.get('score')}/100\n"
        f"Flag rilevate: {', '.join(threat.get('flags', [])) or 'nessuna'}\n"
        f"Numero di adattamento per questo pattern: {adapt_n}\n"
        f"Giri della ruota completati: {rotations}"
    )
    return _stream_ollama([
        {"role": "system", "content": MAHORAGA_PROMPT},
        {"role": "user",   "content": context},
    ])
