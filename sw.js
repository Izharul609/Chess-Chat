const C='chess-chat-v3';
self.addEventListener('install',e=>{self.skipWaiting();e.waitUntil(caches.open(C).then(c=>c.addAll(['./','./index.html'])))});
self.addEventListener('activate',e=>e.waitUntil(clients.claim()));
self.addEventListener('fetch',e=>{if(e.request.mode==='navigate')e.respondWith(fetch(e.request).catch(()=>caches.match('./index.html')))});
// Background notifications (sent by the "push" Supabase function)
self.addEventListener('push',e=>{
  let d={};try{d=e.data.json()}catch(_){}
  e.waitUntil(clients.matchAll({type:'window',includeUncontrolled:true}).then(l=>{
    if(l.some(c=>c.visibilityState==='visible'))return; // app is open on screen, no need
    return self.registration.showNotification(d.title||'Chess Enthusiasts',{body:d.body||'New message',icon:'icon-192.png',badge:'icon-192.png',tag:d.tag||'chat',renotify:true})}))});
self.addEventListener('notificationclick',e=>{e.notification.close();
  e.waitUntil(clients.matchAll({type:'window',includeUncontrolled:true}).then(l=>l.length?l[0].focus():clients.openWindow('./')))});
