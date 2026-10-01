const fs=require('fs'),path=require('path'),sharp=require('sharp');
const root=path.resolve(__dirname,'..');
async function render(dir){for(const e of fs.readdirSync(dir,{withFileTypes:true})){const p=path.join(dir,e.name);if(e.isDirectory())await render(p);else if(p.endsWith('.svg'))await sharp(p).png().toFile(p.replace(/\.svg$/,'.png'));}}
render(root).then(()=>console.log('PNG exports ready')).catch(e=>{console.error(e);process.exit(1)});
