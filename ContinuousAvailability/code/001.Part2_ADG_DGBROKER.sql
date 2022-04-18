1. Use Data Guard Broker

sudo su - oracle
## Review the broker configuration:
sqlplus / as sysdba
show parameter dg_broker

## The broker backups its configuration in two files, for HA purposes.
## Review important parameters for Data Guard 

show parameter log_archive_config
show parameter log_archive_dest_2
show parameter standby_file

dgmgrl
DGMGRL> connect sys/"W3lc0m3#W3lc0m3#W"

DGMGRL>
DGMGRL> show configuration

show database verbose adg_fra22s

--- Change the protection mode from Max Performance to Max Availability !!!

DGMGRL> EDIT DATABASE 'adg_fra22s' SET PROPERTY LogXptMode='SYNC';
Property "logxptmode" updated

DGMGRL> show database 'adg_fra22s' 'LogXptMode';
  LogXptMode = 'SYNC'

DGMGRL> show database 'adg_fra34x' 'LogXptMode';
  LogXptMode = 'ASYNC'
DGMGRL> EDIT DATABASE 'adg_fra34x' SET PROPERTY LogXptMode='SYNC';
Property "logxptmode" updated
DGMGRL> show database 'adg_fra34x' 'LogXptMode';
  LogXptMode = 'SYNC'

--- Now that log transport mode is configured to SYNC, we can apply "MAX AVAILABILITY" mode:

DGMGRL> EDIT CONFIGURATION SET PROTECTION MODE AS MAXAVAILABILITY;
Succeeded.

DGMGRL> show configuration

Configuration - adg_fra22s_adg_fra34x

  Protection Mode: MaxAvailability
  Members:
  adg_fra22s - Primary database
    adg_fra34x - Physical standby database

Fast-Start Failover:  Disabled

Configuration Status:
SUCCESS   (status updated 44 seconds ago)

## In "MAX AVAILABILITY" protection mode, the redolog propagation is synchronous. Should something happen that prevents this synchronous propagation, and after a timeout, DG Broker will automatically change the protection mode to "MAX PERFORMANCE" (ASYNC propagation) after a timeout, until the problem is solved. DG Broker will check at regular intervals whenever the issue has been solved, and change automatically the protection mode back to "MAX AVAILABILITY" when possible.

## Configure the protection mode back to MAX PERFORMANCE

DGMGRL> EDIT CONFIGURATION SET PROTECTION MODE AS MAXPERFORMANCE;
Succeeded.
DGMGRL> EDIT DATABASE 'adg_fra34x' SET PROPERTY LogXptMode='ASYNC';
Property "logxptmode" updated
DGMGRL> EDIT DATABASE 'adg_fra22s' SET PROPERTY LogXptMode='ASYNC';
Property "logxptmode" updated
DGMGRL> show database 'adg_fra22s' 'LogXptMode';
  LogXptMode = 'ASYNC'
DGMGRL> show database 'adg_fra34x' 'LogXptMode';
  LogXptMode = 'ASYNC'

DGMGRL> show configuration

Configuration - adg_fra22s_adg_fra34x

  Protection Mode: MaxPerformance
  Members:
  adg_fra22s - Primary database
    adg_fra34x - Physical standby database

Fast-Start Failover:  Disabled

Configuration Status:
SUCCESS   (status updated 21 seconds ago)


--- From the primary site, run the switchover

DGMGRL> show configuration

Configuration - adg_fra22s_adg_fra34x

  Protection Mode: MaxPerformance
  Members:
  adg_fra22s - Primary database
    adg_fra34x - Physical standby database

Fast-Start Failover:  Disabled

Configuration Status:
SUCCESS   (status updated 57 seconds ago)

-- Ensure switchover is possible: this is an optional step, as DG Broker will take care of this even if you don't execute this command:

DGMGRL> validate database adg_fra34x

  Database Role:     Physical standby database
  Primary Database:  adg_fra22s

  Ready for Switchover:  Yes
  Ready for Failover:    Yes (Primary Running)

  Managed by Clusterware:
    adg_fra22s:  YES
    adg_fra34x:  YES

DGMGRL> switchover to adg_fra34x
Performing switchover NOW, please wait...
Operation requires a connection to database "adg_fra34x"
Connecting ...
Connected to "adg_fra34x"
Connected as SYSDBA.
New primary database "adg_fra34x" is opening...
Oracle Clusterware is restarting database "adg_fra22s" ...
Connected to "adg_fra22s"
Connected to "adg_fra22s"
Switchover succeeded, new primary is "adg_fra34x"

