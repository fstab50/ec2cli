## Screenshots (continued) ##

#### Execute Scripts -- Start Instance 
*Note: this utility may also be used to automate login to a running EC2 instance*
*as well as starting a stopped instance. See step 2. (below)* 

```bash
$ sh ec2-X-start-instance.sh
```
1.Select from list of instance choices:

![](./images/start-instance_01.png)

2.After instance is chosen, script performs a network access check:

  * Access check sources the security group and validates IPs listed in the group against your local IP. 
  * _Note_: if the instance you chose is already running, the script moves immediately to authentication (Step 4).

![](./images/start-instance_02.png)

3.If network access check succeeds, the ec2 wait function is called to prevent login until the instance starts.

![](./images/start-instance_03.png)

4.Authentication start:

  * Public IP and ssh key name are sourced from instance json data via api call.
  * The ssh key is then located on your local machine in the dir specified by the ``$SSH_KEYS`` env variable. 

![](./images/start-instance_04.png)

5.Login established (entire start sequence shown)

![](./images/start-instance_05.png)


( [Back to README](./README.md) )

* * *

#### Execute Scripts -- RDP Instance
This utility automates login of a Windows EC2 instance via RDP client from a Linux client. If the target instance is not running, it will be started.

```bash
$ sh ec2-X-rdp-desktop.sh
```
###### < screenshots pending />

( [Back to README](./README.md) )

* * *

#### Execute Scripts -- Attach Volume 
This utility automates attaching an EBS block storage volume to a running instance via the command line. Primary use case is to eliminate errors and confusion when performing this operation via the AWS console.

```bash
$ sh ec2-X-attach-volume.sh
```
###### < screenshots pending />

( [Back to README](./README.md) )

* * *

#### Execute Scripts -- Take Snapshot
This utility automates snapshotting of an EBS block storage volume via the command line. Primary use case is automate tagging of newly created snapshots with description and date.

```bash
$ sh ec2-X-take-snapshot.sh
```
###### < screenshots pending />

( [Back to README](./README.md) )



