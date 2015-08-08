USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_ViewPaymentWHLS_20131002]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec amb_ViewPaymentWHLS_20131002 'DQ','09/15/2013','22','CLL','24164'
CREATE procedure [dbo].[amb_ViewPaymentWHLS_20131002]
 @ChainID varchar(10),
 @WeekEnd varchar(20),
 @StoreNumber varchar(10),
 @SupplierIdentifier varchar(20),
 @SupplierId varchar(20)

as
Begin
Declare @sqlQueryNew varchar(8000)
		SET @sqlQueryNew=' select distinct sup.SupplierIdentifier as WholesalerID ,c.ChainIdentifier  as ChainID,Cast(InvoicePeriodEnd as date)  as WeekEnding,
		Cast(pd.DisbursementDate as date) as DateIssued,pd.CheckNo AS CheckNumber,s.LegacySystemStoreIdentifier AS StoreID,i.OriginalAmount  AS SumOfTotalCheck,
		t.InvoiceDetailTypeName AS InvType
		--select *
		from DataTrue_Report.dbo.InvoicesSupplier i join DataTrue_Report.dbo.InvoiceDetails d
		on i.SupplierInvoiceID=d.SupplierInvoiceID
		join DataTrue_Report.dbo.Stores s on s.StoreID=d.StoreID 
		and s.ChainID=d.ChainID
		--join Payments p on p.PaymentID = d.PaymentID
		join DataTrue_Report.dbo.PaymentHistory h on h.PaymentID=d.PaymentID 
		join DataTrue_Report.dbo.PaymentDisbursements pd on pd.DisbursementID=h.DisbursementID
		join DataTrue_Report.dbo.Suppliers sup on sup.SupplierID=i.SupplierID
		join DataTrue_Report.dbo.Chains c on c.ChainID=d.ChainID
		join DataTrue_Report.dbo.InvoiceDetailTypes t on t.InvoiceDetailTypeID=d.InvoiceDetailTypeID
		where 1=1 AND i.SupplierID =''' +@SupplierId +''''
		IF(@ChainID<>'-1')
				SET @sqlQueryNew += ' AND C.ChainIdentifier = ''' + @ChainID+''''
				
		IF(CAST( @WeekEnd as DATE) <> CAST( '1900-01-01' as DATE))
			SET @sqlQueryNew += ' and Cast(InvoicePeriodEnd as date)=''' + @WeekEnd +''''
		
		IF(@StoreNumber<>'')
				SET @sqlQueryNew += ' AND s.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%'''
		
		--and i.SupplierID=24164
		--and s.StoreIdentifier=22
		--and c.ChainIdentifier='DQ'
		
		--SET @sqlQueryNew += ' HAVING 1=1  AND ID.SupplierId=' + @SupplierId 
						
		
		

	
		set @sqlQueryNew=@sqlQueryNew+ ' ORDER BY CheckNumber Desc, StoreID, InvType'
		EXEC(@sqlQueryNew)	
		print(@sqlQueryNew)
End
GO
