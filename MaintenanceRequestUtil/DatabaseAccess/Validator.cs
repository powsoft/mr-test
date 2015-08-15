using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MaintenanceRequestLibrary
{
    public class Validator
    {
        public int EDItoMRTableCount(string upc)
        {
            string query = string.Format("SELECT count(*) FROM DataTrue_EDI..costs c " +
            "LEFT OUTER JOIN maintenancerequests m " +
            "ON RecordID = datatrue_edi_costs_recordid WHERE UPC = '{0}';", upc);

            return new DatabaseAction().execute(query, MRDatabase.EDI);
        }

    }
}
