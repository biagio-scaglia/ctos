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

OLLAMA_URL = "http://localhost:11434"
OLLAMA_MODEL = "gpt-oss:120b-cloud"

SUSPICIOUS_PORTS = {9001, 9030, 9050, 9051, 4444, 1337, 31337, 8888, 6666}

SYSTEM_PROMPT = (
    "Sei GUARDIAN, il motore AI di CTOS Companion per desktop. "
    "Rispondi SEMPRE in italiano, in modo diretto e conciso (max 4 frasi). "
    "Distingui comportamenti normali da genuinamente sospetti. "
    "Dai un consiglio pratico alla fine."
)


# ── Helpers ───────────────────────────────────────────────────────────────────

def _risk_level(score: int) -> str:
    if score < 20:  return "safe"
    if score < 40:  return "low"
    if score < 60:  return "moderate"
    if score < 80:  return "high"
    return "critical"


def _conn_suspicion_and_flags(rip: str, rport: int):
    if rip.startswith(("10.", "192.168.", "172.", "127.")):
        return 0, []
    score = 0
    flags = []
    if rport in SUSPICIOUS_PORTS:
        score += 40
        flags.append("PORTA_SOSPETTA")
    if rport == 80:
        score += 10
        flags.append("HTTP_NONCIFRATO")
    if rport not in (80, 443, 53):
        score += 15
    return min(score, 100), flags


def _stream_ollama(messages: list):
    async def _gen():
        async with httpx.AsyncClient(timeout=60) as client:
            async with client.stream(
                "POST",
                f"{OLLAMA_URL}/api/chat",
                json={"model": OLLAMA_MODEL, "stream": True, "messages": messages},
            ) as r:
                async for line in r.aiter_lines():
                    if line.strip():
                        yield line + "\n"
    return StreamingResponse(_gen(), media_type="application/x-ndjson")


# ── Routes ────────────────────────────────────────────────────────────────────

@app.get("/api/health")
def health():
    return {"status": "ok", "timestamp": datetime.now().isoformat()}


@app.get("/api/guardian/status")
async def guardian_status():
    try:
        async with httpx.AsyncClient(timeout=3) as client:
            r = await client.get(f"{OLLAMA_URL}/api/tags")
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
            info = proc.info
            ram = info["memory_info"].rss / 1024 / 1024 if info["memory_info"] else 0
            cpu = proc.cpu_percent(interval=0)
            score = 0
            if cpu > 50:   score += 30
            if ram > 500:  score += 20
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
            rip   = conn.raddr.ip
            rport = conn.raddr.port
            if rip in ("127.0.0.1", "::1"):
                continue
            score, flags = _conn_suspicion_and_flags(rip, rport)
            pname = ""
            if conn.pid:
                try:
                    pname = psutil.Process(conn.pid).name()
                except Exception:
                    pass
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
        conns     = get_connections()
        high_risk = sum(1 for c in conns if c["suspicion_score"] >= 40)
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


# ── Guardian AI ───────────────────────────────────────────────────────────────

@app.post("/api/guardian/chat")
async def guardian_chat(body: dict):
    messages = body.get("messages", [])
    # Inject system prompt if not present
    if not messages or messages[0].get("role") != "system":
        messages = [{"role": "system", "content": SYSTEM_PROMPT}] + messages
    return _stream_ollama(messages)


@app.post("/api/guardian/explain/process")
async def explain_process(body: dict):
    proc = body.get("process", {})
    context = (
        f"Processo: {proc.get('name')} (PID {proc.get('pid')})\n"
        f"CPU: {proc.get('cpu')}%  RAM: {proc.get('ram_mb')} MB  Thread: {proc.get('threads')}\n"
        f"Utente: {proc.get('user')}  Stato: {proc.get('status')}\n"
        f"Punteggio sospetto: {proc.get('suspicion_score')}/100 ({proc.get('risk_level', '').upper()})"
    )
    return _stream_ollama([
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user",   "content": f"PROCESSO:\n{context}\n\nDevo preoccuparmi?"},
    ])
