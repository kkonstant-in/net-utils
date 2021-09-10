# Introduction 
A set of network tools in a container for k8s network troubleshooting and testing, based on Alpine Linux.  
The idea and initial dockerfile were taken from [Network-Multitool](https://hub.docker.com/r/praqma/network-multitool) and adopted to enterprise k8s security requirements and limitations.  
Such requirements include `spec.securityContext.runAsNonRoot=true`, nginx starting from non-root username and port 8080 as a result.  
[The list of tools](#tools-included) includes `aws` S3 command line client, `tcpdump` and some others.  
Please pay attention that some of them can not be used in runAsNonRoot mode.
# Tools included
- apk package manager
- nginx (port 8080) - customizable ports
- curl, wget
- dig, nslookup
- ip, ifconfig, ethtool, mii-tool, route
- ping, traceroute, tracepath, mtr, arp, arping, netcat (nc), socat
- tcpdump, nmap, iperf3
- ps, netstat, ss, find
- awk, sed, grep, jq, cut, diff, wc, vi
- gzip, cpio
- command line clients: aws, telnet, ssh, ftp, rsync, scp, git, mysql, postgresql
- ApacheBench (ab)
# Usage - on Kubernetes
```bash
kubectl run net-utils --image=kkonstant/net-utils --replicas=1
```
Enterprise k8s env may be limited to using some local artifactory.  
It may also require securityContext and resources specified.
```bash
nano k8s/net-utils.yml # edit accordingly
kubectl -n namespace apply -f k8s/net-utils.yml
```
# Usage - on Docker
```bash
docker run --rm -it kkonstant/net-utils /bin/bash
# OR
docker run --name net-utils --rm -d net-utils:2.1
docker exec -it net-utils bash
# OR
docker run -e HTTP_PORT=1080 -e HTTPS_PORT=1443 -p 1080:1080 -p 1443:1443 -d kkonstant/net-utils
```
# Build and Push to dockerhub instructions
```
docker build -t net-utils .
docker tag net-utils kkonstant/net-utils
docker login
docker push kkonstant/net-utils
```
# Build and Push to local artifactory instructions
```bash
docker build -t net-utils .
docker tag net-utils docker.artifactory2.companyname.co.nz/net-utils:2.1
docker tag net-utils docker.artifactory2.companyname.co.nz/net-utils:latest
docker login https://docker.artifactory2.companyname.co.nz/docker-companyname-local/ # for init only
docker push docker.artifactory2.companyname.co.nz/net-utils
```
# Pull alpine docker image for local build
The following may be required in a private secure network with a limited access to the internet
```bash
skopeo --src-tls-verify=false copy docker://alpine:3.13.4 docker-archive:/tmp/alpine.tar:alpine:3.13.4
docker load --input /tmp/alpine.tar
```
