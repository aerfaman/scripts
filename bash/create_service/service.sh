#!/bin/bash

service_name=$1

echo $service_name

main_dir=/opt/$service_name
service_dir=/usr/lib/systemd/system/

if [ ! -d $main_dir ]; then
      echo "Creating directory...."
      mkdir $main_dir
fi

echo "Installing...."

cp -f $service_name $main_dir
cp -f conf.yaml $main_dir

echo "Creating service...."

cp -f service.tmp ./$service_name.service
sed -i -e "s/{{service_name}}/$service_name/g" $service_name.service
cp -f $service_name.service $service_dir
systemctl daemon-reload

