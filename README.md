# Dino English

Aplicativo interativo para aprender **inglês** brincando com um companheiro dinossauro. O projeto foi pensado com uma abordagem **offline-first**: as palavras, o progresso e os dados da experiência ficam armazenados localmente, permitindo estudar sem depender de uma conexão constante com a internet.

## O que temos até o momento

* Tela inicial com acesso aos modos de estudo, provas e minijogos.
* Estudo de palavras em inglês com perguntas de múltipla escolha.
* Etapa de apresentação da palavra e reprodução da pronúncia.
* Modo de revisão em **Provas**, separado do fluxo de estudo.
* Construtor de frases com montagem de palavras e preenchimento de lacunas.
* Minijogo **Word Slash**, no qual o jogador desliza para cortar palavras.
* Aventura do pet em um jogo 2D com coleta de palavras, pontuação e vidas.
* Batalhas contra chefes com barra de vida e projéteis.
* Sistema de XP, nível, sequência de estudos e progresso de domínio.
* Seleção de pets, ovos e evolução do dinossauro.
* Efeitos sonoros, música/sons dos jogos e feedback visual das respostas.
* Layout adaptado para retrato no aplicativo e paisagem durante os jogos.

## Tecnologias utilizadas

* **Flutter e Dart** para a aplicação multiplataforma.
* **Riverpod** para gerenciamento de estado e injeção de dependências.
* **Drift** e **Drift Flutter** para o banco de dados local.
* **Flame** para a experiência de jogos 2D.
* **Flame Audio** para os sons dos minijogos.
* **Flutter TTS** para a pronúncia das palavras e frases.
* **Model Viewer Plus** para exibir modelos 3D de ovos e dinossauros.
* **Path Provider**, **Path** e **UUID** para armazenamento local e identificação dos registros.
* **Build Runner** e **Drift Dev** para geração de código do banco.

## Conteúdo e recursos

O aplicativo utiliza um banco local inicializado a partir de `assets/seed/words_seed.json`. Também estão incluídos assets de modelos 3D, personagens, mapas, tiles, cenários e sons em `assets/`.

A organização principal do código está dividida em:

* `lib/screens/`: telas e fluxos da aplicação.
* `lib/widgets/`: componentes visuais reutilizáveis.
* `lib/core/`: banco local, modelos, repositórios, serviços e fala.
* `lib/game/`: jogos, fases, personagens, efeitos e áudio.
* `lib/providers/`: estado e controladores com Riverpod.
* `lib/theme/`: tema visual neon e cores do aplicativo.

## Como executar

### Pré-requisitos

* Flutter instalado e configurado.
* Dart compatível com o SDK definido em `pubspec.yaml`.
* Um dispositivo ou emulador Android, Windows ou outra plataforma suportada pelo Flutter.

### Comandos

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Para executar os testes:

```bash
flutter test
```

## Estado do projeto

O núcleo da experiência de estudo e dos minijogos já está implementado. O projeto continua em desenvolvimento, principalmente na ampliação do conteúdo de palavras e frases, no refinamento da progressão, na adição de novos pets e fases e na melhoria geral da experiência de aprendizagem.

## Objetivo

Tornar o aprendizado de inglês mais prático e divertido por meio de sessões curtas, exercícios interativos, repetição, áudio e uma progressão inspirada em jogos, mantendo a experiência acessível mesmo quando o usuário estiver offline.

