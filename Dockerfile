FROM registry.svc.ci.openshift.org/openshift/release:golang-1.10 AS builder
WORKDIR /go/src/github.com/metal3-io/metal3-smart-exporter
ADD . /go/src/github.com/metal3-io/metal3-smart-exporter

RUN go build -o smart_exporter ./smart_exporter.go

FROM docker.io/centos:centos7

RUN yum install -y smartmontools && yum clean all

COPY --from=builder /go/src/github.com/metal3-io/metal3-smart-exporter/smart_exporter /bin/smart_exporter
COPY ./return_smart_info.sh /usr/local/bin/return_smart_info.sh
RUN chmod +x /usr/local/bin/return_smart_info.sh

EXPOSE 59100

ENTRYPOINT [ "/bin/smart_exporter" ]