DGMGRL> show configuration

Configuration - adg_fra22s_adg_fra34x

  Protection Mode: MaxPerformance
  Members:
  adg_fra34x - Primary database
    adg_fra22s - Physical standby database

Fast-Start Failover:  Disabled

Configuration Status:
SUCCESS   (status updated 119 seconds ago)

DGMGRL> validate database adg_fra22s

  Database Role:     Physical standby database
  Primary Database:  adg_fra34x

  Ready for Switchover:  Yes
  Ready for Failover:    Yes (Primary Running)

  Managed by Clusterware:
    adg_fra34x:  YES
    adg_fra22s:  YES

--- Switchback !!!
--- Illustrating that a switchover can be issued from either the primary or the standby !!!

DGMGRL> switchover to adg_fra22s
Performing switchover NOW, please wait...
Operation requires a connection to database "adg_fra22s"
Connecting ...
Connected to "adg_fra22s"
Connected as SYSDBA.
New primary database "adg_fra22s" is opening...
Oracle Clusterware is restarting database "adg_fra34x" ...
Connected to "adg_fra34x"
Connected to "adg_fra34x"
Switchover succeeded, new primary is "adg_fra22s"

DGMGRL> show configuration

Configuration - adg_fra22s_adg_fra34x

  Protection Mode: MaxPerformance
  Members:
  adg_fra22s - Primary database
    adg_fra34x - Physical standby database

Fast-Start Failover:  Disabled

Configuration Status:
SUCCESS   (status updated 28 seconds ago)

DGMGRL> validate database adg_fra34x

  Database Role:     Physical standby database
  Primary Database:  adg_fra22s

  Ready for Switchover:  Yes
  Ready for Failover:    Yes (Primary Running)

  Managed by Clusterware:
    adg_fra22s:  YES
    adg_fra34x:  YES

## Show the transport and apply lags on the standby database: both should be near zero when everything works fine.

DGMGRL> show database adg_fra34x

Database - adg_fra34x

Role:               PHYSICAL STANDBY
  Intended State:     APPLY-ON
  Transport Lag:      0 seconds (computed 0 seconds ago)
  Apply Lag:          0 seconds (computed 0 seconds ago)
  Average Apply Rate: 5.00 KByte/s
  Real Time Query:    ON
  Instance(s):
    adg

Database Status:
SUCCESS

**********
FAILOVER:
**********

-- ssh to the primary server as opc, and gain access to "oracle" user:

sudo su - oracle
sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Tue Nov 23 11:08:51 2021
Version 19.12.0.0.0

Copyright (c) 1982, 2021, Oracle.  All rights reserved.


Connected to:
Oracle Database 19c EE Extreme Perf Release 19.0.0.0.0 - Production
Version 19.12.0.0.0

SQL> select open_mode, database_role, flashback_on from v$database;

OPEN_MODE	     DATABASE_ROLE    FLASHBACK_ON
-------------------- ---------------- ------------------
READ WRITE	     PRIMARY	      YES


-- ssh to the standby server as opc, and gain access to "oracle" user:

sudo su - oracle

sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Tue Nov 23 11:09:59 2021
Version 19.12.0.0.0

Copyright (c) 1982, 2021, Oracle.  All rights reserved.


Connected to:
Oracle Database 19c EE Extreme Perf Release 19.0.0.0.0 - Production
Version 19.12.0.0.0

SQL> select open_mode, database_role, flashback_on from v$database;

OPEN_MODE	     DATABASE_ROLE    FLASHBACK_ON
-------------------- ---------------- ------------------
READ ONLY WITH APPLY PHYSICAL STANDBY YES


-- On the primary server, as user "oracle", abort the instance:

srvctl stop database -d $(srvctl config database) -o abort

-- Check the database status:

srvctl status database -d $(srvctl config database)

Instance adg is not running on node adgdb-s01-2021-11-22-170552

--Connect to the standby server and gain access to the "oracle" user. Prepare to perform a failover.

sudo su - oracle

[oracle@adgsby ~]$ dgmgrl
DGMGRL for Linux: Release 19.0.0.0.0 - Production on Tue Nov 23 11:12:25 2021
Version 19.12.0.0.0

Copyright (c) 1982, 2019, Oracle and/or its affiliates.  All rights reserved.

