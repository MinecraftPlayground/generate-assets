# generate-assets
GitHub Action that generates Minecraft default resourcepack assets for a specified version.

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

### Inputs 📥

| Input                | Required? | Default                                                           | Description                                                                            |
| :------------------- | --------- | :---------------------------------------------------------------- | :------------------------------------------------------------------------------------- |
| `version`            | `false`   | `latest-release`                                                  | Minecraft version to generate assets for or one of `latest-release`/`latest-snapshot`. |
| `path`               | `false`   | `./default`                                                       | Relative path under `$GITHUB_WORKSPACE` to place the assets.                           |
| `api-url`            | `false`   | `https://piston-meta.mojang.com/mc/game/version_manifest_v2.json` | URL to the Minecraft manifest API.                                                     |
| `resources-url`      | `false`   | `https://resources.download.minecraft.net`                        | URL to the Minecraft resources API.                                                    |
| `parallel-downloads` | `false`   | `5`                                                               | How much files to download in parallel.                                                |

## License
The scripts and documentation in this project are released under the [GPLv3 License](./LICENSE).
