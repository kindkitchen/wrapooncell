set shell := ["nu", "-c"]

# Does what is really here satisfy `.pov-repo.toml`?
status what="pov-repo":
    @nu .pov-repo.nu status {{what}}

# The way through a mounted skill-repo into its repo.
todo:
    @nu skills/wrapooncell-cli/wrapooncell-cli/main.nu
