-- Create a Fast Start Failover configuration

ssh -i privateKey opc@<public IP>

[opc@dgobserver1 ~]$ sudo su - oracle
Last login: Wed Jul  7 09:42:03 GMT 2021 on pts/2
[oracle@dgobserver1 ~]$ which dgmgrl
/u01/app/oracle/client/bin/dgmgrl


Modify /u01/app/oracle/client/network/admin/tnsnames.ora with your own values:

[oracle@dgobserver1 ~]$ cat /u01/app/oracle/client/network/admin/tnsnames.ora

DBSDU_TSE=(DESCRIPTION=(SDU=65535)(SEND_BUF_SIZE=10485760)(RECV_BUF_SIZE=10485760)(ADDRESS=(PROTOCOL=TCP)(HOST=<database host 1 private IP>) (PORT=1521))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=DBSDU_TSE.sub06221433571.skynet.oraclevcn.com)(UR=A)))
DBSDU_FRA2BW=(DESCRIPTION=(SDU=65535)(SEND_BUF_SIZE=10485760)(RECV_BUF_SIZE=10485760)(ADDRESS=(PROTOCOL=TCP)(HOST=<database host 2 private IP>) (PORT=1521))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=DBSDU_fra2bw.sub06221433571.skynet.oraclevcn.com)(UR=A)))

--- From the observer nodes, test the connections with dgmgrl

ssh -i privateKey opc@<Observer1 public IP>

[opc@dgobserver1 ~]$ sudo su - oracle
Last login: Tue Nov 23 16:10:11 GMT 2021 on pts/0

[oracle@dgobserver1 ~]$ dgmgrl
DGMGRL for Linux: Release 21.0.0.0.0 - Production on Tue Nov 23 16:14:15 2021
Version 21.1.0.0.0

Copyright (c) 1982, 2020, Oracle and/or its affiliates.  All rights reserved.

Welcome to DGMGRL, type "help" for information.
DGMGRL> connect sys/"W3lc0m3#W3lc0m3#W"@adg_fra22s as sysdba
Connected to "adg_fra22s"
Connected as SYSDBA.
DGMGRL>
DGMGRL> connect sys/"W3lc0m3#W3lc0m3#W"@adg_fra34x as sysdba
Connected to "adg_fra34x"
Connected as SYSDBA.
DGMGRL>exit

## If these checks are OK, then take note of the tnsnames.ora entries, as we will have to update it on observer2 and observer3 hosts

-- Repeat the same tests on Observer2 and Observer3 hosts

[opc@dgobserver2 ~]$ sudo su - oracle
Last login: Tue Nov 23 16:11:17 GMT 2021 on pts/0

[opc@dgobserver2 ~]$ vi /u01/app/oracle/client/network/admin/tnsnames.ora

#paste the working entries from observer 1

[oracle@dgobserver2 ~]$ dgmgrl
DGMGRL for Linux: Release 21.0.0.0.0 - Production on Tue Nov 23 16:32:48 2021
Version 21.1.0.0.0

Copyright (c) 1982, 2020, Oracle and/or its affiliates.  All rights reserved.

Welcome to DGMGRL, type "help" for information.
DGMGRL> connect sys/"W3lc0m3#W3lc0m3#W"@adg_fra22s as sysdba
Connected to "adg_fra22s"
Connected as SYSDBA.
DGMGRL> connect sys/"W3lc0m3#W3lc0m3#W"@adg_fra34x as sysdba
Connected to "adg_fra34x"
Connected as SYSDBA.
DGMGRL>exit




[opc@dgobserver3 ~]$ vi /u01/app/oracle/client/network/admin/tnsnames.ora

#paste the working entries from observer 1

[opc@dgobserver3 ~]$ sudo su - oracle
Last login: Tue Nov 23 16:12:12 GMT 2021 on pts/0
[oracle@dgobserver3 ~]$ dgmgrl
DGMGRL for Linux: Release 21.0.0.0.0 - Production on Tue Nov 23 16:31:43 2021
Version 21.1.0.0.0

Copyright (c) 1982, 2020, Oracle and/or its affiliates.  All rights reserved.

