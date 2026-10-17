import hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
CONFIG=['.env','compose.yaml','compose.bootstrap.yaml','ops/Caddyfile','ops/gateway-start.sh']
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def verify(folder):
 p=Path(folder).resolve();m=json.loads((p/'manifest.json').read_text())
 if (m.get('product'),m.get('version'),m.get('status'))!=('hefesto-diagnostico-red','2.0.6','completed'):raise SystemExit('Manifest incorrecto')
 if set(m.get('sha256',{}))!=set(CONFIG):raise SystemExit('Lista inesperada')
 for n,h in m['sha256'].items():
  f=p/n
  if f.is_symlink() or not f.is_file() or p not in f.resolve().parents or sha(f)!=h:raise SystemExit('Ruta/checksum incorrecto: '+n)
 return p
