const CACHE = 'geirfa-v14';
const PRECACHE = ['./index.html', './vocabulary.json', './favicon.svg', './apple-touch-icon.png', './manifest.json'];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE).then(cache => cache.addAll(PRECACHE))
  );
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', e => {
  // The techiaith Orpheus-TTS endpoint is POST-based, which the Cache API
  // cannot store, so we let those requests pass straight through to the
  // network and rely on the page's in-memory blob cache to avoid refetches
  // within a session.
  if (e.request.method !== 'GET') return;
  e.respondWith(
    caches.match(e.request).then(cached => cached || fetch(e.request))
  );
});
