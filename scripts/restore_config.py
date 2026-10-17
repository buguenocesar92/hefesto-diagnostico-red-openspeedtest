import os,shutil,sys
from pathlib import Path
from common import CONFIG,verify
if len(sys.argv)!=3:raise SystemExit('Uso: restore_config.py RESPALDO CARPETA_NUEVA')
p=verify(sys.argv[1]);dst=Path(sys.argv[2]);os.umask(0o077)
dst.mkdir(mode=0o700,parents=False,exist_ok=False)
for n in CONFIG:
 f=dst/n;f.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p/n,f)
print('Configuracion recuperada en carpeta nueva. No se inicia ni modifica ningun servicio.')
