'use strict';
// Clean server foundation. No mining, players, inventory or other game rules.
const http=require('http'),fs=require('fs'),path=require('path'),crypto=require('crypto'),os=require('os');
const root=__dirname,port=Number(process.env.PORT)||3000;
// One-time removal of old game saves and the updater's old-page backup.
const migration=path.join(root,'server-base-version.json');
if(!fs.existsSync(migration)){
  for(const name of ['player-data.json','player-data.json.tmp','world-data.json','world-data.json.tmp','progress-reset-version.json','index.previous.html']){
    try{fs.unlinkSync(path.join(root,name));}catch(error){if(error.code!=='ENOENT')throw error;}
  }
  fs.writeFileSync(migration,JSON.stringify({version:1}));
}
let html='',version='',stamp=0,updateAt=0;
function load(){
  const file=path.join(root,'index.html'),raw=fs.readFileSync(file,'utf8');
  const next=crypto.createHash('sha256').update(raw).digest('hex');
  if(version&&version!==next)updateAt=Date.now();
  html=raw;version=next;stamp=fs.statSync(file).mtimeMs;
}
load();
const watcher=setInterval(()=>{try{if(fs.statSync(path.join(root,'index.html')).mtimeMs!==stamp)load();}catch(error){console.error('Page update:',error.message);}},500);watcher.unref();
function json(res,status,data){res.writeHead(status,{'Content-Type':'application/json; charset=utf-8'});res.end(JSON.stringify(data));}
const server=http.createServer((req,res)=>{
  res.setHeader('Cache-Control','no-store');res.setHeader('X-Content-Type-Options','nosniff');res.setHeader('Referrer-Policy','same-origin');
  let url;try{url=new URL(req.url,'http://local');}catch{return json(res,400,{error:'Bad URL'});}
  if(req.method!=='GET'&&req.method!=='HEAD')return json(res,404,{error:'Not found'});
  if(url.pathname==='/'||url.pathname==='/index.html'){
    res.writeHead(200,{'Content-Type':'text/html; charset=utf-8'});return res.end(req.method==='HEAD'?'':html.replaceAll('__GAME_VERSION__',version));
  }
  if(url.pathname==='/health')return json(res,200,{ok:true,mode:'server-base'});
  if(url.pathname==='/api/status')return json(res,200,{ok:true,mode:'server-base',serverTime:Date.now()});
  if(url.pathname==='/version'){res.writeHead(200,{'Content-Type':'text/plain; charset=utf-8'});return res.end(version);}
  if(url.pathname==='/update-status')return json(res,200,{version,updateAt,serverTime:Date.now()});
  return json(res,404,{error:'Not found'});
});
server.listen(port,'0.0.0.0',()=>{
  console.log('Server: http://localhost:'+port);
  for(const list of Object.values(os.networkInterfaces()))for(const address of list||[])if(address.family==='IPv4'&&!address.internal)console.log('LAN: http://'+address.address+':'+port);
});
server.on('error',error=>{console.error('Server error:',error.message);process.exitCode=1;});
for(const signal of ['SIGINT','SIGTERM'])process.on(signal,()=>server.close(()=>process.exit(0)));
