using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace MaintenanceRequestLibrary.ui
{
    public partial class UI : Form
    {
        public UI()
        {
            InitializeComponent();

            //TODO: see if I can add a watcher on the stored procedures.
        }

        private void runJobBtn_Click(object sender, EventArgs e)
        {
            //Update stored procedures
            ExecuteCommand("../../sql/update_stored_procedures.bat");

            //Run the jobs!
            new MRJobManager().runMRJobs();
        }

        static void ExecuteCommand(string target)
        {
            int timeout = 10;

            try {
                Process proc = new Process();
                proc.StartInfo.FileName = target;
                proc.StartInfo.RedirectStandardError = true;
                proc.StartInfo.RedirectStandardOutput = true;
                proc.StartInfo.UseShellExecute = false;

                proc.Start();

                proc.WaitForExit
                    (
                        (timeout <= 0)
                            ? int.MaxValue : timeout * 1000 * 60
                    );

                Logger.Log(proc.StandardError.ReadToEnd());
                proc.WaitForExit();

                Logger.Log(proc.StandardOutput.ReadToEnd());
                proc.WaitForExit();
            }
            catch(Exception e)
            {
                Logger.Log("Error running stored procedure update", e);
            }
        }

        private void logBox_SelectedIndexChanged(object sender, EventArgs e)
        {

        }
    }
}
