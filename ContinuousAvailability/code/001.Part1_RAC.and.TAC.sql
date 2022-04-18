## Run the following commands either from node 1 or node 1
ssh -i privateKey opc@<public ip of node 1>

## Connect as "grid" user and show the cluster resources
sudo su - grid
/u01/app/19.0.0.0/grid/bin/crsctl stat res -t

## Exit "grid" user and connect to "oracle" user:
## Execute the following commands either from node 1 or node 2
exit
sudo su - oracle
## Get the names of the instances 
ps -ef | grep pmon | grep lvrac

## In that case, the two instances are named lvrac1 and lvrac2

## Create a new service called svctest

srvctl add service -d $(srvctl config database) -s svctest -preferred lvrac1 -available lvrac2 -pdb pdb1

## Start the newly created service
srvctl start service -d $(srvctl config database) -s svctest

## Check the service status: the service is running on the preferred instance
srvctl status service -d $(srvctl config database) -s svctest
exit

## Use the lsnrctl utility to list the services on both node 1 and node 2 as the grid user:

sudo su - grid
export ORACLE_HOME=/u01/app/19.0.0.0/grid
$ORACLE_HOME/bin/lsnrctl services
$ORACLE_HOME/bin/lsnrctl status LISTENER
exit

## Cause the service to fail over. After identifying which instance the service is being offered on, kill that instance by removing the SMON process at the operating system level. Run this on node 1:

sudo su - oracle
ps -ef | grep ora_smon
kill -9 <yourpid>

## Check the service status:
srvctl status service -d $(srvctl config database) -s svctest

=> Service svctest is running on instance(s) lvrac2

## Manually relocate the service on node 1:

srvctl relocate service -d $(srvctl config database) -s svctest -oldinst lvrac2 -newinst lvrac1

srvctl status service -d $(srvctl config database) -s svctest

=> Service svctest is running on instance(s) lvrac1

###################################################
### Configure services for Application Continuity
###################################################

## As oracle user, create a service with AC settings 
## Run the following on any node
srvctl add service -d $(srvctl config database) -s svc_ac -commit_outcome TRUE -failovertype TRANSACTION -failover_restore LEVEL1 -preferred lvrac1 -available lvrac2 -pdb pdb1 -clbgoal LONG -rlbgoal NONE

## Create a service named noac with no AC settings
srvctl add service -d $(srvctl config database) -s noac -commit_outcome FALSE -failovertype NONE -failover_restore NONE -preferred lvrac1 -available lvrac2 -pdb pdb1 -clbgoal LONG -rlbgoal NONE

## Create a service named tac_service with TAC settings
srvctl add service -d $(srvctl config database) -s tac_service -commit_outcome TRUE -failovertype AUTO -failover_restore AUTO -preferred lvrac1 -available lvrac2 -pdb pdb1 -clbgoal LONG -rlbgoal NONE

## Start the three services
srvctl start service -d $(srvctl config database) -s svc_ac
srvctl start service -d $(srvctl config database) -s noac
srvctl start service -d $(srvctl config database) -s tac_service

## Check their status

srvctl status service -d $(srvctl config database) -s svc_ac
=> Service svc_ac is running on instance(s) lvrac1

srvctl status service -d $(srvctl config database) -s noac
=> Service noac is running on instance(s) lvrac1

srvctl status service -d $(srvctl config database) -s tac_service
=> Service tac_service is running on instance(s) lvrac1

###################################################
Demonstrate Application Continuity
###################################################

## Install the sample program on node 1:
-- Connect to node1 as "oracle", and install a sample application:

cd /home/oracle
wget https://objectstorage.us-ashburn-1.oraclecloud.com/p/O8AOujhwl1dSTqhfH69f3nkV6TNZWU3KaIF4TZ-XuCaZ5w-xHEQ14ViOVhUXQjPB/n/oradbclouducm/b/LiveLabTemp/o/ACDemo_19c.zip

