// O service worker do site, escrito à mão.
//
// O do Flutter saiu de cena por dois caminhos ao mesmo tempo, e nenhum deles
// quebrou teste nenhum: o arquivo que o build gera hoje é um toco que se
// desregistra sozinho, e o carregador só encosta em service worker que JÁ
// exista — `loadServiceWorker` sem `serviceWorkerUrl` explícito faz
// `getRegistration()` e desiste se não achar. Para visitante novo, portanto,
// nunca registrou nada. Sem service worker o Chrome não oferece instalar, e
// "PWA instalável" está no escopo da v1.
//
// Este responde offline de verdade: guarda o que já foi baixado e devolve do
// cache quando a rede falha. Quem cobra que ele registra e controla a página
// é `tool/smoke.dart`, no ar — não dá para cobrar isso lendo arquivo.

const CACHE = 'portfolio-os-v1';

// A casca: o mínimo para a primeira tela existir sem rede. O motor e o código
// do app entram no cache conforme forem baixados — pré-carregar 1,7 MB na
// instalação gastaria a banda do visitante duas vezes na primeira visita.
//
// Caminhos relativos de propósito: dentro do worker eles resolvem contra o
// escopo, então o site continua funcionando se um dia for servido de uma
// subpasta.
const SHELL = ['./', './index.html', './manifest.json', './favicon.png', './icons/icon-192.png'];

// O motor (skwasm ou canvaskit) vem do CDN do Google com a revisão do engine
// no caminho: endereço que muda quando o conteúdo muda pode sair do cache
// direto, sem perguntar à rede.
const IMMUTABLE = /^https:\/\/www\.gstatic\.com\/flutter-canvaskit\//;

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches
      .open(CACHE)
      .then((cache) => cache.addAll(SHELL))
      .then(() => self.skipWaiting()),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const names = await caches.keys();
      await Promise.all(names.filter((name) => name !== CACHE).map((name) => caches.delete(name)));
      // Assume a página que já está aberta, em vez de esperar a próxima
      // visita: sem isto, a primeira visita fica sem service worker no ar.
      await self.clients.claim();
    })(),
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;

  const immutable = IMMUTABLE.test(request.url);
  const sameOrigin = new URL(request.url).origin === self.location.origin;
  if (!immutable && !sameOrigin) return;

  event.respondWith(immutable ? cacheFirst(request) : networkFirst(request));
});

// Nada do site tem hash no nome: `main.dart.wasm` hoje é o de hoje e amanhã é
// outro, com o mesmo nome. Servir do cache primeiro prenderia o visitante numa
// versão antiga até o cache vencer. Então a rede manda, e o cache é o chão.
async function networkFirst(request) {
  try {
    const response = await fetch(request);
    if (response.ok && response.type === 'basic') {
      const cache = await caches.open(CACHE);
      await cache.put(request, response.clone());
    }
    return response;
  } catch (error) {
    const cached = await caches.match(request);
    if (cached) return cached;

    // Rota funda sem rede e sem cópia dela mesma: devolve o índice. Quem
    // resolve a rota é o app, e é o que o _redirects já faz no servidor.
    if (request.mode === 'navigate') {
      const index = await caches.match('./index.html');
      if (index) return index;
    }
    throw error;
  }
}

async function cacheFirst(request) {
  const cached = await caches.match(request);
  if (cached) return cached;

  const response = await fetch(request);
  if (response.ok) {
    const cache = await caches.open(CACHE);
    await cache.put(request, response.clone());
  }
  return response;
}
