#!/bin/bash

rm -f message

latest_version=$(rsync --list-only rsync://rsync.kde.org/kdeftp/stable/release-service/ | awk '{print $5}' | sort -r | sed -n '1p')
last_version=$(cat LATEST)

if [[ ${GITHUB_TOKEN} ]]; then
    echo -e "\e[32mLATEST VERSION\e[0m: ${latest_version}" >> message
    echo -e "\e[33mLAST VERSION\e[0m: ${last_version}" >> message

    if [[ ${latest_version} = ${last_version} ]]; then
        echo -e "\e[34m ==========>\e[0m Package is up-to-date." >> message
        echo -e "\e[34m ==========>\e[0m Nothing to do today." >> message
        exit
    fi
fi

# 生成SHA256SUM
curl https://download.kde.org/stable/release-service/${latest_version}/src/yakuake-${latest_version}.tar.xz -LOC -
sha256sum=$(sha256sum yakuake-${latest_version}.tar.xz | awk -F'  ' '{print $1}')

# 编辑templete
cp -f ./PKGBUILD.template ./PKGBUILD
sed "s/%%pkgver%%/${latest_version}/g" PKGBUILD -i
sed "s/%%sha256sum%%/${sha256sum}/g" PKGBUILD -i
cp -f ./SRCINFO.template ./.SRCINFO
sed "s/%%pkgver%%/${latest_version}/g" .SRCINFO -i
sed "s/%%sha256sum%%/${sha256sum}/g" .SRCINFO -i

[[ ${GITHUB_TOKEN} ]] || exit 0

# 更新缓存版本号
echo ${latest_version} > LATEST
git add LATEST
git config --local user.email "41898282+github-actions[bot]@users.noreply.github.com"
git config --local user.name "github-actions[bot]"
git commit -m "New Version ${latest_version}"
git push "https://${GITHUB_TOKEN}@${REPO}" main:main

# 更新AUR
mkdir workdir && cd workdir
git clone ssh://aur@aur.archlinux.org/yakuake-alca7raz.git && cd yakuake-alca7raz
cp -f ../../PKGBUILD ./PKGBUILD
cp -f ../../.SRCINFO ./.SRCINFO
git add PKGBUILD .SRCINFO
git config user.name ${AUR_NAME}
git config user.email ${AUR_EMAIL}
git commit -m "Update ${latest_version}"
git push origin master

cd ../..
echo -e "\e[32m ==========>\e[0m Package has been updated." >> message
rm -rf workdir