cd /home/oracle 
unzip ACDemo_19c.zip
ls -ltr

chmod +x SETUP_AC_TEST.sh

## Run the script SETUP_AC_TEST.sh. You will be prompted for INPUTS. If a default value is shown, press ENTER to accept except for service name

./SETUP_AC_TEST.sh

## Make the run scripts executable
cd /home/oracle/acdemo
chmod +x run*
chmod +x kill_session.sh

## Identify your service names:
srvctl status service -d $(srvctl config database)

Service noac is running on instance(s) lvrac1
Service svc_ac is running on instance(s) lvrac1
Service svctest is running on instance(s) lvrac1
Service tac_service is running on instance(s) lvrac1
Service unisrv is running on instance(s) lvrac1,lvrac2

###################################################
Run the application in NOREPLAY mode
###################################################

## As oracle, on node 1: 
cd /home/oracle/acdemo
cat ac_noreplay.properties

## Now, run the application with no replay:

cd /home/oracle/acdemo
./runnoreplay

## From another terminal, kill the SMON process of the instance where "noac" service is currently running (node 1):

sudo su - oracle
ps -ef | grep smon
kill -9 <yourpid>

## Go back to the terminal where the application is running, and observe the result:

###################################################
Run the application in AC mode
###################################################

cd /home/oracle/acdemo
cat ac_replay.properties

-- Start app in replay mode:
cd /home/oracle/acdemo
./runreplay

-- Kill smon on the instance where the service is running (node2)
ps -ef | grep smon
kill -9 <yourpid>

## Observe the application output

###################################################
Run the application in TAC mode
###################################################

cat tac_replay.properties

## Run the application in TAC mode
cd /home/oracle/acdemo
./runtacreplay

-- Kill smon on the instance where the service is running (node1)
ps -ef | grep smon

## Observe the application output

## TAC will protect applications that do, or do not use a connection pool. Let s try that with a SqlPlus connection:

## Check the TAC service, from any node, as "oracle" user
srvctl status service -d $(srvctl config database) -s tac_service

=> Service tac_service is running on instance(s) lvrac2

## If tac_service is not running on instance 1, relocate it to instance 1

srvctl relocate service -d $(srvctl config database) -s tac_service -oldinst lvrac2 -newinst lvrac1


## Connect to the database with SQL*Plus as the HR user over the TAC-enabled service. 
## COPY THIS CONNECT STRING FROM tac_replay.properties file !!!!!!. 

sqlplus hr/W3lc0m3#W3lc0m3#W@"(DESCRIPTION=(CONNECT_TIMEOUT=90)(RETRY_COUNT=50)(RETRY_DELAY=3)(TRANSPORT_CONNECT_TIMEOUT=3)(ADDRESS_LIST=(ADDRESS=(PROTOCOL=tcp)(HOST=lvracdb-s01-2022-02-03-092348-scan.pub.racdblab.oraclevcn.com)(PORT=1521)))(CONNECT_DATA=(SERVICE_NAME=tac_service.pub.racdblab.oraclevcn.com)))"

-- Update a row in the table EMP4AC. For example:

select empno, ename from emp4ac where rownum < 10;
update emp4ac set empno=9999 where empno=5221 and ename='Bob5221' and rownum < 10;

## LEAVE THE TRANSACTION UNCOMMITTED !!!!

## From another terminal, kill the session with the uncommitted transaction 
## This MUST be run on node 1, where the application has been deployed:

cd /home/oracle/acdemo
./kill_session.sh tac_service.pub.racdblab.oraclevcn.com

## Go back to your sqlplus session, and commit your transaction:

commit;

###################################################
Use Fast Application Notification (FAN)
###################################################

ssh -i privateKey opc@<public ip of node 1>

## Connect as "grid" user and move to FAN callouts default directory:
sudo su - grid
cd /u01/app/19.0.0.0/grid/racg/usrco/

## Use "vi" editor to create a simple callout script: callout-log.sh 
## The content of this callout file must be as follows:
cat callout-log.sh

