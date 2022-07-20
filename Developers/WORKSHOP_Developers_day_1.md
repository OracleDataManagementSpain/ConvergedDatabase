## Converged Database: Modern Development Workshop Day 1



# Descripción del entorno del workshop

[oracle@dev21c ~]$ sql soe/soe@localhost:1521/pdb1


SQLcl: Release 21.2 Production on Mon Jan 03 12:30:24 2022

Copyright (c) 1982, 2022, Oracle.  All rights reserved.

Connected to:
Oracle Database 21c Enterprise Edition Release 21.0.0.0.0 - Production
Version 21.3.0.0.0

SQL> select table_name from user_tables;

              TABLE_NAME
________________________
PRODUCT_INFORMATION
LOGON
ORDERS
CARD_DETAILS
INVENTORIES
PRODUCT_DESCRIPTIONS
CUSTOMERS
ORDER_ITEMS
ORDERENTRY_METADATA
ADDRESSES
WAREHOUSES
PURCHASE_ORDERS

12 rows selected.

SQL> exit
Disconnected from Oracle Database 21c Enterprise Edition Release 21.0.0.0.0 - Production
Version 21.3.0.0.0




# Unplug y plug de PDB1 y creación de PDB2.
# Unplug de PDB1 y plug dentro del Application Container

$ sqlplus / as sysdba
SQL> alter pluggable database PDB1 close;
Pluggable database PDB1 altered.

SQL> ALTER PLUGGABLE DATABASE PDB1 UNPLUG INTO '/home/oracle/pdb1.xml';

Pluggable database PDB1 altered.

SQL> DROP PLUGGABLE DATABASE PDB1 KEEP DATAFILES;

Pluggable database PDB1 dropped.

SQL> show pdbs;

    CON_ID CON_NAME                       OPEN MODE  RESTRICTED
---------- ------------------------------ ---------- ----------
         2 PDB$SEED                       READ ONLY  NO
         4 APP_ROOT                       READ WRITE NO




SQL> alter session set container=app_root;

Session altered.

SQL> CREATE PLUGGABLE DATABASE PDB1 USING '/home/oracle/pdb1.xml';

Pluggable database PDB1 created.

SQL> alter pluggable database pdb1 open;

Pluggable database PDB1 altered.
SQL> alter pluggable database pdb1 open;
ORA-24344: success with compilation error
24344. 00000 -  "success with compilation error"
*Cause:    A sql/plsql compilation error occurred.
*Action:   Return OCI_SUCCESS_WITH_INFO along with the error code

Pluggable database PDB1 altered.

SQL> show pdbs;

    CON_ID CON_NAME                       OPEN MODE  RESTRICTED
---------- ------------------------------ ---------- ----------
         4 APP_ROOT                       READ WRITE NO
         5 PDB1                           READ WRITE YES

SQL> select message,time from pdb_plug_in_violations;

                                                                                          MESSAGE                               TIME
_________________________________________________________________________________________________ __________________________________
Database option OML4PY mismatch: PDB installed version NULL. CDB installed version 21.0.0.0.0.    03-JAN-22 01.40.00.155040000 PM
Database option OML4PY mismatch: PDB installed version NULL. CDB installed version 21.0.0.0.0.    03-JAN-22 01.50.26.032530000 PM
Non-Application PDB plugged in as an Application PDB, requires pdb_to_apppdb.sql be run.          03-JAN-22 01.50.26.105950000 PM




SQL> conn sys/Oracle_4U@localhost:1521/pdb1 as sysdba
Connected.
SQL> @?/rdbms/admin/pdb_to_apppdb.sql
[…]
SQL> conn sys/Oracle_4U@localhost:1521/app_root as sysdba
Connected.
SQL> show pdbs

    CON_ID CON_NAME                       OPEN MODE  RESTRICTED
---------- ------------------------------ ---------- ----------
         4 APP_ROOT                       READ WRITE NO
         5 PDB1                           READ WRITE YES

