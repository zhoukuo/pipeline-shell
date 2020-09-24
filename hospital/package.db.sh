#!/bin/sh

IP=`cat license | grep repo.ip | awk -F = '{print $2}'`
PORT=`cat license | grep repo.port | awk -F = '{print $2}'`
TIMESTAMP=`date +"%Y/%m/%d %H:%M:%S"`
CURRENT_DIR=`pwd`

mkdir db -pv
cd db

wget http://$IP:$PORT/shared/devops/CHANGELOG -O ../CHANGELOG
wget http://$IP:$PORT/shared/devops/hospital/db.deploy.sh -O db.deploy.sh
#wget http://$IP:$PORT/shared/devops/hospital/license -O license
wget http://$IP:$PORT/shared/devops/hospital/mod/ncheck.sh -O ncheck.sh

/bin/cp -f ../license .

sh db.deploy.sh -d

echo -e "\n$TIMESTAMP - download completed!\n"

ls -lht pkg > pkg.list
cat pkg.list

cd $CURRENT_DIR
/bin/rm db-install.tar.gz -fr
echo -e "\n$TIMESTAMP - starting archive ..."
cd db
tar -czf ../db-install.tar.gz .
cd ..
echo -e "$TIMESTAMP - archive completed!"
ls -lh | grep db-install.tar.gz
