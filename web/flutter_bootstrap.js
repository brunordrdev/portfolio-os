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
