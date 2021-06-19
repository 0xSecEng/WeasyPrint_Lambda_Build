#!/bin/bash

set -e

PYVER=py37

docker image build -f Dockerfile -t weasyprint-$PYVER .
docker create -ti --name dummy-$PYVER weasyprint-$PYVER bash
docker cp dummy-$PYVER:/opt/weasyprint-$PYVER.zip .
docker cp dummy-$PYVER:/opt/output.pdf ./output-$PYVER.pdf
docker rm dummy-$PYVER