Welcome to DGMGRL, type "help" for information.
DGMGRL> connect sys/"W3lc0m3#W3lc0m3#W"@adg_fra22s as sysdba
Connected to "adg_fra22s"
Connected as SYSDBA.
DGMGRL> connect sys/"W3lc0m3#W3lc0m3#W"@adg_fra34x as sysdba
Connected to "adg_fra34x"
Connected as SYSDBA.
DGMGRL>

--- If these tests are successful, we can proceed !!!
--- If not, we need to fix the errors before proceeding


-- We are ready to enable Fast Start Failover on the Data Guard configuration. From any observer, enable FSFO:

[oracle@dgobserver1 ~]$ dgmgrl
DGMGRL for Linux: Release 21.0.0.0.0 - Production on Tue Nov 23 16:14:15 2021
Version 21.1.0.0.0

Copyright (c) 1982, 2020, Oracle and/or its affiliates.  All rights reserved.

Welcome to DGMGRL, type "help" for information.
DGMGRL> connect sys/"W3lc0m3#W3lc0m3#W"@adg_fra22s as sysdba
Connected to "adg_fra22s"
Connected as SYSDBA.
DGMGRL> show configuration

Configuration - adg_fra22s_adg_fra34x

  Protection Mode: MaxPerformance
  Members:
  adg_fra22s - Primary database
    adg_fra34x - Physical standby database

Fast-Start Failover:  Disabled

Configuration Status:
SUCCESS   (status updated 39 seconds ago)

-- FSFO is disabled, let's enable it:

DGMGRL> ENABLE FAST_START FAILOVER
Enabled in Potential Data Loss Mode.

DGMGRL> show configuration

Configuration - adg_fra22s_adg_fra34x

  Protection Mode: MaxPerformance
  Members:
  adg_fra22s - Primary database
    Warning: ORA-16819: fast-start failover observer not started

    adg_fra34x - (*) Physical standby database

Fast-Start Failover: Enabled in Potential Data Loss Mode

Configuration Status:
WARNING   (status updated 34 seconds ago)

--- In the following commands, use your own database unique names !!!

DGMGRL> show database adg_fra22s 'DGConnectIdentifier'
  DGConnectIdentifier = 'adg_fra22s'

DGMGRL> show database adg_fra34x 'DGConnectIdentifier'
  DGConnectIdentifier = 'adg_fra34x'

DGMGRL> edit database adg_fra22s set property 'ObserverConnectIdentifier'='adg_fra22s';
Property "ObserverConnectIdentifier" updated

DGMGRL> edit database adg_fra34x set property 'ObserverConnectIdentifier'='adg_fra34x';
Property "ObserverConnectIdentifier" updated


-- Clean-up the /u01/app/oracle/wallet/ directory:

[oracle@dgobserver1 wallet]$ rm /u01/app/oracle/wallet/*
*/[oracle@dgobserver1 wallet]$ cd /u01/app/oracle/wallet
[oracle@dgobserver1 wallet]$ ls -ltr
total 0

-- Create a new wallet:

[oracle@dgobserver1 wallet]$ mkstore -wrl /u01/app/oracle/wallet/ -create
Oracle Secret Store Tool Release 21.0.0.0.0 - Production
Version 21.0.0.0.0
Copyright (c) 2004, 2020, Oracle and/or its affiliates. All rights reserved.

Enter password: W3lc0m3#W3lc0m3#W
Enter password again: W3lc0m3#W3lc0m3#W

[oracle@dgobserver1 wallet]$ ls -ltr
total 8
-rw-------. 1 oracle oinstall   0 Nov 23 16:55 ewallet.p12.lck
-rw-------. 1 oracle oinstall 149 Nov 23 16:55 ewallet.p12
-rw-------. 1 oracle oinstall   0 Nov 23 16:55 cwallet.sso.lck
-rw-------. 1 oracle oinstall 194 Nov 23 16:55 cwallet.sso

--- A wallet has been created, protected by "W3lc0m3#W3lc0m3#W" password.
-- Now add a credential for SYS user to that wallet, for both the primary and the standby database.
-- Use your own database unique names (in green) in the following commands !!!


[oracle@dgobserver1 wallet]$ mkstore -wrl /u01/app/oracle/wallet/ -createCredential 'adg_fra22s' sys W3lc0m3#W3lc0m3#W
Oracle Secret Store Tool Release 21.0.0.0.0 - Production
Version 21.0.0.0.0
Copyright (c) 2004, 2020, Oracle and/or its affiliates. All rights reserved.

