USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMR_process_not_APPROVED_RECORDS_EMAIL_2014_sep14_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMR_process_not_APPROVED_RECORDS_EMAIL_2014_sep14_PRESYNC_20150329]
as



declare @costtablerecordid int
declare @RecordID int
declare @mridreturned int

declare @rec cursor
DECLARE @badrecids varchar(max)=''
DECLARE @requeststatus varchar(4)=''
DECLARE @requestTypeid varchar(2)=''
DECLARE @PDIParticipant varchar(1)=''
DECLARE @SubmitDateTime DATETIME
DECLARE @StartDateTime DATETIME
DECLARE @chainid varchar(8)=''
DECLARE @chainname varchar(60)=''
DECLARE @SupplierID varchar(8)=''
DECLARE @suppliername varchar(60)=''

DECLARE @statusName varchar(max)=''
DECLARE @Subject VARCHAR(MAX)=''
DECLARE @errMessage varchar(max)=''
DECLARE @badrecords table(MaintenanceRequestID int,
                             requeststatus smallint)

declare @rec1 cursor
DECLARE @badrecids1 varchar(max)=''
DECLARE @requeststatus1  varchar(4)=''
DECLARE @statusName1 varchar(max)=''
DECLARE @Subject1 VARCHAR(MAX)=''
DECLARE @errMessage1 varchar(max)=''
DECLARE @badrecords1 table(SubmitDateTime date,StartDateTime date,
                             requeststatus smallint,supplierID int,chainid int,chainname varchar,suppliername varchar,RequestTypeID int
                             )
                             
                             
declare @rec2 cursor
DECLARE @badrecids2 varchar(max)=''
DECLARE @requeststatus2  varchar(4)=''
DECLARE @statusName2 varchar(max)=''
DECLARE @Subject2 VARCHAR(MAX)=''
DECLARE @errMessage2 varchar(max)=''
DECLARE @badrecords2 table(SubmitDateTime date,
                             requeststatus smallint,supplierID int,chainid int,chainname varchar,suppliername varchar,RequestTypeID int
                             )

begin 

       
       
/***********************'Find Not Approved MR Records,which were submitted more then 24 hours ago***********************/       
       
 select  *
  from MaintenanceRequests m
  inner join chains c
  on c.ChainID=m.ChainID
  inner join suppliers s
  on m.SupplierID=s.SupplierID
  where Approved is  null
    and m.datetimecreated<GETDATE()-1
   and m.datetimecreated>GETDATE()-30
  and PDIParticipant=0
  and RequestStatus not in (5,-25,-26,-27,-30,17,999,18,-8)
  --if @@ROWCOUNT >0

--insert @badrecords1
----select MaintenanceRequestID ,m.RequestStatus RequestStatus,cast(SubmitDateTime as date) SubmitDateTime
--select  distinct cast(SubmitDateTime as date) SubmitDateTime,requeststatus,m.chainid,c.chainname,m.SupplierID,suppliername,RequestTypeID
--  from MaintenanceRequests m
--  inner join chains c
--  on c.ChainID=m.ChainID
--  inner join suppliers s
--  on m.SupplierID=s.SupplierID
--  where Approved <>1
--  and m.datetimecreated<GETDATE()-1

--  and m.datetimecreated>'08-28-2014'

 
	
if @@ROWCOUNT >0
set @errMessage1+='Not Approved MR Records yet. Please approve records below' +CHAR(13)+CHAR(10)

if @errMessage1 <>''
begin;
		
set @Subject1 ='Not Approved MR Records' 
       
set @rec1 = CURSOR local fast_forward FOR

select  distinct cast(SubmitDateTime as date) SubmitDateTime,cast(StartDateTime as date) StartDateTime,requeststatus,m.chainid,c.chainname,m.SupplierID,suppliername,RequestTypeID
  from MaintenanceRequests m
  inner join chains c
  on c.ChainID=m.ChainID
  inner join suppliers s
  on m.SupplierID=s.SupplierID
  where Approved is  null
    and m.datetimecreated<GETDATE()-1
   and m.datetimecreated>GETDATE()-30
   and RequestStatus not in (5,-25,-26,-27,-30,999,18,17,-8)
  and PDIParticipant=0  
  and m.datetimecreated>'08-29-2014'
       order by StartDateTime,SubmitDateTime,m.chainid,m.supplierid,RequestStatus,RequestTypeID

     set @errMessage1+=CHAR(13)+CHAR(10)+'StartDate          '+'SubmitDate        '+'    Request Status     '+'     Chain id,Name                      '+'Supplier id,Name '+CHAR(13)+CHAR(10)open @rec1 
