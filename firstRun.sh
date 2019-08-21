#!/usr/bin/env bash

die () {
    echo >&2 "$@"
    exit 1
}

[ "$#" -eq 1 ] || die "NPM_TOKEN Required required, $# provided"

grep -qxF 'export NPM_TOKEN' ~/.bashrc || echo "export NPM_TOKEN=$1" | tee -a ~/.bashrc

. ~/.nvm/nvm.sh
nvm install 9.9.0
mkdir repos
pushd repos

git clone git@github.com:Nautic-ON/deploy-gcp.git
git clone git@github.com:Nautic-ON/cv-backend-documentation.git

popd

gcloud auth login
