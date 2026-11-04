"""Prepare a committed-source iOS export without development MCP autoloads."""
import argparse,hashlib,json,pathlib,plistlib,re,subprocess

def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument('destination',type=pathlib.Path)
 p.add_argument('--sanitize-plist',type=pathlib.Path)
 a=p.parse_args()
 if a.sanitize_plist:
  f=a.sanitize_plist;info=plistlib.loads(f.read_bytes())
  for k in ['NSCameraUsageDescription','NSMicrophoneUsageDescription','NSPhotoLibraryUsageDescription']:
   if not info.get(k,'').strip(): info.pop(k,None)
  info['ITSAppUsesNonExemptEncryption']=False
  f.write_bytes(plistlib.dumps(info,sort_keys=False));return
 root=pathlib.Path(__file__).resolve().parents[1]
 dest=a.destination.resolve();dest.mkdir(parents=True,exist_ok=False)
 rev=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
 names=subprocess.check_output(['git','ls-tree','-r','--name-only',rev],cwd=root,text=True).splitlines()
 hashes={}
 for name in names:
  path=pathlib.Path(name)
  if path.parts[0] in {'docs','tests','tools','server','addons','build'} or any(v.startswith('.') for v in path.parts):continue
  if name.startswith('scenes/proto/'):continue
  data=subprocess.check_output(['git','show',rev+':'+name],cwd=root)
  if name=='project.godot':
   text=data.decode()
   text='\n'.join(line for line in text.split('\n') if not line.startswith(('MCPScreenshot=','MCPInputService=','MCPGameInspector=')))
   text=re.sub(r'\[editor_plugins\]\s*enabled=.*?\n','',text,flags=re.S)
   data=text.encode()
  target=dest/path;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
  hashes[name]=hashlib.sha256(data).hexdigest()
 (dest.parent/'source-manifest.json').write_text(json.dumps({'revision':rev,'files':hashes,'releaseAdjustments':['Removed development MCP autoloads and editor plugin']},indent=2)+'\n')
 print(f'Prepared {len(hashes)} tracked files from {rev}')
if __name__=='__main__':main()
