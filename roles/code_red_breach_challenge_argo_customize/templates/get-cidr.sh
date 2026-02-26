SUCCEEDED_JOB=$(oc get job -l cronjob={{ code_red_breach_challenge_argo_customize_gitea_user_name_base }}1-ping-ripper -n default --ignore-not-found=true -o=jsonpath='{range .items[?(@.status.succeeded==1)]}{.metadata.name}{"\n"}{end}')

if [ ! -z "${SUCCEEDED_JOB}" ]; then

  CLUSTER_ID=$(curl -ks -u {{ code_red_breach_challenge_argo_customize_stackrox_admin_user }}:{{ code_red_breach_challenge_argo_customize_stackrox_admin_password }} https://{{
  code_red_breach_challenge_argo_customize_stackrox_endpoint }}/v1/clusters | jq -r '.clusters[] | select(.name=="production").id')

  if [ -z "${CLUSTER_ID}" ]; then

    exit 1

  fi

  DEPLOYMENT_ID=$(curl -ks -u {{ code_red_breach_challenge_argo_customize_stackrox_admin_user }}:{{ code_red_breach_challenge_argo_customize_stackrox_admin_password }} https://{{
  code_red_breach_challenge_argo_customize_stackrox_endpoint }}/v1/networkgraph/cluster/${CLUSTER_ID} | jq -r '.nodes[] | select(.entity.type == "DEPLOYMENT" and .entity.deployment.name == "quarkus-template" and .entity.deployment.namespace == "customers-{{
  code_red_breach_challenge_argo_customize_gitea_user_name_base }}1").entity.id')

  if [ -z "${DEPLOYMENT_ID}" ]; then

    exit 1

  fi

  CIDR=$(curl -ks -u {{ code_red_breach_challenge_argo_customize_stackrox_admin_user }}:{{ code_red_breach_challenge_argo_customize_stackrox_admin_password }} https://{{
  code_red_breach_challenge_argo_customize_stackrox_endpoint }}/v1/networkgraph/cluster/${CLUSTER_ID}/externalentities/flows/${DEPLOYMENT_ID} | jq -r '.flows[] | select(.props.dstEntity.type == "EXTERNAL_SOURCE" and .props.l4protocol == "L4_PROTOCOL_TCP").props.dstEntity.externalSource.cidr')

  if [ ! -z "${CIDR}" ]; then

    echo $CIDR

  else

    exit 1

  fi

else

  exit 1

fi