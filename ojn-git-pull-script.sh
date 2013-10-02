#!/bin/sh

BASE=$1
TIP=$2

case "${TIP}" in
tegra*)
    REPO=tegra
    ;;
bcm2835*)
    REPO=rpi
    ;;
*)
    echo Cannot determine which repo to pull from
    exit 1
    ;;
esac

BASE_SHA=$(git log --pretty=oneline -1 ${BASE} | cut -d' ' -f 1)
BASE_DESC=$(git log --pretty=oneline -1 ${BASE} | cut -d' ' -f 1 --complement)

TIP_SHA=$(git log --pretty=oneline -1 ${TIP} | cut -d' ' -f 1)
TIP_DESC=$(git log --pretty=oneline -1 ${TIP} | cut -d' ' -f 1 --complement)

TAG_SUBJ=$(git show ${TIP} | awk 'BEGIN {flag=0} /^$/ {flag=1; next} (flag==1) {print;exit}')

echo -n "From foo "; date
echo -n "From: "; git config --get sendemail.from
echo    "Subject: [GIT PULL] ${TAG_SUBJ}"
echo -n "Date: "; date -R
echo "X-NVConfidentiality: public"

# The following prints the blank line required to delineate headers/body
git show ${TIP} | awk 'BEGIN {flag=0} /^$/ {flag++} /-----BEGIN PGP/ {exit} (flag>1) {print}'

echo
echo "----------------------------------------------------------------"
echo

echo "The following changes since commit $BASE_SHA:"
echo
echo "  $BASE_DESC"
echo
echo "are available in the git repository at:"
echo
echo "  git://git.kernel.org/pub/scm/linux/kernel/git/swarren/linux-${REPO}.git $TIP"
echo

echo "for you to fetch changes up to $TIP_SHA:"
echo
echo "  $TIP_DESC"
echo
echo "----------------------------------------------------------------"
echo

git shortlog $BASE_SHA..$TIP_SHA | cat
git diff -M --stat=75 --summary $BASE_SHA..$TIP_SHA | cat
