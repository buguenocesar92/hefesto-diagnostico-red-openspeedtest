import getpass,os,re
from pathlib import Path
r=Path(__file__).resolve().parents[1]
u=input('Usuario de acceso [hefesto]: ').strip() or 'hefesto'
h=getpass.getpass('Pegar hash bcrypt cost 12 (no la clave): ').strip()
if not re.fullmatch(r'[A-Za-z0-9_-]{3,40}',u):raise SystemExit('Usuario invalido')
if not re.fullmatch(r'\$2[aby]\$12\$[./A-Za-z0-9]{53}',h):raise SystemExit('Hash invalido')
fd=os.open(r/'.env',os.O_CREAT|os.O_EXCL|os.O_WRONLY,0o600)
with os.fdopen(fd,'w') as f:f.write('BASIC_AUTH_USER='+u+"\nBASIC_AUTH_HASH='"+h+"'\n")
print('.env creado sin sobrescribir archivos previos. No versionarlo.')