Enter wallet password: W3lc0m3#W3lc0m3#W


[oracle@dgobserver1 wallet]$ mkstore -wrl /u01/app/oracle/wallet/ -createCredential 'adg_fra34x' sys W3lc0m3#W3lc0m3#W
Oracle Secret Store Tool Release 21.0.0.0.0 - Production
Version 21.0.0.0.0
Copyright (c) 2004, 2020, Oracle and/or its affiliates. All rights reserved.

Enter wallet password: W3lc0m3#W3lc0m3#W

-- Now check the sqlnet.ora file:

[oracle@dgobserver1] cat /u01/app/oracle/client/network/admin/sqlnet.ora
NAMES.DIRECTORY_PATH= (TNSNAMES, ONAMES, HOSTNAME,EZCONNECT)
WALLET_LOCATION=(SOURCE=(METHOD=FILE)(METHOD_DATA=(DIRECTORY=/u01/app/oracle/wallet/)))
SQLNET.WALLET_OVERRIDE=TRUE

-- Check that the "DIRECTORY" property points to the directory where you've just generated the new wallet.

[oracle@dgobserver1 wallet]$ dgmgrl
DGMGRL for Linux: Release 21.0.0.0.0 - Production on Tue Nov 23 17:23:46 2021
Version 21.1.0.0.0

Copyright (c) 1982, 2020, Oracle and/or its affiliates.  All rights reserved.

Welcome to DGMGRL, type "help" for information.
DGMGRL> connect sys/"W3lc0m3#W3lc0m3#W"@adg_fra22s as sysdba
Connected to "adg_fra22s"
Connected as SYSDBA.

## Show the observers currently running on the configuration:

DGMGRL> show observer

Configuration - adg_fra22s_adg_fra34x

  Fast-Start Failover:     ENABLED

No observers.

## No observer currently running is the expected behavior !!!

DGMGRL> start observer dgobs1 in background file is '/u01/app/oracle/client/network/admin/fsfo.dat' logfile is '/u01/app/oracle/client/network/admin/observer_dgobs1.log' connect identifier is 'adg_fra22s';

Connected to "adg_fra22s"
Submitted command "START OBSERVER" using connect identifier "adg_fra22s"
DGMGRL> DGMGRL for Linux: Release 21.0.0.0.0 - Production on Tue Nov 23 17:24:09 2021
Version 21.1.0.0.0

Copyright (c) 1982, 2020, Oracle and/or its affiliates.  All rights reserved.

Welcome to DGMGRL, type "help" for information.
Connected to "adg_fra22s"
Connected as SYSDBA.
Succeeded in opening the observer file "/u01/app/oracle/client/network/admin/fsfo.dat".
[W000 2021-11-23T17:24:12.314+00:00] Observer could not validate the contents of the observer file.
[W000 2021-11-23T17:24:12.476+00:00] FSFO target standby is adg_fra34x
Observer 'dgobs1' started
The observer log file is '/u01/app/oracle/client/network/admin/observer_dgobs1.log'.

#press enter to return to the prompt

## Show the running observers again !!!

DGMGRL> show observer

Configuration - adg_fra22s_adg_fra34x

  Fast-Start Failover:     ENABLED

  Primary:            adg_fra22s
  Active Target:      adg_fra34x

Observer "dgobs1"(21.1.0.0.0) - Master

  Host Name:                    dgobserver1
  Last Ping to Primary:         0 seconds ago
  Last Ping to Target:          2 seconds ago
  Log File:
  State File:


  -- On dgobserver2 and dgobserver3, generate the wallet and the credentials exactly the same way as on dgobserver1
-- Then start the observer in background on both machines:

-- dgobserver2

[oracle@dgobserver2 wallet]$ dgmgrl
DGMGRL for Linux: Release 21.0.0.0.0 - Production on Tue Nov 23 17:23:46 2021
Version 21.1.0.0.0

Copyright (c) 1982, 2020, Oracle and/or its affiliates.  All rights reserved.

Welcome to DGMGRL, type "help" for information.
DGMGRL> connect sys/"W3lc0m3#W3lc0m3#W"@adg_fra22s as sysdba
Connected to "adg_fra22s"
Connected as SYSDBA.

