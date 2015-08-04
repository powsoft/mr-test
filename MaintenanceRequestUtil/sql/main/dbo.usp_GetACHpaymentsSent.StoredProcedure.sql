USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetACHpaymentsSent]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- usp_GetACHpaymentsSent '-1','-1'
CREATE procedure [dbo].[usp_GetACHpaymentsSent]
 @SupplierId varchar(20),
 @ChainId varchar(20)

 
as

Begin
Declare @sqlQuery varchar(4000)

	set @sqlQuery = ' SELECT RetailerName as [Retailer Name], 
			SupplierName as [Supplier Name],  
			RetailerRoutingNo as [Retailer Routing No], 
			SupplierRoutingNo as [Supplier Routing No],
			SumOfRountingNo as [Sum of Routing No],
			TotalAmt as [Total Amount],
			[Draft/Aggregator number] as [Draft Number],
			TotalNoRecordsSent as [Total Record Sent],
			TotalAmtSent as [Total Amount Sent],
			convert(varchar(10),DateTimeSent, 101) as [Date Sent],
			convert(varchar(10),DateTimeAckReceived, 101) as [Date Ack Received],
			AckAmount as [Account Amount],
			RejectionReasonCode as [Rejection Reason],
			convert(varchar(10),RejectionDate, 101) as [Rejection Date]
			FROM datatrue_edi.dbo.ACHpaymentsSent ACH 
			WHERE 1=1 '
		
	if(@ChainId <>'-1' ) 
		set @sqlQuery = @sqlQuery + ' and ACH.Retailerid = ''' + @ChainId  +''''

	if(@SupplierId <>'-1' ) 
		set @sqlQuery = @sqlQuery + ' and ACH.SupplierID = ''' + @SupplierId +''''		

		
    set @sqlQuery = @sqlQuery + ' order by 1,2,3 asc '

	exec(@sqlQuery); 

End
GO
