USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetStoreTransctions_Working_LSNNEW]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetStoreTransctions_Working_LSNNEW]
as
Begin
insert into [IC-HQSQL1INST2].DataTrue_Archive.dbo.dbo_StoreTransactions_Working_CT
select *
--select __$start_lsn,COUNT(*)
--select count(*)
--delete 
from DataTrue_Main.CDC.dbo_StoreTransactions_working_CT with (nolock)
where CAST(DateTimeCreated as date)<='3/6/2015'
--and __$start_lsn in (0x00124E4F00030C6E01F9,0x00126AA1000265300152)--,0x0011E059000245F90015,0x0011E04C000173A1000D,0x0011E04600002780004E)--,
--0x0011789600005D0B0001,0x0011789400005241003B,0x001178A0000171970001,0x0011789A00004FE7000C,
--0x0011791F0001F875000C,0x00117A890001FF47018F)
--group by __$start_lsn order by 2

delete 
from DataTrue_Main.CDC.dbo_StoreTransactions_working_CT --with (nolock)
where CAST(DateTimeCreated as date)<='3/6/2015'
--and __$start_lsn in (0x00124E4F00030C6E01F9,0x00126AA1000265300152)--,0x0011E059000245F90015,0x0011E04C000173A1000D,0x0011E04600002780004E)--,
--and __$start_lsn in (0x0011BA710003B63F0088,0x0011B9A6000141710069,0x0011B9970002A307000B,0x0011C2F900011B9F007F)--,
--0x0011789600005D0B0001,0x0011789400005241003B,0x001178A0000171970001,0x0011789A00004FE7000C,
--0x0011791F0001F875000C,0x00117A890001FF47018F)


end
GO