SQL> alter pluggable database pdb1 close;

Pluggable database PDB1 altered.

SQL> alter pluggable database pdb1 open;

Pluggable database PDB1 altered.

SQL> alter pluggable database pdb1 save state;

Pluggable database PDB1 altered.

SQL> show pdbs

    CON_ID CON_NAME                       OPEN MODE  RESTRICTED
---------- ------------------------------ ---------- ----------
         4 APP_ROOT                       READ WRITE NO
         5 PDB1                           READ WRITE NO




# Creación de PDB2 dentro del Application Container

SQL> CREATE PLUGGABLE DATABASE PDB2 ADMIN USER pdbadmin IDENTIFIED BY "Oracle_4U";

Pluggable database PDB2 created.

SQL> alter pluggable database PDB2 open;

Pluggable database PDB2 altered.

SQL> alter pluggable database pdb2 save state;

Pluggable database PDB1 altered.

SQL> show pdbs;

    CON_ID CON_NAME                       OPEN MODE  RESTRICTED
---------- ------------------------------ ---------- ----------
         3 PDB2                           READ WRITE NO
         4 APP_ROOT                       READ WRITE NO
         5 PDB1                           READ WRITE NO

SQL> alter session set container=PDB2;

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

SQL> grant create database link to SOE;

Grant succeeded.

SQL> grant soda_app to SOE;

Grant succeeded.





# Transformación de datos relacionales de App1 en JSON para App2.

DECLARE
    collection  SODA_Collection_T;
BEGIN
    collection := DBMS_SODA.create_collection('PURCHASE_ORDERS');   
END;
/


   select JSON_OBJECT (
      'ORDER_ID' value O.ORDER_ID,
      'ORDER_DATE' value O.ORDER_DATE,
      'ORDER_MODE' value O.ORDER_MODE,
      'CUSTOMER_ID' value O.CUSTOMER_ID,
      'CUSTOMER_NAME' value C.CUST_FIRST_NAME,
      'CUSTOMER_SURNAME' value C.CUST_LAST_NAME,
      'STREET_NAME' value A.STREET_NAME,
      'TOWN' value A.TOWN,
      'ORDER_STATUS' value O.ORDER_STATUS,
      'ORDER_TOTAL' value O.ORDER_TOTAL,
      'WAREHOUSE_ID' value O.WAREHOUSE_ID,
      'DELIVERY_TYPE' value O.DELIVERY_TYPE,
      'CUSTOMER_CLASS' value O.CUSTOMER_CLASS,
      'CARD_ID' value O.CARD_ID,
      'INVOICE_ADDRESS_ID' value O.INVOICE_ADDRESS_ID,
    'ITEMS' value json_arrayagg (
        json_object (
         'ORDER_ID' value  OI.ORDER_ID,
         'LINE_ITEM_ID' value  OI.LINE_ITEM_ID,
         'PRODUCT_ID' value  OI.PRODUCT_ID,
         'UNIT_PRICE' value  OI.UNIT_PRICE,
         'QUANTITY' value  OI.QUANTITY,
         'DISPATCH_DATE' value  OI.DISPATCH_DATE,
         'RETURN_DATE' value  OI.RETURN_DATE,
         'SUPPLIER_ID' value  OI.SUPPLIER_ID,
         'ESTIMATED_DELIVERY' value  OI.ESTIMATED_DELIVERY
    )))
  as jsonorders
 from ORDERS O, order_items OI, CUSTOMERS C, ADDRESSES A
    where O.order_id = OI.order_id and
          O.CUSTOMER_ID = C.CUSTOMER_ID and
          O.DELIVERY_ADDRESS_ID = A.ADDRESS_ID
group by
O.ORDER_ID,
O.ORDER_DATE,
O.ORDER_MODE,
O.CUSTOMER_ID,
C.CUST_FIRST_NAME,
C.CUST_LAST_NAME,
A.STREET_NAME,
A.TOWN,
O.ORDER_STATUS,
O.ORDER_TOTAL,
O.WAREHOUSE_ID,
O.DELIVERY_TYPE,
O.CUSTOMER_CLASS,
O.CARD_ID,
O.INVOICE_ADDRESS_ID;



