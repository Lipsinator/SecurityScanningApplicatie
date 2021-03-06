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
# 3-12-2020  - ADDED - now automatically creates route for polaris dashboard.
# 4-12-2020  - ADDED - delete any old kube-hunter job before creating a new one.
# 8-12-2020  - ADDED - errorlog.txt now contains any errors that may occur during launch.
# 14-12-2020 - ADDED - now automatically installs Quay Container Security Operator
 
clear
echo -e "\e[32m================================="  
echo -e "+ Starting security application +"
echo -e "=================================\e[0m"
echo -e "\e[31mPlease note that in order for this application to work you need to be logged in on your OpenShift platform and have root access.\n Please make sure that there is no namespace called 'kubehunter' when executing this script.\e[0m"
read -p "Press any key to continue: "

mkdir SecurityLogs 2> errorlog.txt

#------------------------------------- Quay Security Operator ----------------------------------

# install the quay operator
kubectl create -f quaycontainersecurity.yaml
echo -e "\e[32mPlease wait 2 mimutes for the Quay container security operator to deploy propperly\e[0m"
sleep 120

# get all vulnerabilities from all namespaces
kubectl get imagemanifestvuln --all-namespaces -o json > SecurityLogs/QuaySecurityScanVulnerabilityReport.txt
echo "                    {
                        "name": "final-vuln",
" >> SecurityLogs/QuaySecurityScanVulnerabilityReport.txt

#-----------------------------------------------------------------------------------------------


#------------------------------------- Kube-hunter ---------------------------------------------
		
# create and switch to the kunehunter namespace
oc create ns kubehunter 2> errorlog.txt
oc project kubehunter 2> errorlog.txt

# delete the old kube-hunter job
oc delete job kube-hunter 2> errorlog.txt

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
kubectl create -f kubehunterjob.yaml 2> errorlog.txt

# wait for the pod to deploy before proceeding
echo -e "\e[32mPlease wait 20 seconds for the kube-hunter pod to deploy propperly\e[0m"
sleep 20

# format the logs from the kube-hunter pod to a log file
oc logs `oc get pods | awk '{print $1, $8}' |  sed 1,1d` > SecurityLogs/kubehunterlogs.txt  
sed -i '/- location: /,$!d' SecurityLogs/kubehunterlogs.txt 
echo "- location: " >> SecurityLogs/kubehunterlogs.txt

# clean up the used job
rm -rf kubehunterjob.yaml


#---------------------------------------------------------------------------------------------

# install polaris to check for kubernetes configuration best practices
kubectl apply -f https://github.com/FairwindsOps/polaris/releases/latest/download/dashboard.yaml

kubectl create -f polarisroute.yaml 2> errorlog.txt

                                                 
echo -e "\e[32m================================="
echo -e "+ Exiting security application +"
echo -e "=================================\e[0m"
echo -e "\e[32mAll logging is stored under the 'SecurityLogs' folder\e[0m"
