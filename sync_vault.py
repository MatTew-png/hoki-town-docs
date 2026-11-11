# -*- coding: utf-8 -*-
"""
HOKI TOWN - Cross-Platform Git Vault Sync Script
"""
import subprocess
import datetime
import sys

def run_cmd(cmd):
    result = subprocess.run(cmd, shell=True, text=True, capture_output=True)
    if result.returncode != 0 and "nothing to commit" not in result.stderr and "nothing to commit" not in result.stdout:
        print(f"Error executing {cmd}:\n{result.stderr}")
    return result.stdout.strip()

print(">>> [HOKI TOWN] Starting Obsidian Vault Git Sync...")

# 1. Pull
print(">>> Pulling latest changes from remote...")
pull_out = run_cmd("git pull --rebase")
if pull_out:
    print(pull_out)

# 2. Stage
print(">>> Staging files...")
run_cmd("git add .")

# 3. Check status
status = run_cmd("git status --porcelain")
if status:
    now_str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    msg = f"vault backup: {now_str}"
    print(f">>> Committing changes: {msg}...")
    run_cmd(f'git commit -m "{msg}"')
    print(">>> Pushing to remote...")
    push_out = run_cmd("git push")
    if push_out:
        print(push_out)
    print(">>> [SUCCESS] Obsidian Vault synced successfully!")
else:
    print(">>> [INFO] Working tree is clean. Nothing to sync.")