create database link db_pdb1 connect to soe identified by "soe" using 'localhost:1521/pdb1';


DECLARE
    collection  SODA_COLLECTION_T;
    document    SODA_DOCUMENT_T;
    status      NUMBER;
    CURSOR c_orders IS
   select JSON_OBJECT (
      'ORDER_ID' value O.ORDER_ID,
      'ORDER_DATE' value O.ORDER_DATE,
      'ORDER_MODE' value O.ORDER_MODE,
      'CUSTOMER_ID' value O.CUSTOMER_ID,
      'CUSTOMER_NAME' value C.CUST_FIRST_NAME,
      'CUSTOMER_SURNAME' value C.CUST_LAST_NAME,
      'STREET_NAME' value A.STREET_NAME,
      'TOWN' value A.TOWN,
      'ORDER_STATUS' value O.ORDER_STATUS,
      'ORDER_TOTAL' value O.ORDER_TOTAL,
      'WAREHOUSE_ID' value O.WAREHOUSE_ID,
      'DELIVERY_TYPE' value O.DELIVERY_TYPE,
      'CUSTOMER_CLASS' value O.CUSTOMER_CLASS,
      'CARD_ID' value O.CARD_ID,
      'INVOICE_ADDRESS_ID' value O.INVOICE_ADDRESS_ID,
    'ITEMS' value json_arrayagg (
        json_object (
         'ORDER_ID' value  OI.ORDER_ID,
         'LINE_ITEM_ID' value  OI.LINE_ITEM_ID,
         'PRODUCT_ID' value  OI.PRODUCT_ID,
         'UNIT_PRICE' value  OI.UNIT_PRICE,
         'QUANTITY' value  OI.QUANTITY,
         'DISPATCH_DATE' value  OI.DISPATCH_DATE,
         'RETURN_DATE' value  OI.RETURN_DATE,
         'SUPPLIER_ID' value  OI.SUPPLIER_ID,
         'ESTIMATED_DELIVERY' value  OI.ESTIMATED_DELIVERY
    )))
  as jsonorders
   from ORDERS@db_pdb1 O, order_items@db_pdb1 OI, CUSTOMERS@db_pdb1 C, ADDRESSES@db_pdb1 A
    where O.order_id = OI.order_id and
          O.CUSTOMER_ID = C.CUSTOMER_ID and
          O.DELIVERY_ADDRESS_ID = A.ADDRESS_ID
group by
O.ORDER_ID,
O.ORDER_DATE,
O.ORDER_MODE,
O.CUSTOMER_ID,
C.CUST_FIRST_NAME,
C.CUST_LAST_NAME,
A.STREET_NAME,
A.TOWN,
O.ORDER_STATUS,
O.ORDER_TOTAL,
O.WAREHOUSE_ID,
O.DELIVERY_TYPE,
O.CUSTOMER_CLASS,
O.CARD_ID,
O.INVOICE_ADDRESS_ID;

BEGIN
    -- Open the collection
    collection := DBMS_SODA.open_collection('PURCHASE_ORDERS');

    FOR cur in c_orders
    LOOP
        document := SODA_DOCUMENT_T(b_content => utl_raw.cast_to_raw(cur.jsonorders));
        -- Insert a document
        status := collection.insert_one(document);
    END LOOP;

END;
/

commit;



select j.JSON_DOCUMENT.ORDER_ID, 
       j.JSON_DOCUMENT.CUSTOMER_NAME, 
       j.JSON_DOCUMENT.CUSTOMER_SURNAME,
       j.JSON_DOCUMENT.TOWN.string() AS TOWN
    from PURCHASE_ORDERS j
    where j.JSON_DOCUMENT.CUSTOMER_NAME.string() like 'jo%';


drop database link db_pdb1;


