#!/bin/sh

IP=`cat license | grep repo.ip | awk -F = '{print $2}'`
PORT=`cat license | grep repo.port | awk -F = '{print $2}'`

CURRENT_DIR=`pwd`

mkdir ywx -pv
cd ywx

wget http://$IP:$PORT/shared/devops/CHANGELOG -O ../CHANGELOG
wget http://$IP:$PORT/shared/devops/hospital/ywx.deploy.sh -O ywx.deploy.sh
#wget http://$IP:$PORT/shared/devops/hospital/license -O license
wget http://$IP:$PORT/shared/devops/hospital/mod/ncheck.sh -O ncheck.sh

/bin/cp ../license .
sh ywx.deploy.sh -d

echo -e "\n`date '+%D %T'` - download completed!\n"

ls -lht pkg > pkg.list
cat pkg.list

cd $CURRENT_DIR
/bin/rm ywx-install.tar.gz -fr
echo -e "\n`date '+%D %T'` - starting archive ..."
cd ywx
tar -czf ../ywx-install.tar.gz .
cd ..
echo -e "`date '+%D %T'` - archive completed!"
ls -lh |grep ywx-install.tag.gz
