#Mac OS Build

aws ecr get-login-password --region eu-south-1 | docker login --username AWS --password-stdin 505630707203.dkr.ecr.eu-south-1.amazonaws.com

docker images |  grep cron | awk '{print $1 ":" $2}' | xargs docker rmi 

docker buildx build --no-cache \
  --platform linux/amd64 \
  -t argocd-plugin-cronjobs:latest -t argocd-plugin-cronjobs:1.0 -t argocd-plugin-cronjobs:amd64-latest -t argocd-plugin-cronjobs:amd64-1.0 \
  -f argocd/plugins/cronjobs/Dockerfile \
  --load \
  .

docker buildx build --no-cache \
  --platform linux/arm64 \
  -t argocd-plugin-cronjobs:arm64-latest -t argocd-plugin-cronjobs:arm64-1.0 \
  -f argocd/plugins/cronjobs/Dockerfile \
  --load \
  .

docker tag argocd-plugin-cronjobs:latest 505630707203.dkr.ecr.eu-south-1.amazonaws.com/argocd-plugin-cronjobs:latest 
docker tag argocd-plugin-cronjobs:amd64-latest 505630707203.dkr.ecr.eu-south-1.amazonaws.com/argocd-plugin-cronjobs:amd64-latest 
docker tag argocd-plugin-cronjobs:1.0 505630707203.dkr.ecr.eu-south-1.amazonaws.com/argocd-plugin-cronjobs:1.0 
docker tag argocd-plugin-cronjobs:arm64-1.0 505630707203.dkr.ecr.eu-south-1.amazonaws.com/argocd-plugin-cronjobs:arm64-1.0
docker tag argocd-plugin-cronjobs:arm64-latest 505630707203.dkr.ecr.eu-south-1.amazonaws.com/argocd-plugin-cronjobs:arm64-latest
...

docker push 505630707203.dkr.ecr.eu-south-1.amazonaws.com/argocd-plugin-cronjobs:latest 
docker push 505630707203.dkr.ecr.eu-south-1.amazonaws.com/argocd-plugin-cronjobs:1.0 
docker push 505630707203.dkr.ecr.eu-south-1.amazonaws.com/argocd-plugin-cronjobs:amd64-latest
docker push 505630707203.dkr.ecr.eu-south-1.amazonaws.com/argocd-plugin-cronjobs:arm64-latest 
docker push 505630707203.dkr.ecr.eu-south-1.amazonaws.com/argocd-plugin-cronjobs:arm64-1.0
...