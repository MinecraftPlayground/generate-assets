# generate-assets
GitHub Action that generates Minecraft default resourcepack assets for a specified version.

[![Test Action](https://github.com/MinecraftPlayground/generate-assets/actions/workflows/test_action.yml/badge.svg)](https://github.com/MinecraftPlayground/generate-assets/actions/workflows/test_action.yml)

## Usage

```yaml
jobs:
  download-assets:
    runs-on: ubuntu-latest
    steps:
      - name: 'Download assets to "./default_assets".'
        id: download_assets
        uses: MinecraftPlayground/generate-assets@latest
        with:
          version: 1.21.2
          path: './default_assets'
          parallel-downloads: 10
```

### Inputs

| Input                | Required? | Default                                                           | Description                                                                            |
| :------------------- | --------- | :---------------------------------------------------------------- | :------------------------------------------------------------------------------------- |
| `version`            | No        | `latest-release`                                                  | Minecraft version to generate assets for or one of `latest-release`/`latest-snapshot`. |
| `path`               | No        | `./default`                                                       | Relative path under `$GITHUB_WORKSPACE` to place the assets.                           |
| `api-url`            | No        | `https://piston-meta.mojang.com/mc/game/version_manifest_v2.json` | URL to the Minecraft manifest API.                                                     |
| `resources-url`      | No        | `https://resources.download.minecraft.net`                        | URL to the Minecraft resources API.                                                    |
| `parallel-downloads` | No        | `5`                                                               | How much files to download in parallel.                                                |
| `download-retries`   | No        | `3`                                                               | How much retries to download failed files.                                             |

### Outputs

| Output             | Description                           |
| :----------------- | :------------------------------------ |
| `failed-downloads` | List of URLs that failed to download. |

## License
The scripts and documentation in this project are released under the [GPLv3 License](./LICENSE).
