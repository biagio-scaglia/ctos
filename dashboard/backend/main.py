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


# ── Helpers ───────────────────────────────────────────────────────────────────

def _conn_suspicion(rip: str, rport: int) -> int:
    if rip.startswith(("10.", "192.168.", "172.")):
        return 0
    score = 0
    if rport in SUSPICIOUS_PORTS:
        score += 40
    if rport == 80:
        score += 10
    if rport not in (80, 443, 53):
        score += 15
    return min(score, 100)


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


@app.get("/api/system")
def get_system():
    mem = psutil.virtual_memory()
    disk = psutil.disk_usage("/")
    cpu = psutil.cpu_percent(interval=0.5)
    try:
        conns = get_connections()
        high_risk = sum(1 for c in conns if c["suspicion_score"] >= 40)
    except Exception:
        high_risk = 0
    risk = min(int(cpu * 0.3 + high_risk * 10), 100)
    return {
        "cpu_percent": round(cpu, 1),
        "ram_used_gb": round(mem.used / 1e9, 2),
        "ram_total_gb": round(mem.total / 1e9, 2),
        "ram_percent": mem.percent,
        "disk_used_gb": round(disk.used / 1e9, 2),
        "disk_total_gb": round(disk.total / 1e9, 2),
        "disk_percent": round(disk.percent, 1),
        "risk_score": risk,
        "suspicious_connections": high_risk,
        "hostname": socket.gethostname(),
    }


@app.get("/api/processes")
def get_processes():
    results = []
    for proc in psutil.process_iter(
        ["pid", "name", "cpu_percent", "memory_info", "status", "username"]
    ):
        try:
            info = proc.info
            ram = info["memory_info"].rss / 1024 / 1024 if info["memory_info"] else 0
            cpu = proc.cpu_percent(interval=0)
            score = 0
            if cpu > 50:
                score += 30
            if ram > 500:
                score += 20
            results.append({
                "pid": info["pid"],
                "name": info["name"] or "unknown",
                "cpu": round(cpu, 1),
                "ram_mb": round(ram, 1),
                "status": info["status"],
                "user": info["username"] or "",
                "suspicion_score": score,
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
            rip = conn.raddr.ip
            if rip in ("127.0.0.1", "::1"):
                continue
            rport = conn.raddr.port
            score = _conn_suspicion(rip, rport)
            pname = ""
            if conn.pid:
                try:
                    pname = psutil.Process(conn.pid).name()
                except Exception:
                    pass
            results.append({
                "local": f"{conn.laddr.ip}:{conn.laddr.port}",
                "remote_ip": rip,
                "remote_port": rport,
                "status": conn.status,
                "pid": conn.pid,
                "process": pname,
                "suspicion_score": score,
            })
    except psutil.AccessDenied:
        pass
    results.sort(key=lambda x: x["suspicion_score"], reverse=True)
    return results


@app.post("/api/guardian/chat")
async def guardian_chat(body: dict):
    return _stream_ollama(body.get("messages", []))


@app.post("/api/guardian/explain/process")
async def explain_process(body: dict):
    proc = body.get("process", {})
    system_prompt = (
        "Sei GUARDIAN, il motore AI di CTOS Companion. "
        "Rispondi SEMPRE in italiano, diretto e conciso (max 4 frasi). "
        "Distingui comportamenti normali da genuinamente sospetti. "
        "Dai un consiglio pratico alla fine."
    )
    context = (
        f"Processo: {proc.get('name')} (PID {proc.get('pid')})\n"
        f"CPU: {proc.get('cpu')}%  RAM: {proc.get('ram_mb')} MB\n"
        f"Utente: {proc.get('user')}  Stato: {proc.get('status')}\n"
        f"Punteggio sospetto: {proc.get('suspicion_score')}/100"
    )
    return _stream_ollama([
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": f"PROCESSO:\n{context}\n\nDevo preoccuparmi?"},
    ])
