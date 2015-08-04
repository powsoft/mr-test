USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_COSTS_PROMOTIONS_STATUS_ERROR_EMAIL_2014APR]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_COSTS_PROMOTIONS_STATUS_ERROR_EMAIL_2014APR]
as


declare @rec cursor
declare @costtablerecordid int
declare @RecordID int
declare @mridreturned int


DECLARE @badrecids1 varchar(max)=''
DECLARE @requeststatus1 varchar(max)=''
DECLARE @Subject1 VARCHAR(MAX)=''
DECLARE @errMessage1 varchar(max)=''
DECLARE @badrecords1 table(MaintenanceRequestID int,
                             requeststatus smallint)

declare @rec2 cursor
DECLARE @badrecids2 varchar(max)=''
DECLARE @requeststatus2 varchar(max)=''
DECLARE @Subject2 VARCHAR(MAX)=''
DECLARE @errMessage2 varchar(max)=''
DECLARE @badrecords2 table (MaintenanceRequestID int,
                            requeststatus smallint)
DECLARE @badreq2 table ( requeststatus smallint)




begin 


--select *from DataTrue_edi.dbo.costs c  with (nolock)
--inner join	MaintenanceRequests m	
--on m.datatrue_edi_costs_recordid=c.RecordID
--AND Recordid in (select RecordID from NOT_updated_costs)
--and m.requeststatus not in(5,6,999,18,17) and m.Approved =1
--and m.datatrue_edi_COSTS_recordid is not null

--if @@ROWCOUNT >0

--insert @badrecords1
--	select MaintenanceRequestID ,m.requeststatus 
--from DataTrue_edi.dbo.costs c  with (nolock)
--inner join	MaintenanceRequests m	
--on m.datatrue_edi_costs_recordid=c.RecordID
--AND Recordid in (select RecordID from NOT_updated_costs)
--and m.requeststatus not in(5,6,999,18,17) and m.Approved =1
--and m.datatrue_edi_COSTS_recordid is not null

 
	

--if @@ROWCOUNT >0
--set @errMessage1+='Cost Records with negative MR RequestStatus' +CHAR(13)+CHAR(10)

--if @errMessage1 <>''
--		begin;
--			with c as (select ROW_NUMBER() over (partition by MaintenanceRequestID order by requeststatus,MaintenanceRequestID)dupe from @badrecords1)
--				delete c where dupe>1
--			set @Subject1 ='Cost Records with negative MR RequestStatus' 
--			select @badrecids1 += cast(RequestStatus as varchar(4))+ ','+cast(MaintenanceRequestID as varchar(13))+ CHAR(13)+CHAR(10) 
--			from @badrecords1
--			set @errMessage1+=CHAR(13)+CHAR(10)+'MS RecodID  RequestStatus :'+CHAR(13)+CHAR(10)+@badrecids1
--			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com',
--				@subject=@Subject1,@body=@errMessage1		
	
--       end   
       
       
/***********************find bad promotions statuses***********************/       
       
       
select m.* from DataTrue_edi.dbo.promotions c  with (nolock)
inner join	MaintenanceRequests m	
on m.datatrue_edi_promotions_recordid=c.RecordID
AND Recordid in (select RecordID from NOT_updated_promotions)
and m.requeststatus not in(6,5,999,108,18,17) and m.Approved =1
and m.datatrue_edi_promotions_recordid is not null

if @@ROWCOUNT >0

insert @badrecords2
	select MaintenanceRequestID ,m.RequestStatus RequestStatus
	 from DataTrue_edi.dbo.promotions c  with (nolock)
inner join	MaintenanceRequests m	
on m.datatrue_edi_promotions_recordid=c.RecordID
AND Recordid in (select RecordID from NOT_updated_promotions)
and m.requeststatus not in(6,5,999,108,18,17) and m.Approved =1
and m.datatrue_edi_promotions_recordid is not null

----insert @badreq2
----	select distinct m.RequestStatus RequestStatus
----	 from DataTrue_edi.dbo.promotions c  with (nolock)
----inner join	MaintenanceRequests m	
----on m.datatrue_edi_promotions_recordid=c.RecordID
----AND Recordid in (select RecordID from NOT_updated_promotions)
----and m.requeststatus not in(6,5,999,108,18,17) and m.Approved =1
----and m.datatrue_edi_promotions_recordid is not null
 
	
if @@ROWCOUNT >0
set @errMessage2+='CostPromotions Records with negative RequestStatus' +CHAR(13)+CHAR(10)

if @errMessage2 <>''
		begin;
			with c as (select ROW_NUMBER() over (partition by MaintenanceRequestID order by MaintenanceRequestID)dupe from @badrecords2)
				delete c where dupe>1
				set @Subject2 ='Records did not move to MaintenanceRequest' 
    set @rec2 = CURSOR local fast_forward FOR
           select distinct m.RequestStatus RequestStatus
	       from DataTrue_edi.dbo.promotions c  with (nolock)
           inner join	MaintenanceRequests m	
           on m.datatrue_edi_promotions_recordid=c.RecordID
           AND Recordid in (select RecordID from NOT_updated_promotions)
           and m.requeststatus not in(6,5,999,108,18,17) and m.Approved =1
          and m.datatrue_edi_promotions_recordid is not null order by RequestStatus
    open @rec2 
    fetch next from @rec2 into @requeststatus2

    while @@FETCH_STATUS = 0
	begin
			
			set @badrecids2 =''
			select @badrecids2 +=  cast(MaintenanceRequestID as varchar(13))+ ','		
			from @badrecords2 where  RequestStatus=@requeststatus2
			set @errMessage2+=CHAR(13)+CHAR(10)+'MS RecodID  ReqStatus '+@requeststatus2 +CHAR(13)+CHAR(10)+@badrecids2
			
	fetch next from @rec2 into @requeststatus2
	end
	
close @rec2
deallocate @rec2
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com;tatiana.alperovitch@icucsolutions.com;charlie.clark@icontroldsd.com',
				@subject=@Subject2,@body=@errMessage2	--;tatiana.alperovitch@icucsolutions.com			
	
       end        
return
end
GO
