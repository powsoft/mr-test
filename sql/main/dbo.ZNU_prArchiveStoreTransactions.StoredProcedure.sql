USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[ZNU_prArchiveStoreTransactions]    Script Date: 06/25/2015 18:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[ZNU_prArchiveStoreTransactions]
as

--waitfor delay '0:0:5'

insert into DataTrue_Archive..StoreTransactions select * from cdc.dbo_StoreTransactions_CT
return
GO
