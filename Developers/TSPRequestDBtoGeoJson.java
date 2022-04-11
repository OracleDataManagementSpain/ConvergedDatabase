import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;

import org.json.simple.JSONObject;
import org.json.simple.JSONValue;
import org.json.simple.JSONArray;
import org.json.simple.parser.JSONParser;

import java.sql.*;
import oracle.jdbc.*;


public class TSPRequestDBtoGeoJson {

    public static Clob getGeoJson(String start_loc, String loc_2,String loc_3) throws Exception{

     
        Connection conn = DriverManager.getConnection("jdbc:default:connection:"); 	
    	
    	String [] start_loc_arr = start_loc.split(";");
    	start_street=start_loc_arr[0];
   	    start_city=start_loc_arr[1];
   	    start_postalcode=start_loc_arr[2];
    	start_region=start_loc_arr[3];
 
    	String [] loc_2_arr = loc_2.split(";");
    	loc_2_street=loc_2_arr[0];
    	loc_2_city=loc_2_arr[1];
   	    loc_2_postalcode=loc_2_arr[2];
   	    loc_2_region=loc_2_arr[3];    	
  	
    	String [] loc_3_arr = loc_3.split(";");
    	loc_3_street=loc_3_arr[0];
    	loc_3_city=loc_3_arr[1];
   	    loc_3_postalcode=loc_3_arr[2];
  	    loc_3_region=loc_3_arr[3];    	

		URL url = new URL("http://maps.oracle.com/elocation/route");
		URLConnection con = url.openConnection();
		HttpURLConnection http = (HttpURLConnection)con;
		http.setRequestMethod("POST"); 
		http.setDoOutput(true);

		String body = "xml_request=<?xml version=\"1.0\" standalone=\"yes\"?>"
				+ "<route_request id=\"48\" route_type=\"closed\" optimize_route=\"true\" return_driving_directions=\"false\" "
				+ "return_route_geometry=\"true\" return_subroute_geometry=\"false\" distance_unit=\"kilometer\">"
				+ "<start_location><input_location id=\"1\"><input_address><gen_form country=\"Spain\" street=\""+start_street+"\" region=\""+start_region+"\" postal_code=\""+start_postalcode+"\" city=\""+start_city+"\"/></input_address></input_location></start_location>"
				      + "<location><input_location id=\"2\"><input_address><gen_form country=\"Spain\" street=\""+loc_2_street+"\" region=\""+loc_2_region+"\" postal_code=\""+loc_2_postalcode+"\" city=\""+loc_2_city+"\"/></input_address></input_location></location>"
				      + "<location><input_location id=\"3\"><input_address><gen_form country=\"Spain\" street=\""+loc_3_street+"\" region=\""+loc_3_region+"\" postal_code=\""+loc_3_postalcode+"\" city=\""+loc_3_city+"\"/></input_address></input_location></location>"
				+ "</route_request>&format=JSON";
		
		byte[] postData = body.getBytes(StandardCharsets.UTF_8);

		int length = postData.length;

		http.setFixedLengthStreamingMode(length);
		http.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
		http.connect();
		try(OutputStream os = http.getOutputStream()) {
			os.write(postData);
		}   

		try (InputStream is =http.getInputStream()) {
			StringBuilder sb = new StringBuilder();
			for (int ch; (ch = is.read()) != -1; ) {
				sb.append((char) ch);
			}

			
			JSONParser parser = new JSONParser();
			JSONArray route = (JSONArray) parser.parse(sb.toString());
			JSONObject points = (JSONObject) route.get(0);
			String coordetaes = points.get("routeGeom").toString();
			String dist = points.get("dist").toString();
			String distUnit = points.get("distUnit").toString();
			String time = points.get("time").toString();
			String timeUnit = points.get("timeUnit").toString();
			coordetaes = coordetaes.replaceAll("[^0-9,.-]","");
			
			String [] coords = coordetaes.split(",");
			

			JSONArray coordinates = new JSONArray();
			String line = new String();
			for (int i = 0; i < coords.length; i=i+2)
			{
				JSONArray p = new JSONArray();
				p.add(Float.parseFloat(coords[i]));
				p.add(Float.parseFloat(coords[i+1]));
				coordinates.add(p);
			}
			
			Map geometry = new LinkedHashMap();
			geometry.put("type", "LineString");
			geometry.put("coordinates", coordinates);
			
			
			Map properties = new LinkedHashMap();
			properties.put("dist", dist);
			properties.put("distUnit", distUnit);
			properties.put("time", time);
			properties.put("timeUnit", timeUnit);
			properties.put("generatedby", "oracle route engine");
			properties.put("workshop", "developers");
			
			Map feature = new LinkedHashMap();
			feature.put("type", "Feature");
			feature.put("properties", properties);
			feature.put("geometry", geometry);
			
			JSONArray features = new JSONArray();
			features.add(feature);
			
			Map geojson = new LinkedHashMap();
			geojson.put("type", "FeatureCollection");
			geojson.put("features",features);
			
			String g = JSONValue.toJSONString(geojson);
			Clob myClob = conn.createClob();
			myClob.setString(1,g);

			return myClob;
			
		}


	}
	
	
}

