using MaintenanceRequestLibrary.Database;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Configuration;

namespace MaintenanceRequestLibrary
{

    public class DatabaseAction
    {
        public static string getConnectionString(string database)
        {

            return string.Format("Server=localhost;Database={0};Trusted_Connection=yes;", database);
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Security", "CA2100:Review SQL queries for security vulnerabilities")]
        public int execute(string statement, string database)
        {

            try
            {
                using (SqlConnection sqlConnection = new SqlConnection(getConnectionString(database)))
                {
                    SqlCommand command = new SqlCommand(statement, sqlConnection);

                    sqlConnection.Open();
                    return command.ExecuteNonQuery();
                }
            }
            catch (Exception e)
            {
                Console.WriteLine(e);
            }
            return 0;
        }

    }
}