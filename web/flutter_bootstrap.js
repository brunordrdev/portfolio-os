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
  // Sem isto o service worker não registra, e sem service worker o Chrome não
  // oferece instalar. O bootstrap padrão passa isto; ao trocá-lo por um
  // próprio, a linha veio junto — de graça não vem.
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
});
