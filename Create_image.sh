#!/bin/bash
# Before first : Install PACKER !!! : https://learn.hashicorp.com/tutorials/packer/get-started-install-cli?in=packer/docker-get-started
# First please login with az login -i if managed identity is used on CChead
# Second, create the right resource group with az group create - done by the script
# third, have an spn handy and fill up variables if needed, you can use managed ID's instead
# Fourth, run this script

FORCE=0

source variables.sh

## Check if Packer is alright :

packerver=$( /usr/bin/packer -v )

if [ "$packerver" >= 1.7 ]; then
  echo Packer version is alright : $packerver
fi

## Creating RG to store SIG if it doesn't exist yet :

RG=$(az group list | grep $imageResourceGroup)

if [ "$RG" == "" ]; then
  az group create -n $imageResourceGroup -l $location
fi

/usr/bin/packer build -force \
## To be used with SPN :
#	-var "subscription_id=$subscriptionID" \          # "subscription_id": "{{user `subscription_id`}}",
#	-var "client_id=$servicePrincipalAppId" \         # "client_id": "{{user `client_id`}}",
#	-var "client_secret=$servicePrincipalPassword" \  # "client_secret": "{{user `client_secret`}}",
#	-var "tenant_id=$servicePrincipalTenant" \        # "tenant_id": "{{user `tenant_id`}}",
## To be used with Managed Identity or azlogin :
  -var "var_use_azure_cli_auth=true" \              # "use_azure_cli_auth": "{{user `var_use_azure_cli_auth`}}",
## Other parameters
  -var "location=$location" \
	-var "var_resource_group=$imageResourceGroup" \
	-var "var_image=$image_name" \
	-var "var_img_version=$version" \
	-var "var_cloud_env=$cloud_env" azhop-centos79-v2-rdma-gpgpu.json

# Now, creation of an image gallery

az sig create --gallery-name $GalleryName -g $imageResourceGroup -l $location

img_def_id=$(az sig image-definition list -r $GalleryName -g $imageResourceGroup --query "[?name=='$image_name'].id" -o tsv)
if [ "$img_def_id" == "" ]; then
  az sig image-definition create -r $GalleryName -i $image_name -g $imageResourceGroup \
                -f $offer --os-type $os_type -p $publisher -s $sku --hyper-v-generation $hyper_v \
                --query 'id' -o tsv
else
  echo "Image definition for $image_name found in gallery $GalleryName"
fi

# Check if the version of the managed image (retrieved thru the tag) exists in the SIG, if not then push to the SIG
image_id=$(az image list -g $imageResourceGroup --query "[?name=='$image_name'].id" -o tsv)
image_version=$(az image show --id $image_id --query "tags.Version" -o tsv)

# Check if the image version exists in the SIG
echo "Looking for image $image_name version $image_version ..."
img_version_id=$(az sig image-version list  -r $GalleryName -i $image_name -g $imageResourceGroup --query "[?name=='$image_version'].id" -o tsv)

if [ "$img_version_id" == "" ] || [ $FORCE -eq 1 ]; then
  # Create an image version Major.Minor.Patch with Patch=YYmmddHHMM
  patch=$(date +"%g%m%d%H%M")
  version=$version
  version+=".$patch"
  echo "Pushing version $version of $image_name in $GalleryName"

  storage_type=$(az image show --id $image_id --query "storageProfile.osDisk.storageAccountType" -o tsv)
 
  az sig image-version create \
    --resource-group $imageResourceGroup \
    --gallery-name $GalleryName \
    --gallery-image-definition $image_name \
    --gallery-image-version $version \
    --storage-account-type $storage_type \
    --location $location \
    --replica-count 1 \
    --managed-image $image_id \
    -o tsv

else
  echo "Image $image_name version $image_version found in galley $sig_name"
fi