start observer dgobs2 in background file is '/u01/app/oracle/client/network/admin/fsfo.dat' logfile is '/u01/app/oracle/client/network/admin/observer_dgobs2.log' connect identifier is 'adg_fra22s';

-- dgobserver3

[oracle@dgobserver3 wallet]$ dgmgrl
DGMGRL for Linux: Release 21.0.0.0.0 - Production on Tue Nov 23 17:23:46 2021
Version 21.1.0.0.0

Copyright (c) 1982, 2020, Oracle and/or its affiliates.  All rights reserved.

Welcome to DGMGRL, type "help" for information.
DGMGRL> connect sys/"W3lc0m3#W3lc0m3#W"@adg_fra22s as sysdba
Connected to "adg_fra22s"
Connected as SYSDBA.

start observer dgobs3 in background file is '/u01/app/oracle/client/network/admin/fsfo.dat' logfile is '/u01/app/oracle/client/network/admin/observer_dgobs3.log' connect identifier is 'adg_fra22s';

-- Now from any observer, show the observers !!!

DGMGRL> show observer

Configuration - adg_fra22s_adg_fra34x

  Fast-Start Failover:     ENABLED

  Primary:            adg_fra22s
  Active Target:      adg_fra34x

Observer "dgobs1"(21.1.0.0.0) - Master

  Host Name:                    dgobserver1
  Last Ping to Primary:         0 seconds ago
  Last Ping to Target:          2 seconds ago
  Log File:
  State File:

Observer "dgobs2"(21.1.0.0.0) - Backup

  Host Name:                    dgobserver2
  Last Ping to Primary:         0 seconds ago
  Last Ping to Target:          2 seconds ago
  Log File:
  State File:

Observer "dgobs3"(21.1.0.0.0) - Backup

  Host Name:                    dgobserver3
  Last Ping to Primary:         0 seconds ago
  Last Ping to Target:          2 seconds ago
  Log File:
  State File:

-- We ended-up with 3 observers, 1 master and 2 backups
-- We can easily change the master role to another observer

DGMGRL> set masterobserver to dgobs2
Succeeded.

DGMGRL> show observer

Configuration - adg_fra22s_adg_fra34x

  Fast-Start Failover:     ENABLED

  Primary:            adg_fra22s
  Active Target:      adg_fra34x

Observer "dgobs2"(21.1.0.0.0) - Master

  Host Name:                    dgobserver2
  Last Ping to Primary:         0 seconds ago
  Last Ping to Target:          2 seconds ago
  Log File:
  State File:

Observer "dgobs1"(21.1.0.0.0) - Backup

  Host Name:                    dgobserver1
  Last Ping to Primary:         0 seconds ago
  Last Ping to Target:          1 second ago
  Log File:
  State File:

Observer "dgobs3"(21.1.0.0.0) - Backup

  Host Name:                    dgobserver3
  Last Ping to Primary:         0 seconds ago
  Last Ping to Target:          1 second ago
  Log File:
  State File:

-- Resilience testing with FSFO and observers

[oracle@dgobserver3 ~]$ dgmgrl
DGMGRL for Linux: Release 21.0.0.0.0 - Production on Wed Nov 24 10:29:00 2021
Version 21.1.0.0.0

Copyright (c) 1982, 2020, Oracle and/or its affiliates.  All rights reserved.

Welcome to DGMGRL, type "help" for information.
DGMGRL> connect sys/"W3lc0m3#W3lc0m3#W"@adg_fra22s as sysdba
Connected to "adg_fra22s"
Connected as SYSDBA.
DGMGRL> show observer

Configuration - adg_fra22s_adg_fra34x

  Fast-Start Failover:     ENABLED

  Primary:            adg_fra22s
  Active Target:      adg_fra34x

Observer "dgobs2"(21.1.0.0.0) - Master

  Host Name:                    dgobserver2
  Last Ping to Primary:         0 seconds ago
  Last Ping to Target:          2 seconds ago
  Log File:
  State File:

Observer "dgobs1"(21.1.0.0.0) - Backup

  Host Name:                    dgobserver1
  Last Ping to Primary:         0 seconds ago
  Last Ping to Target:          1 second ago
  Log File:
  State File:

Observer "dgobs3"(21.1.0.0.0) - Backup

  Host Name:                    dgobserver3
  Last Ping to Primary:         0 seconds ago
  Last Ping to Target:          1 second ago
  Log File:
  State File:

