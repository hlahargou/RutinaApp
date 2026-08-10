// Service Worker para RutinaJGemini
// Estrategia:
//  - Shell (HTML, manifest, íconos, fuentes): Cache First
//  - datos-gemini.json: Network First (para leer última versión sincronizada) con fallback a cache
//  - API del Gist (github.com/api): siempre network, nunca cachear

const CACHE_VERSION = 'rutinajg-v1';
const SHELL_ASSETS = [
  './',
  './rutina-gemini.html',
  './manifest.json',
  './icon-192.png',
  './icon-512.png',
  './icon-maskable-512.png',
  'https://fonts.googleapis.com/css2?family=DM+Mono:wght@400;500&family=Syne:wght@400;600;700&display=swap'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_VERSION).then(cache => {
      // addAll falla si algún recurso falla. Los agrego individualmente para tolerar CDN caído.
      return Promise.all(
        SHELL_ASSETS.map(url =>
          cache.add(url).catch(err => console.warn('No pude cachear:', url, err))
        )
      );
    }).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_VERSION).map(k => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', event => {
  const req = event.request;
  const url = new URL(req.url);

  // No cachear peticiones no GET
  if (req.method !== 'GET') return;

  // Nunca interceptar llamadas a la API de GitHub (Gist)
  if (url.hostname === 'api.github.com') return;

  // Network First para el JSON de datos (queremos la última versión)
  if (url.pathname.endsWith('datos-gemini.json')) {
    event.respondWith(networkFirst(req));
    return;
  }

  // Fuentes de Google: Cache First con actualización en background
  if (url.hostname.includes('fonts.googleapis.com') || url.hostname.includes('fonts.gstatic.com')) {
    event.respondWith(cacheFirst(req));
    return;
  }

  // Todo lo demás dentro del scope: Cache First
  event.respondWith(cacheFirst(req));
});

async function cacheFirst(req) {
  const cached = await caches.match(req);
  if (cached) return cached;
  try {
    const fresh = await fetch(req);
    if (fresh && fresh.status === 200 && fresh.type !== 'opaque') {
      const cache = await caches.open(CACHE_VERSION);
      cache.put(req, fresh.clone());
    }
    return fresh;
  } catch (err) {
    return cached || Response.error();
  }
}

async function networkFirst(req) {
  try {
    const fresh = await fetch(req);
    if (fresh && fresh.status === 200) {
      const cache = await caches.open(CACHE_VERSION);
      cache.put(req, fresh.clone());
    }
    return fresh;
  } catch (err) {
    const cached = await caches.match(req);
    if (cached) return cached;
    throw err;
  }
}
