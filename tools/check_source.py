"""Check local Dart imports and delimiters. This does NOT replace flutter analyze."""
from pathlib import Path
import re
root=Path(__file__).resolve().parents[1]
errors=[]
def verify(path):
 s=path.read_text();n=len(s)
 def code(i,expected=None):
  while i<n:
   if s.startswith('//',i):
    e=s.find('\n',i);i=n if e<0 else e+1;continue
   if s.startswith('/*',i):
    depth=1;i+=2
    while i<n and depth:
     if s.startswith('/*',i):depth+=1;i+=2
     elif s.startswith('*/',i):depth-=1;i+=2
     else:i+=1
    if depth:raise ValueError('unclosed comment')
    continue
   raw=s[i]=='r' and i+1<n and s[i+1] in "\"'"
   if s[i] in "\"'" or raw:
    if raw:i+=1
    quote=s[i]*3 if s.startswith(s[i]*3,i) else s[i];i+=len(quote)
    while i<n:
     if s.startswith(quote,i):i+=len(quote);break
     if not raw and s[i]=='\\':i+=2;continue
     if not raw and s.startswith('${',i):i=code(i+2,'}');continue
     i+=1
    else:raise ValueError('unclosed string')
    continue
   if s[i] in '([{':i=code(i+1,{'(':')','[':']','{':'}'}[s[i]]);continue
   if s[i] in ')]}':
    if s[i]!=expected:raise ValueError(f'line {s[:i].count(chr(10))+1}: unexpected {s[i]}, expected {expected}')
    return i+1
   i+=1
  if expected:raise ValueError('missing '+expected)
  return i
 try:code(0)
 except ValueError as e:errors.append(f'{path.relative_to(root)}: {e}')
 for value in re.findall(r"(?:import|export|part)\s+['\"]([^'\"]+)",s):
  if ':' not in value and not (path.parent/value).is_file():errors.append(f'{path}: missing import {value}')
for file in (root/'lib').rglob('*.dart'):verify(file)
if errors:print('\n'.join(errors));raise SystemExit(1)
print(f'{len(list((root/"lib").rglob("*.dart")))} Dart files: local imports and delimiters OK. Flutter analysis/build still required.')
