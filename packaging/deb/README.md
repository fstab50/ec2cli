* * *
# Deb Package Construction README
* * *

## Instructions | Create Binary Package

1.  Create working directory in the form of <packagename>-<version>.
2.  Create **DEBIAN** directory in the working directory.
3.  Copy control and postint files to **DEBIAN** directory.
4.  Update the version number in the control file with __version__ from core/\version.py module.
5.  Update the pkg_lib path:

    ```
    $  sed '/pkg_lib=/c\pkg_lib="\/usr\/local\/lib\/buildpy"' buildpy 
    ```

6.  Copy updated `buildpy` executable to bin/ directory:

    ```
    $ cp buildpy  <packagename>-<version>/usr/local/bin/
    ```

7.  Copy any dependencies to the lib/ location within the working directory:

    ```
    $ cp core/* <packagename>-<version>/usr/local/lib/buildpy/
    ```

8.  From outside the <packagename> directory, issue cmd to Create package:

    ```
    $ dpk-deb --build <packagename>-<version>
    ```

9.  Creates .deb package next to build directory:  `buildpy-1.6.1.deb`

10.  Install the binary:

    ```
    $ sudo dpkg -i buildpy-1.6.1.deb
    ```

* * *

# References

* [Create Binary .deb Package](http://www.king-foo.com/2011/11/creating-debianubuntu-deb-packages)
