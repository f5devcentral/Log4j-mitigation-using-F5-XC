import paramiko
from scp import SCPClient
import time
import re
import json
import requests
import textwrap
import awslib
import sys
import socket
import time

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
        print("========================= Connecting to instance. =============================")
        client.connect(username=username, hostname=pub_ip, pkey=key)
        scp = SCPClient(client.get_transport())
        print("=============== Waiting for 5 mins to download all images. ====================")
        time.sleep(10)
        stdin, stdout, stderr = client.exec_command('pwd')
        #stdout.channel.recv_exit_status()
        ret = stdout.readlines()
        print("======================  Printing docker ps output  ===================")
        print(ret)
        print("====================== About to execute netcad utility command ===================")
        stdin, stdout, stderr = client.exec_command('nc -lnv 5320')
        ret = stdout.readlines()
        print(ret)
        print("====================== completed executing netcad utility command ===================")
        if "can't access tty; job control turned off" in ret[0] and "$" in ret[1]:
            print("Remote N/W is accessed via reverse shell")
        else:
            print("Remote N/W is not accessed via reverse shell")
        print("========================== Validated Reverse Shell as well =========================")
        
    except Exception as e:
        raise Exception(e)
        
if __name__ == "__main__":
    pub_ip = sys.argv[1]
    deploy_app(pub_ip)
