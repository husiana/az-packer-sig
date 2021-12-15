# Destination image resource group
imageResourceGroup="DemoImages"

# Location (see possible locations in main docs)
location="westeurope"

# Gallery Name & image infos
GalleryName="cycleimages"
image_name="azhop-centos79-v2-rdma-gpgpu"
cloud_env="public"
publisher="democycle"
# Example with Centos7.9 gen2 version :
offer="CentOS"
sku="7.9-gen2"
hyper_v="V2"
os_type="Linux"
version="7.9"

subscriptionID=$(az account show --query id --output tsv)