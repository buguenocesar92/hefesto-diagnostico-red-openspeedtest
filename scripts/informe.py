import datetime,json,math,statistics,sys
from pathlib import Path
if len(sys.argv)!=3:raise SystemExit('Uso: informe.py MEDICIONES.json INFORME_NUEVO.md')
src=Path(sys.argv[1]);out=Path(sys.argv[2])
if src.stat().st_size>1024*1024:raise SystemExit('JSON demasiado grande')
d=json.loads(src.read_text());rows=d.get('pruebas')
if type(d.get('demo')) is not bool:raise SystemExit('Indicar demo true o false')
if not isinstance(rows,list) or not 3<=len(rows)<=100:raise SystemExit('Registrar entre 3 y 100 pruebas')
cols=['bajada_mbps','subida_mbps','latencia_ms']
for row in rows:
 for c in cols:
  v=row.get(c)
  if type(v) not in (int,float) or not math.isfinite(v) or v<0:raise SystemExit('Medicion invalida: '+c)
def esc(s):
 if not isinstance(s,str) or len(s)>4000:raise SystemExit('Texto invalido')
 return s.replace('\\','\\\\').replace('|','\\|').replace('<','&lt;').replace('>','&gt;').replace('\n',' ')
lines=['# Informe de diagnóstico de red','', '**DEMOSTRACIÓN: valores ficticios, sin medición real.**' if d['demo'] else 'Resultados declarados por el operador; no capturados automáticamente.', '']
for k in ['cliente','fecha','punto','servidor','conexion','equipo','observaciones']:lines.append('- '+k+': '+esc(d.get(k,'')))
lines+=['','| Prueba | Bajada Mbps | Subida Mbps | Latencia ms |','| --- | --- | --- | --- |']
for i,row in enumerate(rows,1):lines.append('| '+str(i)+' | '+' | '.join(str(row[c]) for c in cols)+' |')
lines+=['| Mediana | '+' | '.join(str(round(statistics.median(row[c] for row in rows),2)) for c in cols)+' |','','La prueba refleja el trayecto navegador-servidor y sus intermediarios. No certifica el ancho de banda contratado ni atribuye por si sola una falla al proveedor.','']
with out.open('x',encoding='utf8') as f:f.write('\n'.join(lines))
print(out)
