# The essential scripts of a pov-repo, each as `<action> <target>` with named parameters only.
# A write is said only, until `--apply`. The justfile is their public entrypoint.

const config = '.pov-repo/config.toml'

# What the config declares of skill-repos, a row per mount: its variants, each a remote by `remote` and `url` and a `branch` there,
# the first of them being the one mounted. And how far it is here: unmounted, absent, or fetched and pinned or moved.
def declared [] {
    let want = open $config | get --optional skill-repo | default {}
    let rows = $want.submodule? | default {} | transpose name variants
    let odd = $rows | where {|it| not (try { ($it.variants | is-not-empty) and ($it.variants | all {|v| ($v | columns | sort) == [branch remote url] }) } catch { false }) } | get name
    if ($odd | is-not-empty) { error make --unspanned {msg: $'($config): ($odd | str join ", ") must be `[[skill-repo.submodule.<name>]]` variants, each of `remote`, `url` and `branch`'} }
    let state = ^git submodule status | lines | parse --regex '^(?<state>.)\S+ (?<path>.+?)(?: \(.*\))?$'
        | update state {|it| {' ': pinned, '+': moved, '-': absent, 'U': conflict} | get $it.state }
    $rows | each {|it|
        let path = $want.folder? | default '' | path join $it.name
        {name: $it.name, path: $path, ...$it.variants.0, variants: $it.variants, state: ($state | where path == $path | get 0?.state | default unmounted)}
    }
}

# What `.gitmodules` really holds.
def mounted [] {
    if not ('.gitmodules' | path exists) { return [] }
    ^git config --file .gitmodules --list | lines
    | parse --regex '^submodule\.(?<name>.+?)\.(?<key>path|url|branch)=(?<value>.*)$'
    | group-by name | values
    | each {|rows| $rows | reduce --fold {name: $rows.0.name} {|row, mount| $mount | insert $row.key $row.value } }
    | default '' branch | select name path url branch
}

# The remotes a mount really has.
def remotes [path: string] {
    ^git -C $path config --get-regexp '^remote\..*\.url$' | complete | get stdout | lines | parse 'remote.{remote}.url {url}'
}

# The name a folder gives itself in its `SKILL.md`, if it has one.
def skill-name [path: string] {
    let file = $path | path join SKILL.md
    if ($file | path exists) { open --raw $file | lines | parse 'name: {name}' | get 0?.name }
}

# How a fetched mount contradicts what is declared of it.
def contradicts [it: record] {
    let on = ^git -C $it.path branch --show-current | str trim
    [
        ...(if (skill-name $it.path) != $it.name { ['not a skill-repo, its SKILL.md must name it as its folder'] } else { [] })
        ...(remotes $it.path | where {|r| let v = $it.variants | where remote == $r.remote; if ($v | is-empty) { $r.url in $it.variants.url } else { $r.url != $v.0.url } } | each {|r| $'its remote ($r.remote) is not as declared' })
        ...(if $on not-in ['' $it.branch] { [$'on ($on), declared on ($it.branch)'] } else { [] })
        ...(if $on == '' and (^git -C $it.path rev-list --max-count=1 $'refs/heads/($it.branch)' --not HEAD --remotes | complete).stdout != '' { [$'detached, while its ($it.branch) holds commits found nowhere else'] } else { [] })
    ] | each {|said| $'($said): ($it.path)' }
}

# The writes of an action: said only, and done with `--apply`.
def write [apply: bool, commands: list] {
    for command in $commands { print ($command | str join ' '); if $apply { run-external ...$command } }
    if ($commands | is-empty) { print 'nothing to do' } else if not $apply { print 'said only: `--apply` does it' }
}

# Does what is really here contradict the config? It errors when so. `--quiet` says nothing when not.
def "main status pov-repo" [--quiet] {
    cd ($env.FILE_PWD | path dirname)
    let declared = declared
    let mounted = mounted
    let problems = [
        ...(if (open $config | get --optional skill-repo.folder | is-empty) { ['skill-repo.folder is not declared'] } else { [] })
        ...(glob $'*/**/($config)' --exclude ['**/.git/**'] | path relative-to (pwd) | each {|it| $'a pov-repo lives below this one: ($it | path dirname | path dirname)' })
        ...($declared | where state != unmounted and ($it | select path url branch) not-in ($mounted | select path url branch) | each {|it| $'declared, subscribed otherwise: ($it.path)' })
        ...($mounted | where path not-in $declared.path | each {|it| $'mounted, not declared: ($it.path)' })
        ...($declared | where state not-in [unmounted absent] | each {|it| contradicts $it } | flatten)
    ]
    if $quiet and ($problems | is-empty) { return }
    if ($declared | is-not-empty) { print ($declared | select path branch state) }
    if ($problems | is-empty) { print $'nothing here contradicts ($config)' } else { print ...($problems | each { $'- ($in)' }); exit 1 }
}