Welcome to DGMGRL, type "help" for information.
DGMGRL> connect sys/"W3lc0m3#W3lc0m3#W"
Connected to "adg_fra34x"
Connected as SYSDBA.
DGMGRL> show configuration

Configuration - adg_fra22s_adg_fra34x

  Protection Mode: MaxPerformance
  Members:

adg_fra22s - Primary database
    Error: ORA-12514: TNS:listener does not currently know of service requested in connect descriptor

    adg_fra34x - Physical standby database

Fast-Start Failover:  Disabled

Configuration Status:
ERROR   (status updated 0 seconds ago)

## DG Broker cannot access to the primary database

DGMGRL> failover to adg_fra34x
Performing failover NOW, please wait...
Failover succeeded, new primary is "adg_fra34x"

DGMGRL> show configuration

Configuration - adg_fra22s_adg_fra34x

  Protection Mode: MaxPerformance
  Members:
  adg_fra34x - Primary database
    Warning: ORA-16857: member disconnected from redo source for longer than specified threshold

    adg_fra22s - Physical standby database (disabled)
      ORA-16661: the standby database needs to be reinstated

Fast-Start Failover:  Disabled

Configuration Status:
WARNING   (status updated 58 seconds ago)

DGMGRL> validate database adg_fra22s
Error: ORA-16541: member is not enabled

-- The new standby needs to be reinstated.

--- On the former primary server, start the database

[oracle@adgdb-s01-2021-11-22-170552 ~]$ srvctl start database -d $(srvctl config database)
[oracle@adgdb-s01-2021-11-22-170552 ~]$ srvctl status database -d $(srvctl config database)
Instance adg is running on node adgdb-s01-2021-11-22-170552

--- Then we reinstate, from the new primary site  ATTENTION!

[oracle@adgsbydb ~]$ dgmgrl
connect sys/"W3lc0m3#W3lc0m3#W"
DGMGRL> reinstate database adg_fra22s
Reinstating database "adg_fra22s", please wait...
Reinstatement of database "adg_fra22s" succeeded

DGMGRL> show configuration

Configuration - adg_fra22s_adg_fra34x

  Protection Mode: MaxPerformance
  Members:
  adg_fra34x - Primary database
    adg_fra22s - Physical standby database

Fast-Start Failover:  Disabled

Configuration Status:
SUCCESS   (status updated 57 seconds ago)

DGMGRL> validate database adg_fra22s

  Database Role:     Physical standby database
  Primary Database:  adg_fra34x

  Ready for Switchover:  Yes
  Ready for Failover:    Yes (Primary Running)

  Managed by Clusterware:
    adg_fra34x:  YES
    adg_fra22s:  YES

DGMGRL> show database adg_fra22s

Database - adg_fra22s

  Role:               PHYSICAL STANDBY
  Intended State:     APPLY-ON
  Transport Lag:      0 seconds (computed 0 seconds ago)
  Apply Lag:          0 seconds (computed 0 seconds ago)
  Average Apply Rate: 21.00 KByte/s
  Real Time Query:    ON
  Instance(s):
    adg

Database Status:
SUCCESS

-- Perform this step from either the primary or the standby site

DGMGRL> switchover to adg_fra22s
Performing switchover NOW, please wait...
Operation requires a connection to database "adg_fra22s"
Connecting ...
Connected to "adg_fra22s"
Connected as SYSDBA.
New primary database "adg_fra22s" is opening...
Oracle Clusterware is restarting database "adg_fra34x" ...
Connected to "adg_fra34x"
Connected to "adg_fra34x"
Switchover succeeded, new primary is "adg_fra22s"

DGMGRL> show configuration

Configuration - adg_fra22s_adg_fra34x

  Protection Mode: MaxPerformance
  Members:
  adg_fra22s - Primary database
    adg_fra34x - Physical standby database

Fast-Start Failover:  Disabled

Configuration Status:
SUCCESS   (status updated 92 seconds ago)

DGMGRL> show database adg_fra34x

Database - adg_fra34x

  Role:               PHYSICAL STANDBY
  Intended State:     APPLY-ON
  Transport Lag:      0 seconds (computed 0 seconds ago)
  Apply Lag:          0 seconds (computed 0 seconds ago)
  Average Apply Rate: 43.00 KByte/s
  Real Time Query:    ON
  Instance(s):
    adg

Database Status:
SUCCESS


