# Jenkins and K8s
 1. AEM/ - contains a pipeline which builds on publisher/author nodes, and deploys it. Update aem.toml to reference 127.0.0.1 as the hostname
 2. Android/ - Contains a pipeline which builds an apk (based on the included Dockerfile - this is a react native app), and archives it. Deployment to appstores coming soon.
 3. Hybris/ - Includes a shell script to perform a hbris build, run sonar and deploy to two environments. Also contains a neat js automation script which takes care of the initial wait time (on having to update extensions on HAC)
 4. jenkins/charts - Contains a helm chart from bitnami to get you started with deploying stuff on K8s