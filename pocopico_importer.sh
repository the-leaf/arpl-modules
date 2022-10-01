#!/bin/bash

echo "Downloading json"
curl -sLO "https://raw.githubusercontent.com/pocopico/rp-ext/main/rpext-index.json"

echo "Getting releases"
declare -A RELEASES
while IFS="=" read KEY VALUE; do
  [ -n "${KEY}" ] && RELEASES["${KEY}"]="${VALUE}"
done < <(jq -r '.releases | to_entries | map([.key, .value] | join("=")) | .[]' rpext-index.json)
declare -A RELEASES2
for R in ${!RELEASES[@]}; do
  MODEL=`echo ${R} | cut -d'_' -f1`
  NUM=`echo ${R} | cut -c'_' -f2`
  PLATFORM=""
  case "${MODEL}" in
    ds3615xs) PLATFORM="bromolow_3.10.108" ;;
    ds3617xs) PLATFORM="broadwell_4.4.180" ;;
    ds3622xsp) PLATFORM="broadwellnk_4.4.180" ;;
    ds918p) PLATFORM="apollolake_4.4.180" ;;
    ds920p) PLATFORM="geminilake_4.4.180" ;;
    ds1621p) PLATFORM="v1000_4.4.180" ;;
    dva1622) PLATFORM="geminilake_4.4.180" ;;
    dva3221) PLATFORM="denverton_4.4.180" ;;
  esac
  if [ -n "${PLATFORM}" ]; then
    if [ ${NUM} -eq "42218" -o ${NUM} -eq "42661" ]; then
      RELEASES2[${PLATFORM}]="${RELEASES[${R}]}"
    fi
  fi
done

echo "Downloading and extracting"
for R in ${!RELEASES2[@]}; do
  URL="${RELEASES2[${R}]}"
  curl -sL "${URL}" -o "rel.json"
  unset FILES URLS
  declare -a FILES URLS
  while read NAME; do
    FILES+=(${NAME})
  done < <(jq -r '.files[].name' rel.json)
  while read URL; do
    URLS+=(${URL})
  done < <(jq -r '.files[].url' rel.json)
  C=0
  for F in ${FILES[@]}; do
    if grep -q "tgz" <<<${F}; then
        echo "Download ${F} in ${URLS[${C}]}"
        curl -sL "${URLS[${C}]}" -o module.tgz
        mkdir -p "${R}_pocopico"
        echo "Extracting to ${R}_pocopico"
        tar -xvaf module.tgz -C "${R}_pocopico"
        break
    fi
    C=$((${C}+1))
  done
done
rm -f module.tgz
rm -f rel.json
rm -f rpext-index.json
