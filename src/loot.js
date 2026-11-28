export const lootTable=[{id:'key',name:'Ключ',chance:10,icon:'⚿'},{id:'wood',name:'Деревянный меч',chance:50,icon:'⚔'},{id:'stone',name:'Каменный меч',chance:25,icon:'⚔'},{id:'iron',name:'Железный меч',chance:15,icon:'⚔'}];
export function selectLoot(roll=Math.random()) {let threshold=0;for(const item of lootTable){threshold+=item.chance;if(roll*100<threshold)return item;}return lootTable[3];}
export function createLoot(economy){
  const storageKey='chest-loot-v1';let counts={wood:0,stone:0,iron:0};
  try{const saved=JSON.parse(localStorage.getItem(storageKey));for(const id of Object.keys(counts))if(Number.isSafeInteger(saved?.[id])&&saved[id]>=0)counts[id]=saved[id];}catch{}
  const inventory=document.createElement('aside');inventory.className='loot-inventory';inventory.setAttribute('aria-label','Добыча');
  inventory.innerHTML='<div class="loot-heading">ДОБЫЧА</div>'+lootTable.filter(i=>i.id!=='key').map(i=>`<div class="loot-row ${i.id}"><svg viewBox="0 0 28 28" aria-hidden="true"><path d="M8 19 21 3l4 0 0 4-15 14m-5-5 8 8M3 25l5-6"/></svg><span>${i.name}</span><strong data-count="${i.id}">0</strong></div>`).join('');
  document.body.append(inventory);
  function render(){for(const id of Object.keys(counts))inventory.querySelector(`[data-count="${id}"]`).textContent=new Intl.NumberFormat('ru-RU').format(counts[id]);}
  render();
  return {get counts(){return {...counts};},award(){
    const item=selectLoot();
    if(item.id==='key')economy.addKeys(1);else{counts[item.id]++;try{localStorage.setItem(storageKey,JSON.stringify(counts));}catch{}render();}
    return item;
  }};
}
