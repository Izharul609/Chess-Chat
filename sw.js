const C='chess-chat-v1';
self.addEventListener('install',e=>{self.skipWaiting();e.waitUntil(caches.open(C).then(c=>c.addAll(['./','./index.html'])))});
self.addEventListener('activate',e=>e.waitUntil(clients.claim()));
self.addEventListener('fetch',e=>{if(e.request.mode==='navigate')e.respondWith(fetch(e.request).catch(()=>caches.match('./index.html')))});
