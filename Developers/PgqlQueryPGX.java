import oracle.pgx.api.*;
import oracle.pg.rdbms.*;


public class PgqlQueryPGX
{

  public static void main(String[] args) throws Exception
  {
    int idx=0;
    String host               = "localhost";
    String port               = "7007";
    String sid                = "app_root";
    String user               = "soe";
    String password           = "soe";
    String graph              = "GRAFO1";

    PgxSession session = null;
    PgxGraph g = null;
    PgqlResultSet resultSet = null;


    try {
      System.out.println("Conectando...");
      ServerInstance instance = GraphServer.getInstance("https://"+host+":"+port,user,password.toCharArray()); 
      session = instance.createSession("developers-workshop-session");

      System.out.println("Leyendo datos...");
      g = session.readGraphByName(graph,GraphSource.PG_VIEW);

      // Execute query to get a PgqlResultSet object
      String pgql = "select c1.CUST_FIRST_NAME, c1.CUST_LAST_NAME "+
                     "FROM MATCH (c:CUSTOMER)->(:ORDER)-[:HAS_PRODUCT]->(p:PRODUCT), "+
                          "MATCH (c1:CUSTOMER)->(:ORDER)-[:HAS_PRODUCT]->(p:PRODUCT) "+
                     "WHERE c.CUSTOMER_ID=1 AND c.CUSTOMER_ID <> c1.CUSTOMER_ID  "+
                     "GROUP BY c1 ORDER BY count(DISTINCT p) DESC LIMIT 10";

      System.out.println("Ejecutando consulta...");
      resultSet = g.queryPgql(pgql);


      // Print the results
      System.out.println("Lista de clientes a recomendar productos");
      resultSet.print();
    }
    finally {
      // close the result set
      if (resultSet != null) {
        resultSet.close();
      }
      // destroy the graph
      if (g != null) {
        g.destroy();
      }
      // close the session
      if (session != null) {
        session.close();
      }
    }
  }
}

