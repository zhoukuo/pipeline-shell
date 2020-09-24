#!/bin/sh

IP=`cat license | grep repo.ip | awk -F = '{print $2}'`
PORT=`cat license | grep repo.port | awk -F = '{print $2}'`
TIMESTAMP=`date +"%Y/%m/%d %H:%M:%S"`
CURRENT_DIR=`pwd`

mkdir hospital -pv
cd hospital

wget http://$IP:$PORT/shared/devops/CHANGELOG -O ../CHANGELOG
wget http://$IP:$PORT/shared/devops/hospital/hospital.deploy.sh -O hospital.deploy.sh
#wget http://$IP:$PORT/shared/devops/hospital/license -O license
wget http://$IP:$PORT/shared/devops/hospital/mod/ncheck.sh -O ncheck.sh

/bin/cp -f ../license .
sh hospital.deploy.sh -d

echo -e "\n$TIMESTAMP - download completed!\n"

ls -lht pkg > pkg.list
cat pkg.list

cd $CURRENT_DIR
/bin/rm  hospital-install.tar.gz -fr
echo -e "\n$TIMESTAMP - starting archive ..."
cd hospital
tar -czf ../hospital-install.tar.gz .
cd ..
echo -e "$TIMESTAMP - archive completed!"
ls -lh | grep hospital-install.tar.gz
