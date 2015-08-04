using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace MaintenanceRequestLibrary
{
    public class MRJobManager
    {
        List<string> MRJobs;

        public MRJobManager()
        {
            MRJobs = new List<string>();
            MRJobs.Add("MaintenanceRequests_ALL_Move_toMR");
            MRJobs.Add("MaintenanceRequests_All_with_PDI_New");
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

        public void runMRJobs()
        {
            foreach (string job in MRJobs)
            {
                initiateJob(job);
                while (getStatus(job).Equals("idle") == false)
                {
                    Thread.Sleep(3000);
                }
            }
        }

        private void initiateJob(string job)
        {
            SqlConnection DbConn = new SqlConnection(DatabaseAction.getConnectionString(MRDatabase.Main));
            SqlCommand ExecJob = new SqlCommand();
            ExecJob.CommandType = CommandType.StoredProcedure;
            ExecJob.CommandText = "msdb.dbo.sp_start_job";
            ExecJob.Parameters.AddWithValue("@job_name", job);

            using (DbConn)
            {
                DbConn.Open();
                using (ExecJob)
                {
                    ExecJob.ExecuteNonQuery();
                }
            }
        }

        private string getStatus(string job)
        {
            SqlConnection msdbConnection = new SqlConnection(DatabaseAction.getConnectionString(MRDatabase.Main));
            System.Text.StringBuilder resultBuilder = new System.Text.StringBuilder();

            try
            {
                msdbConnection.Open();

                SqlCommand jobStatusCommand = msdbConnection.CreateCommand();

                jobStatusCommand.CommandType = CommandType.StoredProcedure;
                jobStatusCommand.CommandText = "sp_help_job";

                SqlParameter jobName = jobStatusCommand.Parameters.Add("@job_name", SqlDbType.VarChar);
                jobName.Direction = ParameterDirection.Input;
                jobName.Value = job;

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
