#!/usr/bin/env sh


mkdir dist
cp -r src dist/
cp -r resources dist/
cp -r data dist/
cp icon.dds dist/
cp modDesc* dist/

rm -f ./FS17_seasons.zip

cd dist
zip -r ../FS17_seasons.zip .  -x "*.DS_Store"
cd ..

rm -Rf dist/
