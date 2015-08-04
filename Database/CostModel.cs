using MaintenanceRequestLibrary.Database;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MaintenanceRequestLibrary
{
    public class CostModel
    {
        String partnerId;
        String partnerName;
        String priceChangeCode;

        String requestStatus;
        int requestTypeId;
        int storeContextId;
        Boolean syncToRetailer;

        decimal cost;
        Boolean pdiParticipant;
        private string p;

        public CostModel()
        {

        }

        public CostModel(string token)
        {
            partnerId = "ACME" + token.Substring(0, 5);
            partnerName = "ACME Corp " + token.Substring(0, 5);
            priceChangeCode = "A";
            storeContextId = 1;
            requestTypeId = 1;
            syncToRetailer = true;
            cost = 1.0M;
            pdiParticipant = true;
            
        }

    }
}
