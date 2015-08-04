USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_GetPendingPaymentsByWeeksOut_new]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[amb_GetPendingPaymentsByWeeksOut_new]
(
   @ChainID varchar(50),
   @SupplierID varchar(50),
   @NoWeeksOut varchar(20),
   @Amount varchar(20)
)
AS
--amb_GetPendingPaymentsByWeeksOut_New '65232','-1','8',''
Begin
	Declare @SqlQuery varchar(4000)='';
	Set @SqlQuery=' SELECT P.ChainId,P.SupplierID,P.ChainName, P.SupplierName, P.SupplierIdentifier as [Vendor ID],
						P.[PendingPayment] as [Pending Payment], 
						A.AvgWeeklyBilling as [Avg Weekly Billing], 
						(P.[PendingPayment]/ A.AvgWeeklyBilling) as [# of Weeks Out]
						from PendingSupplierPayments P
						inner JOIN Avgweeklybilling A ON P.ChainId=A.ChainId and P.SupplierId=A.SupplierID
						where 1=1 '							
	 if(@ChainID<>'-1')
		Set @SqlQuery=@SqlQuery+' AND P.ChainId = '+ @ChainID
		
	 if(@SupplierID<>'-1')
		Set @SqlQuery=@SqlQuery+' AND P.SupplierID = '+ @SupplierID
		
	 if(@NoWeeksOut<>'')
	    Set @SqlQuery=@SqlQuery+' and (P.[PendingPayment]/ A.AvgWeeklyBilling) > ' + @NoWeeksOut
	    				
	 if(@Amount<>'')
	    Set @SqlQuery=@SqlQuery+' and abs([PendingPayment]) < ' + @Amount 
	    
		Set @SqlQuery=@SqlQuery+' order by 6 desc'  
	  
	  print(@SqlQuery);
	  exec(@SqlQuery);   
End
GO
