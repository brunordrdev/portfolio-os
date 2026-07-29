// Carrega o Flutter dentro de #stage, e não no body.
//
// É o que permite a moldura: acima do ponto de quebra o CSS dá a essa caixa o
// tamanho de um celular e o texto fica ao lado, indexável; abaixo dele a caixa
// ocupa a tela inteira. O Dart não sabe de nada disso — quem decide é o CSS.
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: {
    hostElement: document.querySelector('#stage'),
  },
});

// O service worker é nosso, e o registro é aqui.
//
// Aqui havia um `serviceWorkerSettings` passado ao carregador do Flutter, com
// um comentário dizendo que sem ele o Chrome não oferece instalar. A intenção
// estava certa e o efeito era zero: sem `serviceWorkerUrl` explícito, o
// carregador só atualiza registro que já exista, e para visitante novo nunca
// registrava nada. O arquivo que o build gera virou um toco que se desregistra
// sozinho. Nada disso quebrava teste: o teste lia a string no arquivo.
//
// Depois de `load` de propósito: registrar antes disputa banda com o motor,
// que é o que o visitante está esperando. E resolvido contra `document.baseURI`
// porque `register('sw.js')` numa rota funda pediria `/sobre/sw.js`.
window.addEventListener('load', function () {
  if (!('serviceWorker' in navigator)) return;
  navigator.serviceWorker.register(new URL('sw.js', document.baseURI).href).catch(function (error) {
    console.warn('service worker não registrou:', error);
  });
});
