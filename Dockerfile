FROM ubuntu:14.04


LABEL authors="pavanpkulkarni@pavanpkulkarni.com"
 
RUN apt-get update

# This step will install java 8 on the image
RUN apt-get install software-properties-common -y \
&&  apt-add-repository ppa:webupd8team/java -y \
&&  apt-get update -y \

# this step will agree and install java 8
&&  echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections \
&&  echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections \

# this step will install java and supervisor
&&  apt-get install -y oracle-java8-installer \
    supervisor

############ SBT INSTALLATION ############
ENV SCALA_HOME /usr/local/share/scala
ENV PATH $PATH:$SCALA_HOME/bin

ENV SCALA_VERSION 2.11.11
ENV SBT_VERSION 0.13.16

RUN apt-get update && apt-get install wget curl && \
    wget --quiet http://downloads.lightbend.com/scala/$SCALA_VERSION/scala-$SCALA_VERSION.tgz && \
    tar -xf scala-$SCALA_VERSION.tgz && \
    rm scala-$SCALA_VERSION.tgz && \
    mv scala-$SCALA_VERSION $SCALA_HOME

# Install sbt
RUN \
  curl -L -o sbt-$SBT_VERSION.deb https://dl.bintray.com/sbt/debian/sbt-$SBT_VERSION.deb && \
  dpkg -i sbt-$SBT_VERSION.deb && \
  rm sbt-$SBT_VERSION.deb && \
  apt-get update && \
  apt-get install sbt && \
  sbt sbtVersion

RUN mkdir -p /usr/src/app
COPY . /usr/src/app
WORKDIR /usr/src/app
RUN sbt compile
RUN rm -rf /usr/src/app/*
############ SBT INSTALLATION ############


ENV SPARK_VERSION 2.4.0
ENV HADOOP_VERSION 2.7
# download and extract Spark 
#RUN wget https://archive.apache.org/dist/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop$HADOOP_VERSION.tgz \
RUN wget http://mirrors.estointernet.in/apache/spark/spark-2.4.0/spark-2.4.0-bin-hadoop2.7.tgz \
&&  tar -xzf spark-2.4.0-bin-hadoop2.7.tgz \
&&  mv spark-2.4.0-bin-hadoop2.7 /opt/spark

# Set spark home 
ENV SPARK_HOME /opt/spark
ENV PATH $SPARK_HOME/bin:$PATH

# adding conf files to all images. This will be used in supervisord for running spark master/slave
COPY master.conf /opt/conf/master.conf
COPY slave.conf /opt/conf/slave.conf
COPY history-server.conf /opt/conf/history-server.conf

# Adding configurations for history server
COPY spark-defaults.conf /opt/spark/conf/spark-defaults.conf
RUN  mkdir -p /opt/spark-events

# expose port 8080 for spark UI
EXPOSE 4040 6066 7077 8080 18080 8081

#default command: this is just an option 
CMD ["/opt/spark/bin/spark-shell", "--master", "local[*]"]
