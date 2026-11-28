'use strict';
const {app,BrowserWindow,dialog,shell}=require('electron');
const fs=require('node:fs'),path=require('node:path'),https=require('node:https'),http=require('node:http'),crypto=require('node:crypto');
const marker='<meta name="app-id" content="arena-coin-clicker">';
let win,server,timer,busy=false,html='',hash='',cache;
const digest=s=>crypto.createHash('sha256').update(s).digest('hex');
function valid(s){return typeof s==='string'&&s.includes(marker)&&s.trimEnd().endsWith('</html>');}
function get(url){return new Promise((resolve,reject)=>{
 const req=https.get(url,{headers:{'User-Agent':'ChestDesktop/1.0','Cache-Control':'no-cache'}},res=>{
  if(res.statusCode!==200){res.resume();reject(new Error('HTTP '+res.statusCode));return;}
  let size=0;const chunks=[];res.on('data',c=>{size+=c.length;if(size>8e6)res.destroy(new Error('Too large'));else chunks.push(c);});
  res.on('end',()=>resolve(Buffer.concat(chunks).toString('utf8')));res.on('error',reject);
 });req.setTimeout(8000,()=>req.destroy(new Error('Timeout')));req.on('error',reject);
});}
async function update(){
 if(busy)return;busy=true;
 try{
  const fresh=await get('https://raw.githubusercontent.com/gymsas50-lgtm/coin-clicker/main/index.html');
  if(!valid(fresh))throw new Error('Invalid page');
  const next=digest(fresh);if(next===hash)return;
  const tmp=cache+'.tmp';fs.writeFileSync(tmp,fresh,'utf8');fs.renameSync(tmp,cache);
  html=fresh;hash=next;
 }catch{/* Offline: keep the last valid game. */}finally{busy=false;}
}
if(!app.requestSingleInstanceLock())app.quit();
else{
 app.on('second-instance',()=>{if(win){if(win.isMinimized())win.restore();win.focus();}});
 app.whenReady().then(()=>{
  cache=path.join(app.getPath('userData'),'game.html');
  const fallback=fs.readFileSync(path.join(__dirname,'index.html'),'utf8');
  try{const saved=fs.readFileSync(cache,'utf8');html=valid(saved)?saved:fallback;}catch{html=fallback;}
  hash=digest(html);
  server=http.createServer((req,res)=>{
   res.setHeader('Cache-Control','no-store');res.setHeader('X-Content-Type-Options','nosniff');
   if(req.url==='/'||req.url==='/index.html'){
    res.writeHead(200,{'Content-Type':'text/html; charset=utf-8','Content-Security-Policy':"default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; img-src data: blob:; connect-src 'self'; font-src data:; worker-src blob:;"});
    res.end(html.replaceAll('__GAME_VERSION__',hash));
   }else if(req.url==='/version'){res.writeHead(200,{'Content-Type':'text/plain'});res.end(hash);}
   else if(req.url?.startsWith('/update-status')){res.writeHead(200,{'Content-Type':'application/json'});res.end(JSON.stringify({version:hash}));}
   else{res.writeHead(404);res.end();}
  });
  server.listen(0,'127.0.0.1',()=>{
   const local='http://127.0.0.1:'+server.address().port;
   win=new BrowserWindow({width:1280,height:900,minWidth:640,minHeight:480,title:'Сундук',backgroundColor:'#101215',autoHideMenuBar:true,webPreferences:{nodeIntegration:false,contextIsolation:true,sandbox:true,webSecurity:true}});
   win.setMenu(null);win.webContents.setWindowOpenHandler(()=>({action:'deny'}));
   win.webContents.on('will-navigate',(event,url)=>{if(!url.startsWith(local+'/'))event.preventDefault();});
   win.webContents.session.setPermissionRequestHandler((_wc,_permission,cb)=>cb(false));
   win.loadURL(local+'/');
   update();timer=setInterval(update,15000);
  });
 }).catch(error=>{dialog.showErrorBox('Не удалось открыть сундук',error.message);app.quit();});
 app.on('window-all-closed',()=>app.quit());
 app.on('before-quit',()=>{clearInterval(timer);server?.close();});
}
