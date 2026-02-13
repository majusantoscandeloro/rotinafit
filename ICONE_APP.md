# Onde colocar a logo para usar como ícone do app

- **Ícone do app (launcher)** — o que aparece na tela inicial do celular: **`assets/icon/rotinafitsemicone.png`**. Só é usado para gerar os ícones do Android e iOS (rode `dart run flutter_launcher_icons` ao trocar).
- **Logo nas telas** — login, AppBar da home e Premium: **`assets/icon/icon.png`**.

Você pode usar **uma única imagem** da sua logo e gerar todos os tamanhos automaticamente, ou substituir manualmente os arquivos em cada pasta.

---

## Opção 1: Automático (recomendado) — uma imagem gera todos os ícones

1. **Coloque a sua logo** em um arquivo PNG (quadrado, ex.: **1024×1024 px**) na raiz do projeto, por exemplo:
   ```
   d:\APPs\rotinafit\assets\icon\icon.png
   ```
   (crie a pasta `assets/icon` se não existir.)

2. Instale e use o pacote **flutter_launcher_icons**:
   ```bash
   dart pub global activate flutter_launcher_icons
   flutter pub add dev:flutter_launcher_icons
   ```
   No `pubspec.yaml`, adicione na raiz (fora de `dependencies`):
   ```yaml
   flutter_launcher_icons:
     android: true
     ios: true
     image_path: "assets/icon/icon.png"
     # opcional: adaptive_icon_background: "#0EA5E9"
     # opcional: adaptive_icon_foreground: "assets/icon/icon.png"
   ```
   Depois rode:
   ```bash
   dart run flutter_launcher_icons
   ```
   Isso substitui todos os ícones do Android e do iOS.

---

## Opção 2: Manual — onde está cada ícone

### Android

O ícone do app é o **ic_launcher**. Substitua os PNGs nestas pastas (mantendo o nome `ic_launcher.png`):

| Pasta | Caminho completo | Tamanho sugerido |
|-------|------------------|------------------|
| mdpi  | `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`   | 48×48 px  |
| hdpi  | `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`   | 72×72 px  |
| xhdpi | `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`  | 96×96 px  |
| xxhdpi| `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` | 144×144 px |
| xxxhdpi | `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` | 192×192 px |

Ou seja: coloque a sua logo em cada arquivo **`ic_launcher.png`** dentro de:
```
android/app/src/main/res/mipmap-XXX/ic_launcher.png
```

### iOS

Os ícones ficam em:
```
ios/Runner/Assets.xcassets/AppIcon.appiconset/
```
Substitua os arquivos `Icon-App-...png` pelos mesmos nomes, com a sua logo nos tamanhos corretos (20, 29, 40, 60, 76, 83.5 e 1024 pt, em 1x, 2x e 3x conforme o `Contents.json`). O mais importante é ter **Icon-App-1024x1024@1x.png** (1024×1024 px) para a App Store.

---

## Resumo

- **Só uma imagem (ex.: 1024×1024):** use a **Opção 1** com `flutter_launcher_icons` e coloque a logo em `assets/icon/icon.png`.
- **Manual:** substitua os `ic_launcher.png` em cada `mipmap-*` no Android e os PNGs em `AppIcon.appiconset` no iOS.
