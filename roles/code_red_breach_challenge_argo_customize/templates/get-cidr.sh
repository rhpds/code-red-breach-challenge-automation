CLUSTER_ID=$(curl -ks -u {{ code_red_breach_challenge_argo_customize_stackrox_admin_user }}:{{ code_red_breach_challenge_argo_customize_stackrox_admin_password }} \
  https://{{ code_red_breach_challenge_argo_customize_stackrox_endpoint }}/v1/clusters?query=Cluster:production | \
  jq -r '.clusters[] | select(.name=="production").id')

if [ -z "${CLUSTER_ID}" ]; then
  echo "Failed to get cluster ID"
  exit 1
fi

DEPLOYMENT_ID=$(curl -ks -u {{ code_red_breach_challenge_argo_customize_stackrox_admin_user }}:{{ code_red_breach_challenge_argo_customize_stackrox_admin_password }} \
  "https://{{ code_red_breach_challenge_argo_customize_stackrox_endpoint }}/v1/networkgraph/cluster/${CLUSTER_ID}?query=Deployment:quarkus-template" | \
  jq -r '.nodes[] | select(.entity.type == "DEPLOYMENT").entity.id' | head -1)

if [ -z "${DEPLOYMENT_ID}" ]; then
  echo "Failed to get deployment ID"
  exit 1
fi

EXTERNAL_ENTITY_ID=$(curl -ks -u {{ code_red_breach_challenge_argo_customize_stackrox_admin_user }}:{{ code_red_breach_challenge_argo_customize_stackrox_admin_password }} \
  "https://{{ code_red_breach_challenge_argo_customize_stackrox_endpoint }}/v1/networkbaseline/${DEPLOYMENT_ID}/status/external" | \
  jq -r '((.anomolous // []) + (.baseline // []))[] | select(.peer.entity.type == "EXTERNAL_SOURCE" and .peer.protocol == "L4_PROTOCOL_TCP").peer.entity.id' | \
  head -1)

if [ -z "${EXTERNAL_ENTITY_ID}" ]; then
  echo "Failed to get external entity ID from anomalous or baseline"
  exit 1
fi

CIDR=$(curl -ks -u {{ code_red_breach_challenge_argo_customize_stackrox_admin_user }}:{{ code_red_breach_challenge_argo_customize_stackrox_admin_password }} \
  "https://{{ code_red_breach_challenge_argo_customize_stackrox_endpoint }}/v1/networkgraph/cluster/${CLUSTER_ID}/externalentities/${EXTERNAL_ENTITY_ID}/flows" | \
  jq -r '.entity.externalSource.cidr')

if [ -z "${CIDR}" || "${CIDR}" == "null" ]; then
  ENTITY_SUFFIX=$(echo "${EXTERNAL_ENTITY_ID}" | grep -o '__.*')
  CIDR=$(curl -ks -u {{ code_red_breach_challenge_argo_customize_stackrox_admin_user }}:{{ code_red_breach_challenge_argo_customize_stackrox_admin_password }} \
  "https://{{ code_red_breach_challenge_argo_customize_stackrox_endpoint }}/v1/networkgraph/cluster/${CLUSTER_ID}/externalentities/${ENTITY_SUFFIX}/flows" | \
  jq -r '.entity.externalSource.cidr')
fi

if [ ! -z "${CIDR}" ]; then
  echo $CIDR
else
  echo "Failed to get CIDR from external entity ID: ${EXTERNAL_ENTITY_ID}"
  exit 1
fi