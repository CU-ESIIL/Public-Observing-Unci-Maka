# Getting Started on CyVerse

CyVerse provides cloud computing for running the project notebooks without needing a powerful local machine. This guide walks through everything you need to get up and running.

## Overview

Each CyVerse session runs in a fresh container. Here is what **persists** between sessions and what does not:

| | Persists? |
|---|---|
| Files in `/home/jovyan/data-store/` | Yes — this is your permanent storage |
| Cloned repositories (if saved to data-store) | Yes |
| Conda environments (installed to `/opt/conda/envs/`) | **No** — must be recreated each session |
| Jupyter kernel registrations | **No** — must be re-registered each session |
| GitHub SSH credentials | **No** — must be recreated each session |

The setup steps below take about 5–10 minutes and must be repeated at the start of each new CyVerse analysis.

---

## Prerequisites

Before your first session, make sure you have:

- **CyVerse account** — [user.cyverse.org](https://user.cyverse.org/)
- **GitHub account** — [github.com](https://github.com)
- **NASA Earthdata account** — [urs.earthdata.nasa.gov](https://urs.earthdata.nasa.gov/) (required for `earthaccess` to download HLS and EMIT data)

---

## Step 1: Log in to CyVerse

1. Go to [user.cyverse.org](https://user.cyverse.org/)

   <img width="881" alt="image" src="https://github.com/CU-ESIIL/hackathon2023_datacube/assets/3465768/61b8c22a-bed3-457a-b603-736fd8e59568">

2. Click `Sign up` if you do not already have an account.

   <img width="881" alt="image" src="https://github.com/CU-ESIIL/hackathon2023_datacube/assets/3465768/73dc39a4-30f2-4017-8f0d-1006db24d25b">

3. Head to the CyVerse Discovery Environment at [de.cyverse.org](https://de.cyverse.org) and log in.

   <img width="881" alt="image" src="https://github.com/CU-ESIIL/hackathon2023_datacube/assets/3465768/41970a8d-c434-4075-9dd4-fbcd0f2ea07c">

   You should see the Discovery Environment dashboard:

   <img width="881" alt="image" src="https://github.com/CU-ESIIL/hackathon2023_datacube/assets/3465768/0dcd0048-a4e3-469c-bd28-5a5574c5dec3">

---

## Step 2: Launch JupyterLab

1. From the Discovery Environment, click `Apps` in the left menu.
   ![apps](../assets/cyverse_basics/apps.png)

2. Select `JupyterLab ESIIL`.
   ![use_this_app](../assets/cyverse_basics/use_this_app.png)

3. Configure your analysis. Set disk size to **64 GB or greater**. Adjust CPU/memory as needed.
   ![app_launch](../assets/cyverse_basics/app_launch.png)
   ![app_settings](../assets/cyverse_basics/app_settings.png)
   ![launch](../assets/cyverse_basics/launch.png)

4. Click `Go to analysis`.
   ![go_to_analysis](../assets/cyverse_basics/go_to_analysis.png)

5. JupyterLab will open in your browser.
   ![jupyterlab](../assets/cyverse_basics/jupyterlab.png)

---

## Step 3: Set Up the Project Environment

Open a terminal in JupyterLab (**File → New → Terminal**) and run the following commands. These must be run at the start of every new CyVerse session.

**1. Clone the repository** (only needed if not already in your data-store):
```bash
cd ~/data-store
git clone https://github.com/CU-ESIIL/Public-Observing-Unci-Maka.git
cd Public-Observing-Unci-Maka
```

If already cloned, just pull the latest changes:
```bash
cd ~/data-store/Public-Observing-Unci-Maka
git pull
```

**2. Limit extraction threads** (prevents out-of-memory crashes during install):
```bash
conda config --set fetch_threads 1
conda config --set extract_threads 1
```

**3. Create the conda environment**:
```bash
mamba env create -f environment.yml
```

This takes several minutes. If you see `EnvironmentNameNotFound` when activating later, this step did not complete — run it again.

**4. Register the kernel** (the `--env` flags prevent PROJ/CRS errors in the notebooks):
```bash
conda activate unci-maka-py
python -m ipykernel install --user \
  --name unci-maka-py \
  --display-name "Python (unci-maka-py)" \
  --env PROJ_DATA /opt/conda/envs/unci-maka-py/share/proj \
  --env PROJ_LIB /opt/conda/envs/unci-maka-py/share/proj \
  --env GDAL_DATA /opt/conda/envs/unci-maka-py/share/gdal
```

**5. Refresh JupyterLab** (click the browser refresh button), then open a notebook and select **"Python (unci-maka-py)"** from the kernel picker.

---

## Step 4: Set Up GitHub Credentials

GitHub SSH credentials are tied to each CyVerse container and must be recreated each session. You only need to do this if you want to push changes back to GitHub.

### Video walkthrough
<a href="https://www.youtube.com/watch?v=nOwOzPJEQbU">
    <img src="https://img.youtube.com/vi/nOwOzPJEQbU/0.jpg" style="width: 100%;">
</a>

1. From JupyterLab, click the **Git Extension** icon in the left sidebar.
   ![jupyterlab](../assets/cyverse_basics/jupyterlab.png)

2. Click `Clone a Repository`, paste the cyverse-utils URL below, and click `Clone`:
   ```
   https://github.com/CU-ESIIL/cyverse-utils.git
   ```
   ![clone](../assets/cyverse_basics/clone.png)

3. You should now see the `cyverse-utils` folder in your directory tree (from the default `/home/jovyan/data-store` directory).
   ![cyverse-utils](../assets/cyverse_basics/cyverse-utils.png)

4. Open the `cyverse-utils` folder.
   ![click_cyverse_utils](../assets/cyverse_basics/click_cyverse_utils.png)

5. Open `create_github_keypair.ipynb` (Python) or `create_github_keypair.R` (R).
   ![open_cyverse_utils](../assets/cyverse_basics/open_cyverse_utils.png)

6. Click the **play** button. Enter your GitHub username and email when prompted.
   ![script_1](../assets/cyverse_basics/script_1.png)
   ![username](../assets/cyverse_basics/username.png)
   ![email](../assets/cyverse_basics/email.png)

7. Copy the entire public key line, including `ssh-ed25519` at the start and `jovyan@...` at the end.
   ![key](../assets/cyverse_basics/key.png)

8. Go to your [GitHub Settings](https://github.com/settings/keys) page.
   ![settings](../assets/cyverse_basics/settings.png)

9. Select `SSH and GPG keys`.
   ![ssh](../assets/cyverse_basics/ssh.png)

10. Click `New SSH key`.
    ![new_key](../assets/cyverse_basics/new_key.png)

11. Give it a name, paste the full public key, and click `Add SSH Key`.
    ![paste_key](../assets/cyverse_basics/paste_key.png)

12. Your key will appear in the list. You can now clone private repos and push changes.
    ![final](../assets/cyverse_basics/final.png)

> **Note:** This SSH key is tied to the current container. When you start a new CyVerse analysis, repeat this step. You can delete old keys from GitHub at any time.

---

## Troubleshooting

### `EnvironmentNameNotFound: Could not find conda environment: unci-maka-py`
The environment was not created or was lost when the container was recycled. Re-run Step 3 from the beginning.

### Out-of-memory / segfault during `mamba env create`
Make sure you ran the thread-limiting commands in Step 3.2 before running `mamba env create`. If it still crashes, try:
```bash
mamba create -n unci-maka-py python=3.12 -y
conda activate unci-maka-py
mamba install --file environment.yml -y
```

### `CRSError: Invalid projection` or `pyproj unable to set PROJ database path`
The PROJ environment variables are not being passed to the kernel. Re-run the `ipykernel install` command from Step 3.4 (which embeds the paths in the kernel spec), then restart the kernel.

If the error persists, add this as the **very first cell** in the notebook, before any other imports:
```python
import os, sys
os.environ['PROJ_DATA'] = os.path.join(sys.prefix, 'share', 'proj')
os.environ['PROJ_LIB'] = os.path.join(sys.prefix, 'share', 'proj')
```

### `earthaccess` login / NASA Earthdata errors
You need a free NASA Earthdata account at [urs.earthdata.nasa.gov](https://urs.earthdata.nasa.gov/). When `earthaccess.login()` prompts for credentials, use your Earthdata username and password (not your GitHub credentials).

### Kernel not appearing in the picker after install
Click the browser **Refresh** button (not just the JupyterLab reload). The kernel list is fetched on page load.
