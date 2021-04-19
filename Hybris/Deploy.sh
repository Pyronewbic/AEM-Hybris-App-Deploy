echo "%%Removing Old code from custom"
rm -rf /home/jenkins/hybris6.7.0.0/hybris/bin/custom/*

echo "%%Removing old config files"
rm -rf  /home/jenkins/hybris6.7.0.0/hybris/config/local.properties

echo "%%Copying Code and config from Jenkins Workspace to Hybris Workspace"
chmod -R 777 /home/jenkins/hybris6.7.0.0/hybris/temp/hybris/
#chmod -R 755 /home/jenkins/hybris6.7.0.0/hybris/bin/custom/.git/

cp -avr ${WORKSPACE}/hybris/bin/custom/*  /home/jenkins/hybris6.7.0.0/hybris/bin/custom/
cp -avr ${WORKSPACE}/.git  /home/jenkins/hybris6.7.0.0/hybris/bin/custom/
cp -avr ${WORKSPACE}/hybris/config/DEV/* /home/jenkins/hybris6.7.0.0/hybris/config

echo "%%Setting Ant Env"
cd /home/jenkins/hybris6.7.0.0/hybris/bin/platform
. ./setantenv.sh

echo "%%Setting ANT_OPTS to 2G"
# export ANT_OPTS="-Xmx1024m"
export ANT_OPTS="-Xmx2G"

echo "%%Running Ant Customize and Ant Clean All"
#ant customize
ant clean all

echo "%%Running Sonar and CC"
#isagenixfacades,isagenixfulfilmentprocess,isagenixinitialdata,isagenixstorefront

sed -i 's/db.url/#db.url/g' /home/jenkins/hybris6.7.0.0/hybris/config/local.properties
sed -i 's/db.driver/#db.driver/g' /home/jenkins/hybris6.7.0.0/hybris/config/local.properties
sed -i 's/db.username/#db.username/g' /home/jenkins/hybris6.7.0.0/hybris/config/local.properties
sed -i 's/db.password/#db.password/g' /home/jenkins/hybris6.7.0.0/hybris/config/local.properties

ant jacocoalltests -Dtestclasses.extensions=isagenixcore,isagenixfacades,isagenixfulfilmentprocess,isagenixinitialdata,isagenixstorefront,isagenixpromotions
ant sonar -Dsonar.profile=EC-hybris-Java -Dsonar.jacoco.reportPath=/home/jenkins/hybris6.7.0.0/hybris/bin/jacoco.exec

sed -i 's/#db.url/db.url/g' /home/jenkins/hybris6.7.0.0/hybris/config/local.properties
sed -i 's/#db.driver/db.driver/g' /home/jenkins/hybris6.7.0.0/hybris/config/local.properties
sed -i 's/#db.username/db.username/g' /home/jenkins/hybris6.7.0.0/hybris/config/local.properties
sed -i 's/#db.password/db.password/g' /home/jenkins/hybris6.7.0.0/hybris/config/local.properties

if [ "$DEPLOY" = "true" ]; then
    echo "%%Waiting 45 Seconds for Sonar Reports to generate"
    sleep 45s #for Sonar Reports to generate

    echo "%%Checking Sonar Quality Checks!" #Marks Jenkins build as failure if not
    nodePath=/home/jenkins/nodeScripts
    node $nodePath/sonar.js

    echo "%%Running ant production"
    ant production

    cd /home/jenkins/hybris6.7.0.0/hybris/temp/hybris/hybrisServer
    ls -alh

    echo "%%Getting Previous BuildName from Artifactory"
    dfileName=$(node $nodePath/artifactory.js latest DEV)

    key=tokenXYZ
    url=https://isagenixartifactory.jfrog.io/isagenixartifactory/Hybris-Builds/DEV

    echo "%%Deleting Previous Build ($dfileName) from Artifactory"
    curl -X DELETE -H "X-JFrog-Art-Api:$key" "$url/$dfileName"

    echo "%%Compressing ProdZips for artifactory"
    #CUR=`date +%Y%m%d`
    #fileName=$BUILD_NUMBER-$CUR.tar.gz
    fileName=Packaged_$BUILD_NUMBER.tar.gz
    tar czf $fileName hybrisServer-AllExtensions.zip hybrisServer-Config.zip

    echo "%%Calculating Checksums for $fileName"
    sha1=$(sha1sum $fileName | cut -d ' ' -f1)
    sha256=$(sha256sum $fileName | cut -d ' ' -f1)
    md5=$(md5sum $fileName | cut -d ' ' -f1)

    echo "%%Uploading Packaged Tar for $Build_Number to artifactory"
    curl -H "X-Checksum-Sha1:$sha1" -H "X-Checksum-Sha256:$sha256" -H "X-Checksum-Md5:$md5" -H "X-JFrog-Art-Api:$key" -T /home/jenkins/hybris6.7.0.0/hybris/temp/hybris/hybrisServer/$fileName "$url/$fileName"

    echo "%%Transferring Extensions and Config to Hybris Dev Server"
    scp hybrisServer-AllExtensions.zip hybrisServer-Config.zip isaroot@10.1.40.103:/home/isaroot/Two_Zip_toCopy
    
    echo "###################running deployment script #############################"

    ssh isaroot@10.1.40.103 "/home/isaroot/scripts/hybrisdeploy2.sh"

    if [ "$UPDATE" = "true" ]; then
    	echo "%%Calling script for HAC updates!"
        sleep 310s
        cd $nodePath
        node hac.js DEV $RSYSTEM $INITD $LOCT $ISAGENIXCORE $ISAGENIXPROMOTIONS $ISAGENIXINIT $ISAGENIXINITSAMPLE $ISAGENIXFULFIL $ISAGENIXCOCKPIT $ISAGENIXCOCKPITSREPORT $ISAGENIXFACADES $ISAGENIXBACKOFFICE $ISAGENIXCOMMERCE 2998
    fi
fi