set shell := ["nu", "-c"]

# Does what is really here satisfy `.pov-repo.toml`?
status what="pov-repo":
    @nu .pov-repo.nu status {{what}}
