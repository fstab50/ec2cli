* * *
# Docker Guide
* * *

### Manual Container Create:  Debian Systems

To build Debian system packages (.deb file), execute the following from the top level of this git repository:

```bash
$ docker run --name=debbuild1 -d -v /tmp/deb:/mnt/deb -ti ubuntu16.04:debbuild '<bash command>'

    where '<bash command>' is:   tail -f /dev/null

```


* * *

### Manual Container Create:  Redhat Systems

To build Redhat system packages (.rpm file), execute the following from the top level of this git repository:

```bash
$ docker run --name=rpmbuild1 -d -v /tmp/rpm:/mnt/rpm -ti centos7:rpmbuild '<bash command>'

    where '<bash command>' is:   tail -f /dev/null

```

* * *
