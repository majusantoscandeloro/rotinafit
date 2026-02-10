# Changelog

Todas as mudanças notáveis do RotinaFit são documentadas aqui.

## [1.0.1+2] - 2025-02-10

### Adicionado
- Suporte completo para **iOS**: app configurado para rodar em iPhone e iPad.
- Configuração AdMob no iOS: `GADApplicationIdentifier`, `SKAdNetworkItems` no `Info.plist`.
- Notificações locais no iOS: `DarwinNotificationDetails` em todos os lembretes (água, refeições, atividade, personalizados).
- Ad Unit IDs de teste específicos para iOS no `AdsService` (banner, intersticial, rewarded).
- `UIBackgroundModes` com `remote-notification` para notificações em background no iOS.

### Alterado
- Versão: `1.0.0+1` → `1.0.1+2`.

---

## [1.0.0+1] - Versão inicial

- MVP: Home, Lembretes, Medidas, Resultados.
- Lembretes de água, refeições, atividade física e personalizados.
- Medidas corporais e IMC.
- Modelo freemium: anúncios (AdMob), Premium, remoção de anúncios.
- Suporte Android.
