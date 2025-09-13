# README.md

# Exchange Admin Scripts

Companion scripts for the book
**"The Admin's Guide to Microsoft Exchange Server Subscription Edition."**

These scripts include PowerShell (`.ps1`) and Windows Command Prompt (`.cmd`) files referenced in the book.
They are provided for learning and administrative convenience.

## How to Download
Click the green **Code** button → **Download ZIP**
Or clone with Git:
```powershell
git clone https://github.com/<user>/exchange-admin-scripts.git
```

## Script Organization
- **powershell/** → Example scripts
- **cmd/** → Example AppCmd files
- **docs/** → Additional text files

## Example Usage
From PowerShell:
```powershell
cd .\powershell\chapter01\
.\example-script.ps1
```
## Notes
- Some scripts require elevated permissions.
- Execution Policy may need to be adjusted for `.ps1` files:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```
