# Self hosted local GitHub Actions Runner

Go to github and go to settings>actions>runners and "add new runner". there you will find a token


1. docker build --tag gh-actions-local-runner .

2. docker run \
  --detach \
  --network host \
  --env ORGANIZATION=<YOUR-GITHUB-ORG> \
  --env ACCESS_TOKEN=<YOUR-GITHUB-TOKEN> \
  --name local-runner \
  gh-actions-local-runner


1. docker logs local-runner -f

2. To rerun: docker start local-runner