#!/usr/bin/bash
umask 022
FAN_LOGFILE=/tmp/`hostname -s`_events.log
echo $* " reported = "`date` >> ${FAN_LOGFILE} &

chmod +x callout-log.sh

### REPEAT THE PREVIOUS STEPS ON NODE2

## As grid, from node 1: list the cluster resources

crsctl stat res -t

## Stop force instance 1:

srvctl stop instance -d $(srvctl config database) -i lvrac1 -o immediate -force

## Check the database status on all nodes: confirm that instance 1 is not running

srvctl status database -d $(srvctl config database)

Instance lvrac1 is not running on node lvracdb-s01-2022-02-03-0923481
Instance lvrac2 is running on node lvracdb-s01-2022-02-03-0923482

## If your callout was written correctly and had the appropriate execute permissions, a file named hostname_events.log should be visible in the /tmp directory. 
## Check the content of this file:

cat /tmp/lvracdb-s01-2022-02-03-0923481_events.log

SERVICEMEMBER VERSION=1.0 service=tac_service.pub.racdblab.oraclevcn.com database=lvrac_fra3j8 instance=lvrac1 host=lvracdb-s01-2022-02-03-0923481 status=down reason=USER timestamp=2022-02-04 11:22:00 timezone=+00:00 db_domain=pub.racdblab.oraclevcn.com  reported = Fri Feb 4 11:22:00 UTC 2022
SERVICE VERSION=1.0 service=tac_service.pub.racdblab.oraclevcn.com database=lvrac_fra3j8 instance=lvrac1 host=lvracdb-s01-2022-02-03-0923481 status=down reason=USER timestamp=2022-02-04 11:22:00 timezone=+00:00 db_domain=pub.racdblab.oraclevcn.com  reported = Fri Feb 4 11:22:00 UTC 2022
SERVICEMEMBER VERSION=1.0 service=unisrv.pub.racdblab.oraclevcn.com database=lvrac_fra3j8 instance=lvrac1 host=lvracdb-s01-2022-02-03-0923481 status=down reason=USER timestamp=2022-02-04 11:22:00 timezone=+00:00 db_domain=pub.racdblab.oraclevcn.com  reported = Fri Feb 4 11:22:00 UTC 2022
INSTANCE VERSION=1.0 service=lvrac_fra3j8.pub.racdblab.oraclevcn.com database=lvrac_fra3j8 instance=lvrac1 host=lvracdb-s01-2022-02-03-0923481 status=down reason=USER timestamp=2022-02-04 11:22:32 timezone=+00:00 db_domain=pub.racdblab.oraclevcn.com  reported = Fri Feb 4 11:22:32 UTC 2022

## Now start instance 1 and re-check the logfile:

srvctl start instance -d $(srvctl config database) -i lvrac1
srvctl status database -d $(srvctl config database)

Instance lvrac1 is running on node lvracdb-s01-2022-02-03-0923481
Instance lvrac2 is running on node lvracdb-s01-2022-02-03-0923482

cat /tmp/lvracdb-s01-2022-02-03-0923481_events.log

