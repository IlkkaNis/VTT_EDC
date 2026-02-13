#!/usr/bin/env bash
set -euo pipefail

#IDENTITY_API="http://localhost:7082/api/identity/v1alpha/participants"
#MGMT_API="http://localhost:8081/api/management/v3/secrets"

CONSUMER_IDENTITY_API="http://localhost:7082/api/identity/v1alpha/participants"
CONSUMER_MGMT_API="http://localhost:8081/api/management/v3/secrets"

PROVIDER_IDENTITY_API="http://localhost:7182/api/identity/v1alpha/participants"
PROVIDER_MGMT_API="http://localhost:8181/api/management/v3/secrets"


API_KEY="c3VwZXItdXNlcg==.c3VwZXItc2VjcmV0LWtleQo="

echo "== Seeding participants + STS secrets (MVD 0.12.0) =="

############################################
# CONSUMER
############################################

echo
echo "Creating CONSUMER participant"

CONSUMER_RESPONSE=$(curl -s -X POST "$CONSUMER_IDENTITY_API" \
  -H "X-Api-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "participantId": "consumer-controlplane",
    "did": "did:web:consumer-did-web",
    "roles": ["CONSUMER"],
    "active": true,
    "key": {
      "keyId": "did:web:consumer-did-web#key-1",
      "privateKeyAlias": "consumer-controlplane-alias",
      "keyGeneratorParams": {
        "algorithm": "EdDSA",
        "curve": "Ed25519"
      }
    }
  }')

echo "$CONSUMER_RESPONSE" | jq .



CONSUMER_SECRET=$(echo "$CONSUMER_RESPONSE" | jq -r '.clientSecret // empty')

if [[ -n "$CONSUMER_SECRET" ]]; then
  echo "Storing CONSUMER STS secret"

  jq -n --arg secret "$CONSUMER_SECRET" '{
    "@context": {
      "edc": "https://w3id.org/edc/v0.0.1/ns/"
    },
    "@type": "https://w3id.org/edc/v0.0.1/ns/Secret",
    "@id": "did:web:consumer-did-web-sts-client-secret",
    "https://w3id.org/edc/v0.0.1/ns/value": $secret
  }' | curl -s -X POST "$CONSUMER_MGMT_API" \
        -H "X-Api-Key: password" \
        -H "Content-Type: application/json" \
        -d @- | jq .
else
  echo "Consumer already exists – skipping secret creation"
fi

############################################
# PROVIDER
############################################

echo
echo "Creating PROVIDER participant"

PROVIDER_RESPONSE=$(curl -s -X POST "$PROVIDER_IDENTITY_API" \
  -H "X-Api-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "participantId": "provider-controlplane",
    "did": "did:web:provider-did-web",
    "roles": ["PROVIDER"],
    "active": true,
    "key": {
      "keyId": "did:web:provider-did-web#key-1",
      "privateKeyAlias": "provider-controlplane-alias",
      "keyGeneratorParams": {
        "algorithm": "EdDSA",
        "curve": "Ed25519"
      }
    }
  }')

echo "$PROVIDER_RESPONSE" | jq .

PROVIDER_SECRET=$(echo "$PROVIDER_RESPONSE" | jq -r '.clientSecret // empty')

if [[ -n "$PROVIDER_SECRET" ]]; then
  echo "Storing PROVIDER STS secret"

  jq -n --arg secret "$PROVIDER_SECRET" '{
    "@context": {
      "edc": "https://w3id.org/edc/v0.0.1/ns/"
    },
    "@type": "https://w3id.org/edc/v0.0.1/ns/Secret",
    "@id": "did:web:provider-did-web-sts-client-secret",
    "https://w3id.org/edc/v0.0.1/ns/value": $secret
  }' | curl -s -X POST "$PROVIDER_MGMT_API" \
        -H "X-Api-Key: password" \
        -H "Content-Type: application/json" \
        -d @- | jq .
else
  echo "Provider already exists – skipping secret creation"
fi

echo
echo "== Seeding completed successfully =="
