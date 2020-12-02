#! /bin/bash
#==============================================================
# Security scanner script - Christiaan Lips
#==============================================================
# CHANGELOG
#==============================================================
# 19-11-2020 - ADDED - now gets logging from the Quay Security Operator.
# 	     - ADDED - now installs kube-hunter and creates Job that scans all nodes.
#            - ADDED - Formats all logging from kube-hunter and Quay into yaml and text file.	
# 20-11-2020 - ADDED - now installs polaris.
#	     - ADDED - now waits for the kube hunter pod to deploy before requesting logs.
# 26-11-2020 - ADDED - now gathers quay vulnerability reports more efficiently.
#            - ADDED - now creates own folders and removes existing jobs and used yaml files.
# 30-11-2020 - ADDED - now formats reports optimally for logstash.
#
#
 
clear
echo -e "\e[32m================================="  
echo -e "+ Starting security application +"
echo -e "=================================\e[0m"
echo -e "\e[31mPlease note that in order for this application to work you need to be logged in on your OpenShift platform and have root access\e[0m"
mkdir SecurityLogs

#------------------------------------- Quay Security Operator ----------------------------------

# get all vulnerabilities from all namespaces
kubectl get imagemanifestvuln --all-namespaces -o json > SecurityLogs/QuaySecurityScanVulnerabilityReport.txt
echo "                    {
                        "name": "final-vuln",
" >> SecurityLogs/QuaySecurityScanVulnerabilityReport.txt

#-----------------------------------------------------------------------------------------------


#------------------------------------- Kube-hunter ---------------------------------------------
		
# create and switch to the kunehunter namespace, if there are any old kube-hunter jobs left delete them.
oc create ns kubehunter
oc project kubehunter && oc delete jobs --all

# create the job with substituted nodes
echo "apiVersion: batch/v1
kind: Job
metadata:
  name: kube-hunter
spec:
  template:
    spec:
      containers:
      - name: kube-hunter
        image: aquasec/kube-hunter
        command: ["kube-hunter"]
        args:
          - '--report'
          - yaml
          - '--log'
          - none
          - '--remote'" > kubehunterjob.yaml

oc get nodes | awk '{print "          -",$1, $8}' |  sed 1,1d >> kubehunterjob.yaml

echo "      restartPolicy: Never
  backoffLimit: 4
" >> kubehunterjob.yaml

# create the actual job
kubectl create -f kubehunterjob.yaml

# wait for the pod to deploy before proceeding
echo -e "\e[32mPlease wait 20 seconds for the kube-hunter pod to deploy propperly\e[0m"
sleep 20

# format the logs from kube-hunter to a test file
oc logs `oc get pods | awk '{print $1, $8}' |  sed 1,1d` > SecurityLogs/kubehunterlogs.txt  
sed -i '/- location: /,$!d' SecurityLogs/kubehunterlogs.txt 
echo "- location: " >> SecurityLogs/kubehunterlogs.txt

#---------------------------------------------------------------------------------------------

# install polaris to check for kubernetes configuration best practices
kubectl apply -f https://github.com/FairwindsOps/polaris/releases/latest/download/dashboard.yaml

# clean up the used job
rm -rf kubehunterjob.yaml
                                                 
echo -e "\e[32m================================="
echo -e "+ Exiting security application +"
echo -e "=================================\e[0m"
echo -e "\e[32mAll logging is stored under the 'SecurityLogs' folder\e[0m"


 
