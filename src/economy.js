export function createEconomy() {
  const keyPrice=1000;
  const storageKey='chest-economy-v1';
  let money=0,keys=0,last=performance.now(),remainder=0,noticeTimer;
  try {const s=JSON.parse(localStorage.getItem(storageKey));if(s&&Number.isSafeInteger(s.money)&&s.money>=0&&Number.isSafeInteger(s.keys)&&s.keys>=0){money=s.money;keys=s.keys;}}catch{}
  const panel=document.createElement('aside');panel.className='economy';panel.setAttribute('aria-label','Деньги и ключи');
  panel.innerHTML='<div class="balance-row"><span class="coin-icon" aria-hidden="true">₽</span><div><span class="stat-caption">ДЕНЬГИ</span><strong id="money-count">0</strong></div><span class="income">+15 / сек</span></div><div class="keys-row"><svg class="key-icon" viewBox="0 0 32 32" aria-hidden="true"><circle cx="10" cy="10" r="6"/><path d="m14.3 14.3 13 13m-4-4 4-4m-8 0 4-4"/></svg><div><span class="stat-caption">КЛЮЧИ</span><strong id="key-count">0</strong></div><button type="button" id="buy-key">Купить · 1 000</button></div><p class="economy-note" role="status">1 открытие — 1 ключ</p>';
  document.body.append(panel);
  const moneyEl=panel.querySelector('#money-count'),keyEl=panel.querySelector('#key-count'),buy=panel.querySelector('#buy-key'),note=panel.querySelector('.economy-note');
  const format=new Intl.NumberFormat('ru-RU');
  function save(){try{localStorage.setItem(storageKey,JSON.stringify({money,keys}));}catch{}}
  function render(){moneyEl.textContent=format.format(money);keyEl.textContent=format.format(keys);buy.disabled=money<keyPrice;buy.title=money<keyPrice?'Нужно 1 000 денег':'Купить один ключ за 1 000 денег';}
  function accrue(now=performance.now()) {
    const elapsed=Math.max(0,now-last);last=now;remainder+=elapsed;
    const seconds=Math.floor(remainder/1000);
    if(seconds){remainder-=seconds*1000;money=Math.min(Number.MAX_SAFE_INTEGER-1000,money+seconds*15);render();save();}
  }
  function message(text){clearTimeout(noticeTimer);note.textContent=text;noticeTimer=setTimeout(()=>{note.textContent='1 открытие — 1 ключ';},2800);}
  buy.addEventListener('click',()=>{accrue();if(money<keyPrice)return;money-=keyPrice;keys++;render();save();message('Ключ куплен');});
  render();setInterval(accrue,250);
  addEventListener('pagehide',()=>{accrue();save();});
  return {consumeKey(){accrue();if(keys<1){message('Купи ключ за 1 000 денег');panel.classList.remove('attention');void panel.offsetWidth;panel.classList.add('attention');return false;}keys--;render();save();return true;},get money(){return money;},get keys(){return keys;}};
}
