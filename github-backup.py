"""
This script is used to backup all GitHub repositories of one user.
Q: Isn't it a little bit too much to backup GitHub repositories?
A: Yes... but I somehow don't trust GitHub to keep all my code always safe
   and I don't think someone should have that trust in any company.
   One good example was the OVH fire. So I like to always keep a backup if I can.

To use this script the module ``requests`` is required, a place for the backups
and a read only token from GitHub.
"""
import os
import requests
import subprocess
import sys
import shutil
from datetime import date
import time

opts: list[str] = [opt for opt in sys.argv[1:] if opt.startswith("-")]
args: list[str] = [arg for arg in sys.argv[1:] if not arg.startswith("-")]

# Check user input and exit if it isn't correct.
if not (("-u" in opts) and ("-t" in opts) and ("-p" in opts) and ("-k" in opts) and (len(args) == 4)):
  exit(f"Usage: -u <GITHUB_USERNAME> -t <GITHUB_TOKEN> -p <BACKUP_PATH> -k <KEEP_TIME_IN_DAYS>")

USER: str = args[opts.index("-u")]
TOKEN: str = args[opts.index("-t")]
PATH: str = args[opts.index("-p")].removesuffix("/")
TODAY = date.today()
KEEP_TIME_IN_SECONDS: int = int(args[opts.index("-k")]) * 24 * 60 * 60
HEADERS: dict[str,str] = {
  "Accept": "application/vnd.github+json",
  "Authorization": f"Bearer {TOKEN}",
  "X-GitHub-Api-Version": "2022-11-28"
}

# Get all names of the repositories in a list.
# Doesn't use typing because I'm lazy.
repositories_json = requests.get(f"https://api.github.com/search/repositories?q=user:{USER}", headers=HEADERS).json()

repositories: list[str] = []
for repo in repositories_json["items"]:
  repositories.append(repo["full_name"])

# Create temp directory for the cloned repos. Gets deleted after backup finished
os.mkdir(f"{PATH}/temp")
# Clone all repositories and put them in zip files with the current date.
for repo in repositories:
  repo_local_name = repo.removeprefix(f"{USER}/")
  subprocess.run(["git", "clone", "--mirror", f"https://{USER}:{TOKEN}@github.com/{repo}.git", f"{PATH}/temp/{repo_local_name}.git"])
  shutil.make_archive(f"{PATH}/{repo_local_name}.git-{TODAY}", "zip", f"{PATH}/temp/{repo_local_name}.git")
shutil.rmtree(f"{PATH}/temp")

# Delete old backups.
all_backups: list[str] = os.listdir(PATH)
for f in all_backups:
  if (time.time() - os.stat(f"{PATH}/{f}").st_mtime) > KEEP_TIME_IN_SECONDS:
    print(f"Deleting old backup: {PATH}/{f}")
    os.remove(f"{PATH}/{f}")
