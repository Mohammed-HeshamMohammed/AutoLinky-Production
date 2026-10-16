import re
s=open('supabase/schema_current.sql',encoding='utf-8').read()
tot=0;rows=[]
for m in re.finditer(r'CREATE (?:UNLOGGED )?TABLE public\.(\w+) \((.*?)\n\)',s,re.S):
    cols=[l for l in m.group(2).split('\n') if l.strip() and not l.strip().startswith(('CONSTRAINT','PRIMARY','UNIQUE','FOREIGN','CHECK'))]
    tot+=len(cols);rows.append((m.group(1),len(cols)))
print(tot,len(rows))
