[![DOI](https://zenodo.org/badge/727888683.svg)](https://zenodo.org/doi/10.5281/zenodo.11166898)

# [Public Observing Unci Maka]

Welcome to the **[Observing Unci Maka]** repository, an integral part of the Environmental Data Science Innovation and Inclusion Lab (ESIIL). This repository is the central hub for our working group, encompassing our project overview, proposals, team member information, codebase, and more.

## Our Project
This working group brings together Tribal members, scientists, students and NASA remote-sensing researchers to formulate new methods of using existing earth observation data to identify, monitor, and address environmental impacts on Tribal communities. These methods will be co-developed utilizing culturally-specific data synthesis techniques, which will include leveraging existing resources and hosting community workshops on the Hopi and Pine Ridge Reservations, where members of the working group are from. Both of these Tribal lands are impacted by current and legacy uranium mining, which has lasting effects on the air, water, soils, and health of these communities. During these visits, the working group will discuss how to effectively synthesize available datasets to prioritize new measurements and gaps in resources for addressing and identifying environmental impacts. This will be done through developing new software to identify sources of environmental impacts, degradation, and risk using data from various satellites and surface monitoring networks. Additionally, advancing data sovereignty is a shared goal of this working group and there will be community building, planning, and discussions for how this existing environmental data and future collections can be aligned with traditional ecological knowledge frameworks. Historically, very limited research into the historical impacts of mining has been conducted using remote sensing techniques to address these types of environmental impacts nor have past research efforts been led by the communities impacted, which makes this working group novel and essential.

[Working Group Tasks (Pine Ridge, Year 1)](https://docs.google.com/document/d/1izSjMnHLdHgpwQ0cjH8xl09bSq5cOYV71fZaovFU6v4/edit?tab=t.0)

## Documentation
- Full documentation site: https://cu-esiil.github.io/Public-Observing-Unci-Maka
- Guides for CyVerse setup, Docker, data processing, and analysis are in `docs/resources/`

## Group Members
- Member 1: Joni Tabacco.
- Member 2: Shannon Boldt.
- Member 3: Vanessa Taho.
- Member 4: Darryl Reano.
- Member 5: Ayia Linquist.
- Member 6. Shawn Serbin.
- Member 7. Max Cook.
- Member 8. Bob Rabin.
- Member 9. Elisha YellowThunder.
- Member 10 Sam Toledo.
- Member 11 Sylvie Alexander.
- Memebr 12 Cynthia Sanders.
- Member 13 Betty Poley.
- Member 14 Debi Nalwood
- Member 15 Summer Dupreee
- Member 16 Gabriel Talayumptewa
- ...
- [Link to more detailed bios or profiles if available.]

[Link to Team Member Bios](https://github.com/CU-ESIIL/Public-Observing-Unci-Maka/blob/main/BIOS.md)

## Repository Structure
- **`notebooks/`** — Jupyter notebooks for HLS reflectance, valley bottom extraction (VBET), EMIT remote sensing, and STELLA field data visualization
- **`data/`** — Study area boundaries and ground control points (Craven Canyon / Pine Ridge)
- **`tools/emit/`** — NASA EMIT data access tools, tutorials, and Python modules
- **`tools/STELLA/`** — STELLA-Q2 field spectrometer data outputs
- **`docs/`** — Project documentation, meeting notes, and the mkdocs site source
- **`docker/`** — Dockerfile and environment for the CyVerse JupyterLab image
- **`environment.yml`** — Conda environment for running project notebooks locally or on CyVerse

## Meeting Notes and Agendas
- Regular updates to keep all group members informed and engaged with the project's progress and direction.

## Contributing to This Repository
- Contributions from all group members are welcome.
- Please adhere to these guidelines:
  - Ensure commits have clear and concise messages.
  - Document major changes in the meeting notes.
  - Review and merge changes through pull requests for oversight.

## Getting Help
- For CyVerse and environment setup, see `docs/resources/cyverse_basics.md`
- For issues with the repository, open a GitHub Issue or contact the maintainers directly

---------------------------------------------------------------------------------------------------------------
-----------------------------                     ---------------------             ---------------------------
---------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------

# Observing Unci Maka
A repository for the development of code and workflows for the Observing Unci Maka ESIIL working group.

***

### Instructions for setting up <ins>local</ins> Python environment and Git commands
> Instructions adapted from [Earth Data Science.org](https://www.earthdatascience.org/workshops/setup-earth-analytics-python/setup-git-bash-conda/)

1. **Installing Python on your personal computer from _miniconda_**
> Note: if you already have Python installed you may skip ahead to #3
- Download the correct (e.g., Windows, MacOS, or Linux) _miniconda_ from: https://docs.anaconda.com/miniconda/
  
- Run the installer (**Windows**)
  > Run the installer by double-clicking on the downloaded file and follow the steps below.
  - Click “Run”.
  - Click on “Next”.
  - Click on “I agree”.
  - Leave the selection on “Just me” and click on “Next”.
  - Click on “Next”.
  - Select the first option for “Add Anaconda to my PATH environment variable” and also leave the selection on “Register Anaconda as my default Python 3.7”. Click on “Install”.
    > Note that even though the installation is for Miniconda, the installer uses the word Anaconda in these options. You will also see a message in red text that selecting “Add Anaconda to my PATH environment variable” is not recommended; continue with this selection to make using conda easier in Git Bash.
  - When the install is complete, Click on “Next”.
  - Click on “Finish”.

- Run the installer (**MacOS**)
  - Download the installer: Miniconda installer for Mac. Be sure to download the Python 3.x version!
  - In your Terminal window, run: bash Miniconda3-latest-MacOSX-x86_64.sh.
  - Follow the prompts on the installer screens.
  - If you are unsure about any setting, accept the defaults. You can change them later.
  -  To make sure that the changes take effect, close and then re-open your Terminal window.

2. **Installing Git and Bash (for interacting with GitHub)**
**Windows**
  - Download the [Git Installer for Windows](https://git-scm.com/downloads/win)
    > Run the installer by double-clicking on the downloaded file and by following the steps below:
    - Click on “Run”.
    - Click on “Next”.
    - Click on “Next”.
    - Click on “Next”.
    - Click on “Next”.
    - Click on “Next”.
    - Leave the selection on “Git from the command line and also from 3rd party software” and click on “Next”.
    - Click on “Next”.
    - Leave the selection on “Checkout Windows-style, commit Unix-style line endings” and click on “Next”.
    - Select the second option for Use Windows’ default console window and click on “Next”.
    - Click on “Next”.
    - Click on “Install”.
    - When the install is complete, click on “Finish”.

    > This installation will provide you with both **Git** and **Bash** within the Git Bash program.

  - **Install Git and Bash for MacOS**
    
    > The default shell in all versions of Mac OS X is Bash, so no need to install anything. You access Bash from the Terminal (found in /Applications/Utilities).
    
    - Install Git for MacOS:
      - Follow instructions for installing [Git for MacOS](https://git-scm.com/downloads/mac)

> More instructions for what Bash is and how to use it can be found on the [EarthDataScience.org](https://www.earthdatascience.org/workshops/setup-earth-analytics-python/introduction-to-bash-shell/) tutorial

3. **Clone the repository to your local machine and setup the Python environment**\

Cloning the repository essentially sets up a folder on your local machine that is a copy of the GitHub repository. Any changes you make in this folder (i.e., writing new code) can be "pushed" to the GitHub repository for all to see.

   > Note: Further instructions for cloning repositories can be found [at this link](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository)

  - Option #1: GitHub Desktop
      > Note: I (Max here) like using GitHub Desktop because it is straightforward and requires less from the terminal. However, both of the below options are good
    - Download and install [GitHub Desktop](https://desktop.github.com/download/)
    - In the main repository on GitHub, find the repo URL:\
      <img src="https://docs.github.com/assets/cb-13128/mw-1440/images/help/repository/code-button.webp" width="350">
    - Clone and open the repository with GitHub Desktop, click _Open with GitHub Desktop_
      <img src="https://docs.github.com/assets/cb-44807/mw-1440/images/help/repository/open-with-desktop.webp" width="350">\\
  - Option #2: Use **Git** commands in the terminal (or Bash for Windows)
    - In the main repository on GitHub, find the repo URL:\
      <img src="https://docs.github.com/assets/cb-13128/mw-1440/images/help/repository/code-button.webp" width="350">
    - Copy the HTTPS url:\
      <img src="https://docs.github.com/assets/cb-60499/mw-1440/images/help/repository/https-url-clone-cli.webp" width="350">
    - In your terminal (or Bash for Windows):
      ```
      cd <path-to-local-directory>
      git clone <repository url>
      ```

4. **Install/setup the Python environment**

> For our work, we have a ".yaml" file, which is a Python environment file that can be used to install all the dependencies we will need for coding. Updates to this file with new packages, etc., allows us to keep a consistent environment for everyone working on the project. You may have to periodically reinstall the environment as we make changes (adding new packages). 

** To setup the environment for the first time:\**
  - Open terminal (or Bash for Windows)
  - Change directory into the GitHub repository we cloned above
    ```
    cd <path-to-local-repo>
    ```
  - Using Bash command to print the contents of the directory:
    ```
    ls
    ```
    > You should see the list of files, etc., in the repo including our "py-unci-maka.yaml"
  - Create a new Python environment using the ".yaml" file
    ```
    conda env create --file=py-unci-maka.yaml
    ```
  - Activate the new Python env:
    ```
    conda activate py-unci-maka
    ```
  - Now, we can setup JupyterLab so you can create your own notebooks or access ones already in the GitHub:
      - First, register our Python env with _ipykernel_ so it is accessible in JupyterLab
      ```
      python -m ipykernel install --user --name=py-unci-maka
      ```
      - Now, you can open a new JupyterLab session by typing:
      ```
      jupyter-lab
      ```
      > Note: this will open JupyterLab in your default browser window. When you start a JupyterLab, make sure you 'cd' (change directory) into the GitHub repo you cloned on your local machine. This will ensure you have easy access to all the files and code in the repository.

**To update your 'py-unci-maka' environment:\**
  > Note: These steps are for updating the environment you've created. As we develop code, we will periodically be updating the ".yaml" file with new Python packages. To update the conda environment, or to make sure you are using the most recent version, follow these steps...
  - Make sure the GitHub repository is up to date:
    - If using GitHub Desktop:
      - Open GitHub Desktop
      - Make sure your in the correct repository ("observing-Unci-Maka")
      - In the top right, click "Pull"\
        <img src="https://github.com/maxwellCcook/observing-Unci-Maka/blob/main/images/md/GitHubDesktopPull.png" width="500">
        > Note: this action makes sure that the repository on your local machine is the most up-to-date. For example, if others have made changes to the rpeository since you last worked on it, these changes will be visible once you "pull" them. Similarly, you can "Push" changes to the repository when you have made edits on your local machine.
    - If using Terminal/Bash
      - First, create a personal access token following [these instructions](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
      - Open Terminal/Bash
      - Change directory into the local GitHub repository (where you cloned it on your machine)
        ```
        cd <path-to-local-repo>
        ```
      - Check the origin. When prompted, enter your GitHub username and then copy and paste **the Personal Access Token** for your password
        ```
        git remote -v
        git fetch origin
        ```
      - Pull the latest version of the repository
        ```
        git pull 
        ```
  - Now, you can update your conda environment in terminal/bash:
  ```
  conda activate py-unci-maka
  conda env update --file py-unci-maka.yaml --prune
  ```

**To push local changes to GitHub:\**

### Instructions for working in <ins>CyVerse</ins>

1. Login to [CyVerse](https://cyverse.org/) if you have an account, or email maxwell.cook@colorado.edu for access


