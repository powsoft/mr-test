USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_COSTS_PROMOTIONS_STATUS_ERROR_EMAIL_2014fab03]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--ALTER 
Create
procedure [dbo].[prMaintenanceRequest_COSTS_PROMOTIONS_STATUS_ERROR_EMAIL_2014fab03]
as


declare @rec cursor
declare @costtablerecordid int
declare @RecordID int
declare @mridreturned int


DECLARE @badrecids1 varchar(max)=''
DECLARE @mridreturnedc varchar(max)=''
DECLARE @Subject1 VARCHAR(MAX)=''
DECLARE @errMessage1 varchar(max)=''
DECLARE @badrecords1 table(MaintenanceRequestID int,
                             requeststatus smallint,recordid int,recordstatus smallint,PDIParticipant bit,RequestTypeID smallint)


DECLARE @badrecids2 varchar(max)=''
DECLARE @mridreturnedp varchar(max)=''
DECLARE @Subject2 VARCHAR(MAX)=''
DECLARE @errMessage2 varchar(max)=''
DECLARE @badrecords2 table (MaintenanceRequestID int,
                             requeststatus smallint,recordid int,loadstatus smallint,PDIParticipant bit,RequestTypeID smallint)




begin 


select *from DataTrue_edi.dbo.costs c  with (nolock)
inner join	MaintenanceRequests m	
on m.datatrue_edi_costs_recordid=c.RecordID
AND Recordid in (select RecordID from cost_apr_XXX)
and m.requeststatus not in(5,6,999,18,17) and m.Approved =1

if @@ROWCOUNT >0

insert @badrecords1
	select MaintenanceRequestID ,m.requeststatus requeststatus,RecordID 
	,RecordStatus,m.PDIParticipant PDIParticipant,m.RequestTypeID RequestTypeID
from DataTrue_edi.dbo.costs c  with (nolock)
inner join	MaintenanceRequests m	
on m.datatrue_edi_costs_recordid=c.RecordID
AND Recordid in (select RecordID from cost_apr_XXX)
and m.requeststatus not in(5,6,999,18,17) and m.Approved =1

 
	

if @@ROWCOUNT >0
set @errMessage1+='Cost Records with negative MR RequestStatus' +CHAR(13)+CHAR(10)

if @errMessage1 <>''
		begin;
			with c as (select ROW_NUMBER() over (partition by recordid order by requeststatus,recordid)dupe from @badrecords1)
				delete c where dupe>1
			set @Subject1 ='Cost Records with negative MR RequestStatus' 
			select @badrecids1 += cast(MaintenanceRequestID as varchar(13))+ ','+
			cast(RequestStatus as varchar(4))+ ','+cast(recordid as varchar(13))+ ','+cast(recordstatus as varchar(4))+ ','
			+ ','+cast(PDIParticipant as varchar(4))+ ','+ cast(RequestTypeID as varchar(4))+ CHAR(13)+CHAR(10) 
			from @badrecords1
			set @errMessage1+=CHAR(13)+CHAR(10)+'MS RecodID  ReqStatus RecordID  RecStatus   PDI  ReqType:'+CHAR(13)+CHAR(10)+@badrecids1
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com;tatiana.alperovitch@icucsolutions.com',
				@subject=@Subject1,@body=@errMessage1		
	
       end   
       
select m.* from DataTrue_edi.dbo.promotions c  with (nolock)
inner join	MaintenanceRequests m	
on m.datatrue_edi_promotions_recordid=c.RecordID
AND Recordid in (select RecordID from promotions_apr_XXX)
and m.requeststatus not in(6,5,999,108,18,17) and m.Approved =1
and m.datatrue_edi_promotions_recordid is not null





if @@ROWCOUNT >0

insert @badrecords2
	select MaintenanceRequestID ,m.RequestStatus,loadStatus,m.RequestTypeID,m.PDIParticipant
	 from DataTrue_edi.dbo.promotions c  with (nolock)
inner join	MaintenanceRequests m	
on m.datatrue_edi_promotions_recordid=c.RecordID
AND Recordid in (select RecordID from promotions_apr_XXX)
and m.requeststatus not in(6,5,999,108,18,17) and m.Approved =1
and m.datatrue_edi_promotions_recordid is not null

 
	
if @@ROWCOUNT >0
set @errMessage2+='CostPromotions Records with negative RequestStatus' +CHAR(13)+CHAR(10)

if @errMessage2 <>''
		begin;
			with c as (select ROW_NUMBER() over (partition by recordid order by recordid)dupe from @badrecords2)
				delete c where dupe>1
			set @Subject2 ='Records did not move to MaintenanceRequest' 
			select @badrecids2 += cast(recordid as varchar(13))+ ','--CHAR(13)+CHAR(10) 
			from @badrecords2
			set @errMessage2+=CHAR(13)+CHAR(10)+'Record ID:'+CHAR(13)+CHAR(10)+@badrecids2
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com;tatiana.alperovitch@icucsolutions.com',
				@subject=@Subject2,@body=@errMessage2				
	
       end        
return
end
GO
