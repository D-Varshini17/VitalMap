const fs=require('node:fs'),path=require('node:path'),http=require('node:http'),os=require('node:os');
const {spawn}=require('node:child_process');
const root=path.resolve(__dirname,'../frontend/build/web');
const baseUrl=process.argv[2] || 'http://127.0.0.1:8765/';
const out=path.resolve(__dirname,'../artifacts/ui-audit',process.argv[2] ? 'production' : '.'); fs.mkdirSync(out,{recursive:true});
const misses=[],failures=[],errors=[];
const types={'.html':'text/html','.js':'application/javascript','.json':'application/json','.wasm':'application/wasm','.png':'image/png','.jpeg':'image/jpeg','.woff2':'font/woff2','.ttf':'font/ttf'};
const server=http.createServer((req,res)=>{let url=new URL(req.url,'http://localhost').pathname;let file=path.resolve(root,'.'+decodeURIComponent(url));if(!file.startsWith(root+path.sep)&&file!==root){res.writeHead(403);return res.end();}if(url==='/'||!path.extname(url))file=path.join(root,'index.html');if(!fs.existsSync(file)||!fs.statSync(file).isFile()){misses.push(url);res.writeHead(404);return res.end();}res.setHeader('Content-Type',types[path.extname(file)]||'application/octet-stream');fs.createReadStream(file).pipe(res);});
const delay=ms=>new Promise(r=>setTimeout(r,ms));
(async()=>{
 await new Promise(r=>server.listen(8765,'127.0.0.1',r));
 const profile=fs.mkdtempSync(path.join(os.tmpdir(),'vitalmap-browser-'));
 const chrome=spawn('C:/Program Files/Google/Chrome/Application/chrome.exe',['--headless=new','--disable-gpu','--no-first-run','--remote-debugging-port=9437','--user-data-dir='+profile,'about:blank'],{windowsHide:true,stdio:'ignore'});
 let socket;
 try {
  let targets;for(let i=0;i<60;i++){try{targets=await (await fetch('http://127.0.0.1:9437/json')).json();break;}catch{await delay(250);}}
  if(!targets)throw Error('Chrome debugging endpoint did not start');
  socket=new WebSocket(targets.find(t=>t.type==='page').webSocketDebuggerUrl);
  await new Promise(r=>socket.addEventListener('open',r,{once:true}));
  let id=0;const pending=new Map();
  socket.addEventListener('message',e=>{const m=JSON.parse(e.data);if(m.id){const p=pending.get(m.id);pending.delete(m.id);m.error?p.reject(Error(m.error.message)):p.resolve(m.result);}else if(m.method==='Runtime.exceptionThrown')errors.push(m.params.exceptionDetails.text);else if(m.method==='Network.loadingFailed')failures.push(m.params.errorText);});
  const send=(method,params={})=>new Promise((resolve,reject)=>{pending.set(++id,{resolve,reject});socket.send(JSON.stringify({id,method,params}));});
  await send('Page.enable');await send('Runtime.enable');await send('Network.enable');
  const screenshots=[];
  for(const theme of ['light','dark'])for(const [width,height] of [[390,844],[1440,900]]){
   await send('Emulation.setDeviceMetricsOverride',{width,height,deviceScaleFactor:1,mobile:width<600});
   await send('Emulation.setEmulatedMedia',{features:[{name:'prefers-color-scheme',value:theme}]});
   await send('Page.navigate',{url:baseUrl});await delay(10000);
   await send('Runtime.evaluate',{expression:"document.querySelector('flt-semantics-placeholder')?.click()"});await delay(1000);
   const body=await send('Runtime.evaluate',{expression:'document.body.innerText',returnByValue:true});
   const screenshot=await send('Page.captureScreenshot',{format:'png'});const name=`login-${theme}-${width}.png`;fs.writeFileSync(path.join(out,name),Buffer.from(screenshot.data,'base64'));screenshots.push({name,text:body.result.value});
   if(!body.result.value.includes('Welcome to VitalMap')) throw Error('Login did not render: '+name);
   await send('Runtime.evaluate',{expression:"[...document.querySelectorAll('[role=button]')].find(e=>e.textContent.trim()==='Create account')?.click()"});await delay(1500);
   const signup=await send('Runtime.evaluate',{expression:'document.body.innerText',returnByValue:true});
   const signupImage=await send('Page.captureScreenshot',{format:'png'});const signupName='signup-'+theme+'-'+width+'.png';fs.writeFileSync(path.join(out,signupName),Buffer.from(signupImage.data,'base64'));screenshots.push({name:signupName,text:signup.result.value});
  }
  await send('Page.reload',{ignoreCache:true});await delay(5000);
  const report={screenshots,asset404s:misses,networkFailures:failures,runtimeErrors:errors};fs.writeFileSync(path.join(out,'browser-report.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report,null,2));
 }finally{if(socket)socket.close();chrome.kill();server.close();}
})().catch(e=>{console.error(e);server.close();process.exitCode=1;});