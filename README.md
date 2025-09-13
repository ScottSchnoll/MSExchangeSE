# README.md

# Exchange Admin Scripts

Companion scripts for the book
**"The Admin's Guide to Microsoft Exchange Server Subscription Edition (ISBN: 9798262871872)."**

These scripts include PowerShell (`.ps1`) and Windows Command Prompt (`.cmd`) files referenced in the book.
They are provided for learning and administrative convenience.

## Script Organization
- **powershell/** → Example scripts
- **cmd/** → Example AppCmd files
- **docs/** → Additional text files

## Notes
- Some scripts require elevated permissions.
- Execution Policy may need to be adjusted for `.ps1` files:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```
