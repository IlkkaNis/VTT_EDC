Install and start dataspace: 

1. Run script start-edc.sh
    sudo ./start-edc.sh
2. Run seed-minimal.sh
    ./seed-minimal.sh
3. Extract "x" values
   ```
   curl -X GET "http://localhost:7082/api/identity/v1alpha/dids" -H "X-Api-Key: c3VwZXItdXNlcg==.c3VwZXItc2VjcmV0LWtleQo="
   curl -X GET "http://localhost:7182/api/identity/v1alpha/dids"    -H "X-Api-Key: c3VwZXItdXNlcg==.c3VwZXItc2VjcmV0LWtleQo="
   ```
5. Update did.json file (consumer and provider)
```
	 nano consumer/did-web/.well-known/did.json
     nano provider/did-web/.well-known/did.json
```
7. Restart nginx
```
   sudo docker exec consumer-did-web nginx -s reload
   sudo docker exec provider-did-web nginx -s reload
```
9. (extra step) commended out the "alias" line from consumer env file
     
10. Inject the Membership Credential
```
curl -X POST "http://localhost:7082/api/identity/v1alpha/participants/Y29uc3VtZXItY29udHJvbHBsYW5l/credentials" \
  -H "X-Api-Key: c3VwZXItdXNlcg==.c3VwZXItc2VjcmV0LWtleQo=" \
  -H "Content-Type: application/json" \
  -d '{
    "participantContextId": "consumer-controlplane",
    "verifiableCredentialContainer": {
      "format": "VC1_0_LD",
      "rawVc": "{\"id\":\"membership-credential\",\"type\":[\"VerifiableCredential\",\"MembershipCredential\"]}",
      "credential": {
        "@context": [
          "https://www.w3.org/2018/credentials/v1",
          "https://w3id.org/edc/v0.0.1/ns/"
        ],
        "id": "membership-credential",
        "type": ["VerifiableCredential", "MembershipCredential"],
        "issuer": { "id": "did:web:consumer-did-web" },
        "issuanceDate": "2026-02-11T00:00:00Z",
        "credentialSubject": [
          {
            "id": "did:web:consumer-did-web",
            "claims": {
              "membership": "true"
            }
          }
        ]
      }
    }
  }'
```
	7. Update the Consumer Control Plane .env 
        nano consumer/consumer-connector.env (EDC_IAM_STS_OAUTH_CLIENT_SECRET=6vWTuChwtPZoTX6q ..this was received after the seed))
	9. Restart the Consumer Control Plane
         sudo docker-compose -f consumer/docker-compose.yml restart consumer-controlplane
	11. Manually Seed the Secret into the Control Plane (remember to update the "value")
```
        curl -X POST "http://localhost:8081/api/management/v3/secrets" \
          -H "X-Api-Key: password" \
          -H "Content-Type: application/json" \
          -d '{
            "@context": {
              "edc": "https://w3id.org/edc/v0.0.1/ns/"
            },
            "@type": "Secret",
            "@id": "did:web:consumer-did-web-sts-client-secret",
            "value": "6Y7UKgF5Pf3kiwaI"
          }'
```
      

12. Verify the Secret exists 
    curl -X GET "http://localhost:8081/api/management/v3/secrets/did:web:consumer-did-web-sts-client-secret" -H "X-Api-Key: password"

13: 
```
curl -X POST http://localhost:8081/api/management/v3/catalog/request \
   -H "Content-Type: application/json" \
   -H "X-Api-Key: password" \
   -d '{
     "@context": {
       "edc": "https://w3id.org/edc/v0.0.1/ns/"
     },
     "@type": "CatalogRequest",
     "counterPartyAddress": "http://provider-controlplane:8182/api/dsp",
     "counterPartyId": "did:web:provider-did-web",
     "protocol": "dataspace-protocol-http"
   }'
```


    Test getting the tokens:




    curl -X POST "http://localhost:7086/api/sts/token" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "grant_type=client_credentials" \
      -d "client_id=did:web:consumer-did-web" \
      -d "client_secret=6PhzxPyj0LV0nxBk" \
      -d "audience=did:web:consumer-did-web" \
      -d "scope=edc:control"
    

curl -X POST "http://localhost:7081/api/credentials/v1/participants/Y29uc3VtZXItY29udHJvbHBsYW5l/presentations/query" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <YOUR_NEW_STS_TOKEN>" \
  -d '{
    "@context": ["https://w3id.org/edc/v0.0.1/ns/"],
    "@type": "PresentationQueryMessage",
    "scope": ["membership"]
  }'

