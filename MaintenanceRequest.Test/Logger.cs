using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using log4net;

namespace MaintenanceRequestLibrary
{
    class Logger
    {

        private static readonly ILog defaultLog;
        static Logger()
        {
            log4net.Config.XmlConfigurator.Configure();
            defaultLog = LogManager.GetLogger("default");
        }

        public static void Log(string errorMessage, Exception exception)
        {
            defaultLog.Error(errorMessage, exception);
        }
        public static void Log(string errorMessage)
        {
            defaultLog.Info(errorMessage);
        }

        
    }
}
