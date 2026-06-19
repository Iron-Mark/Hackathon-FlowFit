Add the General Sans font files here.

Recommended filenames and weights:
- GeneralSans-Regular.ttf
- GeneralSans-Medium.ttf (weight 500)
- GeneralSans-SemiBold.ttf (weight 600)
- GeneralSans-Bold.ttf (weight 700)

You must not commit licensed font files to the public repo unless the license allows it. Put fonts into this directory locally and then update `pubspec.yaml` as shown in the docs to reference them.

How to add fonts:
1. Place the .ttf files here
2. Update pubspec.yaml `fonts` section with the assets
3. Run `flutter pub get`
4. If your app uses `fontFamily: 'GeneralSans'` in the theme, it should automatically pick the font.

If you don't have a license to include General Sans, use an open font like Inter, or add your own font with a different family name.