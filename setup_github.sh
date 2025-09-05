#!/bin/bash

echo "🚀 Food Recognition App - GitHub Setup"
echo "======================================"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}This script will help you push your code to GitHub.${NC}"
echo ""

# Get GitHub username
echo -e "${YELLOW}Enter your GitHub username:${NC}"
read -p "Username: " github_username

if [ -z "$github_username" ]; then
    echo "Username cannot be empty. Exiting."
    exit 1
fi

# Get repository name
echo -e "${YELLOW}Enter repository name (default: food-recognition-app):${NC}"
read -p "Repository name: " repo_name

if [ -z "$repo_name" ]; then
    repo_name="food-recognition-app"
fi

echo ""
echo -e "${BLUE}Setting up remote repository...${NC}"

# Add remote
git remote add origin "https://github.com/$github_username/$repo_name.git"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Remote repository added successfully${NC}"
else
    echo "❌ Failed to add remote repository"
    echo "This might be because a remote already exists."
    echo "You can remove it with: git remote remove origin"
    exit 1
fi

echo ""
echo -e "${BLUE}Pushing to GitHub...${NC}"

# Push to GitHub
git branch -M main
git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 Successfully pushed to GitHub!${NC}"
    echo ""
    echo -e "${BLUE}Your repository is now available at:${NC}"
    echo "https://github.com/$github_username/$repo_name"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Go to your repository on GitHub"
    echo "2. Check the 'Actions' tab to see the build process"
    echo "3. Once the build completes, download the APK from 'Releases'"
    echo "4. Install the APK on your Android phone"
    echo ""
    echo -e "${YELLOW}The GitHub Actions workflow will automatically build APKs for you!${NC}"
else
    echo "❌ Failed to push to GitHub"
    echo "Make sure you have created the repository on GitHub first:"
    echo "https://github.com/new"
    echo ""
    echo "Repository details:"
    echo "- Name: $repo_name"
    echo "- Description: AI-powered food recognition app with recipe suggestions"
    echo "- Don't initialize with README (we already have one)"
fi