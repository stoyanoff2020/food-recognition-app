# GitHub Setup Commands

After creating your repository on GitHub, run these commands:

## Add remote repository
```bash
git remote add origin https://github.com/YOUR_USERNAME/food-recognition-app.git
```

## Push to GitHub
```bash
git branch -M main
git push -u origin main
```

## Alternative: Using SSH (if you have SSH keys set up)
```bash
git remote add origin git@github.com:YOUR_USERNAME/food-recognition-app.git
git branch -M main
git push -u origin main
```

Replace `YOUR_USERNAME` with your actual GitHub username.

## After pushing, the GitHub Actions will automatically:
1. Build Android APKs (debug and release)
2. Run all tests
3. Create a release with downloadable APK files
4. You can download the APK from the "Releases" section of your repository

## To trigger a build manually:
1. Go to your repository on GitHub
2. Click "Actions" tab
3. Click "Build Android APK" workflow
4. Click "Run workflow" button