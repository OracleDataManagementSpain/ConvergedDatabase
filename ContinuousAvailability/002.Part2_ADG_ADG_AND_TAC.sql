Active Data Guard and TAC

[oracle@adgdb-s01-2021-11-22-170552 ~]$ dgmgrl
DGMGRL for Linux: Release 19.0.0.0.0 - Production on Tue Nov 23 11:26:40 2021
Version 19.12.0.0.0

Copyright (c) 1982, 2019, Oracle and/or its affiliates.  All rights reserved.

Welcome to DGMGRL, type "help" for information.
DGMGRL> connect sys/"W3lc0m3#W3lc0m3#W"
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
SUCCESS   (status updated 51 seconds ago)

-- Install ACDemo application on the primary node.

sudo su - oracle
cd /home/oracle

wget https://objectstorage.us-ashburn-1.oraclecloud.com/p/O8AOujhwl1dSTqhfH69f3nkV6TNZWU3KaIF4TZ-XuCaZ5w-xHEQ14ViOVhUXQjPB/n/oradbclouducm/b/LiveLabTemp/o/ACDemo_19c.zip

--2021-11-23 11:27:42--  https://objectstorage.us-ashburn-1.oraclecloud.com/p/O8AOujhwl1dSTqhfH69f3nkV6TNZWU3KaIF4TZ-XuCaZ5w-xHEQ14ViOVhUXQjPB/n/oradbclouducm/b/LiveLabTemp/o/ACDemo_19c.zip
Resolving objectstorage.us-ashburn-1.oraclecloud.com (objectstorage.us-ashburn-1.oraclecloud.com)... 134.70.24.1, 134.70.32.1, 134.70.28.1
Connecting to objectstorage.us-ashburn-1.oraclecloud.com (objectstorage.us-ashburn-1.oraclecloud.com)|134.70.24.1|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 8573765 (8.2M) [application/x-zip-compressed]
Saving to: 'ACDemo_19c.zip'

100%[================================================================================================>] 8,573,765   10.3MB/s   in 0.8s

2021-11-23 11:27:43 (10.3 MB/s) - 'ACDemo_19c.zip' saved [8573765/8573765]

[oracle@adgdb-s01-2021-11-22-170552 ~]$ ls -ltr
total 8376
-rw-r--r-- 1 oracle oinstall 8573765 Sep 10 04:21 ACDemo_19c.zip


## Unzip the application

[oracle@adgdb-s01-2021-11-22-170552 ~]$ unzip ACDemo_19c.zip

## On the primary server

[oracle@adgdb-s01-2021-11-22-170552 ~]$ srvctl add service -d $(srvctl config database) -s svc_tac -pdb PDB1 -role primary -replay_init_time 1000 -failoverretry 30 -failoverdelay 3 -commit_outcome TRUE -failovertype AUTO -failover_restore AUTO

[oracle@adgdb-s01-2021-11-22-170552 ~]$
[oracle@adgdb-s01-2021-11-22-170552 ~]$ srvctl start service -d $(srvctl config database) -s svc_tac
[oracle@adgdb-s01-2021-11-22-170552 ~]$ srvctl status service -d $(srvctl config database) -s svc_tac

Service svc_tac is running on instance(s) adg

[oracle@adgdb-s01-2021-11-22-170552 ~]$ srvctl config service -d $(srvctl config database) -s svc_tac
Service name: svc_tac
Server pool:
Cardinality: 1
Service role: PRIMARY
Management policy: AUTOMATIC
DTP transaction: false
AQ HA notifications: false
Global: false
Commit Outcome: true
Failover type: AUTO
Failover method:
Failover retries: 30
Failover delay: 3
Failover restore: AUTO
Connection Load Balancing Goal: LONG
Runtime Load Balancing Goal: NONE
TAF policy specification: NONE
Edition:
Pluggable database name: PDB1
Hub service:
Maximum lag time: ANY
SQL Translation Profile:
Retention: 86400 seconds
Replay Initiation Time: 1000 seconds
Drain timeout:
Stop option:
Session State Consistency: AUTO
GSM Flags: 0
Service is enabled
Preferred instances: adg
Available instances:
CSS critical: no
Service uses Java: false

## On the standby server
## On the standby database, we don''t start the service
## It will be started automatically when the database assumes the primary role

[oracle@adgsby ~]$ srvctl add service -d $(srvctl config database) -s svc_tac -pdb PDB1 -role primary -replay_init_time 1000 -failoverretry 30 -failoverdelay 3 -commit_outcome TRUE -failovertype AUTO -failover_restore AUTO
[oracle@adgsby ~]$ srvctl status service -d $(srvctl config database) -s svc_tac
Service svc_tac is not running.

