set shell := ["nu", "-c"]

# `status pov-repo`: does what is really here contradict `.pov-repo/config.toml`?
status target *flags:
    @nu .pov-repo/main.nu status {{target}} {{flags}}

# `update skill-repo`: bring what the config declares and is not here yet. Said only, until `--apply`.
update target *flags:
    @nu .pov-repo/main.nu update {{target}} {{flags}}

# `pull skill-repo`: take into a mount what a variant of it holds: `--name`, `--remote`, or picked from a list. Said only, until `--apply`.
pull target *flags:
    @nu .pov-repo/main.nu pull {{target}} {{flags}}

# `push skill-repo`: give a variant what its mount holds, the same way.
push target *flags:
    @nu .pov-repo/main.nu push {{target}} {{flags}}

# The way through a mounted skill-repo into its repo.
todo:
    @nu skills/wrapooncell-cli/wrapooncell-cli/main.nu

# `switch pov-repo`: go to a pov-repo the config knows: `--name`, or picked from a list. A branch is switched only with `--apply`.
switch target *flags:
    @nu .pov-repo/main.nu switch {{target}} {{flags}}
