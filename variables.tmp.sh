# Destination image resource group
imageResourceGroup=""

# Location (see possible locations in main docs)
location=""

# Gallery Name & image infos
GalleryName=""
image_name=""
cloud_env="public"
publisher=""
# Example with Centos7.9 gen2 version :
offer="CentOS"
sku="7.9-gen2"
hyper_v="V2"
os_type="Linux"
version="7.9"

subscriptionID=$(az account show --query id --output tsv)
servicePrincipalName="genhpcimages"

#az ad sp create-for-rbac --name $servicePrincipalName --role Contributor --years 1 --output tsv > SPpackerCredentials.out

servicePrincipalAppId=""
servicePrincipalPassword=""
servicePrincipalTenant=""