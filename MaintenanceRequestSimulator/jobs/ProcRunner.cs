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
        public int executeProcedure(string procedureName, SortedDictionary<String, Object> procParms )
        {
            int affectedRecords = 0;

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
                try {
                    conn.Open();
                    affectedRecords = command.ExecuteNonQuery();
                    conn.Close();
                }
                catch(Exception e)
                {
                    Logger.Log("Exception in: " + procedureName, e);
                }
            }

            return affectedRecords;
        }
    }

}
