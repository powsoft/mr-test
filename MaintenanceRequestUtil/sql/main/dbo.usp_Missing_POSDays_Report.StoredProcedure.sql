USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Missing_POSDays_Report]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec [usp_Missing_POSDays_Report] '40557','40393', ''
CREATE procedure [dbo].[usp_Missing_POSDays_Report]
@SupplierId varchar(20),
@ChainId varchar(20),
@StoreNumber varchar(50)
as 
Begin
	
	select c.ChainName as Retailer, st.StoreIdentifier as [Store Number],
		  case when datediff(d,SaleDateTime,getdate()) =0 then 'Today'
		  when datediff(d,SaleDateTime,getdate()) =1 then 'Yesterday'
		  when datediff(d,SaleDateTime,getdate()) =2 then '2 Days Ago'
		  when datediff(d,SaleDateTime,getdate()) =3 then '3 Days Ago'
		  when datediff(d,SaleDateTime,getdate()) =4 then '4 Days Ago'
		  when datediff(d,SaleDateTime,getdate()) =5 then '5 Days Ago'
		  when datediff(d,SaleDateTime,getdate()) =6 then '6 Days Ago'
		  when datediff(d,SaleDateTime,getdate()) =7 then '7 Days Ago'
		  when datediff(d,SaleDateTime,getdate()) =8 then '8 Days Ago'
		  when datediff(d,SaleDateTime,getdate()) =9 then '9 Days Ago'
		  when datediff(d,SaleDateTime,getdate()) =10 then '10 Days Ago'
		  when datediff(d,SaleDateTime,getdate()) =11 then '11 Days Ago'
		  when datediff(d,SaleDateTime,getdate()) =12 then '12 Days Ago'
		  when datediff(d,SaleDateTime,getdate()) =13 then '13 Days Ago'
		  when datediff(d,SaleDateTime,getdate()) =14 then '14 Days Ago'
		  end as 'DaysFromToday',
		  sum(qty) as 'TTLPos' 
	into #tmp1
	from storetransactions s
	inner join stores st on st.StoreID =s.StoreID
	inner join chains c on c.ChainID =st.ChainID
	inner join TransactionTypes t on t.TransactionTypeID =s.TransactionTypeID and t.BucketTypeName ='POS'
	where saledatetime>getdate()-15 and S.SupplierId=@SupplierId and S.ChainId=@ChainId and ST.StoreIdentifier like '%' + @StoreNumber + '%'
	group by st.storeidentifier,SaleDateTime , c.ChainName


	select * from #tmp1      -- Colums to pivot
	pivot (
	   sum (ttlpos)                                                   
	   for DaysFromToday in ([Today] ,[Yesterday], [2 Days Ago],[3 Days Ago],[4 Days Ago],[5 Days Ago],[6 Days Ago],[7 Days Ago],[8 Days Ago],[9 Days Ago],[10 Days Ago],[11 Days Ago],[12 Days Ago],[13 Days Ago],[14 Days Ago]))         -- Make colum where IncomeDay is in one of these.
	   as TotalSales                                                    
	order by 1,2    
End
GO