fetch next from @rec1 into @SubmitDateTime,@StartDateTime,@requeststatus,@chainid,@chainname,@SupplierID,@suppliername,@RequestTypeID

    while @@FETCH_STATUS = 0
	begin
			
			set @errMessage1+=CHAR(13)+CHAR(10)
			+cast(@StartDateTime as varchar(11))+'         '+cast(@SubmitDateTime as varchar(11))+'                       '+@requeststatus+'                     '+@chainid+','+@chainname+'                  '+@SupplierID+','+@suppliername+CHAR(13)+CHAR(10)
			
	fetch next from @rec1 into @SubmitDateTime,@StartDateTime,@requeststatus,@chainid,@chainname,@SupplierID,@suppliername,@RequestTypeID
	end
	
close @rec1
deallocate @rec1
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com;tatiana.alperovitch@icucsolutions.com;bill.harris@icucsolutions.com;amol.sayal@icucsolutions.com;gilad.keren@icucsolutions.com;nathalie.shein@icucsolutions.com;esther.ortiz@icucsolutions.com'
			,
			--
			
				@subject=@Subject1,@body=@errMessage1	--		
	
       end        
       
select  *
from MaintenanceRequests m
inner join chains c
on c.ChainID=m.ChainID
inner join suppliers s
on m.SupplierID=s.SupplierID
where Approved is  null
and PDIParticipant=1
and m.datetimecreated<GETDATE()-1
and m.datetimecreated>GETDATE()-30
and RequestStatus not in (5,-25,-26,-27,-30,-17,999,-31)

 
	
if @@ROWCOUNT >0
set @errMessage1+='Not Approved PDI MR Records Yet.Please approve the recorda below' +CHAR(13)+CHAR(10)

if @errMessage2 <>''
begin;
		
set @Subject2 ='Not Approved PDI MR Records' 
       
set @rec2 = CURSOR local fast_forward FOR

select  distinct cast(SubmitDateTime as date) SubmitDateTime,requeststatus,m.chainid,c.chainname,m.SupplierID,suppliername,RequestTypeID
  from MaintenanceRequests m
  inner join chains c
  on c.ChainID=m.ChainID
  inner join suppliers s
  on m.SupplierID=s.SupplierID
  where Approved is null
   and m.datetimecreated<GETDATE()-1
   and m.datetimecreated>GETDATE()-30
  and PDIParticipant=1
   and RequestStatus not in (5,-25,-26,-27,-30,-17,999,-31,-8)
  

       order by m.chainid,m.supplierid,RequestStatus,SubmitDateTime,RequestTypeID

     set @errMessage2+=CHAR(13)+CHAR(10)+'SubmitDateTime     '+'Request Status'+'     Chain id,Name                      '+'Supplier id,Name              '+CHAR(13)+CHAR(10)
open @rec2 
fetch next from @rec1 into @SubmitDateTime,@requeststatus,@chainid,@chainname,@SupplierID,@suppliername,@RequestTypeID

    while @@FETCH_STATUS = 0
	begin
			
			set @errMessage2+=CHAR(13)+CHAR(10)	+cast(@SubmitDateTime as varchar(11))+'          '+@requeststatus+'                     '+@chainid+','+@chainname+'                  '+@SupplierID+','+@suppliername+CHAR(13)+CHAR(10)
			
			
	fetch next from @rec1 into @SubmitDateTime,@requeststatus,@chainid,@chainname,@SupplierID,@suppliername,@RequestTypeID
	end
	
close @rec2
deallocate @rec2
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com;charlie.clark@icucsolutions.com;dataexchange@profdata.com;dershem.dennis@yahoo.com;gilad.keren@icucsolutions.com',
			--
			
				@subject=@Subject1,@body=@errMessage2	--		
	
       end   






return
end
GO
