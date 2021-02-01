# RPM Construction README

* * *

# Steps

**(1)** Create build directory and tgz archive:

```
$ mkdir ~/build-1.6
$ cp <project_root>/buildpy /tmp/buildpy-1.6/
$ cp <project_root>/core/* /tmp/buildpy-1.6/
```

**(2)** Update paths, content

```
update log_path
update lib_path
update version # in version.py (builddir)
update vesion # in version.py (git root)
```

**(3)** Create TAR Archive

```
$ tar -czf ~/build-1.6.6.tar.gz ~/build-1.6
```

**(4)** Create a SPEC file

```
$ cp packaging/rpm/buildpy.spec `/tmp/buildpy.spec`
$ update MAJOR_VERSION, MINOR_VERSION in /tmp/buildpy.spec
$ update DOCKERUSER
```

**(5)** Create a .rpmmacros file

```
$ cd   packaging/rpm/
$ cp rpmmacros buildpy.spec buildpy-version.tar.gz  packaging/docker/centos/
```

**(6)** Launch Redhat Container from DockerFile

* Dockerfile copies both tarfile and buildpy.spec into container.
* Runs docker-buildrpm.sh script in container


**(7)** [DOCKER]: Install required local dependencies

```
$ yum install rpm-build rpmdevtools
```

**(8)** [DOCKER]:  Create Directory Structure

```
$ cd ~
$ rpmdev-setuptree
```

Validate creation. If failed, create:

```
$ mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS,tmp}
```

**(9)** [DOCKER]:  Mv .rpmmacros File to somewhere (?) in rpmbuild dir:

```
$ mv   ~/.rpmmacros ~/rpmbuild/?/.rpmmacros
```


**(10)** [DOCKER]:  Move tar archive to SOURCES:

```
$ mv ~buildpy-1.6.6.tar.gz ~/rpmbuild/SOURCES/buildpy-1.6.6.tar.gz
```

**(11)** [DOCKER]:  Mv SPEC file to SOURCES

```
$ mv ~/buildpy.spec `~/rpmbuild/SPECS/buildpy.spec`
```

**(10)** [DOCKER]:  Build RPM Package

```
$ cd ~/rpmbuild

$ rpmbuild -ba SPECS/buildpy.spec
```

* * *

# References

* https://tecadmin.net/create-rpm-of-your-own-script-in-centosredhat/
