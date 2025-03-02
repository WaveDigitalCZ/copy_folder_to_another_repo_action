#!/bin/sh

set -e
set -x

if [ -z "$INPUT_SOURCE_FOLDER" ]
then
  echo "Source folder must be defined"
  return 1
fi

if [ -z "$INPUT_DESTINATION_BRANCH" ]
then
  INPUT_DESTINATION_BRANCH=master
fi
OUTPUT_BRANCH="$INPUT_DESTINATION_BRANCH"
git config --global --add safe.directory /github/workspace
INPUT_COMMIT_MSG="$(git show -s --format=%s)"

CLONE_DIR=$(mktemp -d)

echo "Cloning destination git repository"
git config --global user.email "$INPUT_USER_EMAIL"
git config --global user.name "$INPUT_USER_NAME"
git clone --single-branch --branch $INPUT_DESTINATION_BRANCH "https://$API_TOKEN_GITHUB@github.com/$INPUT_DESTINATION_REPO.git" "$CLONE_DIR"


if [ -n "$INPUT_DESTINATION_BRANCH_CREATE" ]
then
  git checkout -b "$INPUT_DESTINATION_BRANCH_CREATE"
  OUTPUT_BRANCH="$INPUT_DESTINATION_BRANCH_CREATE"
fi

echo "Copying contents to git repo"
# shellcheck disable=SC2115
ls -la $CLONE_DIR
cp -af "$INPUT_SOURCE_FOLDER/." "$CLONE_DIR"
cd "$CLONE_DIR"


git config --global --add safe.directory $CLONE_DIR

echo "Adding git commit"
git add .
if git status | grep -q "Changes to be committed"
then
  git commit --message "$INPUT_COMMIT_MSG"
  echo "Pushing git commit"
  git push -u origin "HEAD:$OUTPUT_BRANCH"
else
  echo "No changes detected"
fi
