const CACHE = "business360-v47";
const APP_SHELL = [
  './',
  './index.html',
  './manifest.json',
  './icons/icon-192.png',
  './icons/icon-512.png'
];

self.addEventListener('install', event => {
  event.waitUntil(caches.open(CACHE).then(c => c.addAll(APP_SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener('message', event => { if(event.data?.type==='SKIP_WAITING') self.skipWaiting(); });

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', event => {
  if (event.request.method !== 'GET') return;
  const url = new URL(event.request.url);
  if (url.origin !== location.origin) return;
  const isHtml = event.request.mode === 'navigate' || url.pathname.endsWith('/index.html') || url.pathname.endsWith('/');
  event.respondWith(
    isHtml ? fetch(event.request).then(response => { caches.open(CACHE).then(c => c.put(event.request, response.clone())); return response; }).catch(() => caches.match(event.request).then(r => r || caches.match('./index.html')))
           : caches.match(event.request).then(cached => cached || fetch(event.request).then(response => { caches.open(CACHE).then(c => c.put(event.request, response.clone())); return response; }))
  );
});
