#!/usr/bin/env bash

PACKAGE="$1"
BUCKET="$BUCKET"
PROFILE="gcreds-da-atos"


if [ ${PACKAGE#*amd64} ] == '.deb'; then

    cd '~/git/linux/buildpython3/packages/deb'

    for debpkg in $(ls ~/git/linux/buildpython3/packaging/deb); do
        # copy deb, rpm
        aws s3 cp $debpkg s3://$BUCKET/deb/$debpkg --profile $PROFILE
        # apply acl
        aws s3api put-object-acl --bucket $BUCKET --acl public-read --key deb/$PACKAGE --profile $PROFILE
    done

elif [ ${PACKAGE#*noarch} ] == '.rpm'; then

    cd  '~/git/linux/buildpython3/packages/rpm'

    for rpmpkg in $(ls ~/git/linux/buildpython3/packaging/rpm); do
        # copy rpm
        aws s3 cp $rpmpkg s3://$BUCKET/rpm/$rpmpkg --profile $PROFILE
        # apply acl
        aws s3api put-object-acl --bucket $BUCKET --acl public-read --key rpm/$rpmpkg --profile $PROFILE
    done

else
    echo -e "\nPackage $PACKAGE not recognized, nothing done. Exit"
fi

exit 0
