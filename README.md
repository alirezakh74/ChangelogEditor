# 📝 Changelog Manager Pro (Powered by Gemini)

Changelog Manager Pro is a modern, high-performance desktop application designed for software developers, product managers, and release engineers to construct, curate, and review rich software development logs. Built on top of a highly optimized **C++ backend** and a declarative, hardware-accelerated **Qt Quick/QML frontend**, it merges a rich staging environment with polished, production-grade output visualization.

---

## 🚀 Key Features

- **Rich Change Log Staging:** Effortlessly stage individual release versions, adjust version definitions, modify descriptions on-the-fly, and re-order elements before finalizing changes.
- **Granular Description-Specific Image Attachment:** Attach multiple image assets directly to individual log descriptions. The application uses theme-aware **"Attach Image"** actions to dynamically bind local graphic references to exact modification line items.
- **Lightbox Image Preview Viewer:** Toggle fully interactive image viewers on any thumbnail across the app. Browse attached images through a fluid lightbox overlay layout complete with mouse hover tracking and dynamic arrow navigators (`◀` / `▶`).
- **Sandboxed Local Asset Pipeline:** C++ components compute deterministic SHA/UUID hashes based on the workspace file location to generate an isolated media subdirectory (`/upload/`). Added media files are cleanly copied locally to avoid dead runtime URLs.
- **Automated Garbage Collection:** Includes an explicit asset scrubbing engine (`cleanOrphanedImages`) that programmatically scans the project binary tree, maps active logs, and purges orphaned media files to maintain a lightweight disk footprint.
- **Adaptive Dark & Light Themes:** Toggle seamlessly between eye-friendly dark and clean light mode variations. Every component—from background surfaces down to the interactive buttons—dynamically updates text and background layers using reactive theme parameters (`themeBgDeep`, `themeAccent`, `themeBorder`, etc.).
- **Robust JSON Serialization:** Save and load version matrices directly to and from standard disk profiles seamlessly without state degradation or layout breaking.

---

## 🛠 Tech Stack

- **Core Engine Backend:** C++17, Qt Core, Qt GUI (`QJsonDocument`, `QJsonObject`, `QJsonArray`, `QFile`, `QFileInfo`, `QUuid`)
- **User Interface Frontend:** Qt Quick 2.15, Qt Quick Controls 2.15, Qt Quick Layouts 1.15
- **Architecture Pattern:** Decoupled Model-View-Controller (MVC) utilizing secure context injection (`rootContext()->setContextProperty`) to cross boundary lines without runtime namespace collision risks.

---

## 📂 Project Architecture

```text
├── main.cpp                  # Application bootstrap; instantiates backend core & mounts QML environment
├── ChangeLogManager.h         # C++ header defining LogVersionEntry models, properties, and invokable hooks
├── ChangeLogManager.cpp       # Sandboxing mechanics, active text parsing, and JSON serialization logic
├── Main.qml                  # Root window manager establishing global theme definitions & notification toasts
├── WorkspaceEditor.qml       # Active staging canvas; features item editors, image drop targets & viewer overlays
└── ProductionViewer.qml      # Read-only render pipeline visualizing final formatted logs & asset carousels