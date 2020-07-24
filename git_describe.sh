OUTPUT=$(git describe --exact-match --tags $(git log -n1 --pretty='%h')|grep "fatal:")
if [[ $OUTPUT != "0" ]]; then
    echo "no tag present"
fi
