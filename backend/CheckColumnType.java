import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

public class CheckColumnType {
    public static void main(String[] args) {
        String url = "jdbc:sqlserver://192.168.3.31:1433;databaseName=ASSETS;encrypt=true;trustServerCertificate=true";
        String user = "fongyisa";
        String password = "F0ngY!$@";
        try (Connection con = DriverManager.getConnection(url, user, password);
                Statement stmt = con.createStatement();
                ResultSet rs = stmt.executeQuery("SELECT TOP 5 ID, DEP_NO FROM baccount_DEPT")) {
            while (rs.next()) {
                System.out.println("ID=" + rs.getString("ID") + ", DEP_NO=" + rs.getString("DEP_NO"));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