SERVICEMEMBER VERSION=1.0 service=tac_service.pub.racdblab.oraclevcn.com database=lvrac_fra3j8 instance=lvrac1 host=lvracdb-s01-2022-02-03-0923481 status=down reason=USER timestamp=2022-02-04 11:22:00 timezone=+00:00 db_domain=pub.racdblab.oraclevcn.com  reported = Fri Feb 4 11:22:00 UTC 2022
SERVICE VERSION=1.0 service=tac_service.pub.racdblab.oraclevcn.com database=lvrac_fra3j8 instance=lvrac1 host=lvracdb-s01-2022-02-03-0923481 status=down reason=USER timestamp=2022-02-04 11:22:00 timezone=+00:00 db_domain=pub.racdblab.oraclevcn.com  reported = Fri Feb 4 11:22:00 UTC 2022
SERVICEMEMBER VERSION=1.0 service=unisrv.pub.racdblab.oraclevcn.com database=lvrac_fra3j8 instance=lvrac1 host=lvracdb-s01-2022-02-03-0923481 status=down reason=USER timestamp=2022-02-04 11:22:00 timezone=+00:00 db_domain=pub.racdblab.oraclevcn.com  reported = Fri Feb 4 11:22:00 UTC 2022
INSTANCE VERSION=1.0 service=lvrac_fra3j8.pub.racdblab.oraclevcn.com database=lvrac_fra3j8 instance=lvrac1 host=lvracdb-s01-2022-02-03-0923481 status=down reason=USER timestamp=2022-02-04 11:22:32 timezone=+00:00 db_domain=pub.racdblab.oraclevcn.com  reported = Fri Feb 4 11:22:32 UTC 2022
INSTANCE VERSION=1.0 service=lvrac_fra3j8.pub.racdblab.oraclevcn.com database=lvrac_fra3j8 instance=lvrac1 host=lvracdb-s01-2022-02-03-0923481 status=up reason=USER timestamp=2022-02-04 11:26:02 timezone=+00:00 db_domain=pub.racdblab.oraclevcn.com  reported = Fri Feb 4 11:26:03 UTC 2022
SERVICEMEMBER VERSION=1.0 service=tac_service.pub.racdblab.oraclevcn.com database=lvrac_fra3j8 instance=lvrac1 host=lvracdb-s01-2022-02-03-0923481 status=up reason=USER card=1 timestamp=2022-02-04 11:26:05 timezone=+00:00 db_domain=pub.racdblab.oraclevcn.com  reported = Fri Feb 4 11:26:05 UTC 2022
SERVICE VERSION=1.0 service=tac_service.pub.racdblab.oraclevcn.com database=lvrac_fra3j8 instance=lvrac1 host=lvracdb-s01-2022-02-03-0923481 status=up reason=USER timestamp=2022-02-04 11:26:05 timezone=+00:00 db_domain=pub.racdblab.oraclevcn.com  reported = Fri Feb 4 11:26:05 UTC 2022
SERVICEMEMBER VERSION=1.0 service=unisrv.pub.racdblab.oraclevcn.com database=lvrac_fra3j8 instance=lvrac1 host=lvracdb-s01-2022-02-03-0923481 status=up reason=USER card=2 timestamp=2022-02-04 11:26:05 timezone=+00:00 db_domain=pub.racdblab.oraclevcn.com  reported = Fri Feb 4 11:26:05 UTC 2022


## Create a second shell script on each node, in directory /u01/app/19.0.0.0/grid/racg/usrco/

cat callout_elaborate.sh

#!/usr/bin/bash
# Scan and parse HA event payload arguments: #
# define AWK
AWK=/bin/awk
# Define a log file to see results 
FAN_LOGFILE=/tmp/`hostname -s`.log 
# Event type is handled differently 
NOTIFY_EVENTTYPE=$1
for ARGS in $*; do
  PROPERTY=`echo $ARGS | $AWK -F "=" '{print $1}'` 
  VALUE=`echo $ARGS | $AWK -F "=" '{print $2}'` 
  case $PROPERTY in
     VERSION|version) NOTIFY_VERSION=$VALUE ;;
     SERVICE|service) NOTIFY_SERVICE=$VALUE ;;
     DATABASE|database) NOTIFY_DATABASE=$VALUE ;;
     INSTANCE|instance) NOTIFY_INSTANCE=$VALUE ;;
     HOST|host) NOTIFY_HOST=$VALUE ;;
     STATUS|status) NOTIFY_STATUS=$VALUE ;;
     REASON|reason) NOTIFY_REASON=$VALUE ;;
     CARD|card) NOTIFY_CARDINALITY=$VALUE ;;
     VIP_IPS|vip_ips) NOTIFY_VIPS=$VALUE ;; #VIP_IPS for public_nw_down 
     TIMESTAMP|timestamp) NOTIFY_LOGDATE=$VALUE ;; # catch event date TIMEZONE|timezone) NOTIFY_TZONE=$VALUE ;;
     ??:??:??) NOTIFY_LOGTIME=$PROPERTY ;; # catch event time (hh24:mi:ss)
  esac
