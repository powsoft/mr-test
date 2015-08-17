using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using log4net;
using MaintenanceRequestLibrary.util;

namespace MaintenanceRequestLibrary
{

    class Logger
    {

        private static List<LogListener> listeners;
        private static readonly ILog defaultLog;
        static Logger()
        {
            log4net.Config.XmlConfigurator.Configure();
            listeners = new List<LogListener>();
            defaultLog = LogManager.GetLogger("default");
        }

        public static void Log(string errorMessage, Exception exception)
        {
            defaultLog.Error(errorMessage, exception);
            foreach (LogListener listener in listeners)
            {
                listener.logEvent(errorMessage, exception);
            }
        }

        public static void Log(string message)
        {
            defaultLog.Info(message);

            foreach (LogListener listener in listeners)
            {
                listener.logEvent(message, null);
            }
        }

        public static void registerLogListener(LogListener listener)
        {
            listeners.Add(listener);
        }

    }
}
