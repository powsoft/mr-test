USE [DataTrue_Main]
GO

/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_NOT_MOVED_EMAIL_2014fab03]    Script Date: 08/15/2015 17:02:25 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE

procedure [dbo].[prMaintenanceRequest_NOT_MOVED_EMAIL_2014fab03]
as


declare @rec cursor
declare @costtablerecordid int
declare @RecordID int
declare @mridreturned int
declare @RecordCount int
declare @RecordCountPromo int

DECLARE @badrecids varchar(max)=''
DECLARE @Subject VARCHAR(MAX)=''
DECLARE @errMessage varchar(max)=''
DECLARE @badrecords table (recordid int)


begin 

select @RecordCount=count(*)
--select PDIParticipant,StoreNumber,dtchainid,dtsupplierid,dtstorecontexttypeid
--update c set dtstorecontexttypeid=1
from DataTrue_edi.dbo.costs c
where Recordstatus =0
and DATEADD(day, -30, getdate()) < datetimecreated
and dtstorecontexttypeid<>-1


if @RecordCount >0
BEGIN
set @errMessage+=cast(@RecordCount as varchar)+' Cost Records were found with record status 0' +CHAR(13)+CHAR(10)	

insert @badrecords
	select RecordID from [DataTrue_EDI].[dbo].[costs] p
where Recordstatus =0
and DATEADD(day, -30, getdate()) < datetimecreated
and dtstorecontexttypeid<>-1
END

select RecordID,PartnerIdentifier,dtbanner,dtchainid,dtproductid,dtsupplierid,dtstorecontexttypeid,PriceChangeCode,dtstoreid
from DataTrue_edi.dbo.costs c
where Recordstatus =0
and DATEADD(day, -30, getdate()) < datetimecreated
and dtchainid is null
and dtstorecontexttypeid<>-1

if @@ROWCOUNT >0
BEGIN
insert @badrecords
	select RecordID from [DataTrue_EDI].[dbo].[costs] p
where Recordstatus =0
and DATEADD(day, -30, getdate()) < datetimecreated
and dtchainid is null
and dtstorecontexttypeid<>-1

set @errMessage+=', dtchainid is null' +CHAR(13)+CHAR(10)	
END

select *
from DataTrue_edi.dbo.costs c
where Recordstatus =0
and DATEADD(day, -30, getdate()) < datetimecreated
and dtsupplierid is null
and dtstorecontexttypeid<>-1

if @@ROWCOUNT >0
BEGIN
insert @badrecords
	select RecordID from [DataTrue_EDI].[dbo].[costs] p
where Recordstatus =0
and DATEADD(day, -30, getdate()) < datetimecreated
and dtsupplierid is null 
and dtstorecontexttypeid<>-1

set @errMessage+= ', dtsupplierid is null'	+CHAR(13)+CHAR(10)	
end


select *
from DataTrue_edi.dbo.costs c
where Recordstatus =0
and DATEADD(day, -30, getdate()) < datetimecreated
and dtstorecontexttypeid is null 


if @@ROWCOUNT >0
BEGIN
insert @badrecords
	select RecordID from [DataTrue_EDI].[dbo].[costs] p
where Recordstatus =0
and DATEADD(day, -30, getdate()) < datetimecreated
and dtstorecontexttypeid is null 

set @errMessage+=', dtstorecontexttypeid is null' +CHAR(13)+CHAR(10)	
end

select *
from DataTrue_edi.dbo.costs c
where Recordstatus =0
and DATEADD(day, -30, getdate()) < datetimecreated
and dtbanner  is null
and dtstorecontexttypeid not in (1,-1)

if @@ROWCOUNT >0
begin
insert @badrecords
	select RecordID from [DataTrue_EDI].[dbo].[costs] p
where Recordstatus =0
and DATEADD(day, -30, getdate()) < datetimecreated
and dtbanner  is null
and dtstorecontexttypeid not in (1,-1)


set @errMessage+=', dtbanner  is null' +CHAR(13)+CHAR(10)	
end

select *
from DataTrue_edi.dbo.costs c
where Recordstatus =0
AND Recordid in (select RecordID from NOT_updated_COSTS)
and Recordsource  is null
and dtstorecontexttypeid<>-1

if @@ROWCOUNT >0
begin
insert @badrecords
	select RecordID from [DataTrue_EDI].[dbo].[costs] p
where Recordstatus =0
AND Recordid in (select RecordID from NOT_updated_COSTS)
and Recordsource  is null
and dtstorecontexttypeid<>-1

set @errMessage+=', Recordsource is null' +CHAR(13)+CHAR(10)	
end
/***********************
Records did not move from Promotions
***********/	

