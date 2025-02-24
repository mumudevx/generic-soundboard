# Generic Soundboard
Generic soundboard generator that contains crawling, code generation, auto pipeline solutions in one package.

## Soundboard App Steps

### Generate App Icon

1. Update **icon.png** and **icon_foreground.png** files at ```assets/icon``` folder.
2. Update ```ic_launcher_background``` value at ```android/app/src/main/res/values/colors.xml``` file.
3. Run this command to generate icons automatically: ```dart run flutter_launcher_icons```

### App Configuration (Theme, Common)
- All configurations are at ```lib/config/app_config.dart``` file.

### Admob Configuration
- Update ```com.google.android.gms.ads.APPLICATION_ID``` meta-data value at ```android/app/src/main/AndroidManifest.xml``` (Admob App Id)
- Update the admob ad-unit values under ```Ad Configuration``` section at ```lib/config/app_config.dart``` (Banner, Interstitial Ad-unit Ids)

### Release App (appbundle)
- Run this command to release app: ```flutter build appbundle```
