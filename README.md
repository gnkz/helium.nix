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
| `devShells.x86_64-linux.default` | Updater dependencies |
| `formatter.x86_64-linux` | `nixfmt` formatter |

## Update

Fetch the latest stable release, verify its digest, and update `versions.nix`:

```console
nix develop -c ./update.sh
nix flake check
```

## Upstream and attribution

- Helium is created and maintained by [imput](https://imput.net/).
- Browser source: [`imputnet/helium`](https://github.com/imputnet/helium)
- Linux packaging and releases: [`imputnet/helium-linux`](https://github.com/imputnet/helium-linux)
- This repository is an unofficial Nix package and is not affiliated with imput.
- Helium and bundled Chromium components retain their upstream licenses.
