act:
  act -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:full-latest push

generate:
 bluebuild generate \
  --output ./Containerfile \
  --registry ghcr.io \
  --registry-namespace dkolb \
  --platform linux/amd64 \
  --build-driver buildah \
  --inspect-driver skopeo \
  --signing-driver cosign \
  --run-driver podman \
  ./recipes/stable.yml