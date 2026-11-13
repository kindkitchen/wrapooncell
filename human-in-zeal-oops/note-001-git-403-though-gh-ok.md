- Cause: the only git credential helper is osxkeychain, and the macOS keychain holds a
  github.com token for Nik-Moiseienko-odido. That account has no write access to
  kindkitchen/wrapooncell.
- Why gh doesn't help: gh has kindkitchen as the active account, but it is not
  configured as a git credential helper, so git never uses that token.
- Scope: this blocks every push to origin, not just tags. main has no upstream and git
  ls-remote origin returns no refs, so it looks like nothing has been pushed yet.

The simplest fix is to make this repo use gh's active account (kindkitchen):

```nu
  git config --local credential.helper ""
  git config --local --add credential.helper "!gh auth git-credential"
  git push -u origin main --tags
```

The catch is that it follows whichever gh account is active, so it breaks again if you
run gh auth switch to the odido account.
