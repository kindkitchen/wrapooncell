# The essential scripts of a pov-repo. The justfile is their public entrypoint.

const config = '.pov-repo/config.toml'

# What `.gitmodules` really holds.
def mounted [] {
    if not ('.gitmodules' | path exists) { return [] }
    ^git config --file .gitmodules --list | lines
    | parse --regex '^submodule\.(?<name>.+?)\.(?<key>path|branch)=(?<value>.*)$'
    | group-by name | values
    | each {|rows| $rows | reduce --fold {} {|row, mount| $mount | insert $row.key $row.value } }
    | default '' branch | select path branch
}

# The name a folder gives itself in its `SKILL.md`, if it has one.
def skill-name [path: string] {
    let file = $path | path join SKILL.md
    if ($file | path exists) { open --raw $file | lines | parse 'name: {name}' | get 0?.name }
}

# Does what is really here satisfy the config? It errors when not.
def "main status pov-repo" [] {
    cd ($env.FILE_PWD | path dirname)
    let want = open $config | get --optional skill-repo | default {}
    let folder = $want.folder? | default ''
    let declared = $want.submodule? | default {} | transpose name branch
        | each {|it| {path: ($folder | path join $it.name), branch: $it.branch} }
    let mounted = mounted
    let state = ^git submodule status | lines | parse --regex '^(?<state>.)\S+ (?<path>.+?)(?: \(.*\))?$'
        | update state {|it| {' ': pinned, '+': moved, '-': absent, 'U': conflict} | get $it.state }
    let fetched = $state | where state != absent | get path
    let problems = [
        ...(if ($folder | is-empty) { ['skill-repo.folder is not declared'] } else { [] })
        ...(glob $'*/**/($config)' --exclude ['**/.git/**'] | path relative-to (pwd) | each {|it| $'a pov-repo lives below this one: ($it | path dirname | path dirname)' })
        ...($declared | where $it not-in $mounted | each {|it| $'declared, (if $it.path in $mounted.path { 'subscribed otherwise' } else { 'not mounted' }): ($it.path)' })
        ...($mounted | where path not-in $declared.path | each {|it| $'mounted, not declared: ($it.path)' })
        ...($fetched | where (skill-name $it) != ($it | path basename) | each {|it| $'not a skill-repo, its SKILL.md must name it as its folder: ($it)' })
    ]
    if ($mounted | is-not-empty) { print ($mounted | join --left $state path | select path branch state) }
    if ($problems | is-empty) { print $'($config) is satisfied' } else { print ...($problems | each { $'- ($in)' }); exit 1 }
}

def main [] { help main }
