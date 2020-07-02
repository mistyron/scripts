RELEASE="Keats.20.07.0"

if [[ "$RELEASE" == *"RC"* ]]; then
    echo "it's an RC"
else
    read -p "Apply tag $RELEASE on balena?(N/y)" resp
    if [[ "$resp" == "y" ]]; then
        echo "add the balena tag"
    fi
fi
