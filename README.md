# Automate detection and mitigation of Log4j vulnerability using F5 XC WAF

This Repo will give you the detailed information on how to automate the testing identifying Log4j vulnerability in applications and protecting it using F5 Distributed Cloud WAAP WAF
(https://community.f5.com/t5/technical-articles/f5-distributed-cloud-waap-introducing-the-distributed-cloud-web/ta-p/292992)

**Table of Contents:** <br />
---
&nbsp;&nbsp;&nbsp;&nbsp;•	**[Overview](#Overview)** <br />
&nbsp;&nbsp;&nbsp;&nbsp;•	**[Deployment Design](#Deployment-Design)** <br />
&nbsp;&nbsp;&nbsp;&nbsp;•	**[Prerequisites](#Prerequisites)** <br />
&nbsp;&nbsp;&nbsp;&nbsp;•	**[Steps to run the workflow](#Steps-to-run-the-workflow)** <br />
&nbsp;&nbsp;&nbsp;&nbsp;•	**[Jobs in the workflow](#Jobs-in-the-workflow)** <br />
&nbsp;&nbsp;&nbsp;&nbsp;•	**[Sample output logs](#Sample-output-logs)** <br />
<br />

# Overview:
F5 XC WAF protects web application again modern day attacks such as Log4 Shell. 

To explore this vulnerability the attackers need to control the rogue LDAP server and then submit a request to the vulnerable server directing Log4j logging utility  to download and execute the code from LDAP server. This code instructs the vulnerable server to open a reverse shell session which will effectively grant the attacker remote shell capability. This is carried out though CI/CD deployment using GitHub Actions, Terraform and Python.

![image](https://user-images.githubusercontent.com/115977670/203781465-8a7c8979-d594-4269-942f-7883f72bd544.png)
Fig 1: Attacker gaining remote shell access capability to vulnerable server. 

# Deployment Design:
The objective of this automation is to validate F5 XC WAAP WAF to protect web application from attacker that consists of Log4 Shell vulnerability. <br />
Below are the steps followed to test the behaviour: <br />
1. Create Virtual K8s (vK8s) object in F5 XC console. 
2. Downloaded images of Vulnerable and LDAP server with F5 XC using virtual Kubernetes (vK8s) using yaml file. 
3. Created Origin Pool, Load Balancer in F5 XC console. 
4. Created AWS EC2 Instance to validate remote shell access. 
5. Performed attack to application server contains Log4j vulnerability.  
6. Applied F5 XC WAF Policy to LB to protect server with Log4j vulnerability. 
7. Validated protection of server with Log4j vulnerability using F5 XC WAF. 


![203828709-cba33e7e-82e6-4f0f-9f83-39c16a9d346d](https://user-images.githubusercontent.com/115977670/207570890-7efea518-b99d-4502-b63a-cb1b4e2d7779.png)
Fig 2: Block diagram representation of Log4j testing

![image](https://user-images.githubusercontent.com/115977670/205885212-ff439216-20ba-42a5-afbb-f1f074f000f0.png)
Fig 3: Pictorial representation of Log4j testing Infra

**Prerequisites:**<br />
---
1.	F5 Distributed Cloud account. Refer https://console.ves.volterra.io/signup/usage_plan for account creation. <br />
2.	Create a F5 XC API Certificate and APIToken. Please refer to this page for generation: [https://docs.cloud.f5.com/docs/how-to/user-mgmt/credentials](https://docs.cloud.f5.com/docs/how-to/user-mgmt/credentials) <br />
3.	Extract the certificate and the key from the .p12 using below commands: <br />
```
    openssl pkcs12 -info -in certificate.p12 -out private_key-latest.key -nodes -nocerts
    openssl pkcs12 -info -in certificate.p12 -out certificate-latest.cert -nokeys
```
> Note: Name of Certificate and private key should be as "certificate-latest.cert" and "private_key-latest.key" as mentioned above. <br />

4.	Move the certificate and key files to the repository's root directory. <br />
5.  Create key pair and update RSA Private Key content of pem file to `aws-key.pem` in  `AWS` directory. Please refer to this page for key pair creation: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-key-pairs.html <br />
    1. Follow below step to generate the public key from SSH Private key(.pem) using below command. Copy the content to `aws-key.pub` in AWS directiory from .pub file mentioned below. <br /> 
    > Ex: ssh-keygen -y -f chthonda.pem > aws-test.pub <br />
> Note: The region in which pem file created should be updated in secrets as `AWS_REGION`.
6.  Create a namespace in F5 XC console with name `automation-waap-waf`. <br />
> Note: Update value of "service_name" in `f5_xc_resource_create.tf` and `apply_waf_policy.tf` file in root and WAF directory accordingly as service name followed by namespace as syntax mentioned below. <br />
> ![image](https://user-images.githubusercontent.com/115977670/207538024-69871fc7-2652-4b03-b693-1952daad1144.png) <br />
7.	Make sure to delegate domain in F5 XC console. Please follow the steps mentioned in doc: [https://docs.cloud.f5.com/docs/how-to/app-networking/domain-delegation](https://docs.cloud.f5.com/docs/how-to/app-networking/domain-delegation). <br />
8.	Gather AWS Account with `Access key`, `Secret key` and `Session Token`. Refer https://aws.amazon.com/resources/create-account/ for account creation. <br />
9.  Create vK8s object in F5 XC console. Please follow the steps mentioned here: https://docs.cloud.f5.com/docs/how-to/app-management/create-vk8s-obj
10.  Deploy the Image from registry using vK8s with F5 XC. <br />
&nbsp;&nbsp;&nbsp;&nbsp;a. Deploy resources with the kubeconfig of the vK8s object. Please refer to steps mentioned here: https://docs.cloud.f5.com/docs/how-to/app-management/vk8s-resources <br />
&nbsp;&nbsp;&nbsp;&nbsp;b. For referrence a Sample manifest is mentioned below(this should be modified as per your infra and deployment process), <br />
&nbsp;&nbsp;&nbsp;&nbsp; ![image](https://user-images.githubusercontent.com/115977670/205064286-f9b451a9-5f8f-4040-983b-70d9014452d8.png)


 
**Steps to run the workflow:**<br />
---
1.	In repo `Settings`, navigate to secrets, then expand `Actions` and update your AWS credentials aquired from Prerequisites-step-8. 
    If they are not available please create them with names `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `AWS_SESSION_TOKEN` and `TF_VAR_LBDOMAIN`. <br />
2.	Check the `variables.tf` in root directory and update `api_url` as per your tenant and other variables mentioned. <br />
    > Note: To avoid duplication make sure there is no Origin Pool, LB, WAF already exists with the names mentioned above in F5 XC console. <br />
3.  Check `variables.tf` in `AWS` directory and update the variable `ami` according to Ubuntu AMI ID from respective region of AWS. 
4.	Navigate to `Actions` tab in the repository and select the workflow to execute. <br />
    1. For full end to end testing we have to use `Protecting Log4j vulnerability using F5 XC WAF` workflow (this also destroys infra)
5.  Click on `Run workflow` drop-down on the right side of the UI. <br />
6.  Select the `main` branch and click on `Run workflow` button.  <br />
7.  After completion of test exectuion expand each job logs to understand script execution. <br />
    
**Jobs in the workflow:**<br />
---
&nbsp;&nbsp;&nbsp;&nbsp;• `F5_XC_Pool_LB_creation` - Creates Origin Pool and Load Balancer in F5 XC console. <br />
&nbsp;&nbsp;&nbsp;&nbsp;• `AWS_EC2_creation` - Creates EC2 instance in AWS as a client. <br />
&nbsp;&nbsp;&nbsp;&nbsp;• `LB_Domain_Status_Check` - Validates status of LB by accessing its domain name. <br />
&nbsp;&nbsp;&nbsp;&nbsp;• `Exploit-Log4j-Vulnerability` - Perform curl request to the application with Log4j vulnerability to exploit. <br />
&nbsp;&nbsp;&nbsp;&nbsp;• `Remote_Shell_access_grant_validation` - Executes netcat utility command in client and look for reverse shell session to access vulnerable server. <br /> 
&nbsp;&nbsp;&nbsp;&nbsp;• `Reverse_Shell_connection_status_check` - Performs Log4j vulnerability validation of remote shell connectivity status using linux command. <br /> 
&nbsp;&nbsp;&nbsp;&nbsp;• `F5_XC_WAF_Policy_Apply` - Creates F5 XC WAF policy and apply to Load Balancer. <br /> 
&nbsp;&nbsp;&nbsp;&nbsp;• `Protect_Log4j_vulnerability_with_F5_XC_WAF` - Validates the protection of exploiting application with Log4j vulnerability when WAF is configured. <br /> 
&nbsp;&nbsp;&nbsp;&nbsp;• `Destroy` - Destroys resources created in AWS and F5 XC console. 

**Sample output logs:**<br />
---
Vulnerable application web page: <br />
![image](https://user-images.githubusercontent.com/115977670/204262129-6e1be556-b7fc-42ad-9a5d-b319e674997f.png) <br />
<br />

Full work-flow output: <br />
![image](https://user-images.githubusercontent.com/115977670/207567140-ab3ea6cf-48c5-4d4c-835f-b673518afee0.png) <br />
<br />


F5_XC_Pool_LB_creation Job Output: <br />
![image](https://user-images.githubusercontent.com/115977670/205905590-9fce7094-1e31-404a-b4c4-5a3064e80b2c.png) <br />
<br />

AWS_EC2_creation Job Output Job Output: <br />
![image](https://user-images.githubusercontent.com/115977670/205905842-d58691d9-b078-4045-8211-ad2cf6d17acb.png) <br />
<br />

Exploit-Log4j-Vulnerability Job Output: <br />
![image](https://user-images.githubusercontent.com/115977670/205906229-9066883a-baf7-4f85-90c7-ae7d84930f11.png) <br />
<br />

Remote_Shell_access_grant_validation Job Output: <br />
![image](https://user-images.githubusercontent.com/115977670/205906357-0e27983a-00b0-44f7-a8a0-0055ecf47b4d.png) <br />
<br />

Reverse_Shell_connection_status_check Job Output: <br />
![image](https://user-images.githubusercontent.com/115977670/205906506-078cf3ee-e695-417c-af0f-de27dfa3ec12.png) <br />
<br />

F5_XC_WAF_Policy_Apply Job Output: <br />
![image](https://user-images.githubusercontent.com/115977670/205906666-c5b49558-a47b-4e85-af4c-9dc32b5281cd.png) <br />
<br />

Protect_Log4j_vulnerability_with_F5_XC_WAF Job Output: <br />
![image](https://user-images.githubusercontent.com/115977670/205906949-13081d38-5a12-4fc6-83b6-f936771b710b.png) <br />
<br />

Destroy Job Output: <br />
![image](https://user-images.githubusercontent.com/115977670/205907254-cab2ae1e-522e-4804-a38b-5f85e7d44476.png) <br />
<br />


*Some of the issues and debugging steps: *<br />
1. If your HTTPs Load Balancer DNS Info column shows status as `VIRTUAL_HOST_DNS_A_RECORD_ADDED` instead of `VIRTUAL_HOST_READY` please make sure you don't run automation multiple times back to back.  <br />
2. EC2 instance type of `t3.small` is available in all the 3 availability zones of `ap-south-1`. If any regions other than ap-south-1 is selected does not support t3.small then kindly update ap-south-1 as AWS_REGION in secrets since it has tested many times. 




