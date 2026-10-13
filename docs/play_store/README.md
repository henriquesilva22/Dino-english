# Dino English: publicação na Google Play

Este guia reúne o que já está pronto no projeto e o que **depende de você** na Play Console.
Nada foi enviado à Play Console e nenhuma conta foi alterada.

## 1. O que já está pronto (verificado no código e no build)

| Item | Valor |
|---|---|
| applicationId | `com.dinoenglish.dino_english` (não é um ID de exemplo; **não mude depois da 1ª publicação**) |
| Nome no aparelho | Dino English |
| Versão | `1.0.0` (versionCode `1`), em `pubspec.yaml` → `version: 1.0.0+1` |
| targetSdk / compileSdk | 36 (Android 16), que a Play exige desde 31/08/2026 |
| minSdk | 24 (Android 7.0) |
| Formato | Android App Bundle (`.aab`) |
| Assinatura | Chave de **upload** própria (ver seção 3) |
| Ícone | Ícone adaptativo com o Dino 3D real; ícone de 512×512 em `docs/play_store/icon-512.png` |

Para gerar uma nova versão:

```
# 1) suba a versão em pubspec.yaml (o número após "+" deve sempre aumentar)
version: 1.0.1+2
# 2) gere o bundle
flutter build appbundle --release
# -> build/app/outputs/bundle/release/app-release.aab
```

## 2. Permissões e dados (comportamento real do app)

| Permissão | Por quê |
|---|---|
| `RECORD_AUDIO` | Conversar por voz com o Dino. O áudio é transcrito **no próprio aparelho** (Whisper/sherpa-onnx). O áudio nunca é salvo nem enviado. A permissão é pedida em tempo de execução. Se for negada, o app continua funcionando por texto. |
| `INTERNET` | Exigida pelo Android para o servidor **local** (127.0.0.1) que mostra o Dino 3D. O app não acessa servidores externos: o tráfego em texto puro é permitido só para `localhost` (`res/xml/network_security_config.xml`). |

O que fica salvo **somente no aparelho** (banco SQLite local):
- progresso, XP, moedas, sequência (streak) e palavras;
- histórico da conversa com o Dino (o **texto** do que a criança disse/digitou e as respostas);
- memórias do Dino (nome e idade que a criança contar, preferências como "cor favorita");
- o estado do mascote (fome, sede, energia).

O que o app **não** tem: anúncios, compras no app (as moedas são virtuais e ganhas jogando), login, analytics, rastreamento ou SDKs de terceiros que enviem dados.

> **Backup automático do Android:** o `allowBackup` está no padrão do Android (ativado). O Android pode incluir os dados do app no backup do Google Drive **do próprio usuário**. Isso não é coleta pelo desenvolvedor, mas decida se quer manter (o progresso volta ao trocar de celular) ou desativar.

## 3. Assinatura (já configurada neste computador)

- Keystore de upload: `C:\Users\henri\.android\keystores\dino_english_upload.jks` (**fora** do repositório)
- Senhas e alias: em `android/key.properties`, que **não é versionado** (`android/.gitignore`)
- Modelo para outra máquina: `android/key.properties.example`
- Certificado: `CN=Dino English`, válido até 2054. SHA-256 `7E:02:70:6E:48:74:7B:1E:BA:87:B4:CC:76:7F:7C:3D:9F:FD:89:69:35:4E:A3:A3:17:A8:AC:77:C4:63:E3:8F`

**Faça agora um backup** do `.jks` e do `key.properties` em um lugar seguro, como um gerenciador de senhas ou um pendrive guardado. Sem eles você não consegue assinar atualizações (com a Play App Signing é possível pedir a redefinição da chave de upload, mas o processo é demorado).

Na primeira publicação, aceite a **Play App Signing**: o Google guarda a chave final do app e esta chave serve só para o upload.

Sem o `key.properties`, o build de release sai **sem assinatura** (em vez de usar a chave de debug sem avisar).

## 4. O que você precisa definir ou fornecer

