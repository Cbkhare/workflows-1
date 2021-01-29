# Centos Sample Workflow

This is a sample workflow to provision a Centos machine. This example uses the cloudInit mechanism to make it work.

## Steps to create the workflow 

- Create centos-install action image using below.

```
docker build -t centos-install .
```

- Push the centos-install action image to the registry.
```
docker tag centos-install:latest 192.168.1.1/centos-install
docker push 192.168.1.1/centos-install
```

- We are using [image2disk](https://artifacthub.io/packages/tbaction/tinkerbell-community/image2disk) to fetch the OS from the osie. Push the image2disk image on the repository. 
```
docker pull quay.io/tinkerbell-actions/image2disk:v1.0.0 
docker tag quay.io/tinkerbell-actions/image2disk:v1.0.0 192.168.1.1/quay.io/tinkerbell-actions/image2disk:v1.0.0 
docker push 192.168.1.1/quay.io/tinkerbell-actions/image2disk:v1.0.0 
```

- Place the raw image of the OS inside `OSIE` at location `webroot`. If you prefer to place it somewhere else then please update the template accordingly. 

- Create the hardware and template 
```
docker exec -i deploy_tink-cli_1 tink hardware push < ./hardware_data.json
docker exec -i deploy_tink-cli_1 tink template create --name centos < ./template.yml
```

- Create a workflow with the template id and the `cloudInit` string. 
```
docker exec -i deploy_tink-cli_1 tink workflow create \
    -t  7f44aa4c-6221-11eb-af88-0242ac120005 \
    -r '{"device_1":"08:00:27:00:00:01", "cloudInit": "e3suY2xvdWRJbml0fX0="}'
```

## Steps to boot to centos

- Once the workflow is completed, reboot the the worker.
- Go the boot menu by pressing `F12`.
- Select the Centos boot loader. 

