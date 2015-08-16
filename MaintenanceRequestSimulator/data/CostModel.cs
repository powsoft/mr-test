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
        public Boolean syncToRetailer;

        public decimal cost;
        public Boolean pdiParticipant;
        public string upc;
        public string banner;
        public string storeIdentifier;

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
