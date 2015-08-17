using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MaintenanceRequestLibrary.util
{
    public interface LogListener
    {
         void logEvent(string ev, Exception e);
    }
}