done

# FAN events with the following conditions will be inserted
# into the critical trouble ticket system:
# NOTIFY_EVENTTYPE => SERVICE | DATABASE | NODE
# NOTIFY_STATUS => down | public_nw_down | nodedown
#
if (( [ "$NOTIFY_EVENTTYPE" = "SERVICE" ] ||[ "$NOTIFY_EVENTTYPE" = "DATABASE" ] || \
[ "$NOTIFY_EVENTTYPE" = "NODE" ] \
) && \
( [ "$NOTIFY_STATUS" = "down" ] || \
[ "$NOTIFY_STATUS" = "public_nw_down" ] || \
[ "$NOTIFY_STATUS" = "nodedown " ] ) \
) ; then
# << CALL TROUBLE TICKET LOGGING PROGRAM AND PASS RELEVANT NOTIFY_* ARGUMENTS >>
  echo "Create a service request as " ${NOTIFY_EVENTTYPE} " " ${NOTIFY_STATUS} " occured at " ${NOTIFY_LOGTIME} >> ${FAN_LOGFILE}
else
  echo "Found no interesting event: " ${NOTIFY_EVENTTYPE} " "${NOTIFY_STATUS} >> ${FAN_LOGFILE}
fi

chmod +x callout_elaborate.sh

REPEAT THE SAME STEPS ON NODE 2 !!!

## Stop the database and check its status 

srvctl stop database -d $(srvctl config database) -o immediate -force
srvctl status database -d $(srvctl config database)

Instance lvrac1 is not running on node lvracdb-s01-2022-02-03-0923481
Instance lvrac2 is not running on node lvracdb-s01-2022-02-03-0923482

## Review the logfile on /tmp, for example:

cat /tmp/lvracdb-s01-2022-02-03-0923481.log

Found no interesting event:  SERVICEMEMBER  down
Found no interesting event:  SERVICEMEMBER  down
Create a service request as  SERVICE   down  occured at  11:48:03
Create a service request as  SERVICE   down  occured at  11:48:03
Create a service request as  SERVICE   down  occured at  11:48:03
Found no interesting event:  SERVICEMEMBER  down
Found no interesting event:  SERVICEMEMBER  down
Create a service request as  SERVICE   down  occured at  11:48:03
Create a service request as  SERVICE   down  occured at  11:48:03
Found no interesting event:  SERVICEMEMBER  down
Found no interesting event:  INSTANCE  down
Create a service request as  DATABASE   down  occured at  11:48:43


## Review the logfile on node 2:

cat /tmp/lvracdb-s01-2022-02-03-0923482.log

## Start the database and check the logs on both nodes

srvctl start database -d $(srvctl config database)
srvctl status database -d $(srvctl config database)

###################################################
Client side FAN events
###################################################

mkdir -p /home/oracle/fANWatcher

cd /home/oracle/fANWatcher

wget https://objectstorage.uk-london-1.oraclecloud.com/p/gKfwKKgzqSfL4A48e6lSKZYqyFdDzvu57md4B1MegMU/n/lrojildid9yx/b/labtest_bucket/o/fanWatcher_19c.zip

## Unzip the application:

unzip fanWatcher_19c.zip
ls -ltr

## Edit fanWatcher.bash and set values accordingly

## Chmod the script and execute

chmod +x fanWatcher.bash

./fanWatcher.bash

## From another terminal, connect to node 2 as "oracle" and kill smon process of instance 2 !!!

ps -ef | grep smon
kill -9 <mypid>

## Go back to FANWatcher terminal, and observe how it traps the events:

