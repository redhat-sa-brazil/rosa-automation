FROM registry.access.redhat.com/ubi8/python-39

USER 0
RUN mkdir -p /opt/redhat/automacao
RUN mkdir -p /opt/redhat/backup-yaml
COPY requirements.txt /opt/redhat/ 


#Install requirements and awscli
RUN pip install --upgrade pip && \
    pip install -r /opt/redhat/requirements.txt

RUN wget "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz" && \
    tar -xvf openshift-client-linux.tar.gz && \
    chmod u+x oc kubectl && \
    mv oc /usr/local/bin && \
    mv kubectl /usr/local/bin 

RUN wget "https://mirror.openshift.com/pub/openshift-v4/clients/rosa/latest/rosa-linux.tar.gz" && \
    tar -xvf rosa-linux.tar.gz && \
    chmod u+x rosa && \
    mv rosa /usr/local/bin

RUN git clone https://github.com/redhat-sa-brazil/rosa-automation.git /opt/redhat/automacao

RUN chown -R 1001:0 /opt/redhat
USER 1001
WORKDIR /opt/redhat


CMD ["sh", "-c", "tail -f /dev/null"]