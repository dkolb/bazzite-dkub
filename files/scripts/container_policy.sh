jq '.transports.docker."ghcr.io/dkolb/bazzite-dkub" = [
  {
    "type": "sigstoreSigned",
    "keyPath": "/etc/pki/containers/bazzite-dkub.pub",
    "signedIdentity": {
      "type": "matchRepository"
    }
  }
]' /etc/containers/policy.json > /etc/containers/policy.new.json
mv /etc/containers/policy.new.json /etc/containers/policy.json