## Connect to the PDB as system


sudo su - oracle

# We can get an example of the service fully qualified name from the existing entries of tnsnames.ora file. We can get the server private IP from the same file as well, if needed.

cat $ORACLE_HOME/network/admin/tnsnames.ora

# In the following command, we use the fully qualified service name.

sqlplus system/"W3lc0m3#W3lc0m3#W"@10.0.0.107:1521/svc_tac.pub.adgdblab.oraclevcn.com

   set heading off
   set feedback off
   drop user hr cascade;
   create user hr identified by "W3lc0m3#W3lc0m3#W" default tablespace USERS temporary tablespace temp;
   grant connect, create session, resource to hr;
   alter user hr quota unlimited on USERS;

   create table HR.emp4AC(
    empno number(4) not null,
    ename varchar2(10),
    job char(9),
    mgr number(4),
    hiredate date,
    sal number(7,2),
    comm number(7,2),
    deptno number(2),
    constraint emp_primary_key primary key (empno));

   insert into hr.emp4AC values(7839,'KING','PRESIDENT',NULL,'17-NOV-81',50000,NULL,10);
   insert into hr.emp4AC values(7698,'BLAKE','MANAGER',NULL,'17-NOV-81',8000,NULL,10);
   insert into hr.emp4AC values(7782,'CLARK','MANAGER',NULL,'17-NOV-81',8000,NULL,10);
   insert into hr.emp4AC values(7566,'JONES','MANAGER',NULL,'17-NOV-81',8000,NULL,10);
   insert into hr.emp4AC values(7654,'MARTIN','SALESMAN',NULL,'17-NOV-81',7000,NULL,10);
   insert into hr.emp4AC values(7499,'ALLEN','MANAGER',NULL,'17-NOV-81',9000,NULL,10);
   insert into hr.emp4AC values(7844,'TURNER','CLERK',NULL,'17-NOV-81',5000,NULL,10);
   insert into hr.emp4AC values(7900,'JAMES','MANAGER',NULL,'17-NOV-81',9000,NULL,10);
   insert into hr.emp4AC values(7521,'WARD','PRGRMMER',NULL,'17-NOV-81',9000,NULL,10);
   insert into hr.emp4AC values(7902,'FORD','SALESMAN',NULL,'17-NOV-81',7000,NULL,10);
   insert into hr.emp4AC values(7369,'SMITH','PRGRMMER',NULL,'17-NOV-81',8000,NULL,10);
   insert into hr.emp4AC values(7788,'SCOTT','CLERK',NULL,'17-NOV-81',6000,NULL,10);
   insert into hr.emp4AC values(7876,'ADAMS','PRGRMMER',NULL,'17-NOV-81',7000,NULL,10);
   insert into hr.emp4AC values(7934,'MILLER','SALESMAN',NULL,'17-NOV-81',9000,NULL,10);
   commit;

[oracle@adgdb-s01-2021-11-22-170552 acdemo] cd /home/oracle/acdemo

[oracle@adgdb-s01-2021-11-22-170552 acdemo]$ cp  /home/oracle/acdemo/tac_replay.sbs /home/oracle/acdemo/tac_replay.properties

[oracle@adgdb-s01-2021-11-22-170552 acdemo]$ vi /home/oracle/acdemo/tac_replay.properties



# Stub file to create tac_replay.properties
# Use replay datasource
datasource=oracle.jdbc.replay.OracleDataSourceImpl

# Set verbose mode
VERBOSE=FALSE

# database JDBC URL

url=jdbc:oracle:thin:@(DESCRIPTION=(CONNECT_TIMEOUT=10)(RETRY_COUNT=2)(RETRY_DELAY=3)(TRANSPORT_CONNECT_TIMEOUT=3)(ADDRESS_LIST = (FAILOVER = ON) (LOAD_BALANCE = OFF)(ADDRESS = (PROTOCOL = TCP)(HOST = adgdb-scan.pub.adgdblab.oraclevcn.com)(PORT = 1521))(ADDRESS = (PROTOCOL = TCP)(HOST = adgsbydb-scan.pub.adgdblab.oraclevcn.com)(PORT = 1521)))(CONNECT_DATA =(SERVICE_NAME = svc_tac.pub.adgdblab.oraclevcn.com)))


# database username and password:
username=hr
password=W3lc0m3#W3lc0m3#W

# Enable FAN
fastConnectionFailover=TRUE

