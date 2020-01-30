#!/usr/bin/env bash

# notarizer - macOS notarizing frontend.
#
# Depends on Xcode commandline tools as well as gon, a tool that allows us
# to poll the notarizing session status easily.
#
# usage: AC_PASSWORD=XXXXX notarizer.sh
#    -a ARCHIVE - tarball containing all contents for distribution
#    -u DEVELOPER_ACCOUNT_USER - apple developer account user name
#    -i APP_ID - unique application identifier
#    -v APP_VERSION - application version
#    -c CODESIGN_IDENTITY - certificate identity usable for signing code
#    -p PRODUCTSIGN_IDENTITY - certificate identity usable for signing installer
#    [-r PROVIDER] - apple developer account team identifier
#.   [-d DESTINATION] - installation destination folder - ["/usr/local/bin"]
#    [-h] - help

set -e

archive=""
app_id=""
app_version=""
developer_account_user=""
codesign_identity=""
productsign_identity=""
provider=""

package_name="package"
destination="/usr/local/bin"


function cleanup {
    rm -rf $temp_folder
}

function usage() {
    echo "usage: $0 \\"
    echo "    -a ARCHIVE \\"
    echo "    -u DEVELOPER_ACCOUNT_USER \\"
    echo "    -i APP_ID \\"
    echo "    -v APP_VERSION \\"
    echo "    -c CODESIGN_IDENTITY \\"
    echo "    -p PRODUCTSIGN_IDENTITY \\"
    echo "    [-r PROVIDER] [-d DESTINATION] | [-h]"
}

function process() {
    # Make temporary and package root directories.
    local temp_folder=`mktemp -d -t "notarizer"`
    local package_root="${temp_folder}/root"
    mkdir $package_root

    trap cleanup EXIT

    # Extract archive into temporary folder.
    tar -C $package_root -xvf $archive

    pushd $package_root

    # Go through all files in need of a signature and apply one.
    # Note: This implies that signatures get applied to executable files only.
    # TODO(tillt): Update this for dylib's when needed.
    find . -type f -perm +111 -print |                              \
         tr '\n' '\0' |                                             \
         xargs -n 1 -0                                              \
            codesign -s "$codesign_identity" -f -v --timestamp --options runtime

    popd

    # Package contents of temporary folder.
    pkgbuild --root $package_root                   \
             --identifier $app_id                   \
             --version $app_version                 \
             --install-location $destination        \
             $temp_folder/$package_name.pkg.unsigned

    # Sign the package.
    productsign --sign "$productsign_identity"          \
                --timestamp                             \
                $temp_folder/$package_name.pkg.unsigned \
                $temp_folder/$package_name.pkg

    # Notarize and on success copy resulting package to the invocation location.
    cat <<EOF >> $temp_folder/$package_name.json
{
    "apple_id": {
        "username" : "${developer_account_user}",
        "password":  "@env:AC_PASSWORD",
        "provider":  "${provider}"
    },
    "notarize": {
      "path": "${temp_folder}/${package_name}.pkg",
      "bundle_id": "${app_id}",
      "staple": "true"
    }
}
EOF
    gon -log-level=info $temp_folder/$package_name.json && cp ${temp_folder}/${package_name}.pkg .
}

function main() {
    echo "Codesigning, packaging, package signing and notarizing: "
    echo "  archive: $archive"
    echo "  package_name: ${package_name}"
    echo "  app_id: ${app_id}"
    echo "  app_version: ${app_version}"
    echo "  destination: ${destination}"
    echo "  developer_account_user: ${developer_account_user}"
    echo "  provider: ${provider}"
    echo "  codesign_identity: ${codesign_identity}"
    echo "  productsign_identity: ${productsign_identity}"

    process
}

while [ "$1" != "" ]; do
    case $1 in
        -a | --archive )                shift
                                        archive=$1
                                        ;;
        -i | --app_id )        	        shift
                                        app_id=$1
                                        ;;
        -v | --app_version )            shift
                                        app_version=$1
                                        ;;
        -c | --codesign_identity )      shift
                                        codesign_identity=$1
                                        ;;
        -p | --productsign_identity )   shift
                                        productsign_identity=$1
                                        ;;
        -u | --developer_account_user ) shift
                                        developer_account_user=$1
                                        ;;
        -d | --destination )            shift
                                        destination=$1
                                        ;;
        -r | --provider )               shift
                                        provider=$1
                                        ;;
        -h | --help )                   usage
                                        exit
                                        ;;
        * )                             usage
                                        exit 1
    esac
    shift
done

if [[ -z $archive || \
        -z $developer_account_user ||   \
        -z $codesign_identity ||        \
        -z $productsign_identity ||     \
        -z $app_id ||                   \
        -z $app_version ]]; then
    usage
    exit
fi

main
