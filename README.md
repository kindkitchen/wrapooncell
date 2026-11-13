# About

A starter commit for a web of git submodules: an explicit, manual package (repository) manager. A node of the web:

    pov-repo[skill-repo[repo]]

- `repo` - a target repository. It lives without knowing of any wrapper.
- `skill-repo` - a public devx space around it: a `SKILL.md` with the name of its folder, and the `repo` mounted beside it as `<name>/`.
- `pov-repo` - a private devx space around that. It mounts skill-repos: the one of its own node to work on it, those of other nodes to use them.

A pov-repo starts from the newest `t*-init-pov-repo` tag of this repository, the prototype of them all.

## Rules

- **Strangers.** A pov-repo never lives below another one, at any depth: each is a root of its own, marked by `.pov-repo/config.toml`.
- **Skill layer only.** A pov-repo mounts nothing but skill-repos, each through its remote, the one of its own node too.
- **Subscribed.** A mount follows a branch of its skill-repo: the head that the pov-repo of that node moves forward, or a branch moved from here, which others may follow in turn.
- **Declared.** `.pov-repo/config.toml` declares what a pov-repo wants: the folder of its skill-repos and the branch each one follows. `just status pov-repo` errors when what is really here does not satisfy it.
- **Manual.** Nothing follows by itself. A pin moves when someone commits it, each repository for itself.

## Opinions

- **Folder.** A skill-repo is mounted at `<folder>/<name>/`, where the config names the folder: `skills` here. Its `SKILL.md` is context on need: read it when that node comes into play. `.pi/settings.json` makes pi list them as skills.
- **Entrypoint.** `justfile` is the public face of a pov-repo. The essential scripts behind it are nushell, in `.pov-repo/main.nu`.
- **Origin.** For now a node lives in this same origin, as the branches `pov-repo/<name>/main`, `skill-repo/<name>/main` and `repo/<name>/main`.

## Technical preferences

- `nushell` is a main shell - should be used for terminal commands, scripts, examples.


# Agentic instructions

- Be compact, concise, simple.
- Any content generation especially code - must be happen only when necessary.
It means that until it is not reduce efficiency and quality - try to write less.
- Only user's explicit intentions should initiate generated result. So when the
candidates to improve, refine or fix are detected outside it's attention - they
should be proposed and argued in chat, simply inform user in a btw manner. That's all.
You should not worry about the decision to applying such insights because if user
will be attracted by them - it will be appeared implicitly in his next messages.

#### Git

- Never create git co-author on commits.
- Git work-tree may be created only on user request.

