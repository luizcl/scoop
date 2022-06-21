#!/bin/sh

set -eu

usage() {
    echo "usage: $(basename $0) [-n] NEW_VERSION"
    exit 1
}

SED_ARGS='-i'
BASE_URL='https://releases.infrahq.com/infra'
while getopts 'b:c:hn' OPTION; do
    case $OPTION in
        b) BASE_URL=$OPTARG ;;
        n) SED_ARGS= ;;
        *) usage ;;
    esac
done

shift $(( $OPTIND - 1 ))
[ $# -eq 1 ] || usage
NEW_VERSION=$1

CHECKSUMS=$(mktemp)
cleanup() { rm $CHECKSUMS; }
trap cleanup 0

curl -o$CHECKSUMS -fs $BASE_URL/v$NEW_VERSION/infra-checksums.txt

PACKAGE=infra
PART=${NEW_VERSION##*-}
if [ "$PART" != "$NEW_VERSION" ]; then
    PACKAGE=infra-$PART
fi

OLD_VERSION=$(jq -r .version <$PACKAGE.json)
EXPRS="s/$OLD_VERSION/$NEW_VERSION/g"
while read -r LINE; do
    set -- $LINE
    EXPRS="$EXPRS; /$2/{n;s/hash \".*\"/hash \"$1\"/;}"
done <$CHECKSUMS

echo $EXPRS | sed $SED_ARGS -f- $PACKAGE.json
