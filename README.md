# Dino English

Aplicativo interativo para aprender ingles brincando com um companheiro
dinossauro. O projeto foi pensado com uma abordagem **offline first**: as
palavras, o progresso e os dados da experiencia ficam armazenados localmente,
permitindo estudar sem depender de uma conexao constante com a internet.

## O que temos ate o momento

- Tela inicial com acesso aos modos de estudo, provas e minijogos.
- Estudo de palavras em ingles com perguntas de multipla escolha.
- Etapa de apresentacao da palavra e reproducao da pronuncia.
- Modo de revisao em **Provas**, separado do fluxo de estudo.
- Construtor de frases com montagem de palavras e preenchimento de lacunas.
- Minijogo **Word Slash**, no qual o jogador desliza para cortar palavras.
- Aventura do pet em um jogo 2D com coleta de palavras, pontuacao e vidas.
- Batalhas contra chefe com barra de vida e projeteis.
- Sistema de XP, nivel, sequencia de estudos e progresso de dominio.
- Selecao de pets, ovos e evolucao do dinossauro.
- Efeitos sonoros, musica/sons dos jogos e feedback visual das respostas.
- Layout adaptado para retrato no aplicativo e paisagem durante os jogos.

## Tecnologias utilizadas

- **Flutter e Dart** para a aplicacao multiplataforma.
- **Riverpod** para gerenciamento de estado e injecao de dependencias.
- **Drift** e **Drift Flutter** para o banco de dados local.
- **Flame** para a experiencia de jogos 2D.
- **Flame Audio** para os sons dos minijogos.
- **Flutter TTS** para a pronuncia das palavras e frases.
- **Model Viewer Plus** para exibir modelos 3D de ovos e dinossauros.
- **Path Provider**, **Path** e **UUID** para armazenamento local e identificacao
	dos registros.
- **Build Runner** e **Drift Dev** para geracao de codigo do banco.

## Conteudo e recursos

O aplicativo utiliza um banco local inicializado a partir de
`assets/seed/words_seed.json`. Tambem estao incluidos assets de modelos 3D,
personagens, mapas, tiles, cenarios e sons em `assets/`.

A organizacao principal do codigo esta dividida em:

- `lib/screens/`: telas e fluxos da aplicacao.
- `lib/widgets/`: componentes visuais reutilizaveis.
- `lib/core/`: banco local, modelos, repositorios, servicos e fala.
- `lib/game/`: jogos, fases, personagens, efeitos e audio.
- `lib/providers/`: estado e controladores com Riverpod.
- `lib/theme/`: tema visual neon e cores do aplicativo.

## Como executar

### Pre-requisitos

- Flutter instalado e configurado.
- Dart compativel com o SDK definido em `pubspec.yaml`.
- Um dispositivo ou emulador Android, Windows ou outra plataforma suportada
	pelo Flutter.

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

O nucleo da experiencia de estudo e dos minijogos ja esta implementado. O
projeto continua em desenvolvimento, principalmente na ampliacao do conteudo
de palavras e frases, no refinamento da progressao, na adicao de novos pets e
fases e na melhoria geral da experiencia de aprendizagem.

## Objetivo

Tornar o aprendizado de ingles mais pratico e divertido por meio de sessoes
curtas, exercicios interativos, repeticao, audio e uma progressao inspirada
em jogos, mantendo a experiencia acessivel mesmo quando o usuario estiver
offline.
