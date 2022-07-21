## Converged Database: Modern Development Workshop Day 2


# Creación de PDB3.

# Creación de PDB3 dentro del Application Container

$ sqlplus / as sysdba

SQL> alter session set container=app_root;

Session altered

SQL> CREATE PLUGGABLE DATABASE PDB3 ADMIN USER pdbadmin IDENTIFIED BY "Oracle_4U";

Pluggable database PDB3 created.

SQL> alter pluggable database PDB3 open;

Pluggable database PDB3 altered.

SQL> alter pluggable database PDB3 save state;

Pluggable database PDB3 altered.

SQL> show pdbs;

    CON_ID CON_NAME			  OPEN MODE  RESTRICTED
---------- ------------------------------ ---------- ----------
	 3 APP_ROOT			  READ WRITE NO
	 4 PDB2 			  READ WRITE NO
	 5 PDB1 			  READ WRITE NO
	 7 PDB3 			  READ WRITE NO

SQL> alter session set container=PDB3;

Session altered.

SQL> create tablespace TBS_SOE datafile size 400M;

Tablespace TBS_SOE created.

SQL> create user SOE identified by soe default tablespace TBS_SOE temporary tablespace TEMP;

User SOE created.

SQL> alter user SOE quota unlimited on TBS_SOE;

User SOE altered.

SQL> grant connect, resource to SOE;

Grant succeeded.

SQL> grant create view to SOE;

Grant succeeded.

SQL> grant create any directory to soe;    

Grant succeeded.

SQL> exit 



# Información de Kafka

❯ netstat -an |grep 9092 |grep LISTEN
tcp6       0      0 :::9092                 :::*                    LISTEN
❯ grep kafka /etc/hosts
127.0.0.1  kafka



# Instalación y configuración de Orakafka

❯ cd /home/oracle/sqldeveloper/orakafka
❯ unzip orakafka.zip
Archive:  orakafka.zip
   creating: orakafka-1.2.0/
 extracting: orakafka-1.2.0/kit_version.txt  
  inflating: orakafka-1.2.0/orakafka_distro_install.sh  
 extracting: orakafka-1.2.0/orakafka.zip  
  inflating: orakafka-1.2.0/README   
❯ cd orakafka-1.2.0
❯ ls
kit_version.txt  orakafka_distro_install.sh  orakafka.zip  README



❯ mkdir $ORACLE_HOME/orakafka-1.2.0
❯ ./orakafka_distro_install.sh -p $ORACLE_HOME/orakafka-1.2.0

 Step Create Product Home::
--------------------------------------------------------------
Step Create Product Home: completed.
PRODUCT_HOME=/opt/oracle/product/21c/dbhome_1/orakafka-1.2.0/ora_kafka_home
[…]
Successfully installed orakafka kit in /opt/oracle/product/21c/dbhome_1/orakafka-1.2.0/ora_kafka_home

❯ cd /opt/oracle/product/21c/dbhome_1/orakafka-1.2.0/ora_kafka_home/orakafka/bin
❯ ls
orakafka.sh  orakafka_stream.sh  scripts


❯ cd /opt/oracle/product/21c/dbhome_1/orakafka-1.2.0/ora_kafka_home
❯ mkdir orakafka_user_dirs


❯ java -XshowSettings:properties -version 2>&1 |grep "java.home"
    java.home = /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.302.b08-0.el8_4.x86_64/jre


❯ cd /opt/oracle/product/21c/dbhome_1/orakafka-1.2.0/ora_kafka_home/orakafka/bin
❯ 
❯ ./orakafka.sh setup_all -c KAFKAPODMAN -u SOE -p /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.302.b08-0.el8_4.x86_64/jre -r /opt/oracle/product/21c/dbhome_1/orakafka-1.2.0/ora_kafka_home/orakafka_user_dirs

[…]

***********SUMMARY************

TODO tasks:

1. Configure security properties at /opt/oracle/product/21c/dbhome_1/orakafka-1.2.0/ora_kafka_home/app_data/clusters/KAFKAPODMAN/conf/orakafka.properties
2. Execute the following SQL while connected as sysdba:
   @/opt/oracle/product/21c/dbhome_1/orakafka-1.2.0/ora_kafka_home/app_data/scratch/setup_all_KAFKAPODMAN_user1.sql
3. Execute the following SQL in user schema of "SOE":
   @/opt/oracle/product/21c/dbhome_1/orakafka-1.2.0/ora_kafka_home/app_data/scratch/install_orakafka_user1.sql

The above information is written to /opt/oracle/product/21c/dbhome_1/orakafka-1.2.0/ora_kafka_home/app_data/logs/setup_all.log.2022.01.10-12.29.03


