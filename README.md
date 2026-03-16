# NetPulse

Native macOS menu bar app for real-time internet speed monitoring and speed testing.

![macOS](https://img.shields.io/badge/macOS-13.0+-black?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange?logo=swift)
![Architecture](https://img.shields.io/badge/arch-universal-blue)
![Size](https://img.shields.io/badge/size-~1MB-green)

## Features

- **Real-time monitoring** — Live upload/download speed in the menu bar
- **Speed test** — Cloudflare-powered download, upload, and ping measurement
- **Test history** — Results saved locally with SQLite
- **Native UI** — SwiftUI popover with segmented tabs
- **Lightweight** — ~1MB universal binary, zero external dependencies
- **Privacy** — No data leaves your machine (tests go directly to Cloudflare edge)

## Install

```bash
git clone https://github.com/tansuasici/NetPulse.git
cd NetPulse
bash build.sh
open build/NetPulse.app
```

## Usage

- Click the menu bar icon to open/close the popover
- **Speed tab** — Live traffic + run a speed test
- **History tab** — View past test results
- **Settings tab** — Launch at startup, quit

## How It Works

| Component | Implementation |
|-----------|---------------|
| Menu bar | `NSStatusItem` + `NSPopover` |
| Live speed | `getifaddrs` reading physical interface (`en*`) byte counters |
| Speed test | `URLSession` (ephemeral) against `speed.cloudflare.com` endpoints |
| Storage | `sqlite3` C API via `~/Library/Application Support/NetPulse/` |
| UI | SwiftUI with native `Form`, `GroupBox`, `List` |

## Build Requirements

- macOS 13.0+
- Xcode Command Line Tools (`xcode-select --install`)

## License

MIT
