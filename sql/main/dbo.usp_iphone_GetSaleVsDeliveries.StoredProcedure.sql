USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_iphone_GetSaleVsDeliveries]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_iphone_GetSaleVsDeliveries]
@SupplierID nvarchar(20),
@ChainID nvarchar(20),
@Banner nvarchar(100),
@StoreNo nvarchar(20),
@UPC nvarchar(20),
@ReportType varchar(20),
@Range int,
@AnalysisType varchar(1)
as

Begin
 Declare @sqlQuery1 varchar(4000)
 Declare @sqlQuery2 varchar(4000)
 Declare @sqlCondition varchar(4000)
 Declare @SaleDays datetime, @colName varchar(200)
	
	if(@ReportType='Weekly')
		Begin 
			set @SaleDays =getdate()- (@Range * 7)
			set @colName = 'datename(Week, SaleDateTime)'
		end
	else if(@ReportType='Monthly')
		Begin
			set @SaleDays =  getdate()-(@Range * 30)
			set @colName = 'month(SaleDateTime)'
		end
	else if(@ReportType='Yearly')
		Begin
			set @SaleDays = getdate()-(@Range * 365)
			set @colName = 'year(SaleDateTime)'
		end


	begin try
		Drop Table [@tmpsales]
		Drop Table [@tmpDelieveries]
	end try
	begin catch
	end catch

	set @sqlQuery1 = 'Select top ' + cast(@Range as nvarchar(4)) + ' ' + @colName + '  as Seq, sum(S.Qty * T.QtySign) as units, 
				SUM((s.Qty * T.QtySign) * (ISNULL(s.RuleCost,0) - ISNULL(s.PromoAllowance, 0))) as cost
				into [@tmpsales]
				from StoreTransactions S
				inner join TransactionTypes T on T.TransactionTypeID=S.TransactionTypeID and T.BucketType=1
				inner join Stores ST on ST.StoreID=S.StoreID and ST.ActiveStatus=''Active''
				where S.SaleDateTime > ''' + convert(varchar(10), @SaleDays, 101) + ''''
				
	set @sqlQuery2 = 'Select top ' + cast(@Range as nvarchar(4)) + ' ' + @colName + '  as Seq, sum(S.Qty * T.QtySign) as units,
				SUM((s.Qty * T.QtySign) * (ISNULL(s.RuleCost,0) - ISNULL(s.PromoAllowance, 0))) as cost
				into [@tmpDelieveries]
				from StoreTransactions S
				inner join TransactionTypes T on T.TransactionTypeID=S.TransactionTypeID  and T.BucketType=2
				inner join Stores ST on ST.StoreID=S.StoreID and ST.ActiveStatus=''Active''
				where S.SaleDateTime > ''' + convert(varchar(10), @SaleDays, 101) + ''''				
	
	set @sqlCondition= ''
		
	if(@supplierID<>'-1')
		set @sqlCondition = @sqlCondition +  ' and S.SupplierID=' + @supplierID
		
	if(@ChainID<>'-1')
		set @sqlCondition = @sqlCondition +  ' and S.ChainId=' + @ChainID

	if(@Banner<>'All')
		set @sqlCondition = @sqlCondition +  ' and ST.Custom1=''' + @Banner + ''''

	if(@StoreNo<>'')
		set @sqlCondition = @sqlCondition + ' and  ST.StoreIdentifier like ''%' + @StoreNo + '%'''

	if(@UPC<>'')
		set @sqlCondition = @sqlCondition + ' and UPC like ''%' + @UPC + '%'''

	set @sqlCondition = @sqlCondition + ' group by '  +  @colName
	set @sqlCondition = @sqlCondition + ' order by '  +  @colName
	
	set @sqlQuery1 = @sqlQuery1 + @sqlCondition
	set @sqlQuery2 = @sqlQuery2 + @sqlCondition
	
	exec (@sqlQuery1)
	exec (@sqlQuery2)
	
	Select t1.Seq, t1.Units as SaleUnits, t1.Cost as SaleCost, t2.Units as DeliveryUnits, t2.Cost as DeliveryCost 
	from [@tmpsales] t1
	inner join [@tmpDelieveries] t2 on t1.seq=t2.seq
	

End
--exec [usp_iphone_GetSaleVsDeliveries] 40558, 40393, 'All','','','Weekly', 4
GO