#Disable connection tests
validateConnectionOnBorrow=TRUE

# number of connections in the UCP''s pool:
ucp_pool_size=20

#Connection Wait Timeout for busy pool
connectionWaitTimeout=5

# number of active threads (this simulates concurrent load):
number_of_threads=10

# think time is how much time the threads will sleep before looping:
thread_think_time=50


-- Run the application.

cd /home/oracle/acdemo
chmod +x ./runtacreplay

[oracle@adgdb-s01-2021-11-22-170552 acdemo]$ ./runtacreplay
######################################################
# of Threads             : 10
 UCP pool size            : 20
FCF Enabled:  true
VCoB Enabled: true
ONS Configuration:  null
Enable Intensive Wload:  false
Thread think time        : 50 ms
######################################################

Starting the pool now... (please wait)
Pool is started in 12385ms
10 borrowed, 0 pending, 2ms getConnection wait, TotalBorrowed 278, avg response time from db 66ms
5 borrowed, 0 pending, 0ms getConnection wait, TotalBorrowed 810, avg response time from db 38ms
4 borrowed, 0 pending, 0ms getConnection wait, TotalBorrowed 1371, avg response time from db 33ms
[...]

-- In another terminal, connect to the primary or the standby node and perform a switchover with Data Guard Broker:

[oracle@adgsby ~]$ dgmgrl
DGMGRL for Linux: Release 19.0.0.0.0 - Production on Tue Nov 23 11:46:35 2021
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
    adg_fra34x - Physical standby database

Fast-Start Failover:  Disabled

Configuration Status:
SUCCESS   (status updated 22 seconds ago)

DGMGRL> switchover to adg_fra34x
Performing switchover NOW, please wait...
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
SUCCESS   (status updated 124 seconds ago)

## Observe the application output

2 borrowed, 0 pending, 0ms getConnection wait, TotalBorrowed 4560, avg response time from db 28ms
9 borrowed, 1 pending, 0ms getConnection wait, TotalBorrowed 5193, avg response time from db 25ms
3 borrowed, 0 pending, 0ms getConnection wait, TotalBorrowed 5779, avg response time from db 30ms
1 borrowed, 0 pending, 0ms getConnection wait, TotalBorrowed 6388, avg response time from db 27ms
4 borrowed, 0 pending, 0ms getConnection wait, TotalBorrowed 7007, avg response time from db 26ms
10 borrowed, 0 pending, 0ms getConnection wait, TotalBorrowed 7635, avg response time from db 25ms
0 borrowed, 10 pending, 0ms getConnection wait, TotalBorrowed 7718, avg response time from db 43ms
0 borrowed, 10 pending, 0ms getConnection wait, TotalBorrowed 7718
0 borrowed, 10 pending, 0ms getConnection wait, TotalBorrowed 7718
0 borrowed, 10 pending, 0ms getConnection wait, TotalBorrowed 7718
0 borrowed, 10 pending, 0ms getConnection wait, TotalBorrowed 7718
0 borrowed, 10 pending, 0ms getConnection wait, TotalBorrowed 7718
0 borrowed, 10 pending, 0ms getConnection wait, TotalBorrowed 7718
0 borrowed, 10 pending, 0ms getConnection wait, TotalBorrowed 7718
0 borrowed, 10 pending, 0ms getConnection wait, TotalBorrowed 7718
0 borrowed, 10 pending, 0ms getConnection wait, TotalBorrowed 7718
0 borrowed, 10 pending, 0ms getConnection wait, TotalBorrowed 7718
0 borrowed, 10 pending, 0ms getConnection wait, TotalBorrowed 7718
0 borrowed, 10 pending, 0ms getConnection wait, TotalBorrowed 7718
0 borrowed, 10 pending, 0ms getConnection wait, TotalBorrowed 7718
0 borrowed, 10 pending, 0ms getConnection wait, TotalBorrowed 7718
4 borrowed, 0 pending, 95ms getConnection wait, TotalBorrowed 8034, avg response time from db 28ms
3 borrowed, 0 pending, 88ms getConnection wait, TotalBorrowed 8631, avg response time from db 29ms
1 borrowed, 0 pending, 82ms getConnection wait, TotalBorrowed 9290, avg response time from db 21ms
4 borrowed, 0 pending, 77ms getConnection wait, TotalBorrowed 9856, avg response time from db 33ms
5 borrowed, 0 pending, 73ms getConnection wait, TotalBorrowed 10486, avg response time from db 25ms
1 borrowed, 0 pending, 68ms getConnection wait, TotalBorrowed 11135, avg response time from db 22ms
0 borrowed, 0 pending, 64ms getConnection wait, TotalBorrowed 11803, avg response time from db 20ms
5 borrowed, 4 pending, 61ms getConnection wait, TotalBorrowed 12443, avg response time from db 24ms
1 borrowed, 0 pending, 58ms getConnection wait, TotalBorrowed 13120, avg response time from db 19ms
0 borrowed, 0 pending, 55ms getConnection wait, TotalBorrowed 13787, avg response time from db 20ms
5 borrowed, 1 pending, 52ms getConnection wait, TotalBorrowed 14470, avg response time from db 19ms
4 borrowed, 0 pending, 50ms getConnection wait, TotalBorrowed 15141, avg response time from db 20ms
6 borrowed, 0 pending, 48ms getConnection wait, TotalBorrowed 15819, avg response time from db 19ms