select @RecordCountPromo=count(*)
--select dtstorecontexttypeid,*
--update c set dtstorecontexttypeid=-1
from DataTrue_edi.dbo.promotions c
where loadstatus =0
and DATEADD(day, -30, getdate()) < datetimecreated
and isnull(dtstorecontexttypeid,99)<>-1

if @RecordCountPromo >0
begin
set @errMessage+=cast(@RecordCountPromo as varchar)+' Promotions Records were found with record status 0' +CHAR(13)+CHAR(10)	
Insert @badrecords
	select RecordID from [DataTrue_EDI].[dbo].[promotions] p
where loadstatus =0
and DATEADD(day, -30, getdate()) < datetimecreated
and isnull(dtstorecontexttypeid,99)<>-1


end

select RecordID from [DataTrue_EDI].[dbo].[promotions] p
where loadstatus =0
and DATEADD(day, -30, getdate()) < datetimecreated
and chainid is null
and isnull(dtstorecontexttypeid,99)<>-1

if @@ROWCOUNT >0
begin
insert @badrecords
	select RecordID from [DataTrue_EDI].[dbo].[promotions] p
where loadstatus =0
and DATEADD(day, -30, getdate()) < datetimecreated
and chainid is null
and isnull(dtstorecontexttypeid,99)<>-1

set @errMessage+=', chainid is null' +CHAR(13)+CHAR(10)	
end


select *
from [DataTrue_EDI].[dbo].[promotions] p
where loadstatus =0
and DATEADD(day, -30, getdate()) < datetimecreated
and supplierid is null
and isnull(dtstorecontexttypeid,99)<>-1

if @@ROWCOUNT >0
begin
insert @badrecords
	select RecordID from [DataTrue_EDI].[dbo].[promotions] p
where loadstatus =0
and DATEADD(day, -30, getdate()) < datetimecreated
and supplierid is null
and isnull(dtstorecontexttypeid,99)<>-1

set @errMessage+= CHAR(13)+CHAR(10)+', supplierid is null'	
end


select *
from [DataTrue_EDI].[dbo].[promotions] p
where loadstatus =0
and DATEADD(day, -30, getdate()) < datetimecreated
and dtstorecontexttypeid is null

if @@ROWCOUNT >0
begin
insert @badrecords
	select RecordID from [DataTrue_EDI].[dbo].[promotions] p
where loadstatus =0
and DATEADD(day, -30, getdate()) < datetimecreated
and dtstorecontexttypeid is null

set @errMessage+=', dtstorecontexttypeid is null' +CHAR(13)+CHAR(10)	
end

select *
from  [DataTrue_EDI].[dbo].[promotions] p
where loadstatus =0
and DATEADD(day, -30, getdate()) < datetimecreated
and dtbanner  is null
and dtstorecontexttypeid not in (1,-1)
and isnull(dtstorecontexttypeid,99)<>-1


if @@ROWCOUNT >0
begin
insert @badrecords
	select RecordID from [DataTrue_EDI].[dbo].[promotions] p
where loadstatus =0
and DATEADD(day, -30, getdate()) < datetimecreated
and dtbanner  is null
and dtstorecontexttypeid not in (1,-1)
and isnull(dtstorecontexttypeid,99)<>-1


set @errMessage+=', dtbanner  is null' +CHAR(13)+CHAR(10)	
end

select *
from [DataTrue_EDI].[dbo].[promotions] p
where loadstatus =0
and DATEADD(day, -30, getdate()) < datetimecreated
and Recordsource  is null
and isnull(dtstorecontexttypeid,99)<>-1

if @@ROWCOUNT >0
begin
insert @badrecords
	select RecordID from [DataTrue_EDI].[dbo].[promotions] p
where loadstatus =0
and DATEADD(day, -30, getdate()) < datetimecreated
and Recordsource  is null
and isnull(dtstorecontexttypeid,99)<>-1

set @errMessage+=' , Recordsource is null' +CHAR(13)+CHAR(10)
end
if @errMessage <>''
		begin
			with c as (select ROW_NUMBER() over (partition by recordid order by recordid)dupe from @badrecords)
				delete c where dupe>1
			set @Subject ='Records did not move to MaintenanceRequest' 
			select @badrecids += cast(recordid as varchar(13))+ ','
			from @badrecords
			set @errMessage+=CHAR(13)+CHAR(10)+'Record ID:'+CHAR(13)+CHAR(10)+@badrecids
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com;gilad.keren@icucsolutions.com',
				@subject=@Subject,@body=@errMessage				
	
       end        
return
end 
	


GO

