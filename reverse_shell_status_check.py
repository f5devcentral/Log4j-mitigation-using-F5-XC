import paramiko
from scp import SCPClient
import time
import re
import json
import requests
import textwrap
import awslib
import sys

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())


def deploy_app(pub_ip, username="ubuntu", pem_file=True):
    """Deploy application for EC2 instance with IP: pub_ip."""
    if pem_file:
        key = paramiko.RSAKey.from_private_key_file("./AWS/"+"aws-key.pem")
    else:
        key = paramiko.RSAKey.from_private_key_file("./" + key_pair)
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        result = 0
        print("========================= Connecting to instance. =============================")
        client.connect(username=username, hostname=pub_ip, pkey=key)
        scp = SCPClient(client.get_transport())
        print("=============== Waiting for 5 mins to download all images. ====================")
        time.sleep(2)
        stdin, stdout, stderr = client.exec_command('pwd')
        #stdout.channel.recv_exit_status()
        ret = stdout.readlines()
        print("======================  Printing docker ps output  ===================")
        print(ret)
        for _ in range(75):
            stdin, stdout, stderr = client.exec_command('netstat -a | grep 5320')
            netcat_output = stdout.readlines()
            print(netcat_output)
            if netcat_output == []:
                print("Instance is not listening to port 5320")
                time.sleep(4)
                continue
            elif len(netcat_output) == 1:
                if "LISTEN" and "5320" in netcat_output[0]:
                    print("Device is listening to port 5320")
                    time.sleep(4)
            elif len(netcat_output) == 2:
                if "ESTABLISHED" and "5320" in netcat_output[1]:
                    print("Remote server opens the reverse shell connectivity to netcat utility window")
                    result = 1
                    break
        if result == 1:
            print("pass")
        else:
            print("Fail")
        # Killing the netcat utility
        stdin, stdout, stderr = client.exec_command('lsof -i -P -n | grep LISTEN')
        ls_of = stdout.readlines()
        print(ls_of)
        pid_id = ls_of[0].split()
        print("Pid id is: %s" %pid_id)
        stdin, stdout, stderr = client.exec_command('kill -9 %s' %pid_id[1])
        print("Pid killed successfully")
        for _ in range(5):
            stdin, stdout, stderr = client.exec_command('netstat -a | grep 5320')
            netcat_output = stdout.readlines()
            print(netcat_output)
            if netcat_output == []:
                print("Instance is not listening to port 5320 after killing")
                time.sleep(4)
                break
            elif len(netcat_output) == 1:
                if "LISTEN" and "5320" in netcat_output[0]:
                    print("Device is listening to port 5320 which is not expected")
                    time.sleep(4)
                    continue
        
            
    except Exception as e:
        raise Exception(e)


if __name__ == "__main__":
    pub_ip = sys.argv[1]
    deploy_app(pub_ip)
