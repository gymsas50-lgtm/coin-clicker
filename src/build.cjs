'use strict';
const fs=require('fs'),path=require('path'),esbuild=require('esbuild');
const root=path.resolve(__dirname,'..');
(async()=>{
 const built=await esbuild.build({entryPoints:[path.join(__dirname,'case-three.js')],bundle:true,minify:true,format:'iife',platform:'browser',target:'es2020',write:false,legalComments:'eof',nodePaths:(process.env.NODE_PATH||'').split(path.delimiter).filter(Boolean)});
 const js=built.outputFiles[0].text.replace(/<\/script/gi,'<\\/script');
 const license=fs.readFileSync(path.join(__dirname,'THREE-LICENSE.txt'),'utf8');
 const html=fs.readFileSync(path.join(__dirname,'page.html'),'utf8').replace('/*__BUNDLE__*/',()=>js).replace('</head>',()=>'<'+ '!-- Three.js license\n'+license+' --'+ '></head>');
 if(!html.includes('<meta name="app-id" content="arena-coin-clicker">'))throw Error('Updater marker missing');
 fs.writeFileSync(path.join(root,'index.html'),html);
 console.log('Built self-contained Three.js page: '+Math.round(Buffer.byteLength(html)/1024)+' KiB');
})().catch(error=>{console.error(error);process.exit(1);});
