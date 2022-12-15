import os
import time
import sys
import requests
import urllib3
from tqdm import tqdm
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

lb_domain = sys.argv[1]
# boolean variable: to be update when requests to https lb sends back a response code 
check = 0
# request count variable: increments with each unsuccesful request to https lb (max_limit=10) 
req_count = 0

def validate_deploy():
    """ 
    The function will check the reachability of load balancer 
    
    Parameter:
    secure (Boolean): request protocol HTTP[False]/HTTPS[True]    
    """
    git_env = os.getenv('GITHUB_ENV')
    global check, req_count
    # try/except block to handle connection exception 
    try:
        req = requests.get("https://{}".format(lb_domain), verify=False, timeout=5)
        # verification of request's reponse code
        if req.status_code != 400:
            print('Request status code not equal to 400, please check the IP and port of hosted application')
            check = 1
            with open(git_env, "a") as bashfile:
                bashfile.write("EXIT=true")
        else:
            print('Request to https lb is successful')
            check = 1
            with open(git_env, "a") as bashfile:
                bashfile.write("EXIT=false")
    except requests.exceptions.ConnectionError:
        if req_count == 20:
            print('https://{} is not reachable (Exception raised)'.format(lb_domain))
            with open(git_env, "a") as bashfile:
                bashfile.write("EXIT=true")
                
def main():
    global check, req_count
    for status in tqdm(range(20), desc="accessibility check"):
        if check != 1:
            req_count += 1
            time.sleep(30)
            validate_deploy()
        else:
            break
     
                
if __name__ == "__main__":
    main()
