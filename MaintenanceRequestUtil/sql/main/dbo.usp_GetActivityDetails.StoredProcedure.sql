USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetActivityDetails]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec usp_GetActivityDetails 'Regulated','79370'
CREATE procedure [dbo].[usp_GetActivityDetails]
 @Category varchar(20),
 @ChainId varchar(10)
as
Begin
Declare @sqlQuery varchar(max)

	if(@Category='Regulated')
	  begin 
		set @sqlQuery = 'select c.ChainIdentifier,ChainName, COUNT(distinct StoreID)StoreCnt,COUNT(distinct i.supplierid)SupplierCnt
								from InvoiceDetails i with (index(6))
								join Chains c on i.ChainID = c.ChainID
								join Suppliers s on i.SupplierID = s.SupplierID
								where i.DateTimeCreated > GETDATE()-60 and s.IsRegulated = 1'
		if(@ChainId<>'-1') 
			set @sqlQuery = @sqlQuery +  ' and c.ChainID = ' + @ChainId	
			
		set @sqlQuery = @sqlQuery +  ' group by chainname, c.ChainIdentifier order by ChainName'
												--option (hash join,hash group,maxdop 0)'						
	  end	
	  						
	else if(@Category='Newspaper') 
	  begin
		set @sqlQuery = 'select c.ChainIdentifier,ChainName, COUNT(distinct i.StoreID)StoreCnt,COUNT(distinct i.supplierid)SupplierCnt
								from InvoiceDetails i  with (index(6))
								join Chains c on i.ChainID = c.ChainID
								join Suppliers s on i.SupplierID = s.SupplierID
								join stores st on i.StoreID=st.StoreID
								where i.DateTimeCreated>GETDATE()-60 and RecordType=2
								and s.SupplierName != ''DEFAULT''
								and st.StoreName != ''DEFAULT'''
		if(@ChainId<>'-1') 
			set @sqlQuery = @sqlQuery +  ' and c.ChainID = ' + @ChainId		
			
		set @sqlQuery = @sqlQuery +  ' group by c.ChainIdentifier,ChainName order by ChainName'
												--option (hash join,hash group,maxdop 0) '					
	 End	
	 						
	else if(@Category='SBT') 
	  begin
		set @sqlQuery = 'select c.ChainIdentifier,ChainName, COUNT(distinct i.StoreID)StoreCnt,COUNT(distinct i.supplierid)SupplierCnt
								from InvoiceDetails i  with (index(6))
								join Chains c on i.ChainID = c.ChainID
								join Suppliers s on i.SupplierID = s.SupplierID
								join stores st on i.StoreID=st.StoreID
								join ProductIdentifiers p on i.ProductID=p.ProductID
								where i.DateTimeCreated>=GETDATE()-60
								and isnulL(RecordType,0) =0 and s.IsRegulated=0
								and p.ProductIdentifierTypeID=2
								and s.SupplierName != ''DEFAULT''
								and st.StoreName != ''DEFAULT''
								and c.ChainIdentifier != ''BUCEES'''	
	   if(@ChainId<>'-1') 
			set @sqlQuery = @sqlQuery +  ' and c.ChainID = ' + @ChainId		
			
		set @sqlQuery = @sqlQuery +  ' group by c.ChainIdentifier,ChainName order by ChainName'
												--option (hash join,hash group,maxdop 0)'						
	 End
	 
	else
	  begin
		set @sqlQuery ='select  c.ChainIdentifier,ChainName, COUNT(distinct StoreID)StoreCnt,COUNT(distinct i.supplierid)SupplierCnt
								from InvoiceDetails i with (index(6))
								join Chains c on i.ChainID = c.ChainID
								join Suppliers s on i.SupplierID = s.SupplierID
								join Memberships as m on m.OrganizationEntityID = i.ChainID and m.MemberEntityID = i.SupplierID
								where i.DateTimeCreated > GETDATE()-60
								and s.IsRegulated = 0
								and s.SupplierName != ''DEFAULT''
								and m.MembershipTypeID = 14'	
	  if(@ChainId<>'-1') 
			set @sqlQuery = @sqlQuery +  ' and c.ChainID = ' + @ChainId		
			
		set @sqlQuery = @sqlQuery +  ' group by chainname, c.ChainIdentifier order by ChainName'
												--option (hash join,hash group,maxdop 0)'									
	End	
print(@sqlQuery)	
exec(@sqlQuery)		
End
GO
