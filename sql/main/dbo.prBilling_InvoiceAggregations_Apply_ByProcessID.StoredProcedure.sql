USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_InvoiceAggregations_Apply_ByProcessID]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prBilling_InvoiceAggregations_Apply_ByProcessID]
@chainid int, 
@entityidtoinvoice int,
@ProcessID INT
as

DECLARE @invoiceaggregationid INT
			
INSERT INTO [DataTrue_EDI].[dbo].[Aggregations]
   ([AggregationTypeID]
   ,[AggregationValue])
VALUES
   (1 --<AggregationTypeID, int,>
   ,'') --<AggregationValue, nvarchar(50),>)

set @invoiceaggregationid = SCOPE_IDENTITY()

update [DataTrue_EDI].[dbo].[Aggregations]
set AggregationValue = CAST(@invoiceaggregationid as nvarchar(50))
where AggregationID = @invoiceaggregationid

update datatrue_main.dbo.InvoicesRetailer		--select * from datatrue_main.dbo.InvoicesRetailer
set AggregationID = @invoiceaggregationid
where RetailerInvoiceID in
(select RetailerInvoiceID from datatrue_main.dbo.InvoicesRetailer where chainid = @chainid and ProcessID = @ProcessID and AggregationID is null)
--(Select distinct RetailerInvoiceID from InvoiceDetails where InvoiceDetailID in (select distinct InvoiceDetailID from #invoicedetailstopay))

update datatrue_edi.dbo.InvoicesRetailer
set AggregationID = @invoiceaggregationid
where RetailerInvoiceID in
(select RetailerInvoiceID from datatrue_main.dbo.InvoicesRetailer where chainid = @chainid AND ProcessID = @ProcessID and AggregationID is null)
--(Select distinct RetailerInvoiceID from InvoiceDetails where InvoiceDetailID in (select distinct InvoiceDetailID from #invoicedetailstopay))			
					
return
GO
