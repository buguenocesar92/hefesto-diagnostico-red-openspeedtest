import datetime,json,os,shutil
from common import ROOT,CONFIG,sha
os.umask(0o077)
for n in CONFIG:
 p=ROOT/n
 if p.is_symlink() or not p.is_file():raise SystemExit('Falta archivo regular: '+n)
p=ROOT/'backups'/datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ');p.mkdir(parents=True,mode=0o700)
for n in CONFIG:
 dst=p/n;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/n,dst)
(p/'manifest.json').write_text(json.dumps({'product':'hefesto-diagnostico-red','version':'2.0.6','status':'completed','sha256':{n:sha(p/n) for n in CONFIG}},indent=2))
print('Configuracion respaldada:',p,'No incluye mediciones ni informes externos.')