# Despliegue de App2 (NodeJS + SODA) usando PDB2

git clone https://github.com/OracleDataManagementSpain/ConvergedDatabase/


podman build --tag nodeapp-container-oracle .

podman image ls

podman run -it -d --name app2 -p 3000:3000 nodeapp-container-oracle



select j.JSON_DOCUMENT.ORDER_ID, 
       j.JSON_DOCUMENT.CUSTOMER_NAME, 
       j.JSON_DOCUMENT.CUSTOMER_SURNAME,
       j.JSON_DOCUMENT.TOWN.string() AS TOWN
from PURCHASE_ORDERS j
where ID='id único del navegador';




# Consulta combinada de la información de App1 y App2

$ sql sys/Oracle_4U@localhost:1521/app_root as sysdba


SQLcl: Release 21.2 Production on Tue Jan 04 17:59:41 2022

Copyright (c) 1982, 2022, Oracle.  All rights reserved.

Connected to:
Oracle Database 21c Enterprise Edition Release 21.0.0.0.0 - Production
Version 21.3.0.0.0

SQL> create tablespace TBS_SOE datafile size 100M;
Tablespace TBS_SOE created.

SQL> create user SOE identified by soe default tablespace TBS_SOE temporary tablespace TEMP;

User SOE created.

SQL> alter user SOE quota unlimited on TBS_SOE;

User SOE altered.

SQL> grant connect, resource to SOE;

Grant succeeded.

SQL> grant create view to soe;

Grant succeeded.

SQL> grant graph_developer to soe;

Grant succeeded.

SQL> grant soda_app to soe;

Grant succeeded.


SQL> conn soe/soe@localhost:1521/app_root

Connected.

SQL> CREATE TABLE "CUSTOMERS"
      (   "CUSTOMER_ID" NUMBER(12,0) ,
      "CUST_FIRST_NAME" VARCHAR2(40 BYTE),
      "CUST_LAST_NAME" VARCHAR2(40 BYTE),
      "NLS_LANGUAGE" VARCHAR2(3 BYTE),
      "NLS_TERRITORY" VARCHAR2(30 BYTE),
      "CREDIT_LIMIT" NUMBER(9,2),
      "CUST_EMAIL" VARCHAR2(100 BYTE),
      "ACCOUNT_MGR_ID" NUMBER(12,0),
      "CUSTOMER_SINCE" DATE,
      "CUSTOMER_CLASS" VARCHAR2(40 BYTE),
      "SUGGESTIONS" VARCHAR2(40 BYTE),
      "DOB" DATE,
      "MAILSHOT" VARCHAR2(1 BYTE),
      "PARTNER_MAILSHOT" VARCHAR2(1 BYTE),
      "PREFERRED_ADDRESS" NUMBER(12,0),
      "PREFERRED_CARD" NUMBER(12,0)
     );

Table "CUSTOMERS" created.

SQL> select count(*) from CUSTOMERS;

   COUNT(*)
___________
          0


SQL> select count(*) from containers(CUSTOMERS);

   COUNT(*)
___________
        100


SQL> DECLARE
        collection  SODA_Collection_T;
     BEGIN
        collection := DBMS_SODA.create_collection('PURCHASE_ORDERS');
     END;
    /

PL/SQL procedure successfully completed.

SQL> select count(1) from PURCHASE_ORDERS;

   COUNT(1)
___________
          0

SQL> select count(1) from containers(PURCHASE_ORDERS);

   COUNT(1)
___________
          149

SQL> create or replace view V_CUSTOMERS as select * from containers(CUSTOMERS);

View V_CUSTOMERS created.

SQL> create or replace view V_PURCHASE_ORDERS AS select * from containers(PURCHASE_ORDERS);

View V_PURCHASE_ORDERS created.



# Exposición de datos en API REST con ORDS.

ps -ef | grep ords | grep -v grep

http://localhost:8080/ords/soe/v_customers/


curl http://localhost:8080/ords/soe/v_customers/ | jq