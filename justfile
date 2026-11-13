set shell := ["nu", "-c"]

# Does what is really here satisfy `.pov-repo/config.toml`?
status what="pov-repo":
    @nu .pov-repo/main.nu status {{what}}

# The way through a mounted skill-repo into its repo.
todo:
    @nu skills/wrapooncell-cli/wrapooncell-cli/main.nu

# Go to a pov-repo the config knows, picked from a list without a name.
switch what="pov-repo" name="":
    @nu .pov-repo/main.nu switch {{what}} {{name}}
