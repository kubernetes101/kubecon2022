# Intro to Kubernetes, GitOps, and Observability Hands-On Tutorial

![License](https://img.shields.io/badge/license-MIT-green.svg)

## Overview

This tutorial offers newcomers a quick way to experience Kubernetes and its natural evolutionary developments: GitOps and Observability. Attendees will be able to use and experience the benefits of Kubernetes that impact reliability, velocity, security, and more. The session will cover key concepts and practices, as well as offer attendees a way to experience the commands in real-time.

We use this Codespaces platform for `inner-loop` Kubernetes training and development. Note that it is not appropriate for production use but is a great `Developer Experience`. Feedback calls the approach `game-changing` - we hope you agree!

## Join the Kubernetes101 GitHub Org

> You must be a member of the Kubernetes101 GitHub organization

- If you can't open a Codespace in this repo, you need to join the GitHub org(s)
  - Join the org by going [here](https://kube101.dev/)
- Return to this repo after joining the org

## Open with Codespaces

- Click the `Code` button on this repo
- Click the `Codespaces` tab
- Click `Create codespace on main`

<!-- TODO: Update image below -->
![Create Codespace](./images/OpenWithCodespaces.jpg)


![Running Codespace](./images/RunningCodespace.png)

<!-- TODO change image ^ -->

## Checking the k3d Cluster

- A k3d cluster is automatically created as part of the Codespace setup

  ```bash

  # check the namespaces
  kubectl get ns

  # check the services
  kubectl get services -A

  # check the pods
  kubectl get pods -A

  ```

- Output from `kubectl get pods -A` should resemble this

  ```text

  NAMESPACE     NAME                                      READY   STATUS              RESTARTS   AGE
  kube-system   metrics-server-86cbb8457f-qlp8v           1/1     Running             0          48s
  kube-system   local-path-provisioner-5ff76fc89d-wfpjx   1/1     Running             0          48s
  kube-system   coredns-7448499f4d-dnjzl                  1/1     Running             0          48s
  kube-system   helm-install-traefik-crd-zk5gr            0/1     Completed           0          48s
  kube-system   helm-install-traefik-mbr2l                0/1     Completed           1          48s
  kube-system   svclb-traefik-2ks5t                       2/2     Running             0          22s
  kube-system   traefik-97b44b794-txs9h                   1/1     Running             0          22s

  ```

## Introduction to Kuberenetes

To get started using kubernetes, we will be manually deploying our IMDB application. This REST application written in .NET allows us to run an in-memory database that accepts several movie and actor queries.

  ```bash

  # navigate to the folder containing all our imdb application manifests
  cd workshop-manifests/imdb

  # create the namespace that will contain all of our imdb application
  kubectl apply -f 01-namespace.yaml #(this also be accomplished by running `kubectl create ns imdb`)

  # apply our deployment yaml
  kubectl apply -f 02-deploy.yaml

  # verify that our pods were created
  kubectl get pods -n imdb

  # check application logs
  kubectl logs <pod name from above> -n imdb

  # query our application's endpoint (this will fail)
  http localhost:30080/healthz

  # apply our service yaml
  kubectl apply -f 03-service.yaml

  # query our application's endpoint
  http localhost:30080/healthz

  # delete our deployments
  kubectl delete ns imdb

  ```


- Review IMDB App yaml (Deploy, service, NodePort)
- Apply YAML
- Validate Deployment via http or curl
- Open IMDB Swagger in Browser

## GitOps with Flux

Flux has been installed into the k3d cluster, and the Flux CLI is included in the workshop codespaces.

First, you will need to create a Flux GitRepository. The Flux GitRepository allows the Flux Source Controller to
know which Git Repository and branch it should monitor.

```bash

export BRANCH=your-branch-here

flux create source git "${organization}-${repository}" \
    --url "https://github.com/${organization}/${repository}" \
    --branch $BRANCH \
    --namespace flux-system \
    --username PersonalAccessToken \
    --password ${GITHUB_TOKEN}

```

Next, create a Flux Kustomization. The Flux Kustomization allows the Flux Kustomize Controller to know where in the
GitRepository to find your declaratively defined desired state.

We will first create a Kustomization for the Observability components. In our Kustomizations, the `path` is defined as `/deploy/observability`; this means that Flux will
look in the `/deploy/observability` folder in your branch within the kubernetes101/kubecon2022 repository.

```bash

flux create kustomization "observability" \
    --source GitRepository/"${organization}-${repository}" \
    --path "/deploy/observability" \
    --namespace flux-system \
    --prune true \
    --interval 1m

```

We will then create a Kustomization for the IMDB Application. Note that the "application" Kustomization depends on the "observability" Kustomization.

```bash

flux create kustomization "application" \
    --source GitRepository/"${organization}-${repository}" \
    --path "/deploy/application" \
    --namespace flux-system \
    --prune true \
    --depends-on observability \
    --interval 1m

```

### Validating endpoints

Open [curl.http](./curl.http)

> [curl.http](./curl.http) is used in conjuction with the Visual Studio Code [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) extension.
>
> When you open [curl.http](./curl.http), you should see a clickable `Send Request` text above each of the URLs

![REST Client example](./images/RESTClient.png)

Clicking on `Send Request` should open a new panel in Visual Studio Code with the response from that request like so:

![REST Client example response](./images/RESTClientResponse.png)


## NodePorts

- Codespaces exposes `ports` to the local browser
- We take advantage of this by exposing `NodePort` on most of our K8s services
- Codespaces ports are setup in the `.devcontainer/devcontainer.json` file

- Exposing the ports

  ```json

  // forward ports for the app
  "forwardPorts": [
    30000,
    30080,
    31080,
    32000
  ],

  ```

- Adding labels to the ports

  ```json

  // add labels
  "portsAttributes": {
    "30000": { "label": "Prometheus" },
    "30080": { "label": "IMDb-app" },
    "31080": { "label": "Heartbeat" },
    "32000": { "label": "Grafana" },
  },

  ```

## View IMDB App

- Click on the `ports` tab of the terminal window
- Click on the `open in browser icon` on the IMDb-App port (30080)
- This will open the imdb-app home page (Swagger) in a new browser tab

## View Heartbeat

- Click on the `ports` tab of the terminal window
- Click on the `open in browser icon` on the Heartbeat port (31080)
- This will open the heartbeat home page (Swagger) in a new browser tab
  - Note that you will see page `Under construction ...` as heartbeat does not have a UI
  - Add `version` or `/heartbeat/17` to the end of the URL in the browser tab

## Validate deployment with k9s

> To exit K9s - `:q <enter>`

- From the Codespace terminal window, start `k9s`
  - Type `k9s` and press enter
  - Press `0` to select all namespaces

  - Use the arrow key to select `webv` pod for `heartbeat` then press the `l` key to view logs from the pod
    - Notice that WebV is making a heartbeat request every 5 seconds
    - To go back, press the `esc` key

  - Use the arrow key to select `webv` pod for `imdb` then press the `l` key to view logs from the pod
    - Notice that WebV is making 10 IMDb requests per second
    - To go back, press the `esc` key

  - Use the arrow key to select `jumpbox` then press `s` key to open a shell in the container
    - Test the `IMDb-App` service from within the cluster by executing

      ```bash

      # httpie is a "pretty" version of curl
      # test the webv-imdb service endpoint using local DNS
      http webv.imdb.svc.cluster.local:8080/metrics

      ```

      - `exit <enter>`
  - To view other resources - press `shift + :` followed by the deployment type (e.g. `secret`, `services`, `deployment`, etc).

![k9s](./images/k9s.png)

## View Fluent Bit Logs

> Fluent Bit is set to forward logs to stdout for debugging
>
> Fluent Bit can be configured to forward to different services including Grafana Cloud or Azure Log Analytics

- Start `k9s` from the Codespace terminal (if it's not running from previous step)
- Press `0` to show all `namespaces`
- Select `fluentbit` pod and press `enter`
- Press `enter` again to see the logs
- Press `s` to Toggle AutoScroll
- Press `w` to Toggle Wrap
- Review logs that will be sent to Grafana when configured

> To exit K9s - `:q <enter>`

## View Prometheus Dashboard

- Click on the `ports` tab of the terminal window
- Click on the `open in browser icon` on the Prometheus port (30000)
- This will open Prometheus in a new browser tab

- From the Prometheus tab
  - Begin typing `ImdbAppDuration_bucket` in the `Expression` search
  - Click `Execute`
  - This will display the log table that Grafana uses for the charts

## View Grafana Dashboard

- Grafana login info
  - admin
  - kubecon101

- Click on the `ports` tab of the terminal window
  - Click on the `open in browser icon` on the Grafana port (32000)
  - This will open Grafana in a new browser tab

![Codespace Ports](./images/CodespacePorts.jpg)

> `IMDb-App` dashboard is set as the default home dashboard to visualize constant load generated to the IMDB application.

![Grafana](./images/imdb-requests-by-mode.png)

### Explore Grafana Dashboards

- Click on the dashboard folder `General` at the top (with four squares) to access the dashboard search. The dashboard search can also be opened by using the shortcut `F`.
- The list will show all the dashboards configured in Grafana.
- We configure two dashboards as part of the initial deployment:
  - IMDb App
  - Dotnet

## Run integration and load tests

```bash

# from Codespaces terminal

# run an integration test (will generate warnings in Grafana)
kic test integration

# run a 30 second load test
kic test load

```

- Switch to the Grafana browser tab
- The integration test generates 400 and 404 results by design
- The requests metric will go from green to yellow to red as load increases
  - It may skip yellow
- As the test completes
  - The metric will go back to green (10 req/sec)
  - The request graph will return to normal

![Load Test](./images/test-with-errors-and-load-test.png)

## Troubleshooting

### Stopping a Codespace

- Codespaces will shutdown automatically after being idle for 30 minutes
- To shutdown a codespace immediately
  - Click `Codespaces` in the lower left of the browser window
  - Choose `Stop Current Codespace` from the context menu

### Rebuilding a Codespace

- You can also rebuild the container that is running your Codespace
  - Any changes in `/workspaces` will be retained
  - Other directories will be reset
  - Click `Codespaces` in the lower left of the browser window
  - Choose `Rebuild Container` from the context menu
  - Confirm your choice

### Deleting a Codespace

    - <https://github.com/codespaces>
    - Use the context menu to delete the Codespace
    - Please delete your Codespace once you complete the lab
    - Creating a new Codespace only takes about 45 seconds!

## FAQ

- Why don't we use helm to deploy Kubernetes manifests?
  - The target audience for this repository is app developers so we chose simplicity for the Developer Experience.
  - In our daily work, we use Helm for deployments and it is installed in the `Codespace` should you want to use it.
- Why `k3d` instead of `Kind`?
  - We love kind! Most of our code will run unchanged in kind (except the cluster commands)
  - We had to choose one or the other as we don't have the resources to validate both
  - We chose k3d for these main reasons
    - Smaller memory footprint
    - Faster startup time
    - Secure by default
      - K3s supports the [CIS Kubernetes Benchmark](https://rancher.com/docs/k3s/latest/en/security/hardening_guide/)
    - Based on [K3s](https://rancher.com/docs/k3s/latest/en/) which is a certified Kubernetes distro
      - Many customers run K3s on the edge as well as in CI-CD pipelines
    - Rancher provides support - including 24x7 (for a fee)
    - K3s has a vibrant community
    - K3s is a CNCF sandbox project

- How is Codespaces built?

Codespaces extends the use of development containers by providing a remote hosting environment. A development container is a fully-featured development environment running in a Docker container.

Developers can simply click on a button in GitHub to open a Codespace for the repo. Behind the scenes, GitHub Codespaces is:

- Starting a VM
- Shallow clone the repo in that VM. The shallow clone pulls the `devcontainer.json` onto the VM
- Start the development container on the VM
- Clone the repository in the development container
- Connect to the remotely hosted development container via the browser or Visual Studio Code

`.devcontainer` folder contains the following:

- `devcontainer.json`: This configuration file determines the environment for new Codespaces created for the repository by defining a development container that can include frameworks, tools, extensions, and port forwarding. For more information about the settings and properties that you can set in a devcontainer.json, see [devcontainer.json reference](https://code.visualstudio.com/docs/remote/devcontainerjson-reference) in the Visual Studio Code documentation.

- `Dockerfile`: Dockerfile in `.devcontainer` defines a container image and installs software. You can use an existing base image by using the `FROM` instruction. For more information on using a Dockerfile in a dev container, see [Create a development container](https://code.visualstudio.com/docs/remote/create-dev-container#_dockerfile) in the Visual Studio Code documentation.

- `Bash scripts`: We store lifecycle scripts under the `.devcontainer` folder. They are the hooks that allow you to run commands at different points in the development container lifecycle which include:
  - onCreateCommand - Run when creating the container
  - postCreateCommand - Run after the container is created
  - postStartCommand - Run every time the container starts

  For more information on using Lifecycle scripts, see [Codespaces lifecycle scripts](https://code.visualstudio.com/docs/remote/devcontainerjson-reference#_lifecycle-scripts).

  > Note: Provide executable permissions to scripts using: `chmod+ x`.


## Support

This project uses GitHub Issues to track bugs and feature requests. Please search the existing issues before filing new issues to avoid duplicates.  For new issues, file your bug or feature request as a new issue.

## Contributing

This project welcomes contributions and suggestions and has adopted the [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct.html).

For more information see [Contributing.md](./.github/CONTRIBUTING.md)

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Any use of third-party trademarks or logos are subject to those third-party's policies.
