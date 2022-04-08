#!/bin/bash

# this runs at Codespace creation - not part of pre-build

echo "post-create start"
echo "$(date)    post-create start" >> "$HOME/status"

# update the repos
git -C /workspaces/imdb-app pull
git -C /workspaces/webvalidate pull

# install Flux
flux install >> ~/status

# create Flux GitRepository
flux create source git "${organization,,}-${repository,,}" \
    --url https://github.com/${organization}/${repository} \
    --branch main \
    --username=PersonalAccessToken \
    --password=${GITHUB_TOKEN} >> ~/status

# create Flux Kustomization
flux create kustomization "${organization,,}-${repository,,}" --source GitRepository/"${organization,,}-${repository,,}" --path="${deploymentPath}" --prune=true --interval=1m >> ~/status

echo "post-create complete"
echo "$(date +'%Y-%m-%d %H:%M:%S')    post-create complete" >> "$HOME/status"
