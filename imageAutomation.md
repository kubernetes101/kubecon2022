# Image Automation with Flux Spike

The following instructions will demonstrate how to bootstrap a Kubernetes Cluster with FluxCD v2 including the Image Reflector and Image Automation controllers while showing an end-to-end flow.

## Bootstrap Flux with extra components

``` bash
export BRANCH='image-automation'

git checkout -b $BRANCH

git push --set-upstream origin $BRANCH

flux bootstrap git \
  --url "https://github.com/${organization}/${repository}" \
  --branch $BRANCH \
  --token-auth \
  --password ${GITHUB_TOKEN} \
  --path "/deploy/bootstrap" \
  --components-extra=image-reflector-controller,image-automation-controller

  git pull
  ```

## Deploy NGSA Application

```bash
kubectl create ns ngsa

flux create kustomization "ngsa" \
    --source GitRepository/flux-system \
    --path "/deploy/ngsa" \
    --namespace flux-system \
    --prune true \
    --interval 1m \
    --export > deploy/bootstrap/ngsa-kustomization.yaml

git add deploy/bootstrap/ && \
    git commit -m "Add ngsa kustomization" && \
    git push && \
    flux reconcile source git flux-system && \
    flux reconcile kustomization flux-system
```

### View current image version

``` bash
kubectl get deployment/ngsa-memory -oyaml -n ngsa | grep 'image:'
```

## Configure Image Scanning

Create an ImageRepository to tell Flux which container registry to scan for new tags:

``` bash
flux create image repository ngsa \
--image=ghcr.io/joaquinrz/ngsa-app \
--interval=1m \
--export > ./deploy/ngsa/ngsa-app-registry.yaml
```

Create an ImagePolicy to tell Flux which semver range to use when filtering tags:

``` bash
flux create image policy ngsa \
--image-ref=ngsa \
--select-semver=1.2.x \
--export > ./deploy/ngsa/ngsa-app-policy.yaml
```

Commit changes and reconcile

``` bash
git add deploy && \
git commit -m "add ngsa image scan" && \
git push && \
flux reconcile kustomization flux-system --with-source
```

Wait for Flux to fetch the image tag list from GitHub container registry:

``` bash
flux get image repository ngsa

flux get image policy ngsa
```

Create an ImageUpdateAutomation to tell Flux which Git repository to write image updates to:

``` bash
flux create image update flux-system \
--git-repo-ref=flux-system \
--git-repo-path="./deploy/ngsa" \
--checkout-branch=$BRANCH \
--push-branch=$BRANCH \
--author-name=fluxcdbot \
--author-email=fluxcdbot@users.noreply.github.com \
--commit-template="{{range .Updated.Images}}{{println .}}{{end}}" \
--export > ./deploy/ngsa/flux-system-automation.yaml
```

Commit changes and reconcile

``` bash
git add deploy && \
git commit -m "Added image updates automation" && \
git push && \
flux reconcile kustomization flux-system --with-source
```

> 🛑 Do changes to ngsa-app and bump version

``` bash
flux reconcile kustomization flux-system --with-source

kubectl describe ImageUpdateAutomation flux-system -n flux-system
```

### View current image version

``` bash
kubectl get deployment/ngsa-memory -oyaml -n ngsa | grep 'image:'
```