- [ ] **Nome público** na loja (sugestão: "Dino English", confirme disponibilidade)
- [ ] **Descrição curta** (até 80 caracteres) e **descrição completa** (rascunhos abaixo; revise)
- [ ] **Capturas de tela reais** (mínimo 2 de celular; recomendado 4 a 8): conversa, comer, brincar, dormir, Pet Adventure, perfil
- [ ] **Imagem de destaque** 1024×500 (feature graphic)
- [ ] **E-mail de suporte** (obrigatório e público)
- [ ] **URL pública da política de privacidade**: publique `privacy_policy_draft.md` revisado (por exemplo, no GitHub Pages) e preencha seus dados de contato
- [ ] **Categoria**: Educação (sugestão)
- [ ] **Questionário de classificação de conteúdo** (IARC)
- [ ] **Público-alvo e faixa etária** (seção 5)
- [ ] **Segurança dos dados (Data safety)**: responda conforme a seção 2 (rascunho na seção 6)
- [ ] **Declaração de anúncios**: "Não contém anúncios"
- [ ] **Permissões sensíveis**: microfone (justificativa: conversa por voz com o mascote, processada no aparelho)

### Rascunhos de texto (revise antes de usar)

**Descrição curta:**
> Aprenda inglês brincando com o Dino: converse, cuide e jogue, tudo offline.

**Descrição completa:**
> Dino English é um companheiro virtual para aprender inglês brincando.
>
> • Converse com o Dino por voz ou texto. Ele fala português e coloca palavras em inglês nas frases. Quer saber o que significa? É só perguntar: "O que é eat?"
> • Cuide do Dino: dê comida e água, brinque de bola e coloque-o para dormir.
> • Estude com sessões curtas e revisão espaçada das palavras.
> • Jogue Pet Adventure, Word Slash e monte frases.
> • Acompanhe nível, XP, moedas, sequência de dias e as palavras para revisar.
>
> Funciona offline: o reconhecimento de voz acontece no próprio aparelho, sem anúncios e sem compras.

## 5. Público infantil (Política para Famílias)

O app tem aparência e conteúdo infantis. Se o público-alvo incluir **menores de 13 anos**, ele entra na **Política para Famílias** da Google Play, que exige:
- política de privacidade clara sobre dados de crianças;
- nenhum SDK de anúncios ou analytics que não seja certificado para famílias (o app não tem nenhum);
- conteúdo adequado à idade;
- declarar corretamente o uso do microfone.

**Você** decide a faixa etária na Play Console. Pelo que foi verificado no código, o app não transmite dados. Confirme isso também se adicionar algum serviço no futuro.

## 6. Rascunho de Segurança dos dados (Data safety)

Com base no comportamento verificado:
- **O app coleta ou compartilha dados?** Não. Os dados ficam só no aparelho e não são enviados ao desenvolvedor nem a terceiros.
- Áudio: processado no aparelho, sem envio ("dados processados apenas no dispositivo" não contam como coleta).
- Criptografia em trânsito: não se aplica (não há transmissão).
- Exclusão: o usuário apaga tudo ao limpar os dados ou desinstalar o app.

## 7. Etapas da conta Google Play (fora do código)

- **Contas pessoais novas** precisam fazer um **teste fechado com pelo menos 12 testadores por 14 dias** antes de liberar a produção. Confira na sua Play Console se isso vale para a sua conta.
- **Verificação de identidade do desenvolvedor**: conclua na Play Console, se for solicitada.
- **Prazo do target API**: o app já usa o target 36. A Google oferece extensão até 01/11/2026 para quem precisar.

## 8. Problemas conhecidos

- **Tablets (Android 16, largura ≥ 600dp):** com target 36, o Android ignora o travamento de orientação em telas grandes. O Pet Adventure trava em paisagem; em tablets pode abrir em retrato. Teste em um tablet ou emulador.
- **Tamanho:** o `.aab` tem cerca de 200 MB (inclui símbolos de depuração e 3 ABIs). O download real por aparelho fica em torno de 110 MB, abaixo do limite de 200 MB do módulo base. Os maiores itens são os modelos de voz (cerca de 72 MB).
- **Olhos ao dormir:** o modelo 3D não tem pálpebras. Enquanto dorme, o Dino aparece deitado com "z Z z" flutuando, mas não fecha os olhos. Para isso seria preciso um modelo com pálpebras ou blendshapes.
- `flutter_tts` usa o Kotlin Gradle Plugin (aviso do Flutter). Funciona hoje, mas vai precisar de atualização do plugin no futuro.
