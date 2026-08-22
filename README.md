# Digitale Kloon

[![Build](https://github.com/parvenuprompting/Digitale-Kloon-iOS/actions/workflows/ios.yml/badge.svg)](https://github.com/parvenuprompting/Digitale-Kloon-iOS/actions/workflows/ios.yml)
[![iOS](https://img.shields.io/badge/iOS-17.0%2B-19202C?logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white)](https://www.swift.org/)
[![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-0A84FF?logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![SwiftData](https://img.shields.io/badge/Persistence-SwiftData-19202C?logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftdata/)
[![XcodeGen](https://img.shields.io/badge/Project-XcodeGen-19202C)](https://github.com/yonaskolb/XcodeGen)
[![Offline](https://img.shields.io/badge/Network-0%20verbindingen-2ea44f)](https://developer.apple.com/ios/)
[![Encrypted](https://img.shields.io/badge/Data-AES--GCM%20versleuteld-5EEAD4)](https://developer.apple.com/documentation/cryptokit)
[![Face ID](https://img.shields.io/badge/Lock-Face%20ID%20%2F%20Touch%20ID-0A84FF?logo=apple&logoColor=white)](https://developer.apple.com/documentation/localauthentication)

Een **volledig offline, lokale digitale kluis** voor puur persoonlijk gebruik. Digitale Kloon is je "tweede brein" waarin je veilig wachtwoorden, API-keys, IBAN-rekeningnummers, accountgegevens en crypto-wallet credentials bewaart — naast notities en logs met volledige tijd- en datumregistratie.

> **Privacy-first ontwerp**: de app doet letterlijk nooit een netwerkoproep. Er is geen cloud, geen analytics en geen derde-partij SDK. Data verlaat de app uitsluitend wanneer **jij** expliciet iets deelt of kopieert.

---

## Inhoud

- [Functies](#functies)
- [Beveiligingsarchitectuur](#beveiligingsarchitectuur)
- [Datamodel](#datamodel)
- [Snel starten](#snel-starten)
- [Projectstructuur](#projectstructuur)
- [Back-ups](#back-ups)
- [Bouwen & testen](#bouwen--testen)
- [Signing & distributie](#signing--distributie)

---

## Functies

- **Kluis** met categorieën en eigen veldtemplates:
  - `wachtwoord` — gebruikersnaam + wachtwoord
  - `apiKey` — naam + key
  - `bank` — IBAN + naam rekeninghouder
  - `crypto` — wallet + private key / seed
  - `account` — accountnaam + wachtwoord
- **Toon/verberg + kopieer** per geheim veld, met automatische klembord-wissing.
- **Wachtwoordgenerator** met instelbare lengte en tekenset + lokale sterkte-indicator.
- **Favorieten**, zoeken en categoriefilter.
- **Notities** en **Logs** met automatische registratie van *aangemaakt*, *bewerkt* en *laatst geopend*.
- **Instellingen**: Face ID/Touch ID aan/uit, klembord-timer, standaardcategorie, versleutelde export/import, gegevens wissen.
- **App-intro** en een modern, minimalistisch donker design.

## Beveiligingsarchitectuur

| Maatregel | Implementatie |
|---|---|
| **Geen netwerk** | Geen `URLSession`/Network-framework/derde-partij SDK. Geen CloudKit, geen analytics. |
| **Vergrendeling** | `LocalAuthentication` (Face ID / Touch ID) bij elke koude start én bij terugkeer uit de achtergrond. |
| **Geen inhoud in app-switcher** | Cover-view bij `.background`; geheime velden gemarkeerd `.privacySensitive()`. |
| **Encryptie op rust** | Master-sleutel (willekeurig, 256-bit) in de **Keychain**. Geheime velden versleuteld met **AES-GCM (CryptoKit)**, ciphertext opgeslagen in SwiftData. |
| **Geen OS-backup** | SwiftData-store en bestanden gemarkeerd `isExcludedFromBackup` (geen iCloud/device/Mac-backup). |
| **Klembord** | Geheimen worden tijdelijk gekopieerd en na N seconden automatisch gewist (instelbaar). |

> **Eén uitgangspunt**: data kan alleen de app verlaten via een expliciete **share** of **copy** van jouw kant, of via de versleutelde back-up die jij zelf start.

## Datamodel

SwiftData-`@Model`-typen (`DigitaleKloon/Models/Models.swift`):

- `VaultItem` — een geheim: `title`, `categoryRaw`, `notes`, `favorite`, `createdAt`, `updatedAt`, `lastOpenedAt`, en een relatie naar `VaultField`.
- `VaultField` — label + waarde. Open velden worden als plaintext opgeslagen; geheime velden als AES-GCM `combined`-data (`secretData`).
- `Note` — `title`, `body`, `pinned`, plus de drie tijdstempels.
- `LogEntry` — `text`, plus de drie tijdstempels.

Categorieën en hun veldtemplates staan in `DigitaleKloon/Models/VaultCategory.swift`.

## Snel starten

1. Installeer XcodeGen (indien nog niet aanwezig):

   ```bash
   brew install xcodegen
   ```

2. Genereer het Xcode-project en open het:

   ```bash
   xcodegen generate
   open DigitaleKloon.xcodeproj
   ```

3. Stel je eigen Apple Developer-team in (zie [Signing & distributie](#signing--distributie)) en bouw naar je toestel.

## Projectstructuur

```text
digitale-kloon-ios/
├── project.yml                    # XcodeGen als bron van waarheid
├── .github/workflows/ios.yml      # CI (build + test)
├── DigitaleKloon/
│   ├── DigitaleKloonApp.swift     # @main, intro-overlay, lock-gate, scenePhase
│   ├── BackupService.swift        # versleutelde export/import
│   ├── App/
│   │   ├── RootView.swift         # (via SecurityState)
│   │   ├── SecurityState.swift    # lock-state + ModelContainer (excludedFromBackup)
│   │   ├── SplashView.swift       # app-intro
│   │   ├── LockView.swift         # Face ID / Touch ID
│   │   └── IdentifiableExtensions.swift
│   ├── Models/
│   │   ├── Models.swift           # VaultItem, VaultField, Note, LogEntry
│   │   └── VaultCategory.swift
│   ├── Security/
│   │   ├── MasterKeyService.swift # Keychain master-sleutel
│   │   ├── CryptoService.swift    # AES-GCM encrypt/decrypt + backup-key
│   │   ├── SecretStore.swift      # gecachte sleutel + VaultField lees/schrijf
│   │   ├── BiometricGate.swift    # LocalAuthentication
│   │   ├── ClipboardService.swift # klembord + AppSettings
│   │   └── PasswordGenerator.swift
│   ├── Views/
│   │   ├── MainTabView.swift
│   │   ├── VaultListView.swift
│   │   ├── VaultItemDetailView.swift
│   │   ├── VaultItemFormView.swift
│   │   ├── PasswordGeneratorView.swift
│   │   ├── NotesListView.swift
│   │   ├── LogsListView.swift
│   │   ├── SettingsView.swift
│   │   └── Components/            # Theme, SecretField, ActivityView
│   └── Resources/
│       └── Assets.xcassets/       # kleuren, app-icon, logo
└── DigitaleKloonTests/            # unit-tests
```

## Back-ups

Vanuit **Instellingen → Back-up**:

- **Exporteren** — de volledige kluis wordt geserialiseerd en versleuteld met een eigen wachtzin (PBKDF2-HMAC-SHA256 met 600.000 iteraties + AES-GCM). Het resultaat is een `.kloonbackup`-bestand dat je via de deel-sheet verstuurt of bewaart.
- **Importeren** — kies het bestand, geef de wachtzin en de kluis wordt hersteld. Geheime velden worden opnieuw versleuteld met de *huidige* master-sleutel van het toestel, zodat back-ups tussen apparaten overdraagbaar zijn.

> Bewaar je wachtzin goed: zonder wachtzin is een back-up niet te openen.

## Bouwen & testen

Lokaal:

```bash
xcodegen generate

# Bouwen voor de simulator
xcodebuild -project DigitaleKloon.xcodeproj -scheme DigitaleKloon \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build

# Tests uitvoeren (vereist een beschikbare simulator)
xcodebuild -project DigitaleKloon.xcodeproj -scheme DigitaleKloon \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO test
```

CI (GitHub Actions) draait automatisch build + test op elke push naar `main`.

## Signing & distributie

Dit is een persoonlijke, lokale app en is **niet** bedoeld voor de App Store.

- Bundle identifier: `nl.tiendo.digitalekloon`
- Code signing staat standaard op `Automatic`. Voor een toestel-build selecteer je je eigen Apple Developer-team in Xcode (Signing & Capabilities) of configureer je `DEVELOPMENT_TEAM` in `project.yml`.
- **Let op:** Face ID/Touch ID en Keychain-gedrag werken niet (volledig) op de simulator; test biometrie op een echt toestel.

---

*Volledig lokaal. Volledig versleuteld. Alleen van jou.*
