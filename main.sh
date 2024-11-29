VERSION=$1
PATH=$2
MANIFEST_API_URL=$3
RESOURCES_API_URL=$4

echo "Make temp download directory."
TEMP_DOWNLOAD_DIR=$(mktemp -d)

echo "Fetch package URL."
package_url=$(curl -L $MANIFEST_API_URL | jq -r ".VERSIONs[] | select(.id == \"$VERSION\") | .url")



echo "Fetch client.jar URL from \"$package_url\"."
jar_url=$(curl -L $package_url | jq -r ".downloads.client.url")

echo "Downloading client.jar from \"$jar_url\"."
curl -L -o $TEMP_DOWNLOAD_DIR/client.jar $jar_url

echo "Saved client.jar to \"$TEMP_DOWNLOAD_DIR\"."


echo "Extract assets from client.jar"
mkdir -p "$TEMP_DOWNLOAD_DIR/generated"
        
unzip $TEMP_DOWNLOAD_DIR/client.jar "pack.png" -d "$TEMP_DOWNLOAD_DIR/generated"
unzip $TEMP_DOWNLOAD_DIR/client.jar "assets/*" -d "$TEMP_DOWNLOAD_DIR/generated"



echo "Fetch asset index URL from \"$package_url\""
asset_index_url=$(curl -L $package_url | jq -r ".assetIndex.url")

assets_path=$(mkdir -p "$TEMP_DOWNLOAD_DIR/generated/assets")

curl -L $asset_index_url | jq -r '.objects | to_entries[] | "\(.key) \(.value.hash)"' | while read -r path hash; do
  
  mkdir -p "$assets_path/$(dirname "$PATH")"
  
  first_hex="${hash:0:2}"

  url="$RESOURCES_API_URL/$first_hex/$hash"

  destination="$assets_path/$PATH"

  curl -s -o "$destination" "$url"

  echo "Saved \"$url\"" to \"$destination\"."
done

ls -al $TEMP_DOWNLOAD_DIR
