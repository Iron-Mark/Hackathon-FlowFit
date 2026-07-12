# General Sans fonts

The 12 `GeneralSans-*.otf` files that belong in this directory are **not
committed** to the repository. General Sans is distributed by
[Fontshare](https://www.fontshare.com/fonts/general-sans) under the Fontshare
Free Font License, which allows embedding the fonts in the app but not
redistributing the raw font files (for example, hosting them in a public git
repository).

To install them locally, run once after cloning:

```powershell
pwsh scripts/fetch_fonts.ps1
```

CI runs the same script automatically before building or testing. The build
fails with a missing-asset error if the fonts have not been fetched, because
`pubspec.yaml` declares them under `flutter.fonts`.