## As we left it before, dgobs2 is the master, dgobs1 and dgobs3 are backup
-- The first test is about observer resilience
-- Kill the master observer, in this case dgobs2

[oracle@dgobserver2 wallet]$ ps -ef | grep dgmgrl
oracle   10385     1 31 10:14 ?        00:05:37 /u01/app/oracle/client/bin/dgmgrl              START OBSERVER dgobs2 FILE IS '/u01/app/oracle/client/network/admin/fsfo.dat' LOGFILE IS '/u01/app/oracle/client/network/admin/observer_dgobs2.log'
oracle   15103  2217  0 10:32 pts/0    00:00:00 grep --color=auto dgmgrl

[oracle@dgobserver2 wallet]$ kill -9 10385

-- From observer 3 machine, observe the configuration:

[oracle@dgobserver3 ~]$ dgmgrl
DGMGRL for Linux: Release 21.0.0.0.0 - Production on Wed Nov 24 10:33:29 2021
Version 21.1.0.0.0

Copyright (c) 1982, 2020, Oracle and/or its affiliates.  All rights reserved.

Welcome to DGMGRL, type "help" for information.
DGMGRL> connect sys/"W3lc0m3#W3lc0m3#W"@adg_fra22s as sysdba
Connected to "adg_fra22s"
Connected as SYSDBA.
DGMGRL> show observer

Configuration - adg_fra22s_adg_fra34x

  Fast-Start Failover:     ENABLED

  Primary:            adg_fra22s
  Active Target:      adg_fra34x

Observer "dgobs1"(21.1.0.0.0) - Master

  Host Name:                    dgobserver1
  Last Ping to Primary:         0 seconds ago
  Last Ping to Target:          2 seconds ago
  Log File:
  State File:

Observer "dgobs2"(21.1.0.0.0) - Backup

  Host Name:                    dgobserver2
  Last Ping to Primary:         59 seconds ago
  Last Ping to Target:          28 seconds ago
  Log File:
  State File:

Observer "dgobs3"(21.1.0.0.0) - Backup

  Host Name:                    dgobserver3
  Last Ping to Primary:         0 seconds ago
  Last Ping to Target:          2 seconds ago
  Log File:
  State File:

DGMGRL>

[oracle@dgobserver2 wallet]$ dgmgrl
DGMGRL for Linux: Release 21.0.0.0.0 - Production on Wed Nov 24 10:36:48 2021
Version 21.1.0.0.0

Copyright (c) 1982, 2020, Oracle and/or its affiliates.  All rights reserved.

Welcome to DGMGRL, type "help" for information.
DGMGRL> connect sys/"W3lc0m3#W3lc0m3#W"@adg_fra22s as sysdba
Connected to "adg_fra22s"
Connected as SYSDBA.
DGMGRL>
DGMGRL>
DGMGRL> start observer dgobs2 in background file is '/u01/app/oracle/client/network/admin/fsfo.dat' logfile is '/u01/app/oracle/client/network/admin/observer_dgobs2.log' connect identifier is 'adg_fra22s';
Connected to "adg_fra22s"
Submitted command "START OBSERVER" using connect identifier "adg_fra22s"
DGMGRL> DGMGRL for Linux: Release 21.0.0.0.0 - Production on Wed Nov 24 10:37:12 2021
Version 21.1.0.0.0

Copyright (c) 1982, 2020, Oracle and/or its affiliates.  All rights reserved.

Welcome to DGMGRL, type "help" for information.
Connected to "adg_fra22s"
Connected as SYSDBA.
Succeeded in opening the observer file "/u01/app/oracle/client/network/admin/fsfo.dat".
Observer 'dgobs2' started
The observer log file is '/u01/app/oracle/client/network/admin/observer_dgobs2.log'.

[oracle@dgobserver3 ~]$ dgmgrl
DGMGRL for Linux: Release 21.0.0.0.0 - Production on Wed Nov 24 10:38:02 2021
Version 21.1.0.0.0

Copyright (c) 1982, 2020, Oracle and/or its affiliates.  All rights reserved.

Welcome to DGMGRL, type "help" for information.
DGMGRL> connect sys/"W3lc0m3#W3lc0m3#W"@adg_fra22s as sysdba
Connected to "adg_fra22s"
Connected as SYSDBA.
DGMGRL> show observer