[oracle@adgsby ~]$ srvctl status service -d $(srvctl config database) -s svc_tac
Service svc_tac is running on instance(s) adg


-- From any node, as "oracle" user, check the Data Guard configuration

[oracle@adgsby ~]$ dgmgrl
DGMGRL for Linux: Release 19.0.0.0.0 - Production on Tue Nov 23 13:19:44 2021
Version 19.12.0.0.0

Copyright (c) 1982, 2019, Oracle and/or its affiliates.  All rights reserved.

Welcome to DGMGRL, type "help" for information.
DGMGRL> connect sys/"W3lc0m3#W3lc0m3#W" as sysdba
Connected to "adg_fra34x"
Connected as SYSDBA.
DGMGRL> show configuration

Configuration - adg_fra22s_adg_fra34x

  Protection Mode: MaxPerformance
  Members:
  adg_fra34x - Primary database
    adg_fra22s - Physical standby database

Fast-Start Failover:  Disabled

Configuration Status:
SUCCESS   (status updated 11 seconds ago)


[oracle@adgdb-s01-2021-11-22-170552 acdemo]$ sqlplus hr/"W3lc0m3#W3lc0m3#W"@" (DESCRIPTION=(CONNECT_TIMEOUT=10)(RETRY_COUNT=3)(RETRY_DELAY=3)(TRANSPORT_CONNECT_TIMEOUT=3)(ADDRESS_LIST = (FAILOVER = ON) (LOAD_BALANCE = OFF)(ADDRESS = (PROTOCOL = TCP)(HOST = adgdb-scan.pub.adgdblab.oraclevcn.com)(PORT = 1521))(ADDRESS = (PROTOCOL = TCP)(HOST = adgsbydb-scan.pub.adgdblab.oraclevcn.com)(PORT = 1521)))(CONNECT_DATA =(SERVICE_NAME = svc_tac.pub.adgdblab.oraclevcn.com)))"

SQL*Plus: Release 19.0.0.0.0 - Production on Tue Nov 23 13:21:35 2021
Version 19.12.0.0.0

Copyright (c) 1982, 2021, Oracle.  All rights reserved.

Last Successful login time: Tue Nov 23 2021 13:16:29 +00:00

Connected to:
Oracle Database 19c EE Extreme Perf Release 19.0.0.0.0 - Production
Version 19.12.0.0.0

SQL>
SQL> select SYS_CONTEXT('USERENV','DB_UNIQUE_NAME') from dual;

SYS_CONTEXT('USERENV','DB_UNIQUE_NAME')
--------------------------------------------------------------------------------
adg_fra34x

-- As expected, we are connected to the primary database

--- Initiate a transaction, but don't commit .... will commit that after a (short) coffee break !!!

SQL> update emp4ac set sal=sal*1.1 where ename like 'Bob%';

13501 rows updated.


[oracle@adgsby ~]$ dgmgrl
DGMGRL for Linux: Release 19.0.0.0.0 - Production on Tue Nov 23 13:19:44 2021
Version 19.12.0.0.0

Copyright (c) 1982, 2019, Oracle and/or its affiliates.  All rights reserved.

Welcome to DGMGRL, type "help" for information.
DGMGRL> connect sys/"W3lc0m3#W3lc0m3#W" 


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
SUCCESS   (status updated 102 seconds ago)

-- Go back to your Sql*Plus session and commit your transaction:

SQL> commit;

Commit complete.

SQL> select SYS_CONTEXT('USERENV','DB_UNIQUE_NAME') from dual;

SYS_CONTEXT('USERENV','DB_UNIQUE_NAME')
--------------------------------------------------------------------------------
adg_fra22s



