#!/bin/bash
# QAMANI Project Setup Script
# يجمع كل ما أنجزناه ويجهز المشروع للرفع على GitHub

# 1️⃣ تثبيت الأدوات الأساسية (بدون Terraform)
apk update && apk upgrade
apk add nano git python3 py3-pip curl wget \
    nginx mariadb mariadb-client docker kubectl ufw htop rsync tar \
    helm ansible unzip

# 2️⃣ تثبيت Terraform يدويًا
wget https://releases.hashicorp.com/terraform/1.9.0/terraform_1.9.0_linux_amd64.zip
unzip terraform_1.9.0_linux_amd64.zip
mv terraform /usr/local/bin/
rm terraform_1.9.0_linux_amd64.zip


# 2️⃣ إنشاء هيكل المشروع
mkdir -p qamani-cheatsheet/{scripts,examples,charts/qamani/templates,ansible/roles/qamani-role/{tasks,handlers,vars},.github/workflows}
cd qamani-cheatsheet

# 3️⃣ README.md
cat > README.md << 'EOF'
# QAMANI Linux Cheat Sheet
مشروع متكامل يشمل:
- Dockerfile
- docker-compose.yml
- Kubernetes YAML
- Helm Chart
- Terraform
- Ansible Playbooks
- CI/CD عبر GitHub Actions
EOF

# 4️⃣ Dockerfile
cat > Dockerfile << 'EOF'
FROM alpine:latest
RUN apk update && apk upgrade && apk add --no-cache \
    bash nano git python3 py3-pip curl wget \
    nginx mariadb mariadb-client docker kubectl ufw htop rsync tar helm terraform ansible
WORKDIR /opt/qamani
COPY scripts/ ./scripts/
COPY README.md .
RUN chmod +x ./scripts/*.sh
CMD ["bash"]
EOF

# 5️⃣ docker-compose.yml
cat > examples/docker-compose.yml << 'EOF'
version: '3.8'
services:
  qamani-app:
    build: ..
    container_name: qamani-app
    image: qamani-cheatsheet:latest
    command: bash
    volumes:
      - ../scripts:/opt/qamani/scripts
    networks:
      - qamani-net
  nginx:
    image: nginx:latest
    container_name: qamani-nginx
    ports:
      - "8080:80"
    networks:
      - qamani-net
    depends_on:
      - qamani-app
  mariadb:
    image: mariadb:latest
    container_name: qamani-db
    environment:
      MYSQL_ROOT_PASSWORD: qamani123
      MYSQL_DATABASE: qamani_db
      MYSQL_USER: qamani
      MYSQL_PASSWORD: qamani_pass
    ports:
      - "3306:3306"
    networks:
      - qamani-net
networks:
  qamani-net:
    driver: bridge
EOF

# 6️⃣ Kubernetes YAML
cat > examples/kubernetes-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: qamani-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: qamani
  template:
    metadata:
      labels:
        app: qamani
    spec:
      containers:
      - name: qamani-container
        image: qamani-cheatsheet:latest
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: qamani-service
spec:
  selector:
    app: qamani
  ports:
    - port: 80
      targetPort: 8080
  type: ClusterIP
EOF

# 7️⃣ Helm Chart
cat > charts/qamani/Chart.yaml << 'EOF'
apiVersion: v2
name: qamani
description: QAMANI Helm Chart
type: application
version: 0.1.0
appVersion: "1.0.0"
EOF

cat > charts/qamani/values.yaml << 'EOF'
replicaCount: 2
image:
  repository: qamani/qamani-cheatsheet
  tag: latest
  pullPolicy: IfNotPresent
service:
  type: ClusterIP
  port: 80
EOF

# 8️⃣ Terraform
cat > examples/terraform/main.tf << 'EOF'
provider "aws" {
  region = var.region
}
resource "aws_instance" "qamani_server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  tags = { Name = "QAMANI-Server" }
}
EOF

# 9️⃣ Ansible Playbook
cat > ansible/inventory.ini << 'EOF'
[qamani_servers]
server1 ansible_host=192.168.1.10 ansible_user=root
EOF

cat > ansible/playbook.yml << 'EOF'
- name: QAMANI Playbook
  hosts: qamani_servers
  become: true
  roles:
    - qamani-role
EOF

cat > ansible/roles/qamani-role/tasks/main.yml << 'EOF'
- name: Update system packages
  apk:
    update_cache: yes
    upgrade: yes
EOF

# 🔟 CI/CD Workflow
cat > .github/workflows/ci-cd.yml << 'EOF'
name: QAMANI CI/CD
on:
  push:
    branches: [ "main" ]
jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: docker/setup-buildx-action@v2
    - uses: docker/login-action@v2
      with:
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}
    - uses: docker/build-push-action@v4
      with:
        context: .
        push: true
        tags: qamani/qamani-cheatsheet:latest
EOF

# 1️⃣1️⃣ رفع المشروع على GitHub
git init
git add .
git commit -m "QAMANI Project Initial Commit"
git branch -M main
git remote add origin https://github.com/qamanicode/qamani-cheatsheet.git
git push -u origin main