bootstrap.servers=kafka:9092
security.protocol=PLAINTEXT
sasl.mechanism=PLAIN
sasl.plain.username=
sasl.plain.password=
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username=\"${sasl.plain.username}\" password=\"${sasl.plain.password}\";



❯ cat /opt/oracle/product/21c/dbhome_1/orakafka-1.2.0/ora_kafka_home/app_data/clusters/KAFKAPODMAN/conf/orakafka.properties
bootstrap.servers=localhost:9092
security.protocol=PLAINTEXT
sasl.mechanism=PLAIN
sasl.plain.username=
sasl.plain.password=
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username=\"${sasl.plain.username}\" password=\"${sasl.plain.password}\";



❯ sqlplus sys/Oracle_4U@localhost:1521/pdb3 as sysdba

SQL*Plus: Release 21.0.0.0.0 - Production on Mon Jan 10 15:30:33 2022
Version 21.3.0.0.0

Copyright (c) 1982, 2022, Oracle.  All rights reserved.


Connected to:
Oracle Database 21c Enterprise Edition Release 21.0.0.0.0 - Production
Version 21.3.0.0.0

SQL> @/opt/oracle/product/21c/dbhome_1/orakafka-1.2.0/ora_kafka_home/app_data/scratch/setup_all_KAFKAPODMAN_user1.sql

Creating database directory "KAFKAPODMAN_CONF_DIR"..

Directory created.

The above information is written to /opt/oracle/product/21c/dbhome_1/orakafka-1.2.0/ora_kafka_home/app_data/logs/orakafka_create_KAFKAPODMAN_CONF_DIR.log
Checking if user exists..

PL/SQL procedure successfully completed.

Creating location and default directories..

PL/SQL procedure successfully completed.


Directory created.


Directory created.


Grant succeeded.


Grant succeeded.

Creation of location dir "SOE_KAFKA_LOC_DIR" and default dir "SOE_KAFKA_DEF_DIR" completed.
Grant of required permissions on "SOE_KAFKA_LOC_DIR","SOE_KAFKA_DEF_DIR" to "SOE" completed.
The above information is written to /opt/oracle/product/21c/dbhome_1/orakafka-1.2.0/ora_kafka_home/app_data/logs/setup_db_dirs_user1.log

PL/SQL procedure successfully completed.

Granting permissions on "KAFKAPODMAN_CONF_DIR" to "SOE"

Grant succeeded.

The above information is written to /opt/oracle/product/21c/dbhome_1/orakafka-1.2.0/ora_kafka_home/app_data/logs/orakafka_adduser_cluster_KAFKAPODMAN_user1.log
Disconnected from Oracle Database 21c Enterprise Edition Release 21.0.0.0.0 - Production
Version 21.3.0.0.0





❯ sqlplus soe/soe@localhost:1521/pdb3

SQL*Plus: Release 21.0.0.0.0 - Production on Mon Jan 10 15:32:50 2022
Version 21.3.0.0.0

Copyright (c) 1982, 2022, Oracle.  All rights reserved.


Connected to:
Oracle Database 21c Enterprise Edition Release 21.0.0.0.0 - Production
Version 21.3.0.0.0

SQL> @/opt/oracle/product/21c/dbhome_1/orakafka-1.2.0/ora_kafka_home/app_data/scratch/install_orakafka_user1.sql

Verifying user schema..

PL/SQL procedure successfully completed.

Verifying that location and default directories are accessible..

PL/SQL procedure successfully completed.

Installing ORA_KAFKA package in user schema..
.. Creating ORA_KAFKA artifacts

Table created.


Table created.


Table created.


Table created.


Package created.

No errors.

Package created.

No errors.

Package body created.

No errors.

Package body created.

No errors.
The above information is written to /opt/oracle/product/21c/dbhome_1/orakafka-1.2.0/ora_kafka_home/app_data/logs/install_orakafka_user1.log
Disconnected from Oracle Database 21c Enterprise Edition Release 21.0.0.0.0 - Production
Version 21.3.0.0.0



❯ sqlplus soe/soe@localhost:1521/pdb3

SQL*Plus: Release 21.0.0.0.0 - Production on Mon Jan 10 15:37:14 2022
Version 21.3.0.0.0

Copyright (c) 1982, 2022, Oracle.  All rights reserved.

Last Successful login time: Mon Jan 10 2022 15:35:46 +00:00

Connected to:
Oracle Database 21c Enterprise Edition Release 21.0.0.0.0 - Production
Version 21.3.0.0.0

SQL> set serveroutput on

SQL> BEGIN
 ORA_KAFKA.REGISTER_CLUSTER('KAFKAPODMAN',
                            'localhost:9092',
                            'SOE_KAFKA_DEF_DIR',
                            'SOE_KAFKA_LOC_DIR',
                            'KAFKAPODMAN_CONF_DIR',
                            'Podman Kafka Workshop Developers');
 dbms_output.put_line('Registered Podman Kafka Workshop Developers');
