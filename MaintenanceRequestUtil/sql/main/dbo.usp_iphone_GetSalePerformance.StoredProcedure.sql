USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_iphone_GetSalePerformance]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec usp_iphone_GetSalePerformance 40558, 40393, 'All','','','Yearly', 4, 1 ; exec usp_iphone_GetSalePerformance 40558, 40393, 'All','','','Yearly', 4, 2
CREATE procedure [dbo].[usp_iphone_GetSalePerformance]
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
 Declare @sqlQuery varchar(4000)
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


	set @sqlQuery = 'Select top ' + cast(@Range as nvarchar(4)) + ' ' + @colName + '  as Seq, sum(S.Qty * T.QtySign) as units, 
					SUM((s.Qty * T.QtySign) * (ISNULL(s.RuleCost,0) - ISNULL(s.PromoAllowance, 0))) as cost
					from StoreTransactions S
					inner join TransactionTypes T on T.TransactionTypeID=S.TransactionTypeID and T.BucketType=' + @AnalysisType + '
					inner join Stores ST on ST.StoreID=S.StoreID and ST.ActiveStatus=''Active''
					where S.SaleDateTime > ''' + convert(varchar(10), @SaleDays, 101) + ''''
	
	if(@supplierID<>'-1')
		set @sqlQuery = @sqlQuery +  ' and S.SupplierID=' + @supplierID

	if(@ChainID<>'-1')
		set @sqlQuery = @sqlQuery +  ' and S.ChainId=' + @ChainID

	if(@Banner<>'All')
		set @sqlQuery = @sqlQuery +  ' and ST.Custom1=''' + @Banner + ''''

	if(@StoreNo<>'')
		set @sqlQuery = @sqlQuery + ' and  ST.StoreIdentifier like ''%' + @StoreNo + '%'''

	if(@UPC<>'')
		set @sqlQuery = @sqlQuery + ' and UPC like ''%' + @UPC + '%'''

	set @sqlQuery = @sqlQuery + ' group by '  +  @colName
	set @sqlQuery = @sqlQuery + ' order by '  +  @colName
	
	exec(@sqlQuery);

End

--Select top 3 datename(Week, SaleDateTime), sum(qty) as units, sum(qty*S.ReportedCost+ReportedAllowance) as cost
--from StoreTransactions S
--inner join TransactionTypes T on T.TransactionTypeID=S.TransactionTypeID and T.BucketType=1
--inner join Stores ST on ST.StoreID=S.StoreID and ST.ActiveStatus='Active'
--inner join ProductIdentifiers PD on PD.ProductID=S.ProductID and PD.ProductIdentifierTypeID=2
--where S.SupplierID=40562 and S.ChainID=40393 
--and SaleDateTime > GETDATE() - 21
--group by datename(Week, SaleDateTime)
--order by datename(Week, SaleDateTime)


--Select top 3 month(SaleDateTime), sum(qty) as units, sum(qty*S.ReportedCost+ReportedAllowance) as cost
--from StoreTransactions S
--inner join TransactionTypes T on T.TransactionTypeID=S.TransactionTypeID and T.BucketType=1
--inner join Stores ST on ST.StoreID=S.StoreID and ST.ActiveStatus='Active'
--where S.SupplierID=40562 and S.ChainID=40393 
--and SaleDateTime > GETDATE() - 90
--group by month(SaleDateTime)
--order by month(SaleDateTime)


--Select top 2 year(SaleDateTime), sum(qty) as units, sum(qty*S.ReportedCost+ReportedAllowance) as cost
--from StoreTransactions S
--inner join TransactionTypes T on T.TransactionTypeID=S.TransactionTypeID and T.BucketType=1
--inner join Stores ST on ST.StoreID=S.StoreID and ST.ActiveStatus='Active'
--where S.SupplierID=40562 and S.ChainID=40393 
--and SaleDateTime > GETDATE() - (365 * 2) and ST.Custom1='Cub Foods'
--group by year(SaleDateTime)
--order by year(SaleDateTime)
GO
