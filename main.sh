#!/bin/sh

echo "Make temp download directory."
TEMP_DOWNLOAD_DIR=$(mktemp -d)

echo "Fetch package URL from \"$INPUT_MANIFEST_API_URL\"."
package_url=$(curl -L $INPUT_MANIFEST_API_URL | jq -r ".versions[] | select(.id == \"$INPUT_VERSION\") | .url")

echo "Fetch client.jar URL from \"$package_url\"."
jar_url=$(curl -L $package_url | jq -r ".downloads.client.url")

echo "Downloading client.jar from \"$jar_url\"."
curl -L -o $TEMP_DOWNLOAD_DIR/client.jar $jar_url

echo "Saved \"client.jar\" to \"$TEMP_DOWNLOAD_DIR\"."
  
echo "::group:: Extract assets from client.jar"
unzip $TEMP_DOWNLOAD_DIR/client.jar "pack.png" -d "$INPUT_PATH"
unzip $TEMP_DOWNLOAD_DIR/client.jar "assets/*" -d "$INPUT_PATH"
echo "::endgroup::"

echo "Fetch asset index URL from \"$package_url\"."
asset_index_url=$(curl -L $package_url | jq -r ".assetIndex.url")

echo "::group:: Downloading additional assets from \"$asset_index_url\"."
assets_path="$INPUT_PATH/assets"

count=0

curl -L $asset_index_url | jq -r '.objects | to_entries[] | "\(.key) \(.value.hash)"' | while read -r path hash; do
  
  mkdir -p "$assets_path/$(dirname $path)"
  
  first_hex="${hash:0:2}"

  url="$INPUT_RESOURCES_API_URL/$first_hex/$hash"

  destination="$assets_path/$path"

  if curl -f -s -o "$destination" "$url"; then
    count=$($count + 1)
    echo "Saved \"$url\" to \"$destination\"."
  else
    echo "Failed to download \"$url\"."
  fi
done

echo "::endgroup::"
echo "Total files saved: $count"

exit 0
