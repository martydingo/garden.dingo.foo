cd content && git pull && cd ..
docker buildx build --platform=linux/amd64,linux/arm64 -t martydingo/garden-dingo-foo:latest . --push