END;
/  
Registered Podman Kafka Workshop Developers

PL/SQL procedure successfully completed.



SQL> create table ORDER_STATUS (
    key varchar2(4000),
    value JSON);  

Table created.


SQL> DECLARE
  num_records_loaded INTEGER;
BEGIN
  ORA_KAFKA.LOAD_TABLE
    ('KAFKAPODMAN',           -- The name of the cluster
    'LOADAPP',                -- The name of the Kafka group
    'oracle',                 -- The name of the topic
    'JSON_VARCHAR2',          -- The format of the Kafka record
    'ORDER_STATUS',           -- The name of the target table in Oracle.
    num_records_loaded);      -- The number of Kafka records loaded
  dbms_output.put_line('Kafka records loaded = ' || num_records_loaded);
  COMMIT;
END;
/  

Kafka records loaded = 0
PL/SQL procedure successfully completed.

SQL> exit



# Encolar un pedido en JSON en el tópico


❯ cd /home/oracle/orders
❯ cat order_1.json
{"ORDER":{"ORDER_ID":1,"ORDER_DATE":"2007-05-12T04:00:00.000000Z","ORDER_MODE":"direct","CUSTOMER_ID":56,"ORDER_STATUS":5,"ORDER_TOTAL":4990,"SALES_REP_ID":499, "PROMOTION_ID":499,"WAREHOUSE_ID":704,"DELIVERY_TYPE":"Standard","COST_OF_DELIVERY":1,"WAIT_TILL_ALL_AVAILABLE":"ship_when_ready","DELIVERY_ADDRESS_ID":2,"CUSTOMER_CLASS":"Occasional","CARD_ID":121,"INVOICE_ADDRESS_ID":2},"LATITUDE":"40.48837","LONGITUDE":"-3.96458","ITEMS":[{"ORDER_ID":1,"LINE_ITEM_ID":1,"PRODUCT_ID": 499,"UNIT_PRICE":998,"QUANTITY":4,"DISPATCH_DATE":"2012-02-11T00:00:00","RETURN_DATE":null,"GIFT_WRAP":"None","CONDITION":"New","SUPPLIER_ID":499,"ESTIMATED_DELIVERY":"2006-05-01T00:00:00"},{"ORDER_ID":1,"LINE_ITEM_ID":4,"PRODUCT_ID":522,"UNIT_PRICE":1044,"QUANTITY":5,"DISPATCH_DATE":"2012-04-24T00:00:00","RETURN_DATE":null,"GIFT_WRAP":"None","CONDITION":"New","SUPPLIER_ID":522,"ESTIMATED_DELIVERY":"2004-07-30T00:00:00"},{"ORDER_ID":1,"LINE_ITEM_ID":3,"PRODUCT_ID":708,"UNIT_PRICE":1415,"QUANTITY":7,"DISPATCH_DATE":"2012-02-21T00:00:00","RETURN_DATE":null,"GIFT_WRAP":"None","CONDITION":"New","SUPPLIER_ID":708,"ESTIMATED_DELIVERY":"2009-09-25T00:00:00"},{"ORDER_ID":1,"LINE_ITEM_ID":2,"PRODUCT_ID":416,"UNIT_PRICE":832,"QUANTITY":4,"DISPATCH_DATE":"2012-01-06T00:00:00","RETURN_DATE":null,"GIFT_WRAP":"None","CONDITION":"New","SUPPLIER_ID":416,"ESTIMATED_DELIVERY":"2000-03-21T00:00:00"}]}


❯ /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server kafka:9092 --topic oracle
>


❯ /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic oracle --from-beginning



# Leer el pedido JSON en el tópico desde Oracle


❯ sqlplus soe/soe@localhost:1521/pdb3

SQL*Plus: Release 21.0.0.0.0 - Production on Mon Jan 10 17:44:06 2022
Version 21.3.0.0.0

Last Successful login time: Mon Jan 10 2022 16:31:08 +00:00
Connected to:
Oracle Database 21c Enterprise Edition Release 21.0.0.0.0 - Production
Version 21.3.0.0.0

SQL> set serveroutput on

SQL> DECLARE
  num_records_loaded INTEGER;
BEGIN
  ORA_KAFKA.LOAD_TABLE
    ('KAFKAPODMAN',           -- The name of the cluster
    'LOADAPP',                -- The name of the Kafka group
    'oracle',                 -- The name of the topic
    'JSON_VARCHAR2',          -- The format of the Kafka record
    'ORDER_STATUS',           -- The name of the target table in Oracle.
    num_records_loaded);      -- The number of Kafka records loaded
  dbms_output.put_line('Kafka records loaded = ' || num_records_loaded);
  COMMIT;
