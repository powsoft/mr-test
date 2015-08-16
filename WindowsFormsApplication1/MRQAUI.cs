using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

using MaintenanceRequestLibrary;

namespace WindowsFormsApplication1
{
    public partial class MRQAUI : Form
    {
        public MRQAUI()
        {
            InitializeComponent();
        }

        private void button1_Click(object sender, EventArgs e)
        {
            new MRJobManager().runMRJobs();
        }

        private void MRQAUI_Load(object sender, EventArgs e)
        {

        }
    }
}
