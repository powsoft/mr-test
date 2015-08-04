USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_POS_Polling_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE procedure [dbo].[usp_Report_POS_Polling_PRESYNC_20150524] 
	-- exec usp_Report_POS_Polling '40393','40384','All','','-1','','530','1900-01-01','1900-01-01'
	@chainID varchar(20),
	@PersonID int,
	@Banner varchar(50),
	@ProductUPC varchar(20),
	@SupplierId varchar(10),
	@StoreId varchar(10),
	@LastxDays int,
	@StartDate varchar(20),
	@EndDate varchar(20)
AS
BEGIN
Declare @Query varchar(5000)
declare @AttValue int

	select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
 
	set @query = '

select c.ChainName as Retailer, st.StoreIdentifier as [Store Number],

	case when datediff(d,SaleDateTime,getdate()) =0 then ''Today''
	when datediff(d,SaleDateTime,getdate()) =1 then ''Yesterday''
	when datediff(d,SaleDateTime,getdate()) =2 then ''2 Days Ago''
	when datediff(d,SaleDateTime,getdate()) =3 then ''3 Days Ago''
	when datediff(d,SaleDateTime,getdate()) =4 then ''4 Days Ago''
	when datediff(d,SaleDateTime,getdate()) =5 then ''5 Days Ago''
	when datediff(d,SaleDateTime,getdate()) =6 then ''6 Days Ago''
	when datediff(d,SaleDateTime,getdate()) =7 then ''7 Days Ago''
	when datediff(d,SaleDateTime,getdate()) =8 then ''8 Days Ago''
	when datediff(d,SaleDateTime,getdate()) =9 then ''9 Days Ago''
	when datediff(d,SaleDateTime,getdate()) =10 then ''10 Days Ago''
	when datediff(d,SaleDateTime,getdate()) =11 then ''11 Days Ago''
	when datediff(d,SaleDateTime,getdate()) =12 then ''12 Days Ago''
	when datediff(d,SaleDateTime,getdate()) =13 then ''13 Days Ago''
	when datediff(d,SaleDateTime,getdate()) =14 then ''14 Days Ago''
	end as ''DaysFromToday'', 

	sum(qty) as ''TTLPos''  
into #tmp1
from datatrue_report.dbo.StoreTransactions s 
	inner join stores st on st.StoreID =s.StoreID 
	inner join chains c on c.ChainID =st.ChainID 
	inner join TransactionTypes t on t.TransactionTypeID =s.TransactionTypeID and t.BucketTypeName =''POS''
where saledatetime>getdate()-15
'
	if @AttValue =17
		set @query = @query + ' and s.ChainID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
	else
		set @query = @query + ' and s.SupplierID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'


	if(@chainID  <>'-1') 
		set @Query   = @Query  +  ' and s.ChainID=' + @chainID 

	if(@Banner<>'All') 
		set @Query  = @Query + ' and st.custom1  like ''%' + @Banner + '%'''

	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and s.SupplierId=' + @SupplierId  


	if(@ProductUPC  <>'-1') 
		set @Query   = @Query  +  ' and  s.UPC like ''%' + @ProductUPC + '%'''

	--if (@LastxDays > 0)
	--	set @Query = @Query + ' and (CP.[Begin Date] between dateadd(d,-' +  cast(@LastxDays as varchar) + ', { fn NOW() }) and { fn NOW() })'  
	
	--if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
	--	set @Query = @Query + ' and CP.[Begin Date] >= ''' + @StartDate  + '''';

	--if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
	--	set @Query = @Query + ' and CP.[Begin Date] <= ''' + @EndDate  + '''';

	set @Query   = @Query  +  'group by st.storeidentifier,SaleDateTime , c.ChainName 

			select * from #tmp1

			pivot (
			   sum (ttlpos)                                                    
			   for DaysFromToday in ([Today] ,[Yesterday], [2 Days Ago],[3 Days Ago],[4 Days Ago],[5 Days Ago],[6 Days Ago],[7 Days Ago],[8 Days Ago],[9 Days Ago],[10 Days Ago],[11 Days Ago],[12 Days Ago],[13 Days Ago],[14 Days Ago]))         -- Make colum where IncomeDay is in one of these.
			   as TotalSales                                                     
			order by 1,2    '

		
	exec (@Query )
END
GO
