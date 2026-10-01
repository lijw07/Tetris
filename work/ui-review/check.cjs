const {chromium}=require('/Users/jaili/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('fs');
(async()=>{
const b=await chromium.launch({headless:true,executablePath:'/Users/jaili/Library/Caches/ms-playwright/chromium_headless_shell-1228/chrome-headless-shell-mac-arm64/chrome-headless-shell'});
const p=await b.newPage({viewport:{width:1200,height:1000}}),errors=[];p.on('pageerror',e=>errors.push(e.message));
await p.goto('file:///Users/jaili/projects/godot/Tetris/outputs/simple-ui-v3/preview.html');
for(const name of ['main menu','pause','settings','game over','how to play','restart confirm']){await p.getByRole('button',{name,exact:true}).click();await p.locator('#screen').evaluate(i=>i.decode());}
await p.getByRole('button',{name:'main menu',exact:true}).click();
const audio=await p.locator('audio').evaluate(async a=>{await a.play();const data={duration:a.duration,playing:!a.paused};a.pause();return data});
await p.setViewportSize({width:390,height:844});
const width=await p.evaluate(()=>({viewport:innerWidth,content:document.documentElement.scrollWidth}));
await p.screenshot({path:'/Users/jaili/projects/godot/Tetris/work/ui-review/mobile.png',fullPage:true});
const results={errors,screens_checked:6,audio,mobile:width};
fs.writeFileSync('/Users/jaili/projects/godot/Tetris/work/ui-review/browser-validation.json',JSON.stringify(results,null,2));console.log(JSON.stringify(results));await b.close();
if(errors.length||!audio.playing||width.content>width.viewport)process.exit(1);
})().catch(e=>{console.error(e);process.exit(1)});
