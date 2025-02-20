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

asset_list=$(curl -L $asset_index_url | jq -r '.objects | to_entries[] | "\(.key) \(.value.hash)"')

echo "$asset_list" | while read -r path hash; do
  echo "$path $hash"
done | xargs -n 2 -P "$INPUT_PARALLEL_DOWNLOADS" -I {} sh -c '
  path=$(echo {} | awk "{print \$1}")
  hash=$(echo {} | awk "{print \$2}")
  first_hex="${hash:0:2}"
  url="$INPUT_RESOURCES_API_URL/$first_hex/$hash"
  destination="$assets_path/$path"

  mkdir -p "$(dirname "$destination")"

  if curl -f -s -o "$destination" "$url"; then
    echo "Saved \"$url\" to \"$destination\"."
  else
    echo "Failed to download \"$url\"."
  fi
'

echo "::endgroup::"

echo "::group:: Iterate over downloaded files to find and unzip ZIP files."

find "$INPUT_PATH" -type f -name "*.zip" | while read -r zipfile; do
  unzip_dir="${zipfile%.zip}"
  
  echo "Unzipping \"$zipfile\" to \"$unzip_dir\"."
  
  mkdir -p "$unzip_dir"
  
  if unzip -o "$zipfile" -d "$unzip_dir"; then
    echo "Successfully unzipped \"$zipfile\"."
  else
    echo "Failed to unzip \"$zipfile\"."
  fi

  echo "Removing \"$zipfile\"."
  
  rm $zipfile
done

echo "::endgroup::"

echo "All ZIP files processed."

exit 0
