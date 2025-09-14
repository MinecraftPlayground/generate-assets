#!/bin/sh

if [ "$INPUT_VERSION" == "latest-snapshot" ]; then
  echo "Fetching the latest snapshot version."
  latest_version=$(curl -L $INPUT_MANIFEST_API_URL | jq -r '.latest.snapshot')

  if [ -z "$latest_version" ]; then
    echo "Error: Could not find the latest snapshot version in the manifest."
    exit 1
  fi

  echo "Using latest snapshot version: $latest_version"
  INPUT_VERSION="$latest_version"

elif [ "$INPUT_VERSION" == "latest-release" ]; then
  echo "Fetching the latest release version."
  latest_version=$(curl -L $INPUT_MANIFEST_API_URL | jq -r '.latest.release')

  if [ -z "$latest_version" ]; then
    echo "Error: Could not find the latest release version in the manifest."
    exit 1
  fi

  echo "Using latest release version: $latest_version"
  INPUT_VERSION="$latest_version"

else
  echo "Using specified version: $INPUT_VERSION"
fi

echo "Make temp download directory."
TEMP_DOWNLOAD_DIR=$(mktemp -d)

echo "Fetch package URL from \"$INPUT_MANIFEST_API_URL\"."
package_url=$(curl -L $INPUT_MANIFEST_API_URL | jq -r ".versions[] | select(.id == \"$INPUT_VERSION\") | .url")

echo "Fetch client.jar URL from \"$package_url\"."
jar_url=$(curl -L $package_url | jq -r ".downloads.client.url")

echo "Fetching client.jar SHA1 hash from \"$package_url\"."
client_jar_sha1=$(curl -L $package_url | jq -r ".downloads.client.sha1")

echo "Downloading client.jar from \"$jar_url\"."
curl -L -o $TEMP_DOWNLOAD_DIR/client.jar $jar_url

echo "Verifying SHA1 hash of client.jar."
downloaded_sha1=$(sha1sum "$TEMP_DOWNLOAD_DIR/client.jar" | awk '{print $1}')

if [ "$downloaded_sha1" != "$client_jar_sha1" ]; then
  echo "Error: SHA1 hash does not match. Expected $client_jar_sha1, but got $downloaded_sha1."
  exit 1
else
  echo "SHA1 hash verification passed for client.jar."
fi

echo "Saved \"client.jar\" to \"$TEMP_DOWNLOAD_DIR\"."

echo "::group:: Extract assets from client.jar"
unzip "$TEMP_DOWNLOAD_DIR/client.jar" "pack.png" -d "$INPUT_PATH"
unzip "$TEMP_DOWNLOAD_DIR/client.jar" "assets/*" -d "$INPUT_PATH"
echo "::endgroup::"

echo "Fetch asset index URL from \"$package_url\"."
asset_index_url=$(curl -L $package_url | jq -r ".assetIndex.url")

echo "::group:: Downloading additional assets from \"$asset_index_url\"."
export assets_path="$INPUT_PATH/assets"

echo "Saving additional assets to \"$assets_path\"."

asset_list=$(curl -L $asset_index_url | jq -r '.objects | to_entries[] | "\(.key) \(.value.hash)"')

FAILED_DOWNLOADS_FILE=$(mktemp)

echo "$asset_list" | while read -r path hash; do
  echo "$path $hash"
done | xargs -n 2 -P "$INPUT_PARALLEL_DOWNLOADS" -I {} sh -c '
  path=$(echo {} | awk "{print \$1}")
  hash=$(echo {} | awk "{print \$2}")
  first_hex="${hash:0:2}"
  url="$INPUT_RESOURCES_API_URL/$first_hex/$hash"
  destination="$assets_path/$path"
  failed_file="$1"

  mkdir -p "$(dirname "$destination")"

  retries="$INPUT_DOWNLOAD_RETRIES"
  attempt=1

  while [ $attempt -le $retries ]; do
    if curl -f -s -o "$destination" "$url"; then
      echo -e "Saved \"$url\" to \"$destination\"."
      exit 0
    else
      echo -e "\033[33mAttempt $attempt/$retries failed for \"$url\".\033[0m"
      attempt=$((attempt + 1))
      sleep 1
    fi
  done

  echo -e "\033[31mFailed to download \"$url\" after $retries attempts.\033[0m"
  echo "\"$url\"" >> "$failed_file"
' _ "$FAILED_DOWNLOADS_FILE"

echo "::endgroup::"

echo "::group:: Iterate over downloaded files to find and unzip ZIP files."

find "$INPUT_PATH" -type f -name "*.zip" | while read -r zipfile; do
  unzip_dir="${zipfile%.zip}_unzipped"
  
  echo "Unzipping \"$zipfile\" to \"$unzip_dir\"."
  
  mkdir -p "$unzip_dir"
  
  if unzip -o "$zipfile" -d "$unzip_dir"; then
    echo "Successfully unzipped \"$zipfile\"."
  else
    echo "Failed to unzip \"$zipfile\"."
  fi
  
  echo "Removing \"$zipfile\"."
  rm "$zipfile"
  
  original_name="${zipfile%.zip}.zip"
  echo "Renaming \"$unzip_dir\" to \"$original_name\"."
  mv "$unzip_dir" "$original_name"

done

echo "::endgroup::"

echo "All files downloaded and processed."

if [ -s "$FAILED_DOWNLOADS_FILE" ]; then
  echo "::group:: Some downloads failed:"
  cat "$FAILED_DOWNLOADS_FILE"
  echo "::endgroup::"

  failed_urls=$(jq -R -s -c 'split("\n")[:-1]' "$FAILED_DOWNLOADS_FILE")
  echo "failed-downloads=$failed_urls" >> "$GITHUB_OUTPUT"
else
  echo "failed-downloads=[]" >> "$GITHUB_OUTPUT"
fi

exit 0