Configuration - adg_fra22s_adg_fra34x

  Fast-Start Failover:     ENABLED

  Primary:            adg_fra22s
  Active Target:      adg_fra34x

Observer "dgobs1"(21.1.0.0.0) - Master

  Host Name:                    dgobserver1
  Last Ping to Primary:         0 seconds ago
  Last Ping to Target:          0 seconds ago
  Log File:
  State File:

Observer "dgobs2"(21.1.0.0.0) - Backup

  Host Name:                    dgobserver2
  Last Ping to Primary:         0 seconds ago
  Last Ping to Target:          2 seconds ago
  Log File:
  State File:

Observer "dgobs3"(21.1.0.0.0) - Backup

  Host Name:                    dgobserver3
  Last Ping to Primary:         0 seconds ago
  Last Ping to Target:          0 seconds ago
  Log File:
  State File:

## Let that dgmgrl session opened and proceed !!!


[opc@adgdb-s01-2021-11-22-170552 ~]$ sudo su - oracle
Last login: Wed Nov 24 10:39:31 UTC 2021
[oracle@adgdb-s01-2021-11-22-170552 ~]$ sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Wed Nov 24 10:40:06 2021
Version 19.12.0.0.0

Copyright (c) 1982, 2021, Oracle.  All rights reserved.


Connected to:
Oracle Database 19c EE Extreme Perf Release 19.0.0.0.0 - Production
Version 19.12.0.0.0

SQL> select open_mode, database_role from v$database;

OPEN_MODE	     DATABASE_ROLE
-------------------- ----------------
READ WRITE	     PRIMARY


SQL> exit 
-- Abort the instance

srvctl stop database -d $(srvctl config database) -o abort

srvctl status database -d $(srvctl config database)
Instance adg is not running on node adgdb-s01-2021-11-22-170552

## Run a "show observer" command on the previous dgmgrl session on dgobserver3 machine:

DGMGRL> show observer
ORA-03113: end-of-file on communication channel
Process ID: 18645
Session ID: 209 Serial number: 28128

Configuration details cannot be determined by DGMGRL


[oracle@dgobserver3 ~]$ dgmgrl
DGMGRL for Linux: Release 21.0.0.0.0 - Production on Wed Nov 24 10:51:10 2021
Version 21.1.0.0.0

Copyright (c) 1982, 2020, Oracle and/or its affiliates.  All rights reserved.

Welcome to DGMGRL, type "help" for information.
DGMGRL> connect sys/"W3lc0m3#W3lc0m3#W"@adg_fra34x as sysdba
Connected to "ADG_FRA34X"
Connected as SYSDBA.
DGMGRL> show observer

Configuration - adg_fra22s_adg_fra34x

  Fast-Start Failover:     ENABLED

  Primary:            adg_fra34x
  Active Target:      adg_fra22s

Observer "dgobs1"(21.1.0.0.0) - Master

  Host Name:                    dgobserver1
  Last Ping to Primary:         0 seconds ago
  Last Ping to Target:          594 seconds ago
  Log File:
  State File:

Observer "dgobs2"(21.1.0.0.0) - Backup

  Host Name:                    dgobserver2
  Last Ping to Primary:         0 seconds ago
  Last Ping to Target:          594 seconds ago
  Log File:
  State File:

Observer "dgobs3"(21.1.0.0.0) - Backup

  Host Name:                    dgobserver3
  Last Ping to Primary:         0 seconds ago
  Last Ping to Target:          594 seconds ago
  Log File:
  State File:


DGMGRL> show configuration

Configuration - adg_fra22s_adg_fra34x

  Protection Mode: MaxPerformance
  Members:
  adg_fra34x - Primary database
    Warning: ORA-16824: multiple warnings, including fast-start failover-related warnings, detected for the database

    adg_fra22s - (*) Physical standby database (disabled)
      ORA-16661: the standby database needs to be reinstated

Fast-Start Failover: Enabled in Potential Data Loss Mode

Configuration Status:
WARNING   (status updated 13 seconds ago)

## Here we observer that a failover was performed automatically by FSFO
## Check the two databases:

DGMGRL> show database adg_fra22s

