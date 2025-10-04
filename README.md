# FTW DE Bootcamp Group 2 – Setup Instructions (WSL & macOS)

Follow these steps carefully to set up your local environment and start working on your branch.

---

## 🧭 Step 1: Navigate to the Correct Folder

### 🪟 For WSL (Windows)

1. Open your **File Explorer**.
2. In the sidebar, scroll down and click on:
   ```
   Linux → Ubuntu → home → <your_username>
   ```
   > 🔹 Replace `<your_username>` with your actual Ubuntu username.
3. Inside that folder, **right-click** and choose **“Open in Terminal”** or **type `cmd`** in the address bar and press **Enter**.
4. You should now see a terminal window open inside your WSL environment.

Now, create a new working folder called `g2-playground`:

```bash
mkdir g2-playground
cd g2-playground
```

---

### 🍏 For macOS

1. Open **Finder**.
2. Go to your **Home directory** by pressing **Shift + Command + H**.
3. Right-click and choose **“New Terminal at Folder”** (or open Terminal manually and run):

```bash
cd ~
mkdir g2-playground
cd g2-playground
```

Now clone the repository:

```bash
git clone https://github.com/shieryl-ryle/ftw-de-bootcamp
cd ftw-de-bootcamp
```

Then open the folder in **Visual Studio Code**:

```bash
code .
```

> 💡 If `code` command is not recognized, open VS Code → press `Cmd + Shift + P` → type **“Shell Command: Install 'code' command in PATH”** → press Enter.

---

## 🧰 Step 2: Clone the Repository (for WSL)

Once inside your `g2-playground` folder, clone the project repository:

```bash
git clone https://github.com/shieryl-ryle/ftw-de-bootcamp
```

Then move into the cloned project:

```bash
cd ftw-de-bootcamp
```

Open the project in **Visual Studio Code**:

```bash
code .
```

> 💡 Same note as macOS: if `code` is not recognized, install it from VS Code’s command palette.

---

## 🌿 Step 3: Checkout the Base Branch

Switch to the base branch `g2/v2`:

```bash
git checkout g2/v2
```

---

## 🪄 Step 4: Create Your Own Branch

Create a new branch **from** `g2/v2` using this naming format:

```
v2/<your_name>
```

Example:

```bash
git checkout -b v2/shi
```

> 🔹 Replace `shi` with your own name or alias.

Commit and push your work to your branch only:

```bash
git add .
git commit -m "Initial work on v2/<your_name>"
git push origin v2/<your_name>
```

---

## 🧪 Optional: Use the DLT Playground Branch

If you want to **try CSV ingestion into the database**, use the **`g2/v2/dlt-playground`** branch.

```bash
git checkout g2/v2/dlt-playground
```

> ⚠️ **Important:**
> - This branch connects to the **sandbox database**, so you can test ingestion safely.  
> - Please **do not push** any commits directly to `g2/v2`.  
> - `g2/v2` is the **main working branch** for the group.

---

## ✅ Summary of Commands

```bash
# Create and enter your folder
mkdir g2-playground
cd g2-playground

# Clone the repository
git clone https://github.com/shieryl-ryle/ftw-de-bootcamp
cd ftw-de-bootcamp

# Open in VS Code
code .

# Checkout base branch
git checkout g2/v2

# Create your own branch
git checkout -b v2/<your_name>

# Push your branch
git push origin v2/<your_name>

# (Optional) Test ingestion on sandbox
git checkout g2/v2/playground
```

---

## 🛠️ Troubleshooting

**Git not installed:**
```bash
sudo apt update && sudo apt install git -y
```

**Permission denied (HTTPS/SSH):**
```bash
git config --global user.name "<your_name>"
git config --global user.email "<your_email>"
```

**Check current branch:**
```bash
git branch
```

**Check remote branches:**
```bash
git branch -r
```

---

✅ You’re now ready to start working!
Use your own branch for development, and switch to `g2/v2/playground` only if you need to test data ingestion in the sandbox.