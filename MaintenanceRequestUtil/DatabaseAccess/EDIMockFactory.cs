using MaintenanceRequestLibrary.Database;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MaintenanceRequestLibrary
{
    public class EDIMockFactory : InsertAction
    {

        public static string createCostRecord(CostModel model)
        {
            return string.Format("INSERT [dbo].[costs] ([PartnerIdentifier], [PartnerName], [PartnerDuns], [PartnerAddress], [PartnerCity], [PartnerState], [PartnerZip], [PriceChangeCode], [Banner], [StoreIdentifier], [StoreName], [StoreAddress], [StoreCity], [StoreState], [StoreZip], [PricingMarket], [AllStores], [Cost], [SuggRetail], [RawProductIdentifier], [ProductIdentifier], [ProductName], [ProcessDate], [ProcessTime], [EffectiveDate], [EndDate], [FirstOrderDate], [FirstShipDate], [FirstArrivalDate], [MarketAccount], [MarketAccountDescription], [PriceBracket], [UOM], [PrePriced], [Qty], [StoreNumber], [unitweight], [weightqualifier], [weightunitcode], [FileName], [DateCreated], [PriceListNumber], [RecordStatus], [dtchainid], [dtstoreid], [dtproductid], [dtbrandid], [dtsupplierid], [dtbanner], [dtstorecontexttypeid], [dtmaintenancerequestid], [Recordsource], [SentToRetailer], [DateSentToRetailer], [dtcostzoneid], [TempNeedToSend], [dtpromoallowance], [ProductNameReceived], [Deleted], [ApprovalDateTime], [Approved], [BrandIdentifier], [ChainLoginID], [CurrentSetupCost], [datetimecreated], [DealNumber], [DeleteDateTime], [DeleteLoginId], [DeleteReason], [DenialReason], [EmailGeneratedToSupplier], [EmailGeneratedToSupplierDateTime], [RequestStatus], [RequestTypeID], [Skip_879_889_Conversion_ProcessCompleted], [SkipPopulating879_889Records], [SubmitDateTime], [SupplierLoginID], [ProductCategory], [ActualEffectiveDateSent], [PrimaryGroupLevel], [AlternateGroupLevel], [ItemGroup], [AlternateItemGroup], [Size], [ManufacturerIdentifier], [SellPkgVINAllowReorder], [SellPkgVINAllowReClaim], [PrimarySellablePkgIdentifier], [VIN], [VINDescription], [PurchPackDescription], [PurchPackQty], [SellablePackageQty], [AltSellPackage1], [AltSellPackage1Qty], [AltSellPackage1UPC], [AltSellPackage1Retail], [AltSellPackage2], [AltSellPackage2Qty], [AltSellPackage2UPC], [AltSellPackage2Retail], [AltSellPackage3], [AltSellPackage3Qty], [AltSellPackage3UPC], [AltSellPackage3Retail], [PDIParticipant], [OldUPC], [InvoiceNo], [StoreDuns], [OldVIN], [OldVINDescription], [ReplaceUPC], [StoreGLN], [SupplierIdentifier], [ChainIdentifier], [ProductIdentifierType], [Bipad], [OwnerMarketID], [SupplierPackageID], [FileType], [GTIN]) " +
                                            "VALUES ('{0}', N'{1}', N'556370831', NULL, NULL, NULL, NULL, N'{2}', N'{3}', N'{4}', N'iACME Test Store', NULL, NULL, NULL, NULL, N'006', N'1', {5}, N'4.99', N'071896441659   ', N'071896441659   ', N'NFL MAGAZINE', N'20120504', NULL, CAST(0x0000A04600000000 AS DateTime), NULL, NULL, NULL, NULL, NULL, NULL, NULL, N'EA', NULL, N'1', NULL, NULL, NULL, NULL, N'TestingApplication', N'May 16 2012 11:02AM', N'046757696', {6}, 40393, NULL, 21235, NULL, 41440, N'Albertsons - ACME', NULL, NULL, NULL, 3, NULL, NULL, 0, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)", model.partnerId, model.partnerName, model.priceChangeCode, model.banner, model.storeIdentifier, model.cost, model.requestStatus, model.syncToRetailer);
        }
    }
}
