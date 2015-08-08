USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_GetStoreTransactionView]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_GetStoreTransactionView]
@chainid int=null
--prUtil_GetStoreTransactionView 7608
as

if @chainid is null
	begin
select tt.TransactionTypeName as TransType, s.StatusName as Status, st.*
from dbo.StoreTransactions st
inner join dbo.TransactionTypes tt
on st.TransactionTypeID = tt.TransactionTypeID
inner join dbo.Statuses s
on st.TransactionStatus = s.StatusIntValue
and s.StatusTypeID = 4
and st.TransactionTypeId in (2,6,7,16,17,18,22)
--where ChainID = @chainid
union
select tt.TransactionTypeName as TransType, s.StatusName as Status, st.*
from dbo.StoreTransactions st
inner join dbo.TransactionTypes tt
on st.TransactionTypeID = tt.TransactionTypeID
inner join dbo.Statuses s
on st.TransactionStatus = s.StatusIntValue
and s.StatusTypeID = 5
and st.TransactionTypeId in (4,5,8,9,13,14,19,20,21,23)
--where ChainID = @chainid
union
select tt.TransactionTypeName as TransType, s.StatusName as Status, st.*
from dbo.StoreTransactions st
inner join dbo.TransactionTypes tt
on st.TransactionTypeID = tt.TransactionTypeID
inner join dbo.Statuses s
on st.TransactionStatus = s.StatusIntValue
and s.StatusTypeID = 13
and st.TransactionTypeId in (10,11)
--where ChainID = @chainid
order by SaleDateTime
	end
else
	begin
	
select tt.TransactionTypeName as TransType, s.StatusName as Status, st.*
from dbo.StoreTransactions st
inner join dbo.TransactionTypes tt
on st.TransactionTypeID = tt.TransactionTypeID
inner join dbo.Statuses s
on st.TransactionStatus = s.StatusIntValue
and s.StatusTypeID = 4
and st.TransactionTypeId in (2,6,7,16,17,18,22)
where ChainID = @chainid
union
select tt.TransactionTypeName as TransType, s.StatusName as Status, st.*
from dbo.StoreTransactions st
inner join dbo.TransactionTypes tt
on st.TransactionTypeID = tt.TransactionTypeID
inner join dbo.Statuses s
on st.TransactionStatus = s.StatusIntValue
and s.StatusTypeID = 5
and st.TransactionTypeId in (4,5,8,9,13,14,19,20,21,23)
where ChainID = @chainid
union
select tt.TransactionTypeName as TransType, s.StatusName as Status, st.*
from dbo.StoreTransactions st
inner join dbo.TransactionTypes tt
on st.TransactionTypeID = tt.TransactionTypeID
inner join dbo.Statuses s
on st.TransactionStatus = s.StatusIntValue
and s.StatusTypeID = 13
and st.TransactionTypeId in (10,11)
where ChainID = @chainid
order by SaleDateTime	
	end
--select * from inventoryperpetual

--select * from relatedtransactions

--select * from DataTrue_Report..StoreTransactions

--select * from DataTrue_Report..InventoryPerpetual



return
GO
