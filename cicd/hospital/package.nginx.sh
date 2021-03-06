#!/bin/sh

IP=`cat license | grep repo.ip | awk -F = '{print $2}'`
PORT=`cat license | grep repo.port | awk -F = '{print $2}'`

CURRENT_DIR=`pwd`

mkdir nginx -pv
cd nginx

wget http://$IP:$PORT/shared/devops/CHANGELOG -O ../CHANGELOG
wget http://$IP:$PORT/shared/devops/hospital/nginx.deploy.sh -O nginx.deploy.sh
#wget http://$IP:$PORT/shared/devops/hospital/license -O license
wget http://$IP:$PORT/shared/devops/hospital/mod/ncheck.sh -O ncheck.sh

/bin/cp ../license .
sh nginx.deploy.sh -d

echo -e "\n`date '+%D %T'` - download completed!\n"

ls -lht pkg > pkg.list
cat pkg.list

cd $CURRENT_DIR
/bin/rm nginx-install.tar.gz -fr
cd nginx
tar -czf ../nginx-install.tar.gz .
cd ..
echo -e "`date '+%D %T'` - archive completed!"
ls -lh | grep nginx-install.tar.gz
