USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ShrinkDetail]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_ShrinkDetail]
 @SupplierID varchar(5),
 @ChainId varchar(5),
 @custom1 varchar(255),
 @BrandId varchar(5),
 @TransFromDate varchar(50),
 @TransToDate varchar(50),
 @ProductIdentifierType int,
 @ProductIdentifierValue varchar(50),
 @StoreIdentifierType int,
 @StoreIdentifierValue varchar(50),
 @Others varchar(50)
 
as
Begin
 Declare @sqlQuery varchar(4000)
 
 set @sqlQuery = 'select C.ChainName as [Retailer], SupplierName as [Supplier], ST.Custom1 as Banner, 
					  ST.StoreName as Store, ST.Custom2 as [SBT Number],  ST.StoreIdentifier as [Store No], 
					  P.Description as [Product Desc], I.UPC,
					  convert(varchar(10), I.PhysicalInventoryDate, 101) as [Last Transaction Date],  
					  I.ShrinkUnits as Qty, ''Shrink'' as [Activity Type], 
					  I.SupplierAcctNo as [Supplier Acct Number], '''' as [Driver Name], ''''  as [Route Number]  
				 from InventorySettlementRequests I 
				 inner join Suppliers S on S.SupplierID=I.supplierId
				 inner join Stores ST on ST.StoreID=I.StoreID and ST.ActiveStatus=''Active''
				 inner join Chains C on C.ChainId=ST.ChainId
				 inner join Products P on P.ProductID=I.ProductID 
				 inner join SupplierBanners SB on SB.SupplierId = S.SupplierId and SB.Status=''Active'' and SB.Banner=ST.Custom1 where 1=1 ' 
			 
			 if(@ChainId <>'-1') 
				set @sqlQuery = @sqlQuery +  ' and ST.ChainID=' + @ChainId
		  
			if(@SupplierID <>'-1') 
				set @sqlQuery = @sqlQuery +  ' and I.SupplierId=' + @SupplierId
		 
			if(@custom1='') 
				set @sqlQuery = @sqlQuery + ' and ST.custom1 is Null'
			else if(@custom1<>'-1') 
				set @sqlQuery = @sqlQuery + ' and ST.custom1=''' + @custom1 + ''''
				
			if (convert(date, @TransFromDate  ) > convert(date,'1900-01-01'))
				set @sqlQuery = @sqlQuery + ' and I.PhysicalInventoryDate  >= ''' + @TransFromDate  + ''''
		 
			if(convert(date, @TransToDate ) > convert(date,'1900-01-01')) 
				set @sqlQuery = @sqlQuery + ' and I.PhysicalInventoryDate  <=''' + @TransToDate  + ''''

		 
			if(@ProductIdentifierValue<>'')
				begin
					set @sqlQuery = @sqlQuery + ' and I.UPC like ''%' + @ProductIdentifierValue + '%''';
				end   
		 
			if(@StoreIdentifierValue<>'')
				begin
					-- 1 = Store Number, 2 = SBT Number, 3 = Store Name
					if (@StoreIdentifierType=1)
						set @sqlQuery = @sqlQuery + ' and ST.storeidentifier like ''%' + @StoreIdentifierValue + '%'''
					else if (@StoreIdentifierType=2)
						set @sqlQuery = @sqlQuery + ' and ST.Custom2 like ''%' + @StoreIdentifierValue + '%'''
					else if (@StoreIdentifierType=3)
						set @sqlQuery = @sqlQuery + ' and ST.StoreName like ''%' + @StoreIdentifierValue + '%'''
				end
			
			set @sqlQuery = @sqlQuery + ' Union ALL '
			 
 			set @sqlQuery = @sqlQuery + ' select C.ChainName as [Retailer], I.SupplierName, I.Banner, 
 												ST.StoreName as Store, ST.Custom2 as [SBT Number],  ST.StoreIdentifier as [Store No], 
												P.Description as [Product Desc], I.UPC,
												convert(varchar(10), I.LastInventoryCountDate, 101) as [Last Transaction Date],  
												I.ShrinkUnits as Qty, ''Pending Shrink'' as [Activity Type], 
												I.SupplierAcctNo as [Supplier Acct Number], '''' as [Driver Name], ''''  as [Route Number]  
										 from DataTrue_CustomResultSets.dbo.InventoryReport_New_FactTable_Active I 
										 inner join Stores ST on ST.StoreID=I.StoreID
										  inner join Chains C on C.ChainId=ST.ChainId
										 inner join Products P on P.ProductID=I.ProductID
										 inner join SupplierBanners SB on SB.SupplierId = I.SupplierId and SB.Status=''Active'' and SB.Banner=ST.Custom1
										 where LastInventoryCountDate > (select MAX(PhysicalInventoryDate) from InventorySettlementRequests MR 
																			where I.supplierId=MR.SupplierID and I.StoreID=MR.StoreID 
																			and I.ProductID=MR.ProductID)'
			
			if(@ChainId <>'-1') 
				set @sqlQuery = @sqlQuery +  ' and ST.ChainID=' + @ChainId
		  
			if(@SupplierID <>'-1') 
				set @sqlQuery = @sqlQuery +  ' and I.SupplierId=' + @SupplierId
		 
			if(@custom1='') 
				set @sqlQuery = @sqlQuery + ' and ST.custom1 is Null'
			else if(@custom1<>'-1') 
				set @sqlQuery = @sqlQuery + ' and ST.custom1=''' + @custom1 + ''''
				
			if (convert(date, @TransFromDate  ) > convert(date,'1900-01-01'))
				set @sqlQuery = @sqlQuery + ' and I.LastInventoryCountDate  >= ''' + @TransFromDate  + ''''
		 
			if(convert(date, @TransToDate ) > convert(date,'1900-01-01')) 
				set @sqlQuery = @sqlQuery + ' and I.LastInventoryCountDate  <=''' + @TransToDate  + ''''

		 
			if(@ProductIdentifierValue<>'')
				begin
					set @sqlQuery = @sqlQuery + ' and I.UPC like ''%' + @ProductIdentifierValue + '%''';
				end   
		 
			if(@StoreIdentifierValue<>'')
				begin
					-- 1 = Store Number, 2 = SBT Number, 3 = Store Name
					if (@StoreIdentifierType=1)
						set @sqlQuery = @sqlQuery + ' and ST.storeidentifier like ''%' + @StoreIdentifierValue + '%'''
					else if (@StoreIdentifierType=2)
						set @sqlQuery = @sqlQuery + ' and ST.Custom2 like ''%' + @StoreIdentifierValue + '%'''
					else if (@StoreIdentifierType=3)
						set @sqlQuery = @sqlQuery + ' and ST.StoreName like ''%' + @StoreIdentifierValue + '%'''
				end
				
	 
			set @sqlQuery = @sqlQuery + ' Union ALL '
			 
 			set @sqlQuery = @sqlQuery + ' select C.ChainName as [Retailer], I.SupplierName, I.Banner, 
 												ST.StoreName as Store, ST.Custom2 as [SBT Number],  ST.StoreIdentifier as [Store No], 
												P.Description as [Product Desc], I.UPC,
												convert(varchar(10), I.LastInventoryCountDate, 101) as [Last Transaction Date],  
												I.ShrinkUnits as Qty, ''Pending Shrink'' as [Activity Type], 
												I.SupplierAcctNo as [Supplier Acct Number], '''' as [Driver Name], ''''  as [Route Number]  
										 from DataTrue_CustomResultSets.dbo.InventoryReport_New_FactTable_Active I 
										 inner join Stores ST on ST.StoreID=I.StoreID
										  inner join Chains C on C.ChainId=ST.ChainId
										 inner join Products P on P.ProductID=I.ProductID
										 inner join SupplierBanners SB on SB.SupplierId = ISR.SupplierId and SB.Status=''Active'' and SB.Banner=ST.Custom1
										 left join InventorySettlementRequests ISR on  ISR.SupplierID=I.supplierId 
										 and ISR.StoreID=I.StoreID and ISR.ProductID=I.ProductID and ISR.PhysicalInventoryDate=I.LastInventoryCountDate
										Where ISR.supplierId is null'
			
			if(@ChainId <>'-1') 
				set @sqlQuery = @sqlQuery +  ' and ST.ChainID=' + @ChainId
		  
			if(@SupplierID <>'-1') 
				set @sqlQuery = @sqlQuery +  ' and I.SupplierId=' + @SupplierId
		 
			if(@custom1='') 
				set @sqlQuery = @sqlQuery + ' and ST.custom1 is Null'
			else if(@custom1<>'-1') 
				set @sqlQuery = @sqlQuery + ' and ST.custom1=''' + @custom1 + ''''
				
			if (convert(date, @TransFromDate  ) > convert(date,'1900-01-01'))
				set @sqlQuery = @sqlQuery + ' and I.LastInventoryCountDate  >= ''' + @TransFromDate  + ''''
		 
			if(convert(date, @TransToDate ) > convert(date,'1900-01-01')) 
				set @sqlQuery = @sqlQuery + ' and I.LastInventoryCountDate  <=''' + @TransToDate  + ''''

		 
			if(@ProductIdentifierValue<>'')
				begin
					set @sqlQuery = @sqlQuery + ' and I.UPC like ''%' + @ProductIdentifierValue + '%''';
				end   
		 
			if(@StoreIdentifierValue<>'')
				begin
					-- 1 = Store Number, 2 = SBT Number, 3 = Store Name
					if (@StoreIdentifierType=1)
						set @sqlQuery = @sqlQuery + ' and ST.storeidentifier like ''%' + @StoreIdentifierValue + '%'''
					else if (@StoreIdentifierType=2)
						set @sqlQuery = @sqlQuery + ' and ST.Custom2 like ''%' + @StoreIdentifierValue + '%'''
					else if (@StoreIdentifierType=3)
						set @sqlQuery = @sqlQuery + ' and ST.StoreName like ''%' + @StoreIdentifierValue + '%'''
				end
			
			set @sqlQuery = @sqlQuery + ' order by 1, 2,3 , 6, 9 desc '
	execute(@sqlQuery);
 
End
GO
