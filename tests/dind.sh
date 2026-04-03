# [[file:../doc/dind.org::*Test script][Test script:1]]
ROOT='/home/sam/prog/dagger'
source "./helpers.sh"

dind_docker_installed_code () {
      dagger call dind-container with-exec --args="docker","--version" stdout
}

dind_docker_installed_expected () {
      cat<<"EOEXPECTED"
Docker version 29.3.1, build c2be9cc
EOEXPECTED
}

echo 'Run dind_docker_installed'

{ dind_docker_installed_code || true ; } > "${TMP}/code.txt" 2>/dev/null
dind_docker_installed_expected > "${TMP}/expected.txt"
diff -uBw "${TMP}/code.txt" "${TMP}/expected.txt" || {
echo "Something went wrong when trying dind_docker_installed"
exit 1
}


dind_docker_info_code () {
      dagger call dind-with-docker --cmd="docker info" stdout
}

dind_docker_info_expected () {
      cat<<"EOEXPECTED"
  Client: Docker Engine - Community
   Version:    29.3.1
   Context:    default
   Debug Mode: false
   Plugins:
    buildx: Docker Buildx (Docker Inc.)
      Version:  v0.33.0
      Path:     /usr/libexec/docker/cli-plugins/docker-buildx
    compose: Docker Compose (Docker Inc.)
      Version:  v5.1.1
      Path:     /usr/libexec/docker/cli-plugins/docker-compose

  Server:
   Containers: 0
    Running: 0
    Paused: 0
    Stopped: 0
   Images: 0
   Server Version: 29.3.1
   Storage Driver: overlayfs
    driver-type: io.containerd.snapshotter.v1
   Logging Driver: json-file
   Cgroup Driver: cgroupfs
   Cgroup Version: 2
   Plugins:
    Volume: local
    Network: bridge host ipvlan macvlan null overlay
    Log: awslogs fluentd gcplogs gelf journald json-file local splunk syslog
   CDI spec directories:
    /etc/cdi
    /var/run/cdi
   Swarm: inactive
   Runtimes: io.containerd.runc.v2 runc
   Default Runtime: runc
   Init Binary: docker-init
   containerd version: 301b2dac98f15c27117da5c8af12118a041a31d9
   runc version: v1.3.4-0-gd6d73eb8
   init version: de40ad0
   Security Options:
    seccomp
     Profile: builtin
    cgroupns
   Kernel Version: 6.8.0-64-generic
   Operating System: Ubuntu 24.04.4 LTS (containerized)
   OSType: linux
   Architecture: aarch64
   CPUs: 8
   Total Memory: 23.42GiB
   Name: 1e50e5c6-67a3-46a1-8114-04252517c214
   ID: 6efa0e05-37d1-4a37-96a0-be2299fd76bd
   Docker Root Dir: /var/lib/docker
   Debug Mode: false
   Experimental: false
   Insecure Registries:
    ::1/128
    127.0.0.0/8
   Live Restore Enabled: false
   Firewall Backend: iptables


EOEXPECTED
}

echo 'Run dind_docker_info'

{ dind_docker_info_code || true ; } > "${TMP}/code.txt" 2>/dev/null
dind_docker_info_expected > "${TMP}/expected.txt"
diff -uBw "${TMP}/code.txt" "${TMP}/expected.txt" || {
echo "Something went wrong when trying dind_docker_info"
exit 1
}
# Test script:1 ends here
