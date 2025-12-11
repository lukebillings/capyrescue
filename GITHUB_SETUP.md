# Setting Up GitHub Repository

## Answer: Use the Parent Directory

**Initialize git in the parent directory** (`/Users/lukebillings/code/lukebillings/Capybara_Rescue_App`), which contains:

- `Capybara_Rescue_App.xcodeproj` (the Xcode project file)
- `Capybara_Rescue_App/` folder (your source code)
- `.gitignore` (already set up)

This is the standard structure for Xcode projects.

## Step-by-Step Instructions

### 1. Navigate to the parent directory

```bash
cd /Users/lukebillings/code/lukebillings/Capybara_Rescue_App
```

### 2. Initialize git (if not already done)

```bash
git init
```

### 3. Add all files to git

```bash
git add .
```

### 4. Make your first commit

```bash
git commit -m "Initial commit: Capybara Rescue App"
```

### 5. Create a new repository on GitHub

- Go to https://github.com/new
- Choose a repository name (e.g., `Capybara_Rescue_App`)
- **Do NOT** initialize with README, .gitignore, or license (you already have these)
- Click "Create repository"

### 6. Connect your local repository to GitHub

After creating the repository, GitHub will show you commands. Use these:

```bash
git remote add origin https://github.com/YOUR_USERNAME/Capybara_Rescue_App.git
git branch -M main
git push -u origin main
```

(Replace `YOUR_USERNAME` with your actual GitHub username)

## Alternative: Using SSH (if you have SSH keys set up)

```bash
git remote add origin git@github.com:YOUR_USERNAME/Capybara_Rescue_App.git
git branch -M main
git push -u origin main
```

## Important Notes

- ✅ **DO initialize git in the parent directory** (where `.xcodeproj` is)
- ❌ **DON'T initialize git in the `Capybara_Rescue_App/` subfolder**
- Your `.gitignore` is already configured correctly for Xcode projects
- The entire project structure (including the subfolder) will be tracked from the parent directory
