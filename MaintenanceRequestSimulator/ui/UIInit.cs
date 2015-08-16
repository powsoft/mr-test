using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

using log4net;

namespace MaintenanceRequestLibrary.ui
{
    class UIInit
    {
        static void Main(string[] args)
        {
            log4net.Config.XmlConfigurator.Configure();

            Logger.Log("Starting Maintenance Request Simulator UI");
            Application.Run(new UI());
        }


    }
}
