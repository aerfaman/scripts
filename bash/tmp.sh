#配置代理
cat > ~/.bashrc <<EOF
proxyoff='unset http_proxy && unset https_proxy'
proxyon='export http_proxy=http://192.168.50.12:7890 && export https_proxy=http://192.168.50.12:7890'
EOF

cat > /etc/profile.d/proxy.sh << EOF
export http_proxy=http://192.168.50.12:7890
export https_proxy=http://192.168.50.12:7890
EOF

source ~/.bashrc
source /etc/profile

