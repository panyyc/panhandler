
FROM python:3.6-alpine

LABEL description="Panhandler"
LABEL version="2.3"
LABEL maintainer="sp-solutions@paloaltonetworks.com"

ENV TERRAFORM_VERSION=0.11.13
ENV TERRAFORM_SHA256SUM=5925cd4d81e7d8f42a0054df2aafd66e2ab7408dbed2bd748f0022cfe592f8d2
ENV CNC_USERNAME=paloalto
ENV CNC_PASSWORD=panhandler
ENV CNC_HOME=/home/cnc_user
ENV CNC_APP=Panhandler

WORKDIR /app
ADD requirements.txt /app/requirements.txt

COPY cnc /app/cnc
COPY src /app/src

RUN apk add --update --no-cache git curl build-base musl-dev python3-dev libffi-dev openssl-dev \
    linux-headers libxml2-dev libxslt-dev openssh && \
    pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt && \
    echo "===> Installing Terraform..."  && \
    curl -k https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    > terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    echo "${TERRAFORM_SHA256SUM}  terraform_${TERRAFORM_VERSION}_linux_amd64.zip" > terraform_${TERRAFORM_VERSION}_SHA256SUMS && \
    sha256sum -cs terraform_${TERRAFORM_VERSION}_SHA256SUMS && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /bin && \
    rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip  && \
    rm -f terraform_${TERRAFORM_VERSION}_SHA256SUMS && \
    apk del build-base linux-headers openssl-dev python3-dev libffi-dev musl-dev && \
    rm -rf /var/cache/apk/* && \
    if [ -f /app/cnc/db.sqlite3 ]; then rm /app/cnc/db.sqlite3; fi && \
    addgroup -S cnc_group && adduser -S cnc_user -G cnc_group -u 9001 && \
    mkdir /home/cnc_user/.pan_cnc && \
    chown cnc_user:cnc_group /home/cnc_user/.pan_cnc && \
    chgrp cnc_group /app/cnc && \
    chgrp cnc_group /app/src/panhandler/snippets && \
    chmod g+w /app/cnc && \
    chmod g+w /app/src/panhandler/snippets

# Run  Prisma Public Cloud Vulnerability Scan API
# add -k option for SSL decrypt scenarios
#RUN curl -i -s -k -X POST https://scanapi.redlock.io/v1/vuln/os \
# -F "fileName=/etc/alpine-release" -F "file=@/etc/alpine-release" \
# -F "fileName=/lib/apk/db/installed" -F "file=@/lib/apk/db/installed" \
# -F "rl_args=report=detail" | grep -i "x-redlock-scancode: pass"

USER cnc_user
EXPOSE 8080
CMD ["/app/cnc/start_app.sh"]
