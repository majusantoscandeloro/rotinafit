# RotinaFit

**Lembretes + acompanhamento do corpo num lugar só.**

App Flutter (Dart) para iOS e Android: lembretes de água, alimentação e atividade física; registro de medidas corporais; IMC; e resultados com modelo freemium.

## Telas (MVP)

1. **Home** – Cards: Água (meta + progresso), Alimentação, Atividade física, Medidas, IMC.
2. **Lembretes** – Horários de água; café/almoço/jantar/lanche; dias e horário de atividade; toggle "Ativar notificações".
3. **Medidas e composição** – Peso, altura, cintura, quadril, peito, braço, coxa; opcional: pescoço, panturrilha. Botão "Salvar check-in do mês".
4. **Resultados** – IMC; comparação com mês anterior (Premium); gráfico mês a mês (Premium); tela Histórico com preview + cadeado no free.

## Freemium

- **Free + anúncios**: Lembretes, IMC, medidas do mês atual; histórico com preview e bloqueio; banner + intersticial (ex.: ao salvar check-in).
- **Premium (assinatura)**: Sem anúncios, histórico ilimitado, comparação automática, gráficos.
- **Remoção de anúncios (pagamento único)**: Só remove anúncios; histórico mês a mês continua no Premium.

## Como rodar

```bash
cd d:\APPs\rotinafit
flutter pub get
flutter run
```

Para Android: `flutter run -d android`  
Para iOS (mac): `flutter run -d ios`

## Produção

- **Anúncios**: Trocar IDs em `lib/services/ads_service.dart` pelos seus Ad Unit IDs do AdMob e inicializar o SDK no `AndroidManifest.xml` / `Info.plist` conforme a documentação do Google Mobile Ads.
- **In-app purchase**: Conectar `in_app_purchase` aos produtos de assinatura e compra única nas lojas (Google Play / App Store) e substituir os botões "simulado" em `lib/screens/results_screen.dart` (PremiumScreen) pela compra real.

## Estrutura

- `lib/main.dart` – Entrada e `RotinaFitApp`.
- `lib/screens/` – Home, Lembretes, Medidas, Resultados (incl. Histórico e Premium).
- `lib/models/` – BodyMeasurements, RemindersConfig, WaterProgress.
- `lib/providers/app_provider.dart` – Estado global (medidas, lembretes, água, premium/ads).
- `lib/services/` – Storage, notificações locais, anúncios.
- `lib/theme/app_theme.dart` – Tema claro/escuro.