# Bring what the config declares of skill-repos and is not here yet: each mounted, fetched at its pin with what it mounts,
# its remotes beside it under their names, and on its branch. A pin that went ahead is merged in. A mount that went ahead stays where it is.
def "main update skill-repo" [--apply] {
    cd ($env.FILE_PWD | path dirname)
    main status pov-repo --quiet
    let stale = [
        ...(^git submodule status --recursive | lines | where $it starts-with '-' | parse --regex '^.\S+ (?<path>.+)$' | get path)
        ...(^git submodule foreach --quiet --recursive 'git merge-base --is-ancestor $sha1 HEAD 2>/dev/null || echo "$displaypath"' | lines)
    ]
    let mounted = mounted
    let plan = declared | each {|it|
        let git = [git -C $it.path]
        let rest = $it.variants | uniq-by remote | where {|v| $v.remote != $it.remote }
        let attach = [[...$git branch --force --track $it.branch $'($it.remote)/($it.branch)'] [...$git switch --force-create $it.branch]]
        let all = [[git submodule update --init --recursive --merge $it.path]]
        let module = $mounted | where path == $it.path | get 0?.name | default $it.path
        let kept = $it.state == 'absent' and (^git rev-parse --git-path $'modules/($module)' | str trim | path exists)
        if $kept {                                      # its clone was kept: it is looked at once it is back
            $all
        } else if $it.state in [unmounted absent] {     # not here yet: fetched as git does, then named and put as declared
            [
                (if $it.state == 'unmounted' { [git submodule add -b $it.branch $it.url $it.path] } else { [git submodule update --init $it.path] })
                ...(if $it.remote != 'origin' { [[...$git remote rename origin $it.remote]] } else { [] })
                ...($rest | each {|v| [...$git remote add $v.remote $v.url] })
                ...(if $it.state == 'absent' { $attach } else { [] })
                ...$all
            ]
        } else {                                        # here: only what it lacks
            let have = remotes $it.path | get remote
            [
                ...($rest | where {|v| $v.remote not-in $have } | each {|v| [...$git remote add $v.remote $v.url] })
                ...(if (^git -C $it.path branch --show-current | str trim) == '' { $attach } else { [] })
                ...(if ($stale | any {|path| $'($path)/' starts-with $'($it.path)/' }) { $all } else { [] })
            ]
        }
    } | flatten
    write $apply $plan
    if $apply { main status pov-repo; if ($plan | is-not-empty) { main update skill-repo } }
}

# A variant of a skill-repo that is here: the one `--name` and `--remote` leave, else picked from a list.
def variant [name: any, remote: any] {
    let all = declared | each {|it| $it.variants | each {|v| {name: $it.name, ...$v, path: $it.path, state: $it.state} } } | flatten
        | where ($name == null or $it.name == $name) and ($remote == null or $it.remote == $remote)
    let pick = if ($all | length) > 1 { $all | input list --fuzzy --display {|it| $'($it.name) ($it.remote) ($it.branch)' } 'variant' } else { $all | get 0? }
    if $pick == null { if ($all | is-empty) { error make --unspanned {msg: 'the config knows no such variant'} }; return }
    if $pick.state in [unmounted absent] or $pick.remote not-in (remotes $pick.path | get remote) { error make --unspanned {msg: $'($pick.path) has no ($pick.remote) yet: `update skill-repo` brings it'} }
    $pick
}

# Take into a mounted skill-repo what one of its variants holds.
def "main pull skill-repo" [--name: string, --remote: string, --apply] {
    cd ($env.FILE_PWD | path dirname)
    main status pov-repo --quiet
    let it = variant $name $remote
    if $it != null { write $apply [[git -C $it.path pull $it.remote $it.branch]] }
}

# Give one of its variants what a mounted skill-repo holds.
def "main push skill-repo" [--name: string, --remote: string, --apply] {
    cd ($env.FILE_PWD | path dirname)
    main status pov-repo --quiet
    let it = variant $name $remote
    if $it != null { write $apply [[git -C $it.path push $it.remote $'HEAD:refs/heads/($it.branch)']] }
}

# Go to a pov-repo the config knows, picked from a list without `--name`:
# to its location, when it has one and is there on its branch, else to its branch in this very repository.
def "main switch pov-repo" [--name: string, --apply] {
    cd ($env.FILE_PWD | path dirname)
    let known = open $config | get --optional pov-repo | default {} | transpose name it
        | each {|row| {name: $row.name, branch: $row.it.branch, location: $row.it.location?} }
    let pick = if $name != null { $known | where name == $name | get 0? } else if ($known | is-not-empty) { $known | input list --fuzzy 'pov-repo' }
    if $pick == null { if $name != null { error make --unspanned {msg: $'the config knows no pov-repo ($name)'} }; return }
    if $pick.location == null { write $apply [[git switch --recurse-submodules $pick.branch]]; return }
    let location = $pick.location | path expand
    let on = ^git -C $location branch --show-current | str trim | default --empty 'no branch'
    if $on != $pick.branch { error make --unspanned {msg: $'($location) is on ($on), not on ($pick.branch)'} }
    print $'a shell at ($location): `exit` comes back'
    cd $location
    exec $nu.current-exe
}

def main [] { help main }
