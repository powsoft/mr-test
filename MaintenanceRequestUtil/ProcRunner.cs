using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Configuration;

namespace MaintenanceRequestLibrary
{
    public class ProcRunner
    {
        public string executeProcedure(String procedureName, SortedDictionary<String, Object> procParms )
        {


            string dbPass = ConfigurationManager.AppSettings.Get("db_host");


            using (var conn = new SqlConnection(DatabaseAction.getConnectionString(MRDatabase.Main)))
            using (var command = new SqlCommand(procedureName, conn)
            {
                CommandType = CommandType.StoredProcedure
            })
            {
                foreach (KeyValuePair<string, Object> param in procParms)
                {
                    command.Parameters.Add(new SqlParameter(param.Key, param.Value));
                }

                conn.Open();
                command.ExecuteNonQuery();
                conn.Close();
            }

            return null;
        }
    }

}
