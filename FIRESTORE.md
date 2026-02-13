# Firestore – RotinaFit

Estrutura das coleções e uso no app.

## Visão geral

- **Autenticação:** Firebase Auth (e-mail/senha e Google). O login não fica no Firestore; o Firestore guarda só os **dados do usuário** (perfil, medidas, lembretes, água, preferências).
- **Escopo:** Tudo fica sob `users/{uid}/...`. Cada usuário acessa apenas os próprios dados (regras de segurança).

## Coleções e documentos

As coleções são criadas automaticamente ao escrever o primeiro documento. Não é preciso criá-las manualmente no console.

### 1. Perfil do usuário

| Caminho | Tipo | Descrição |
|--------|------|-----------|
| `users/{uid}` | documento | Perfil: `email`, `displayName`, `createdAt`, `updatedAt`. Criado/atualizado no login. |

### 2. Medidas (evolução do corpo)

| Caminho | Tipo | Descrição |
|--------|------|-----------|
| `users/{uid}/measurements/{measurementId}` | subcoleção | Um documento por check-in. Campos: `monthKey`, `weightKg`, `heightCm`, `waistCm`, `hipCm`, etc. (ver `BodyMeasurements.toJson`). |

- **Ordenação:** `monthKey` descendente (meses mais recentes primeiro).
- O `measurementId` é o mesmo `id` do modelo no app.

### 3. Configuração de lembretes

| Caminho | Tipo | Descrição |
|--------|------|-----------|
| `users/{uid}/config/reminders` | documento | Um único doc com a config de lembretes (água, refeições, atividade). Ver `RemindersConfig.toJson`. |

### 4. Preferências (premium, IMC, gordura, água)

| Caminho | Tipo | Descrição |
|--------|------|-----------|
| `users/{uid}/config/preferences` | documento | Um único doc: `premium`, `imcFreeViewedMonth`, `bodyFatUnlockedUntil`, `waterGoalChangeDate`, `waterGoalChangeCount`. |

### 5. Lembretes personalizados

| Caminho | Tipo | Descrição |
|--------|------|-----------|
| `users/{uid}/custom_reminders/{reminderId}` | subcoleção | Um doc por lembrete: `name`, `time`, `days`. |

### 6. Progresso de água

| Caminho | Tipo | Descrição |
|--------|------|-----------|
| `users/{uid}/water_progress/{dateKey}` | subcoleção | Um doc por dia. `dateKey` = `yyyy-MM-dd`. Campos: `goalGlasses`, `currentGlasses`. |

## Comportamento no app

- **Logado:** leitura e gravação vão para o Firestore (por `FirestoreService`). No primeiro carregamento após login, o doc `users/{uid}` é criado/atualizado com e-mail e nome.
- **Deslogado:** uso apenas de `SharedPreferences` (local), via `StorageService`.
- **Login:** após login (e-mail ou Google), o app chama `AppProvider.load()`, que carrega tudo do Firestore para o usuário atual.
- **Logout:** ao abrir a tela de login de novo, o app chama `load()` e passa a usar só dados locais.

## Regras de segurança

Arquivo: `firestore.rules`.

- Apenas usuário autenticado.
- Acesso somente ao próprio `users/{userId}/...`.

Publicar regras:

```bash
firebase deploy --only firestore:rules
```

## Índices

A consulta em `measurements` usa `orderBy('monthKey', descending: true)`. Em muitos casos o Firestore cria o índice sozinho. Se o console pedir um índice, use o link que aparece no erro ou crie em **Firestore > Índices**.
