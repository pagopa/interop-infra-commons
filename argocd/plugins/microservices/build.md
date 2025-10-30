#Mac OS Build

aws ecr get-login-password --region eu-south-1 | docker login --username AWS --password-stdin 505630707203.dkr.ecr.eu-south-1.amazonaws.com

docker buildx build --no-cache \
  --platform linux/amd64 \
  -t argocd-plugin-microservices:latest -t argocd-plugin-microservices:1.0 -t argocd-plugin-microservices:amd64-latest -t argocd-plugin-microservices:amd64-1.0 \
  -f argocd/plugins/microservices/Dockerfile \
  --load \
  .

docker buildx build --no-cache \
  --platform linux/arm64 \
  -t argocd-plugin-microservices:arm64-latest -t argocd-plugin-microservices:arm64-1.0 \
  -f argocd/plugins/microservices/Dockerfile \
  --load \
  .

docker tag argocd-plugin-microservices:latest 505630707203.dkr.ecr.eu-south-1.amazonaws.com/argocd-plugin-microservices:latest 
docker tag argocd-plugin-microservices:amd64-latest 505630707203.dkr.ecr.eu-south-1.amazonaws.com/argocd-plugin-microservices:amd64-latest 
docker tag argocd-plugin-microservices:1.0 505630707203.dkr.ecr.eu-south-1.amazonaws.com/argocd-plugin-microservices:1.0 
docker tag argocd-plugin-microservices:arm64-1.0 505630707203.dkr.ecr.eu-south-1.amazonaws.com/argocd-plugin-microservices:arm64-1.0
docker tag argocd-plugin-microservices:arm64-latest 505630707203.dkr.ecr.eu-south-1.amazonaws.com/argocd-plugin-microservices:arm64-latest
...

docker push 505630707203.dkr.ecr.eu-south-1.amazonaws.com/argocd-plugin-microservices:latest 
docker push 505630707203.dkr.ecr.eu-south-1.amazonaws.com/argocd-plugin-microservices:1.0 
docker push 505630707203.dkr.ecr.eu-south-1.amazonaws.com/argocd-plugin-microservices:amd64-latest
docker push 505630707203.dkr.ecr.eu-south-1.amazonaws.com/argocd-plugin-microservices:arm64-latest 
docker push 505630707203.dkr.ecr.eu-south-1.amazonaws.com/argocd-plugin-microservices:arm64-1.0
...