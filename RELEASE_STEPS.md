# How to release a new version of Beslet

## Every release — do these 4 steps in order:

### Step 1 — Bump the version in pubspec.yaml
Change the version line. The number after + must go up by 1 every release.
Example: 1.0.0+1 → 1.1.0+2 → 1.2.0+3

### Step 2 — Build the release APK
Run this in the terminal:
flutter build apk --release

The APK will be at:
build/app/outputs/flutter-apk/app-release.apk

### Step 3 — Upload APK to GitHub Releases
1. Go to github.com/GITHUB_USERNAME/beslet-releases
2. Click Releases → Create a new release
3. Tag: v1.1.0 (match your version number)
4. Title: Beslet v1.1.0
5. Drag the app-release.apk file into the upload area
6. Click Publish release
7. After publishing, right-click the APK in Assets and copy the download link

### Step 4 — Update version.json on GitHub
1. Go to the version.json file in the repo
2. Click the pencil (edit) icon
3. Update these fields:
   - "version": "1.1.0"
   - "versionCode": 2  ← must match the number after + in pubspec.yaml
   - "downloadUrl": "paste the APK link you copied"
   - "releaseNotes": "describe what is new"
4. Click Commit changes

Done. All existing users will see an update popup the next time they open the app.
