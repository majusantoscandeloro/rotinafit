# RotinaFit

**Lembretes + acompanhamento do corpo num lugar só.**

App Flutter (Dart) para iOS e Android (incl. iPad): lembretes de água, alimentação e atividade física; lembretes personalizados; registro de medidas corporais; IMC; resultados com gráficos; e modelo freemium com assinatura Premium.

## Telas

1. **Login** – E-mail/senha e Google (Firebase Auth).
2. **Home** – Cards: Água (meta + progresso), Alimentação, Atividade física, Lembretes personalizados, Medidas, Resultados e (se free) Conheça o Premium. Versão do app exibida no rodapé.
3. **Lembretes** – Horários de água; café/almoço/jantar/lanche/ceia; dias e horário de atividade; toggle para ativar notificações.
4. **Água** – Meta do dia (copos 200 ml), progresso e botões +/-.
5. **Alimentação** – Lembretes de refeições (configuração por horário).
6. **Atividade física** – Dias e horários de atividade.
7. **Lembretes personalizados** – Lista de lembretes customizados (ex.: Tomar creatina 5g).
8. **Medidas** – Peso, altura, cintura, quadril, peito, braço, coxa; opcional: pescoço, panturrilha. Check-in do mês.
9. **Resultados** – IMC; evolução e comparação com mês anterior; gráficos por medida; Histórico (preview no free, ilimitado no Premium).
10. **Premium** – Assinatura mensal ou anual (in-app purchase); sem anúncios, histórico completo e gráficos.

## Freemium

- **Free (com anúncios)**: Lembretes, água, medidas, IMC, resultados do mês atual; histórico com preview limitado; banner e intersticial.
- **Premium (assinatura)**: Sem anúncios, histórico ilimitado, comparação automática e gráficos. Produtos: `rotinafit_premium_monthly` e `rotinafit_premium_yearly` (configurar no App Store Connect e Google Play Console).

## Como rodar

```bash
cd rotinafit
flutter pub get
flutter run
```

Para Android: `flutter run -d android`  
Para iOS (mac): `flutter run -d ios`

## Produção

- **Firebase**: Configurar projeto no Firebase (Auth e Firestore), colocar `google-services.json` (Android) e `GoogleService-Info.plist` (iOS), e gerar `firebase_options.dart` com FlutterFire CLI.
- **Anúncios**: Trocar IDs em `lib/services/ads_service.dart` pelos Ad Unit IDs do AdMob; configurar no `AndroidManifest.xml` e no `Info.plist` conforme o Google Mobile Ads.
- **In-app purchase**: Criar os produtos de assinatura (`rotinafit_premium_monthly`, `rotinafit_premium_yearly`) no App Store Connect e na Play Console. O fluxo real está em `lib/services/iap_service.dart` e na `PremiumScreen` em `lib/screens/results_screen.dart`.
- **App Tracking Transparency (iOS)**: Já integrado em `lib/services/att_service.dart`; configurar a chave no `Info.plist` conforme a documentação.

## Estrutura

- `lib/main.dart` – Entrada e `RotinaFitApp`.
- `lib/screens/` – Login, Home, Lembretes, Água, Alimentação, Atividade, Lembretes personalizados, Medidas, Resultados (Histórico e Premium), Debug.
- `lib/widgets/` – `HomeCard` e outros componentes reutilizáveis.
- `lib/models/` – BodyMeasurements, RemindersConfig, WaterProgress, CustomReminder.
- `lib/providers/` – AppProvider (estado global), AuthProvider.
- `lib/services/` – Storage, notificações locais, anúncios, IAP, ATT, Firebase (Auth, Firestore).
- `lib/utils/` – app_version, responsive (layout iPhone/iPad), evolution_config.
- `lib/theme/app_theme.dart` – Tema claro/escuro.
