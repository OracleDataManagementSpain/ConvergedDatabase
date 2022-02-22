import java.sql.Connection;
import oracle.pg.rdbms.pgql.PgqlConnection; 
import oracle.pg.rdbms.pgql.PgqlResultSet; 
import oracle.pg.rdbms.pgql.PgqlStatement;
import oracle.ucp.jdbc.PoolDataSourceFactory; 
import oracle.ucp.jdbc.PoolDataSource;

public class PgqlQuery
{

  public static void main(String[] args) throws Exception
  {
    int idx=0;
    String host               = "localhost";
    String port               = "1521";
    String sid                = "app_root";
    String user               = "soe";
    String password           = "soe";
    String graph              = "GRAFO1";

    Connection conn = null;
    PgqlStatement ps = null;
    PgqlResultSet rs = null;

    try {

      //Get a jdbc connection
      PoolDataSource  pds = PoolDataSourceFactory.getPoolDataSource();
      pds.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
      pds.setURL("jdbc:oracle:thin:@"+host+":"+port +"/"+sid);
      pds.setUser(user);
      pds.setPassword(password);
      conn = pds.getConnection();

      // Get a PGQL connection
      PgqlConnection pgqlConn = PgqlConnection.getConnection(conn);
      pgqlConn.setGraph(graph);

      // Create a PgqlStatement
      ps = pgqlConn.createStatement();

      // Execute query to get a PgqlResultSet object
      String pgql = "select c1.CUST_FIRST_NAME, c1.CUST_LAST_NAME "+
                     "FROM MATCH (c:CUSTOMER)->(:ORDER)-[:HAS_PRODUCT]->(p:PRODUCT) ON GRAFO1, "+
                          "MATCH (c1:CUSTOMER)->(:ORDER)-[:HAS_PRODUCT]->(p:PRODUCT) ON GRAFO1 "+
                     "WHERE c.CUSTOMER_ID=1 AND c.CUSTOMER_ID <> c1.CUSTOMER_ID  "+
                     "GROUP BY c1 ORDER BY count(DISTINCT p) DESC LIMIT 10";

      rs = ps.executeQuery(pgql, /* query string */
                           ""    /* options */);

      // Print the results
      rs.print();
    }
    finally {
      // close the result set
      if (rs != null) {
        rs.close();
      }
      // close the statement
      if (ps != null) {
        ps.close();
      }
      // close the connection
      if (conn != null) {
        conn.close();
      }
    }
  }
}

