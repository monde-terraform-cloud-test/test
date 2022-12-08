#!/bin/bash
# terraform用リソース追加スクリプト
if [ $# != 2 ];then
    echo "`basename $0` <env(stg/prod)> <resource_name>"
    exit 1
fi
ENV=$1
RESOURCE_NAME=$2
echo "setup terraform resource space [ ${ENV}/${RESOURCE_NAME} ]"

mkdir ../${ENV}/${RESOURCE_NAME}
cd ../${ENV}/${RESOURCE_NAME}
ln -fs ../variables.tf ./_shared_variables.tf
ln -fs ../data_resource.tf ./_shared_data_resource.tf

sed -e "s|__ENVIRONMENT__|${ENV}|g; s|__TFSTATE_KEY_PREFIX__|${RESOURCE_NAME}|g" ../../_scripts/template_terraform.tf > _terraform.tf
#terraform init
echo "setup finished."
echo "enjoy: cd $1 && terraform init"