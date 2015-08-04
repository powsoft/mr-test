USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Get_DisputeResolutionList]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [usp_Get_DisputeResolutionList] 50964,'-1','','','Receiving'

CREATE procedure [dbo].[usp_Get_DisputeResolutionList]
 @ChainId varchar(5),
 @StoreId varchar(5),
 @ProductIdentifier varchar(50),
 @Status varchar(50),
 @WhoseRecordsAreCorrect varchar(50)
as
 
Begin
 Declare @sqlQuery varchar(4000)
 
 set @sqlQuery = ' Select
						D.ReconcileId 
						,S.StoreIdentifier as [Store Number]
						,P.IdentifierValue as UPC
						,D.Old_Qnt as  [Distributor Qty]
						,cast(D.Old_Cost as numeric(10,2)) as [Distributor Cost]
						,D.Old_Qnt*cast(D.Old_Cost as numeric(10,2)) as [Distributor Amount]
						,D.New_Qnt as [Receiving Qty] 
						,cast(D.New_Cost as numeric(10,2)) as [Receiving Cost]
						,D.New_Qnt*cast(D.New_Cost as numeric(10,2)) as [Receiving Amount]
						,cast(D.PostOffValue as numeric(10,2)) as PostOff
						,D.CorrectRecord as [WhoseRecordsAreCorrect]
						,cast(D.DifferenceAmount as numeric(10,2)) as Differential
					From
						DisputeResolution as D 
						Inner join Stores As S on S.StoreId=D.StoreId
						Inner join ProductIdentifiers as P on P.ProductId=D.ProductId and P.ProductIdentifierTypeId=2
						Inner Join Chains as C on  C.ChainID=S.ChainID
					Where 1=1  ' 
                
 if(@ChainId<>'-1')
	set @sqlQuery = @sqlQuery +  ' and C.ChainID=' + @ChainID
	
 if(@StoreId<>'-1')
	set @sqlQuery = @sqlQuery + ' and S.StoreId=' + @StoreId
 
 if(@ProductIdentifier<>'')
	set @sqlQuery = @sqlQuery + ' and P.IdentifierValue like ''%' + @ProductIdentifier + '%''' 
	
 if(@WhoseRecordsAreCorrect<>'All')
	set @sqlQuery = @sqlQuery + ' and D.CorrectRecord='''+ @WhoseRecordsAreCorrect +''''
 
 if(@Status<>'-1' or @Status<>'All')
	 begin
		if(upper(@Status)=upper('Pending'))
			set @sqlQuery = @sqlQuery + ' and D.PaymentProcessed=0 and D.SupplierDecision is null '
			
		if(upper(@Status)=upper('Rejected'))
			set @sqlQuery = @sqlQuery + ' and D.PaymentProcessed=0 and D.SupplierDecision=1 '
			
		if(upper(@Status)=upper('Approved'))
			set @sqlQuery = @sqlQuery + ' and D.PaymentProcessed=0 and D.SupplierDecision=2 '
			
		if(upper(@Status)=upper('Processed'))
			set @sqlQuery = @sqlQuery + ' and D.PaymentProcessed=1 '
	 end

--print @sqlQuery 
execute(@sqlQuery);
 
End
GO
