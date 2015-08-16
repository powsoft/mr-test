using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MaintenanceRequestLibrary
{
    class SQLJobManager
    {

        public void runMRJobs()
        {
            SqlConnection DbConn = new SqlConnection(new DatabaseAction().getConnectionString());
            SqlCommand ExecJob = new SqlCommand();
            ExecJob.CommandType = CommandType.StoredProcedure;
            ExecJob.CommandText = "msdb.dbo.sp_start_job";
            ExecJob.Parameters.AddWithValue("@job_name", "YourJobName");

            using (DbConn)
            {
                DbConn.Open();
                using (ExecJob)
                {
                    ExecJob.ExecuteNonQuery();
                }
            }
        }

        private Dictionary<int, string> ExecutionStatusDictionary = new Dictionary<int, string>()
    {
        {0, "Not idle or suspended"},
        {1, "Executing"},
        {2, "Waiting for thread"},
        {3, "Between retries"},
        {4, "Idle"},
        {5, "Suspended"},
        {7, "Performing completion actions"}
    };

        public string GetStatus(string nameOfJob)
        {
            SqlConnection msdbConnection = new SqlConnection(new DatabaseAction().getConnectionString());
            System.Text.StringBuilder resultBuilder = new System.Text.StringBuilder();

            try
            {
                msdbConnection.Open();

                SqlCommand jobStatusCommand = msdbConnection.CreateCommand();

                jobStatusCommand.CommandType = CommandType.StoredProcedure;
                jobStatusCommand.CommandText = "sp_help_job";

                SqlParameter jobName = jobStatusCommand.Parameters.Add("@job_name", SqlDbType.VarChar);
                jobName.Direction = ParameterDirection.Input;
                jobName.Value = nameOfJob;

                SqlParameter jobAspect = jobStatusCommand.Parameters.Add("@job_aspect", SqlDbType.VarChar);
                jobAspect.Direction = ParameterDirection.Input;
                jobAspect.Value = "JOB";

                SqlDataReader jobStatusReader = jobStatusCommand.ExecuteReader();

                while (jobStatusReader.Read())
                {
                    resultBuilder.Append(string.Format("{0} {1}",
                        jobStatusReader["name"].ToString(),
                        ExecutionStatusDictionary[(int)jobStatusReader["current_execution_status"]]
                    ));
                }
                jobStatusReader.Close();
            }
            finally
            {
                msdbConnection.Close();
            }

            return resultBuilder.ToString();
        }
    }
}
