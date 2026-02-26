# Como funciona a assinatura Premium (explicação simples)

## O que você quer

- **Mês 1:** a pessoa assina → tem Premium (sem anúncios, tudo liberado).
- **Mês 2:** ela não renova (ou cancela) → volta a ser Free (com anúncios, limites).

Ou seja: o app precisa **saber quando a assinatura acabou** para tirar o Premium.

---

## Como o app sabe se a pessoa é Premium?

Hoje o app guarda no **Firestore** (e no celular em cache):

- `isPremium`: true ou false
- `premiumUntil`: **data em que a assinatura acaba** (ex.: 2025-03-15)

A regra que já está no código é:

- Se **hoje < premiumUntil** → a pessoa é Premium.
- Se **hoje ≥ premiumUntil** (ou a data já passou) → a pessoa **não** é mais Premium; o app trata como Free e volta a mostrar anúncios.

Quando o app abre, ele lê isso e, se `premiumUntil` já passou, **marca Premium como false** sozinho. Ou seja: **a lógica “mês 1 sim, mês 2 não” já está preparada no app.**

---

## O que está faltando hoje

Quando a pessoa **compra** a assinatura, o app só consegue saber:

- “Ela comprou” (a loja devolve isso).
- **Não** devolve no app, de forma simples, a **data em que a assinatura termina** (ex.: fim do mês, fim do ano).

Por isso hoje a gente **não grava** `premiumUntil` na compra. Fica assim:

- Comprou → guardamos `isPremium = true`, mas `premiumUntil` fica vazio.
- Com `premiumUntil` vazio, o app trata como “Premium sem data de fim” → na prática a pessoa continua Premium até alguém mudar no backend ou você mudar à mão.

Resumindo: **o app já sabe “desligar” o Premium quando a data passou; o que falta é alguém preencher essa data (`premiumUntil`) quando a pessoa assina (e quando renova ou cancela).**

---

## Quem pode preencher a data de fim? (premiumUntil)

Quem tem a informação correta de “até quando vale a assinatura” são as **lojas** (Google Play e App Store). O app sozinho não recebe isso de forma confiável. Por isso precisa de um **serviço no meio** que fale com as lojas e atualize o Firestore.

Duas formas comuns:

### 1) Backend (Cloud Function ou servidor)

- Quando a pessoa **compra ou restaura**, o app manda o “comprovante” (token/receipt) para **sua Cloud Function** (ou outro backend).
- A Cloud Function:
  - pergunta à **Google Play** ou à **App Store**: “essa compra é válida? Até quando?”
  - recebe a data de fim da assinatura.
  - grava no Firestore: `isPremium = true` e `premiumUntil = essa data`.

Assim, no **mês 2**, quando a pessoa não renovar:

- A data que está em `premiumUntil` já terá passado.
- Na próxima vez que ela abrir o app, o app lê do Firestore, vê que `hoje >= premiumUntil` e **marca como Free** sozinho.

Ou seja: **com backend preenchendo `premiumUntil`, o app já consegue ver que “comprou 1 mês e no outro não”** e tirar o Premium.

### 2) Notificações das lojas (recomendado junto com o backend)

- **Android:** Real-time Developer Notifications – o Google avisa seu backend quando a assinatura renova, cancela ou expira.
- **iOS:** App Store Server Notifications – a Apple avisa quando renova ou cancela.

Seu backend (ex.: Cloud Function) recebe esse aviso e atualiza o Firestore (por exemplo coloca `premiumUntil` no passado ou `isPremium = false`). No próximo abrir do app, ele já vê que não é mais Premium.

---

## Resumindo em uma frase

- **O app já “vê” que a pessoa não renovou** desde que exista uma **data de fim** (`premiumUntil`) no Firestore.
- **Hoje essa data não é preenchida** na compra, porque isso exige falar com a Google/Apple (via backend).
- **Quando você tiver um backend** (por exemplo Cloud Function) que valide a compra com a loja e grave `premiumUntil` (e, se quiser, escute as notificações de cancelamento/expiração), o app **já está pronto** para tratar “mês 1 comprou, mês 2 não” e desativar o Premium sozinho ao abrir.

Se quiser, no próximo passo podemos desenhar o fluxo “compra → backend → Firestore → app abre e vê que expirou” em um diagrama ou checklist de implementação.
