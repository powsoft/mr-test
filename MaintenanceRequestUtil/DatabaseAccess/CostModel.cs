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
        public String partnerId;
        public String partnerName;
        public String priceChangeCode;

        public String requestStatus;
        public int requestTypeId;
        public int storeContextId;
        public int storeIdentifier;
        public int syncToRetailer;

        public String banner;

        public decimal cost;
        public int pdiParticipant;

        public string upc;

        public CostModel(string token)
        {
            partnerId = "ACME" + token.Substring(0, 5);
            partnerName = "ACME Corp " + token.Substring(0, 5);
            priceChangeCode = "A";
            storeContextId = 1;
            requestTypeId = 1;
            syncToRetailer = 1;
            cost = 1.0M;
            pdiParticipant = 1;
            upc = System.Guid.NewGuid().ToString();
            requestStatus = "1";
        }



    }
}
