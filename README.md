# helium.nix

Nix flake for the official [Helium](https://helium.computer/) Linux binary release.

- System: `x86_64-linux`
- Package: `helium-bin`
- Executable: `helium`
- Source: official [`imputnet/helium-linux`](https://github.com/imputnet/helium-linux) release tarball
- Integrity: pinned SHA-256, checked against the GitHub release digest by `update.sh`
- Sandbox: Chromium sandbox enabled; no `--no-sandbox` flag

## Run

```console
nix run github:gnkz/helium.nix
```

Pass browser arguments after `--`:

```console
nix run github:gnkz/helium.nix -- --incognito
```

## Temporary shell

```console
nix shell github:gnkz/helium.nix
helium
```

One command:

```console
nix shell github:gnkz/helium.nix -c helium
```

## Profile installation

```console
nix profile add github:gnkz/helium.nix
helium
```

Remove:

```console
nix profile remove helium
```

## Flake input

```nix
{
  inputs.helium.url = "github:gnkz/helium.nix";
}
```

## NixOS

Use the `helium` input from the enclosing flake `outputs` arguments:

```nix
{
  environment.systemPackages = [
    helium.packages.x86_64-linux.default
  ];
}
```

## Home Manager

Use the `helium` input from the enclosing flake `outputs` arguments:

```nix
{
  home.packages = [
    helium.packages.x86_64-linux.default
  ];
}
```

## Outputs

| Output | Purpose |
| --- | --- |
| `packages.x86_64-linux.default` | Default Helium package |
| `packages.x86_64-linux.helium` | Named Helium package |
| `apps.x86_64-linux.default` | Default `nix run` application |
| `apps.x86_64-linux.helium` | Named `nix run` application |
| `devShells.x86_64-linux.default` | Development and release dependencies |
| `formatter.x86_64-linux` | `nixfmt` formatter |

## Development and updates

Enter the development shell for `just`, Git, and the updater dependencies, then
list the available tasks:

```console
nix develop
just
```

| Task | Purpose |
| --- | --- |
| `just build` | Build Helium |
| `just check` | Check the flake and build Helium |
| `just fmt` | Format Nix files |
| `just show` | Show flake outputs |
| `just run [args…]` | Run Helium with optional browser arguments |
| `just develop` | Enter the development shell |
| `just update-inputs [inputs…]` | Update all or selected inputs in `flake.lock` |
| `just check-update` | Check for a newer stable Helium release without downloading the archive or changing files |
| `just update` | Download and verify a newer release, then update `versions.nix` |
| `just release` | Update Helium, check the flake, commit, and push |

`just check-update` reports the current/latest versions and exits successfully
whether or not an update is available; lookup or validation failures exit nonzero.
The updater leaves the pin unchanged when the latest version is equal to or older
than the current version.

Run `just release` from a clean checkout on a branch with a configured upstream.
It checks for a newer stable release, verifies the downloaded archive against
GitHub's digest when provided, and updates the flake's package pin in `versions.nix`.
It then runs `nix flake check --no-update-lock-file`, commits only `versions.nix`
as `chore: update Helium to <version>`, and pushes the current branch to its
configured upstream. With no newer version, it makes no commit or push.
Flake inputs are updated separately with `just update-inputs`.

Failures stop the release immediately. A failed check leaves the update available
for inspection; a failed push leaves the local commit so you can retry the push
after resolving the error.

The updater also works directly via `nix develop -c ./update.sh [--check]`.

## Upstream and attribution

- Helium is created and maintained by [imput](https://imput.net/).
- Browser source: [`imputnet/helium`](https://github.com/imputnet/helium)
- Linux packaging and releases: [`imputnet/helium-linux`](https://github.com/imputnet/helium-linux)
- This repository is an unofficial Nix package and is not affiliated with imput.
- Helium and bundled Chromium components retain their upstream licenses.
