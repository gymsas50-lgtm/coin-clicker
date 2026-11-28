const fs=require('node:fs'),path=require('node:path');
fs.copyFileSync(path.join(__dirname,'page.html'),path.join(__dirname,'../index.html'));
console.log('Built blank white page');