END;
/  

Kafka records loaded = 3

SQL> select j.value from order_status j;

VALUE
--------------------------------------------------------------------------------
{"ORDER":{"INVOICE_ADDRESS_ID":2,"COST_OF_DELIVERY":1,"LONGITUDE":"-3.913976","S
{"ORDER":{"INVOICE_ADDRESS_ID":2,"COST_OF_DELIVERY":1,"LONGITUDE":"-3.790824","S
{"ORDER":{"INVOICE_ADDRESS_ID":2,"COST_OF_DELIVERY":1,"LONGITUDE":"-3.96458","SA

SQL> select json_value(value, '$.ORDER.ORDER_ID' returning number) order_id,
            json_value(value, '$.ORDER.LATITUDE' returning number) latitude,
            json_value(value, '$.ORDER.LONGITUDE' returning number) longitude
from ORDER_STATUS;

  ORDER_ID   LATITUDE  LONGITUDE
---------- ---------- ----------
	 1  40.365844  -3.913976
	 2  40.457248  -3.790824
	 3   40.48837	  -3.96458

SQL> exit




# Carga de estaciones de la AEMET

❯ cd /home/oracle/Oracle_Spatial_Studio
❯ ./start.sh
[…]
21:31:19     INFO  org.eclipse.jetty.server.Server - Started @22681ms
21:31:19     INFO  o.a.gretty.JettyServerStartInfo - Jetty 9.4.40.v20220413 started and listening on port 4040
21:31:19     INFO  o.a.gretty.JettyServerStartInfo - spatialstudio runs at:
21:31:19     INFO  o.a.gretty.JettyServerStartInfo -   https://localhost:4040/spatialstudio



❯ sqlplus soe/soe@localhost:1521/pdb3

SQL> with CCCP as
(
   select json_value(value, '$.ORDER.LATITUDE' returning number) latitude,
          json_value(value, '$.ORDER.LONGITUDE' returning number) longitude
   from ORDER_STATUS
   where rownum=1
)
SELECT t1.INDICATIVO, t1.NOMBRE
  FROM AEMET_COMPLETAS_TCM30_176815__ESTACIONES_COMPLETAS t1, CCCP
  WHERE SDO_NN(t1.GEOM, SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(CCCP.longitude, CCCP.latitude, NULL),NULL,NULL), 'sdo_num_res=1') = 'TRUE';
/

INDICATIVO
--------------------------------------------------------------------------------
NOMBRE
--------------------------------------------------------------------------------
3196
MADRID/CUATRO VIENTOS

SQL> exit



# Consulta a API Rest para recuperar información

# Consulta API Rest desde PL/SQL a georouting de maps.oracle.com

❯ sqlplus sys/Oracle_4U@localhost:1521/pdb3 as sysdba

SQL*Plus: Release 21.0.0.0.0 - Production on Wed Jan 12 11:09:55 2022
Version 21.3.0.0.0

Copyright (c) 1982, 2022, Oracle.  All rights reserved.


Connected to:
Oracle Database 21c Enterprise Edition Release 21.0.0.0.0 - Production
Version 21.3.0.0.0

SQL> grant execute on utl_http to SOE;

Grant succeeded.

SQL> grant execute on dbms_lock to SOE;

Grant succeeded.

SQL> BEGIN
  DBMS_NETWORK_ACL_ADMIN.create_acl (
    acl          => 'maps_oracle_acl_file.xml', 
    description  => 'Oracle Routing endpoint',
    principal    => 'SOE',
    is_grant     => TRUE, 
    privilege    => 'connect',
    start_date   => SYSTIMESTAMP,
    end_date     => NULL);
end;
/

PL/SQL procedure successfully completed.


SQL> begin
  DBMS_NETWORK_ACL_ADMIN.assign_acl (
    acl         => 'maps_oracle_acl_file.xml',
    host        => 'maps.oracle.com', 
    lower_port  => 80,
    upper_port  => NULL);    
end; 
/

PL/SQL procedure successfully completed.

SQL> 
SQL> exit


❯ sqlplus soe/soe@localhost:1521/pdb3

SQL*Plus: Release 21.0.0.0.0 - Production on Wed Jan 12 11:23:35 2022
Version 21.3.0.0.0

Copyright (c) 1982, 2022, Oracle.  All rights reserved.

Last Successful login time: Wed Jan 12 2022 11:03:55 +00:00

Connected to:
Oracle Database 21c Enterprise Edition Release 21.0.0.0.0 - Production
Version 21.3.0.0.0

SQL> create or replace function get_route (start_loc_lat in varchar2, start_loc_lon in varchar2, end_loc_lat in varchar2, end_loc_lon in varchar2) return clob
  is
  req utl_http.req;
  res utl_http.resp;
  url varchar2(4000) := 'http://maps.oracle.com/elocation/route';
  API_TEMPLATE varchar2(4000) := '<?xml version="1.0" standalone="yes"?>
<route_request id="8" route_preference="shortest" optimize_route="true" road_preference="highway" return_driving_directions="false" return_route_geometry="false" return_subroute_geometry="false" return_segment_geometry= "false" distance_unit="kilometer">
<start_location>
  <input_location id="1" longitude="$start_loc_lon" latitude="$start_loc_lat"/>
</start_location>
<end_location>
  <input_location id="2" longitude="$end_loc_lon" latitude="$end_loc_lat"/>
</end_location>
</route_request>'||chr(38)||'format=json';
  content varchar2(4000);
  t_response_text varchar2(4000);
begin
  content := replace( API_TEMPLATE, '$start_loc_lon', start_loc_lon );
  content := replace( content, '$start_loc_lat', start_loc_lat );
  content := replace( content, '$end_loc_lon', end_loc_lon );
  content := replace( content, '$end_loc_lat', end_loc_lat );
  content := 'xml_request='||content||chr(38)||'format=json';
  req := utl_http.begin_request(url, 'POST',' HTTP/1.1');
  utl_http.set_header(req, 'user-agent', 'mozilla/4.0');
  utl_http.set_header(req, 'content-type', 'application/x-www-form-urlencoded');
  utl_http.set_header(req, 'Content-Length', length(content));
  utl_http.write_text(req, content);
  res := utl_http.get_response(req);
  -- process the response from the HTTP call
  utl_http.read_text(res, t_response_text);
  utl_http.end_response(res);
  return t_response_text;
  end;
/

Function created.

SQL>


SQL> CREATE TABLE routing_info (
  id NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY (CACHE 5) PRIMARY KEY,
  route JSON);

Table created.

SQL> insert into routing_info (route) values (get_route('40.38638', '-3.93908', '40.472513','-3.872538'));

1 row created.

SQL> col distance_km format a16
SQL> col time_minutes format a16
SQL> select r.id, r.route.dist as distance_km, r.route.time as time_minutes from routing_info r;

	ID DISTANCE_KM	    TIME_MINUTES
---------- ---------------- ----------------
	 1   16.06	         23.25

SQL> exit


# Consulta API Rest con Java a AEMET opendata.aemet.es

git clone https://github.com/OracleDataManagementSpain/ConvergedDatabase/


❯ git clone https://github.com/OracleDataManagementSpain/ConvergedDatabase/
Cloning into 'ConvergedDatabase'...
remote: Enumerating objects: 599, done.
remote: Counting objects: 100% (90/90), done.
remote: Compressing objects: 100% (55/55), done.
remote: Total 599 (delta 41), reused 64 (delta 33), pack-reused 509
Receiving objects: 100% (599/599), 389.42 MiB | 28.25 MiB/s, done.
Resolving deltas: 100% (255/255), done.
❯ cd ConvergedDatabase/Developers
❯ ls
AEMETRequest.java  java_libraries.zip  nodeapp2.zip  Readme.md
❯ unzip java_libraries.zip
Archive:  java_libraries.zip
  inflating: javax.json-1.1.4.jar    
  inflating: okhttp-3.9.1.jar        
  inflating: okio-1.13.0.jar   


eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ3a2VuZXJvMjIwOEBteWJlc3RkZW1vLmNvbSIsImp0aSI6IjE1ZWYxN2I0LTU4MGQtNDdkNi05YjA3LTM2OWQ1MjJjMTc4ZSIsImlzcyI6IkFFTUVUIiwiaWF0IjoxNjQzMTA5NjI4LCJ1c2VySWQiOiIxNWVmMTdiNC01ODBkLTQ3ZDYtOWIwNy0zNjlkNTIyYzE3OGUiLCJyb2xlIjoiIn0.eeqxwZcedBSCXClyLGKBU2J0wNQX7osWlQNQc4sQZ4k


sed -i 's/String api_key = "";/String api_key = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ3a2VuZXJvMjIwOEBteWJlc3RkZW1vLmNvbSIsImp0aSI6IjE1ZWYxN2I0LTU4MGQtNDdkNi05YjA3LTM2OWQ1MjJjMTc4ZSIsImlzcyI6IkFFTUVUIiwiaWF0IjoxNjQzMTA5NjI4LCJ1c2VySWQiOiIxNWVmMTdiNC01ODBkLTQ3ZDYtOWIwNy0zNjlkNTIyYzE3OGUiLCJyb2xlIjoiIn0.eeqxwZcedBSCXClyLGKBU2J0wNQX7osWlQNQc4sQZ4k";/' AEMETRequest.java


❯ $ORACLE_HOME/jdk/bin/javac -cp javax.json-1.1.4.jar:okhttp-3.9.1.jar:okio-1.13.0.jar AEMETRequest.java
❯ ls
AEMETRequest.class  java_libraries.zip    nodeapp2.zip      okio-1.13.0.jar
AEMETRequest.java   javax.json-1.1.4.jar  okhttp-3.9.1.jar  Readme.md


❯ loadjava -user soe/soe@localhost:1521/pdb3 -genmissing -r okio-1.13.0.jar okhttp-3.9.1.jar javax.json-1.1.4.jar AEMETRequest.class


❯ sqlplus sys/Oracle_4U@localhost:1521/pdb3 as sysdba

SQL*Plus: Release 21.0.0.0.0 - Production on Tue Jan 11 12:40:43 2022
Version 21.3.0.0.0

Copyright (c) 1982, 2022, Oracle.  All rights reserved.


Connected to:
Oracle Database 21c Enterprise Edition Release 21.0.0.0.0 - Production
Version 21.3.0.0.0

SQL> exec dbms_java.grant_permission( 'SOE', 'SYS:java.net.NetPermission','getProxySelector', '' );

PL/SQL procedure successfully completed.

SQL> exec dbms_java.grant_permission('SOE', 'SYS:java.net.SocketPermission', 'opendata.aemet.es', 'resolve' );

PL/SQL procedure successfully completed.

SQL> exec dbms_java.grant_permission('SOE', 'SYS:java.net.SocketPermission', '212.128.97.177:443','connect,resolve' );

PL/SQL procedure successfully completed.

SQL> exec dbms_java.grant_permission( 'SOE', 'SYS:java.util.PropertyPermission', 'javax.net.ssl.trustStore', 'write' );

PL/SQL procedure successfully completed.

SQL> exec dbms_java.grant_permission( 'SOE', 'SYS:java.util.PropertyPermission', 'javax.net.ssl.trustStorePassword', 'write' );

PL/SQL procedure successfully completed.

SQL> exit



❯ sqlplus soe/soe@localhost:1521/pdb3

SQL*Plus: Release 21.0.0.0.0 - Production on Tue Jan 11 12:56:49 2022
Version 21.3.0.0.0

Copyright (c) 1982, 2022, Oracle.  All rights reserved.

Last Successful login time: Tue Jan 11 2022 12:53:08 +00:00

Connected to:
Oracle Database 21c Enterprise Edition Release 21.0.0.0.0 - Production
Version 21.3.0.0.0

SQL> CREATE OR REPLACE FUNCTION get_aemet_j (station_id varchar2, fecha_inicio varchar2, fecha_fin varchar2) RETURN VARCHAR2
AS LANGUAGE JAVA
NAME 'AEMETRequest.GetAEMETInfo(java.lang.String,java.lang.String,java.lang.String) return java.lang.String';
/ 

Function created.



SQL> DECLARE
   v_classpath VARCHAR2(4000);
   v_classpath2 VARCHAR2(4000);
BEGIN
   v_classpath := DBMS_JAVA.set_property('javax.net.ssl.trustStore', '/opt/oracle/product/21c/dbhome_1/jdk/jre/lib/security/cacerts');
   v_classpath2 := DBMS_JAVA.set_property('javax.net.ssl.trustStorePassword', 'changeit');
END;
/
  2    3    4    5    6    7    8  
PL/SQL procedure successfully completed.


SQL> select get_aemet_j('8178D','2022-01-01T00:00:00UTC','2022-01-01T12:00:00UTC') as aemetdata from dual;

AEMETDATA
--------------------------------------------------------------------------------
[ {
  "fecha" : "2022-01-01",
  "indicativo" : "8178D",
  "nombre" : "ALBACETE",
  "provincia" : "ALBACETE",
  "altitud" : "676",
  "tmed" : "3,8",
  "prec" : "0,9",
  "tmin" : "0,8",
  "horatmin" : "03:10",
  "tmax" : "6,8",
  "horatmax" : "14:10",
  "dir" : "27",
  "velmedia" : "2,5",
  "racha" : "13,1",
  "horaracha" : "14:10",
  "presMax" : "933,5",
  "horaPresMax" : "24",
  "presMin" : "930,6",
  "horaPresMin" : "07"
} ]

SQL> exit


# Enriquecimiento del pedido con información meteorológica y de cálculo de ruta.

❯ sqlplus soe/soe@localhost:1521/pdb3

SQL*Plus: Release 21.0.0.0.0 - Production on Wed Jan 12 18:58:13 2022
Version 21.3.0.0.0

Copyright (c) 1982, 2022, Oracle.  All rights reserved.

Connected to:
Oracle Database 21c Enterprise Edition Release 21.0.0.0.0 - Production
Version 21.3.0.0.0

SQL> CREATE OR REPLACE TYPE T_OI_REC AS OBJECT
(
order_id NUMBER(12),
DELIVERY_DATE  varchar2(100),
  latitude           number,
  longitude          number,
  indicativo       VARCHAR2(20),
  distance         varchar2(20),
  trip_duration         varchar2(20),
  tmed		varchar2(20),
  prec     varchar2(20) );
/  

Type created.

SQL> CREATE OR REPLACE TYPE T_OI_RECS IS TABLE OF T_OI_REC;
/   

Type created.



CREATE OR REPLACE FUNCTION FN_GET_ORDER_INFO (
        p_batch_size  IN PLS_INTEGER)
RETURN T_OI_RECS
PIPELINED
IS
    v_rec T_OI_REC := T_OI_REC(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
    v_fecha1 varchar2(100);
    v_fecha2 varchar2(100);
    v_classpath VARCHAR2(4000);
    v_classpath2 VARCHAR2(4000);
BEGIN
        --- JVM parameters
        v_classpath := DBMS_JAVA.set_property('javax.net.ssl.trustStore', '/opt/oracle/product/21c/dbhome_1/jdk/jre/lib/security/cacerts');
        v_classpath2 := DBMS_JAVA.set_property('javax.net.ssl.trustStorePassword', 'changeit');


	for cur 
	in (select json_value(value, '$.ORDER.ORDER_ID' returning number) order_id,
                   json_value(value, '$.ORDER.DELIVERY_DATE' returning varchar2) delivery_date,
                   json_value(value, '$.ORDER.LATITUDE' returning number) latitude,
                   json_value(value, '$.ORDER.LONGITUDE' returning number) longitude
            from order_status 
            where json_value(value, '$.ORDER.PROCESSED' returning varchar2 null on error) is null
                  and rownum < p_batch_size+1)
	LOOP

            -- Averiguar estacion AEMET cercana
	    SELECT cur.order_id, cur.delivery_date, cur.latitude, cur.longitude, t1.INDICATIVO
		into v_rec.order_id, v_rec.DELIVERY_DATE, v_rec.latitude, v_rec.longitude, v_rec.indicativo
	    FROM AEMET_COMPLETAS_TCM30_176815__ESTACIONES_COMPLETAS t1
	    WHERE SDO_NN(t1.GEOM, SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(cur.longitude, cur.latitude, NULL),NULL,NULL), 'sdo_num_res=1') = 'TRUE'; 


            -- Recuperar informacion de AEMET
	    v_fecha1 := to_char(to_date(cur.delivery_date,'YYYY-MM-DD"T"HH24:MI:SS'),'YYYY-MM-DD"T00:00:00UTC"');
        v_fecha2 := to_char(to_date(v_fecha1,'YYYY-MM-DD"T"HH24:MI:SS"UTC"')+(23/24),'YYYY-MM-DD"T"HH24:MI:SS"UTC"');


	    WITH aemet_info as
	    (
	     select get_aemet_j(v_rec.indicativo, v_fecha1, v_fecha2) as info from dual
	    )
	    select json_value(j.info, '$.tmed' returning varchar2) as temp_med,
	           json_value(j.info, '$.prec' returning varchar2) as precip
	    into v_rec.tmed, v_rec.prec
	    from aemet_info j;

            -- Completamos la información con distancia y duración del trayecto !!!
            WITH route_info as
            (
             select get_route('40.38638', '-3.93908',cur.latitude,cur.longitude) as info from dual
            )
            select json_value(j.info, '$.dist' returning varchar2) as distance,
                   json_value(j.info, '$.time' returning varchar2) as trip_duration
            into v_rec.distance, v_rec.trip_duration
            from route_info j;

            pipe row (v_rec);

	END LOOP;

END FN_GET_ORDER_INFO;
/



BEGIN
for cur 
in (select * from TABLE(FN_GET_ORDER_INFO(10)))
LOOP

    update ORDER_STATUS  
    set    "VALUE" = json_mergepatch (   
            "VALUE", '{ "ORDER":{ "DISTANCE" : "' || cur.distance || 
            '", "TRIP_DURATION" : "' || cur.trip_duration ||
            '", "TMED" : "' || cur.tmed ||
            '", "PREC" : "' || cur.prec ||
            '", "PROCESSED" : "' || to_char(sysdate,'YYYY-MM-DD"T"HH24:MI:SS') ||'"}}'
        )
    where json_value(value, '$.ORDER.ORDER_ID' returning number) = cur.order_id;
END LOOP;
commit;
END;
/



SQL> select order_id,tmed,distance from TABLE(FN_GET_ORDER_INFO(10)); 

  ORDER_ID TMED 		DISTANCE
---------- -------------------- --------------------
	 1 -5,2 		4.29
	 2 4,1			18.52
	 3 3,1			17.32



SQL> col processed format a25
col distance format a10
col tmed format a8
col prec format a8
col trip_duration format a16
col processed format a20
select json_value(value, '$.ORDER.ORDER_ID' returning number) order_id,
       json_value(value, '$.ORDER.DISTANCE' returning varchar2) distance,
       json_value(value, '$.ORDER.TRIP_DURATION' returning varchar2) trip_duration,
       json_value(value, '$.ORDER.TMED' returning varchar2) tmed,
       json_value(value, '$.ORDER.PREC' returning varchar2) prec,
       json_value(value, '$.ORDER.PROCESSED' returning varchar2 null on error) processed
from order_status;

  ORDER_ID DISTANCE   TRIP_DURATION    TMED	PREC	 PROCESSED
---------- ---------- ---------------- -------- -------- --------------------
	 1 4.29       12.07	       -5,2	0,0	 2022-03-21T15:19:42
	 2 18.52      39.99	       4,1	0,0	 2022-03-21T15:19:42
	 3 17.32      54.87	       3,1	0,0	 2022-03-21T15:19:42
SQL> exit



# Aplicación Low Code con APEX

# Preparación de vistas


❯ sqlplus soe/soe@localhost:1521/app_root

SQL*Plus: Release 21.0.0.0.0 - Production on Thu Mar 10 17:19:13 2022
Version 21.3.0.0.0

Copyright (c) 1982, 2021, Oracle.  All rights reserved.

Last Successful login time: Thu Mar 10 2022 13:15:28 +00:00

Connected to:
Oracle Database 21c Enterprise Edition Release 21.0.0.0.0 - Production
Version 21.3.0.0.0

SQL> create table ORDER_STATUS (
    key varchar2(4000),
    value JSON);  
  
Table created.

SQL> create or replace view v_order_status_ax as
select json_value(k."VALUE", '$.ORDER.ORDER_ID' returning number) as ID,
       json_value(k."VALUE", '$.ORDER.LONGITUDE' returning number) as LONGITUDE,
       json_value(k."VALUE", '$.ORDER.LATITUDE' returning number) as LATITUDE,
       json_value(k."VALUE", '$.ORDER.DISTANCE' returning number) as DISTANCE,
       json_value(k."VALUE", '$.ORDER.TRIP_DURATION' returning number) as TRIP_DURATION,
       json_value(k."VALUE", '$.ORDER.TMED' returning varchar) as TMED,
       json_value(k."VALUE", '$.ORDER.PREC' returning number) as PREC
       from containers(ORDER_STATUS) k;
  
View created.

SQL> create or replace view v_purchase_orders_ax as
select json_value(k.JSON_DOCUMENT, '$.ORDER_ID' returning number) as ID,
       json_value(k.JSON_DOCUMENT, '$.CUSTOMER_ID' returning number) as CUSTOMER_ID,
       json_value(k.JSON_DOCUMENT, '$.CUSTOMER_NAME' returning varchar) as CUSTOMER_NAME,
       json_value(k.JSON_DOCUMENT, '$.CUSTOMER_SURNAME' returning varchar) as CUSTOMER_SURNAME,
       json_value(k.JSON_DOCUMENT, '$.STREET_NAME' returning varchar) as STREET_NAME,
       json_value(k.JSON_DOCUMENT, '$.TOWN' returning varchar) as TOWN,
       json_value(k.JSON_DOCUMENT, '$.ORDER_DATE' returning date) as ORDER_DATE,
       json_value(k.JSON_DOCUMENT, '$.ORDER_TOTAL' returning number) as ORDER_TOTAL 
       from containers(PURCHASE_ORDERS) k;
  
View created.

SQL>  


select p.id, p.customer_id, p.CUSTOMER_NAME, 
       p.CUSTOMER_SURNAME, p.ORDER_DATE, p.ORDER_TOTAL, 
       p.STREET_NAME, p.TOWN,
       o.distance, o.TRIP_DURATION, o.TMED, o.LATITUDE, o.LONGITUDE
 from v_order_status_ax o, v_purchase_orders_ax p
 where o.ID (+)= p.ID;


# Creación de workspace APEX

select p.id, p.customer_id, p.CUSTOMER_NAME, 
       p.CUSTOMER_SURNAME, p.ORDER_DATE, p.ORDER_TOTAL, 
       p.STREET_NAME, p.TOWN,
       o.distance, o.TRIP_DURATION, o.TMED, o.LATITUDE, o.LONGITUDE
 from v_order_status_ax o, v_purchase_orders_ax p
 where o.ID (+)= p.ID;


