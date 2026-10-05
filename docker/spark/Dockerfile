ARG SPARK_VERSION=3.5.1

FROM apache/spark:${SPARK_VERSION}@sha256:b49e3b73ce385c1693cc3294ec4b5b3882e9fa9bd5fc599d4c79198abc49cc94 AS spark-runtime

ARG HADOOP_AWS_VERSION=3.3.4
ARG AWS_SDK_BUNDLE_VERSION=1.12.262

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates curl procps python3 python3-pip python3-venv python3-numpy \
    && ln -sf /usr/bin/python3 /usr/bin/python \
    && rm -rf /var/lib/apt/lists/*

RUN curl --fail --location --retry 5 \
      "https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_AWS_VERSION}/hadoop-aws-${HADOOP_AWS_VERSION}.jar" \
      --output "/opt/spark/jars/hadoop-aws-${HADOOP_AWS_VERSION}.jar" \
    && curl --fail --location --retry 5 \
      "https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/${AWS_SDK_BUNDLE_VERSION}/aws-java-sdk-bundle-${AWS_SDK_BUNDLE_VERSION}.jar" \
      --output "/opt/spark/jars/aws-java-sdk-bundle-${AWS_SDK_BUNDLE_VERSION}.jar"

COPY config/spark/ /opt/spark/conf/

COPY docker/spark/jars.sha256 /opt/spark/jars.sha256
RUN cd /opt/spark/jars && sha256sum -c /opt/spark/jars.sha256

RUN mkdir -p /data /workspace /spark-events \
    && chmod 0777 /data /workspace /spark-events


FROM spark-runtime AS jupyter-runtime

ARG SPARK_VERSION=3.5.1

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends tini \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.lock /opt/spark-lab-requirements.txt
RUN pip3 install --no-cache-dir "pyspark==${SPARK_VERSION}" \
      -r /opt/spark-lab-requirements.txt \
    && pip3 check

RUN mkdir -p /home/jovyan/work \
    && chmod 0777 /home/jovyan /home/jovyan/work

WORKDIR /home/jovyan/work

ENTRYPOINT ["/usr/bin/tini", "--"]

CMD ["jupyter", "lab", \
     "--LabApp.extension_manager=readonly", \
     "--ServerApp.ip=0.0.0.0", \
     "--ServerApp.port=8888", \
     "--ServerApp.root_dir=/home/jovyan/work", \
     "--ServerApp.allow_root=True", \
     "--ServerApp.open_browser=False", \
     "--ServerApp.allow_remote_access=True"]
