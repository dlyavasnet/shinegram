<div align="center">

<img src="shine/readme/banner.svg" alt="ShineGram" width="100%">

<br>

[![macOS](https://img.shields.io/badge/macOS-10.13%2B-b9b8ff?style=for-the-badge&logo=apple&logoColor=white&labelColor=0b0a12)](#-установка)
[![Build](https://img.shields.io/github/actions/workflow/status/dlyavasnet/shinegram/build.yml?style=for-the-badge&label=build&labelColor=0b0a12&color=7dffb2)](https://github.com/dlyavasnet/shinegram/actions/workflows/build.yml)
[![License](https://img.shields.io/badge/license-GPL--2.0-9d7bff?style=for-the-badge&labelColor=0b0a12)](LICENSE)
[![Channel](https://img.shields.io/badge/канал-@dlyavasnet-7fe3ff?style=for-the-badge&logo=telegram&logoColor=white&labelColor=0b0a12)](https://t.me/dlyavasnet)

```text
  ┌──────────────────────────────────────────────────────────────┐
  │ клиент для macOS на исходниках Telegram, с функциями AyuGram │
  │  читай тихо · смотри анонимно · ничего не теряй              │
  └──────────────────────────────────────────────────────────────┘
```

</div>

<img src="shine/readme/divider.svg" width="100%">

## `$ shinegram --features`

<div align="center">
<img src="shine/readme/features.svg" alt="features" width="100%">
</div>

<img src="shine/readme/divider.svg" width="100%">

## `$ shinegram ghost --on`

<table>
<tr>
<td width="200" align="center">
<img src="shine/readme/ghost.svg" alt="ghost" width="170">
</td>
<td>

```console
$ shinegram ghost --status
  read_receipts   ░░░░░░░░░░  hidden
  online          ░░░░░░░░░░  hidden
  typing          ░░░░░░░░░░  hidden
  stories         ░░░░░░░░░░  hidden
  voice_played    ░░░░░░░░░░  hidden
  send_scheduled  ██████████  +12s
> ghost mode: ACTIVE 👻
```

</td>
</tr>
</table>

**Режим призрака** включается одной кнопкой с призраком вверху списка чатов. Подробная настройка: `Настройки → ShineGram`.

> [!NOTE]
> Сервер Telegram сам помечает чат прочитанным, когда ты туда пишешь. Поэтому в режиме призрака сообщения уходят как **отложенные на 12 секунд**: чат остаётся непрочитанным, а ты не появляешься в сети. Исключения: «Избранное», секретные чаты и боты.

<img src="shine/readme/divider.svg" width="100%">

## `$ ls ~/shinegram/icons`

<div align="center">
<img src="shine/readme/icons-pixel.png" alt="icons" width="100%">
</div>

```console
$ shinegram icon --set ruby
✓ dock icon updated  →  ruby
```

Шесть иконок со звездой: `starlight` · `gold` · `ruby` · `emerald` · `ocean` · `nebula`. Выбираются в `Настройки → ShineGram → Иконка приложения`, Dock обновляется сразу.

<img src="shine/readme/divider.svg" width="100%">

## `$ shinegram --help`

```text
USAGE
  ShineGram.app  [модули]

GHOST
  ghost.read_receipts      не отправлять отметку о прочтении
  ghost.online             не отправлять статус «в сети»
  ghost.typing             не отправлять «печатает…»
  ghost.stories            смотреть истории анонимно
  ghost.voice              не отмечать голосовые и кружки прослушанными
  ghost.send_scheduled     не читать чат при отправке (+12 с)

MESSAGES
  anti_delete              удалённые сообщения остаются с пометкой «удалено»   [по умолчанию: on]
  edit_history             прошлые версии сообщений в контекстном меню         [по умолчанию: on]
  no_ads                   скрыть спонсорские сообщения                       [по умолчанию: on]

INTERFACE
  streamer_mode            окна не видны на скриншотах и в записи экрана
  hide_stories             убрать полосу историй
  message_seconds          время сообщений с секундами: 14:05:37
  copy_id                  «Копировать ID» чата, отправителя и сообщения       [по умолчанию: on]
  app_icon                 6 иконок для Dock

LANG
  ru / en                  переключается вместе с языком Telegram
```

<img src="shine/readme/divider.svg" width="100%">

## `$ install shinegram`

<a id="-установка"></a>

```bash
# 1 · скачай ShineGram-x86_64.zip или .dmg
open https://github.com/dlyavasnet/shinegram/actions/workflows/build.yml

# 2 · перетащи ShineGram в «Программы»

# 3 · сними карантин: приложение не подписано сертификатом Apple
xattr -cr /Applications/ShineGram.app

# 4 · запускай ✦
open -a ShineGram
```

> [!TIP]
> Если macOS пишет, что разработчик не проверен: правый клик по ShineGram → **Открыть**.

<img src="shine/readme/divider.svg" width="100%">

## `$ make build`

На Mac ничего собирать не нужно: всё собирает **GitHub Actions**.

```console
$ gh workflow run build.yml -f arch=x86_64    # или arm64 / universal
$ gh run watch
  ✓ checkout + submodules
  ✓ apply shine/patches/telegram-ios.patch
  ✓ native libs (из кэша)
  ✓ xcodebuild -scheme Release
  ✓ ShineGram-x86_64.zip
```

Секреты репозитория: `TG_API_ID` и `TG_API_HASH`, получить их можно на [my.telegram.org](https://my.telegram.org/apps).

```text
shinegram/
├── shine/
│   ├── patches/telegram-ios.patch   ← ядро: ghost, anti-delete, history
│   ├── icon/render-icon.swift       ← генератор иконки
│   └── readme/                      ← пиксельные картинки этого README
├── packages/SettingsUI/…/Shine*     ← экран ShineGram, иконки, стример
├── packages/ChatListUI/…/ShineGhostButton.swift
└── .github/workflows/build.yml
```

<img src="shine/readme/divider.svg" width="100%">

## `$ cat CREDITS`

```text
based on   Telegram for macOS · github.com/TelegramMessenger/telegram-macos
inspired   AyuGram
license    GNU GPL v2.0
```

ShineGram — неофициальный клиент. Он не связан с Telegram FZ-LLC и не одобрен ею. Используешь на свой страх и риск.

<div align="center">

<br>

```text
✦  made with shine  ✦  t.me/dlyavasnet  ✦
```

</div>