Database - adg_fra22s

  Role:                PHYSICAL STANDBY
  Intended State:      APPLY-ON
  Transport Lag:       (unknown)
  Apply Lag:           (unknown)
  Average Apply Rate:  (unknown)
  Real Time Query:     OFF
  Instance(s):
    adg

Database Status:
DISABLED - ORA-16661: the standby database needs to be reinstated

## A reinstate is needed for the former primary, as it has been aborted.

DGMGRL> show database adg_fra34x

Database - adg_fra34x

  Role:                PRIMARY
  Intended State:      TRANSPORT-ON
  Instance(s):
    adg

  Database Warning(s):
    ORA-16829: fast-start failover configuration is lagging
    ORA-16869: fast-start failover target not initialized

Database Status:
WARNING

## Connect to the former primary host and start the database
## In a real case, we would restore from a backup

srvctl start database -d $(srvctl config database)
srvctl status database -d $(srvctl config database)
Instance adg is running on node adgdb-s01-2021-11-22-170552


DGMGRL> show configuration

Configuration - adg_fra22s_adg_fra34x

  Protection Mode: MaxPerformance
  Members:
  adg_fra34x - Primary database
    Warning: ORA-16824: multiple warnings, including fast-start failover-related warnings, detected for the database

    adg_fra22s - (*) Physical standby database
      Warning: ORA-16657: reinstatement of database in progress

Fast-Start Failover: Enabled in Potential Data Loss Mode

Configuration Status:
WARNING   (status updated 102 seconds ago)


DGMGRL> show configuration

Configuration - adg_fra22s_adg_fra34x

  Protection Mode: MaxPerformance
  Members:
  adg_fra34x - Primary database
    adg_fra22s - (*) Physical standby database

Fast-Start Failover: Enabled in Potential Data Loss Mode

Configuration Status:
SUCCESS   (status updated 46 seconds ago)


DGMGRL> show database adg_fra34x

Database - adg_fra34x

  Role:                PRIMARY
  Intended State:      TRANSPORT-ON
  Instance(s):
    adg

Database Status:
SUCCESS

DGMGRL> show database adg_fra22s

Database - adg_fra22s

  Role:                PHYSICAL STANDBY
  Intended State:      APPLY-ON
  Transport Lag:       0 seconds (computed 1 second ago)
  Apply Lag:           0 seconds (computed 1 second ago)
  Average Apply Rate:  17.00 KByte/s
  Real Time Query:     ON
  Instance(s):
    adg

Database Status:
SUCCESS


DGMGRL> validate database adg_fra22s

  Database Role:     Physical standby database
  Primary Database:  adg_fra34x

  Ready for Switchover:  Yes
  Ready for Failover:    Yes (Primary Running)

  Managed by Clusterware:
    adg_fra34x:  YES
    adg_fra22s:  YES

=> OK


--- From any observer, run the switchover command !!!

DGMGRL> switchover to adg_fra22s
2021-11-24T11:01:36.994+00:00
Performing switchover NOW, please wait...

2021-11-24T11:01:41.317+00:00
Operation requires a connection to database "adg_fra22s"
Connecting ...
Connected to "adg_fra22s"
Connected as SYSDBA.

2021-11-24T11:01:41.823+00:00
Continuing with the switchover...

2021-11-24T11:02:28.676+00:00
New primary database "adg_fra22s" is opening...

2021-11-24T11:02:28.676+00:00
Oracle Clusterware is restarting database "adg_fra34x" ...
Connected to "adg_fra34x"
Connected to "adg_fra34x"
2021-11-24T11:03:44.657+00:00
Switchover succeeded, new primary is "adg_fra22s"

2021-11-24T11:03:44.659+00:00
Switchover processing complete, broker ready.

--- After a while, we are back to the initial configuration

DGMGRL> show configuration

Configuration - adg_fra22s_adg_fra34x

  Protection Mode: MaxPerformance
  Members:
  adg_fra22s - Primary database
    adg_fra34x - (*) Physical standby database

Fast-Start Failover: Enabled in Potential Data Loss Mode

Configuration Status:
SUCCESS   (status updated 18 seconds ago)


DGMGRL> validate database adg_fra34x

  Database Role:     Physical standby database
  Primary Database:  adg_fra22s

  Ready for Switchover:  Yes
  Ready for Failover:    Yes (Primary Running)

  Managed by Clusterware:
    adg_fra22s:  YES
    adg_fra34x:  YES


