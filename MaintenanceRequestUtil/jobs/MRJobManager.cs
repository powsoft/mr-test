using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;
using System.Data.SqlClient;
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

        private Dictionary<int, string> jobSteps = new Dictionary<int, string>()
        {
            //TODO: Build this by hooking to .71 and getting the jobs.
            {1, "prMR_process_Populate_PDI_CHAIN_SUPPLIER_RELATIONS"},
            {2, "prMaintenanceRequest_BEFORE_POCESS_COSTS_PROMOTIONS_REC_2014fab03"},
            {3, "prUtil_MaintenanceRequest_EDICosts_Load_Newspapers_jun"},
            {4, "prUtil_EDIPromotions_Load_To_MaintenanceRequests_ByStore_New_rule_jun"},
            {5, "prUtil_EDIPromotions_Load_To_MaintenanceRequests_ZoneOrBanner_Job_New_jun"},
            {6, "prUtil_MaintenanceRequest_EDICosts_Load_job_storeLevel_jun"},
            {7, "prUtil_MaintenanceRequest_EDICosts_Load_job_New_Rule_jun"},
            {8, "prUtil_EDIPromotions_Load_To_MaintenanceRequests_ByStore_New_PDI_jun"},
            {9, "prUtil_EDIPromotions_Load_To_MaintenanceRequests_ZoneOrBanner_Job_New_PDI_jun"},
            {10, "prUtil_MaintenanceRequest_EDICosts_Load_Job_StoreLevel_PDI_jun"},
            {11, "prUtil_MaintenanceRequest_EDICosts_Load_Job_Rule_PDI_jun"},
            {12, "prMaintenanceRequest_NOT_MOVED_EMAIL_2014fab03"},
            {13, "prMaintenanceRequest_SupplierLoginID_Populate"}

        };

        public void runMRJobs()
        {
            ProcRunner procedureRunner = new ProcRunner();
            foreach(KeyValuePair<int, string> proc in jobSteps) {

                //Track the duration of the stored procedure.
                DateTime startTime = new DateTime();
                Logger.Log("Running Procedule #" + proc.Key + " : " + proc.Value);

                //Executes a stored procedure
                int res = procedureRunner.executeProcedure(
                    proc.Value, new SortedDictionary<string, object>());

                //Log result
                Logger.Log("Complete" + proc.Key +
                         ": Total MS: " + new DateTime().Subtract(startTime).TotalMilliseconds +
                         " Total affected rows: " + res);
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
