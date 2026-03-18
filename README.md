# Planner App

Une application de planning personnel avec calendrier et todo list.

## Fonctionnalités

### Todo list
- Thèmes et sous-thèmes avec couleurs (niveaux illimités)
- Sous-tâches
- Barre de progression par thème
- Collapse/expand des thèmes
- Vue flat ou vue par thèmes
- Filtres par thème

### Calendrier
- Vue mois, semaine et jour
- Événements avec couleur et description
- Page de détail par événement

---

## Compiler depuis le code source

### Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Git

### Étapes

```bash
# Cloner le repo
git clone https://github.com/EvanLadeira/Planner_App.git
cd Planner_App/calendrier_app

# Installer les dépendances
flutter pub get

# Lancer en mode développement
flutter run -d linux     # Linux
flutter run -d windows   # Windows

# Compiler
flutter build apk        # Android
flutter build linux      # Linux
flutter build windows    # Windows (depuis Windows uniquement)
```

### Trouver les fichiers compilés

| Plateforme | Emplacement |
|---|---|
| Android | `build/app/outputs/flutter-apk/app-release.apk` |
| Linux | `build/linux/x64/release/bundle/` |
| Windows | `build/windows/x64/runner/Release/` |
