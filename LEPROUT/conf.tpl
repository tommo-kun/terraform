#!/bin/bash
yum update -y
yum install -y haproxy
echo "Z2xvYmFsCiAgICBsb2cgICAgICAgICAxMjcuMC4wLjEgbG9jYWwyCgogICAgY2hyb290ICAgICAgL3Zhci9saWIvaGFwcm94eQogICAgcGlkZmlsZSAgICAgL3Zhci9ydW4vaGFwcm94eS5waWQKICAgIG1heGNvbm4gICAgIDQwMDAKICAgIHVzZXIgICAgICAgIGhhcHJveHkKICAgIGdyb3VwICAgICAgIGhhcHJveHkKICAgIGRhZW1vbgoKICAgIHN0YXRzIHNvY2tldCAvdmFyL2xpYi9oYXByb3h5L3N0YXRzCgogICAgc3NsLWRlZmF1bHQtYmluZC1jaXBoZXJzIFBST0ZJTEU9U1lTVEVNCiAgICBzc2wtZGVmYXVsdC1zZXJ2ZXItY2lwaGVycyBQUk9GSUxFPVNZU1RFTQoKZGVmYXVsdHMKICAgIG1vZGUgICAgICAgICAgICAgICAgICAgIGh0dHAKICAgIGxvZyAgICAgICAgICAgICAgICAgICAgIGdsb2JhbAogICAgb3B0aW9uICAgICAgICAgICAgICAgICAgaHR0cGxvZwogICAgb3B0aW9uICAgICAgICAgICAgICAgICAgZG9udGxvZ251bGwKICAgIG9wdGlvbiBodHRwLXNlcnZlci1jbG9zZQogICAgb3B0aW9uIGZvcndhcmRmb3IgICAgICAgZXhjZXB0IDEyNy4wLjAuMC84CiAgICBvcHRpb24gICAgICAgICAgICAgICAgICByZWRpc3BhdGNoCiAgICByZXRyaWVzICAgICAgICAgICAgICAgICAzCiAgICB0aW1lb3V0IGh0dHAtcmVxdWVzdCAgICAxMHMKICAgIHRpbWVvdXQgcXVldWUgICAgICAgICAgIDFtCiAgICB0aW1lb3V0IGNvbm5lY3QgICAgICAgICAxMHMKICAgIHRpbWVvdXQgY2xpZW50ICAgICAgICAgIDFtCiAgICB0aW1lb3V0IHNlcnZlciAgICAgICAgICAxbQogICAgdGltZW91dCBodHRwLWtlZXAtYWxpdmUgMTBzCiAgICB0aW1lb3V0IGNoZWNrICAgICAgICAgICAxMHMKICAgIG1heGNvbm4gICAgICAgICAgICAgICAgIDMwMDAKCgo=" | base64 -d > /etc/haproxy/haproxy.cfg
cat << EOF >> /etc/haproxy/haproxy.cfg

frontend web_front
        bind *:80
        mode http
        use_backend web_back
backend web_back
		balance roundrobin
	    mode tcp
		server master ${WEB_IP1:80 check
		server node ${WEB_IP2}:80 check
		server server1 ${WEB_IP3}:80 check

EOF
systemctl enable --now haproxy
exit
