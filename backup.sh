#!/bin/bash
# backup openshift 
# Global Configurations
#======================
set -e
BACKUP_DIR=/opt/redhat/backup-yaml

# in dev
#AWS_CMD=/usr/bin/aws
#TIME_STAMP=$(date +%Y-%m-%d_%H-%M)
######################
#rosa login -t $ROSA_TOKEN
oc login -u cluster-admin -p $CLUSTER_PASSWORD `rosa describe cluster -c rocpah1 | grep API |awk '{print $3}'`

function get_secret {
  oc get secret -n ${1} -o=yaml --field-selector type!=kubernetes.io/service-account-token | sed -e '/resourceVersion: "[0-9]\+"/d' -e '/uid: [a-z0-9-]\+/d' -e '/selfLink: [a-z0-9A-Z/]\+/d'
}

function get_configmap {
  oc get configmap -n ${1} -o=yaml | sed -e '/resourceVersion: "[0-9]\+"/d' -e '/uid: [a-z0-9-]\+/d' -e '/selfLink: [a-z0-9A-Z/]\+/d'
}

function get_ingress {
  oc get ing -n ${1} -o=yaml | sed -e '/status:/,+2d' -e '/\- ip: \([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}/d' -e '/resourceVersion: "[0-9]\+"/d' -e '/uid: [a-z0-9-]\+/d' -e '/selfLink: [a-z0-9A-Z/]\+/d'
}

function get_service {
  oc get service -n ${1} -o=yaml | sed -e '/ownerReferences:/,+5d' -e '/resourceVersion: "[0-9]\+"/d' -e '/uid: [a-z0-9-]\+/d' -e '/selfLink: [a-z0-9A-Z/]\+/d' -e '/clusterIP: \([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}/d'
}

function get_deployment {
  oc get deployment -n ${1} -o=yaml | sed -e '/deployment\.kubernetes\.io\/revision: "[0-9]\+"/d' -e '/resourceVersion: "[0-9]\+"/d' -e '/uid: [a-z0-9-]\+/d' -e '/selfLink: [a-z0-9A-Z/]\+/d' -e '/status:/,+18d'
}

function get_cronjob {
  oc get cronjob -n ${1} -o=yaml | sed -e '/status:/,+1d' -e '/resourceVersion: "[0-9]\+"/d' -e '/uid: [a-z0-9-]\+/d' -e '/selfLink: [a-z0-9A-Z/]\+/d'
}

function get_pvc {
  oc get pvc -n ${1} -o=yaml | sed -e '/control\-plane\.alpha\.kubernetes\.io\/leader\:/d' -e '/resourceVersion: "[0-9]\+"/d' -e '/uid: [a-z0-9-]\+/d' -e '/selfLink: [a-z0-9A-Z/]\+/d'
}

function get_pv {
  for pvolume in `oc get pvc -n ${1} -o=custom-columns=:.spec.volumeName` 
  do
     oc get pv -o=yaml --field-selector metadata.name=${pvolume} | sed -e '/resourceVersion: "[0-9]\+"/d' -e '/uid: [a-z0-9-]\+/d' -e '/selfLink: [a-z0-9A-Z/]\+/d'
  done
}

function export_ns {
  mkdir -p ${BACKUP_DIR}/${CLUSTER_NAME}/
  cd ${BACKUP_DIR}/${CLUSTER_NAME}/
  for namespace in `oc get namespaces --no-headers=true | awk '{ print $1 }' | grep -e "cea-"`
  do
     echo "Namespace: $namespace"
     echo "+++++++++++++++++++++++++"
     mkdir -p $namespace

     for object_kind in configmap ingress service secret deployment cronjob pvc
     do
       if oc get ${object_kind} -n ${namespace} 2>&1 | grep "No resources" > /dev/null; then
         echo "No resources found for ${object_kind} in ${namespace}"
       else
         get_${object_kind} ${namespace} > ${namespace}/${object_kind}.${namespace}.yaml &&  echo "${object_kind}.${namespace}";
         
         if [ ${object_kind} = "pvc" ]; then
           get_pv ${namespace} > ${namespace}/pv.${namespace}.yaml &&  echo "pv.${namespace}";
         fi
       fi
     done
     echo "+++++++++++++++++++++++++"
  done
}
export_ns