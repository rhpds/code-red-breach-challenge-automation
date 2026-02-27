CLUSTER_ID=$(curl -ks -u {{ code_red_breach_challenge_argo_customize_stackrox_admin_user }}:{{ code_red_breach_challenge_argo_customize_stackrox_admin_password }} \
  https://{{ code_red_breach_challenge_argo_customize_stackrox_endpoint }}/v1/clusters?query=Cluster:production | \
  jq -r '.clusters[] | select(.name=="production").id')

if [ -z "${CLUSTER_ID}" ]; then
  echo "Failed to get cluster ID"
  exit 1
fi

# Get deployment ID for quarkus-template
DEPLOYMENT_ID=$(curl -ks -u {{ code_red_breach_challenge_argo_customize_stackrox_admin_user }}:{{ code_red_breach_challenge_argo_customize_stackrox_admin_password }} \
  "https://{{ code_red_breach_challenge_argo_customize_stackrox_endpoint }}/v1/networkgraph/cluster/${CLUSTER_ID}?query=Deployment:quarkus-template" | \
  jq -r '.nodes[] | select(.entity.type == "DEPLOYMENT").entity.id' | head -1)

if [ -z "${DEPLOYMENT_ID}" ]; then
  echo "Failed to get deployment ID"
  exit 1
fi

# Get external entity ID with TCP protocol
EXTERNAL_ENTITY_ID=$(curl -ks -u {{ code_red_breach_challenge_argo_customize_stackrox_admin_user }}:{{ code_red_breach_challenge_argo_customize_stackrox_admin_password }} \
  "https://{{ code_red_breach_challenge_argo_customize_stackrox_endpoint }}/v1/networkbaseline/${DEPLOYMENT_ID}/status/external" | \
  jq -r '.anomalous[] | select(.peer.entity.type == "EXTERNAL_SOURCE" and .peer.protocol == "L4_PROTOCOL_TCP").peer.entity.id' |
head -1)

if [ -z "${EXTERNAL_ENTITY_ID}" ]; then
  echo "Failed to get external entity ID"
  exit 1
fi

# Extract suffix from __ to end
ENTITY_SUFFIX=$(echo "${EXTERNAL_ENTITY_ID}" | grep -o '__.*')

if [ -z "${ENTITY_SUFFIX}" ]; then
  echo "Failed to extract entity suffix"
  exit 1
fi

# Get CIDR from flows
CIDR=$(curl -ks -u {{ code_red_breach_challenge_argo_customize_stackrox_admin_user }}:{{ code_red_breach_challenge_argo_customize_stackrox_admin_password }} \
  "https://{{ code_red_breach_challenge_argo_customize_stackrox_endpoint }}/v1/networkgraph/cluster/${CLUSTER_ID}/externalentities/${ENTITY_SUFFIX}/flows" | \
  jq -r '.entity.externalSource.cidr')

if [ ! -z "${CIDR}" ]; then
  echo $CIDR
else
  echo "Failed to get CIDR"
  exit 1
fi