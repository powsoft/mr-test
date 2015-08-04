USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMR_INCORRECT_COSTZONE_RECORDS_EMAIL_2015]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMR_INCORRECT_COSTZONE_RECORDS_EMAIL_2015]
as




declare @costtablerecordid int
declare @RecordID int
declare @mridreturned int
declare @RecordCount1 int
declare @RecordCount2 int
declare @RecordCount3 int
declare @RecordCount4 int
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
DECLARE @Storenumber varchar(8)=''
DECLARE  @source varchar(20)=''
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
                             
                              
declare @rec3 cursor
DECLARE @badrecids3 varchar(max)=''
DECLARE @requeststatus3  varchar(4)=''
DECLARE @statusName3 varchar(max)=''
DECLARE @Subject3 VARCHAR(MAX)=''
DECLARE @errMessage3 varchar(max)=''
DECLARE @badrecords3 table(SubmitDateTime date,
                             requeststatus smallint,supplierID int,chainid int,chainname varchar,suppliername varchar,RequestTypeID int
                             ) 
 declare @rec4 cursor
DECLARE @badrecids4 varchar(max)=''
DECLARE @requeststatus4  varchar(4)=''
DECLARE @statusName4 varchar(max)=''
DECLARE @Subject4 VARCHAR(MAX)=''
DECLARE @errMessage4 varchar(max)=''
DECLARE @badrecords4 table(SubmitDateTime date,
                             requeststatus smallint,supplierID int,chainid int,chainname varchar,suppliername varchar,RequestTypeID int
                             )                              
                                                        
  
  DECLARE @filename varchar(max)=''        
                           

begin 

       
/***********************'Cost Records with missing costzones***********************/       
 
 select @RecordCount1=count(*)
from MaintenanceRequests c
where RequestStatus  not in (5,999)
and dtstorecontexttypeid=3
and DATEADD(day, -30, getdate()) < datetimecreated
and PDIParticipant=0
and costzoneid is  null

if @RecordCount1 >0


set @errMessage1+=cast(@RecordCount1 as varchar)+' Records with missing cost zones' +CHAR(13)+CHAR(10)

if @errMessage1 <>''
begin;
		
set @Subject1 ='Records with missing cost zones' 
       
set @rec1 = CURSOR local fast_forward FOR
select  distinct source,	filename,chainid,chainname,SupplierID,suppliername
	from (
	select   'Costs' source,
	filename,m.chainid,c.chainname,m.SupplierID,suppliername
	from MaintenanceRequests m
	inner join [DataTrue_EDI].[dbo].[Costs] p
	on datatrue_edi_costs_recordid=recordid
	inner join chains c
	on c.ChainID=dtchainid
	inner join suppliers s
	on s.SupplierID=dtsupplierid
    where m.RequestStatus  not in (5,999)
	and m.dtstorecontexttypeid=3
	and DATEADD(day, -30, getdate()) < m.datetimecreated
	and m.PDIParticipant=0
	and costzoneid is null
	
	UNION
	select   'Promotions' source,
	filename,m.chainid,c.chainname,m.SupplierID,s.suppliername
	from MaintenanceRequests m
	inner join [DataTrue_EDI].[dbo].[promotions] p
	on datatrue_edi_promotions_recordid=recordid
	inner join chains c
	on c.ChainID=m.chainid
	inner join suppliers s
	on s.SupplierID=m.SupplierID
    where m.RequestStatus  not in (5,999)
	and m.dtstorecontexttypeid=3
	and DATEADD(day, -30, getdate()) < m.datetimecreated
	and m.PDIParticipant=0
	and costzoneid is null)a
	order by  source,chainid,supplierid
	
   set @errMessage1+=CHAR(13)+CHAR(10)+ 'Source   '+ 'filename   '+'     Chain id,Name                       '+'             Supplier id,Name '+CHAR(13)+CHAR(10)
   open @rec1 

  fetch next from @rec1 into @source,@filename,@chainid,@chainname,@SupplierID,@suppliername

    while @@FETCH_STATUS = 0
	begin
	set @errMessage1+=CHAR(13)+CHAR(10)+ @source+'    '+@filename+'        '+@chainid+','+@chainname+'   '+@SupplierID+','+@suppliername+CHAR(13)+CHAR(10)
 			
	fetch next from @rec1 into  @source,@filename,@chainid,@chainname,@SupplierID,@suppliername
	end
	
close @rec1
deallocate @rec1
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com'--;tatiana.alperovitch@icucsolutions.com;'
			,				
				@subject=@Subject1,@body=@errMessage1	
	
       end   
      
       


--  /***********************'Records with incorrect cost zones***********************/       
 
select @RecordCount2=count(*)
 -- select distinct m.SupplierID,m.chainid,m.costzoneid,c.costzoneid
from MaintenanceRequests m
LEFT OUTER JOIN  CostZones c
on ChainID=OwnerEntityID
and m.SupplierID=c.SupplierId
and m.CostZoneID=c.costzoneid
where c.costzoneid is  null
and RequestStatus  not in (5,999)
and dtstorecontexttypeid=3
--and datetimecreated>GETDATE()-160
and PDIParticipant=0
and m.costzoneid is not null

if @RecordCount2 >0

set @errMessage2+=cast(@RecordCount2 as varchar)+' Records with incorrect costzones' +CHAR(13)+CHAR(10)

if @errMessage2 <>''
begin;
		
set @Subject2 ='Records with Incorrect costzones' 
       

       
set @rec2 = CURSOR local fast_forward FOR
select  distinct source,	filename,chainid,chainname,SupplierID,suppliername
	from (
	select   'Costs' source,
	filename,m.chainid,c.chainname,m.SupplierID,suppliername
	from MaintenanceRequests m
	inner join [DataTrue_EDI].[dbo].[Costs] p
	on datatrue_edi_costs_recordid=recordid
	inner join chains c
	on c.ChainID=dtchainid
	inner join suppliers s
	on s.SupplierID=dtsupplierid
    LEFT OUTER JOIN  CostZones z
	on m.ChainID=OwnerEntityID
	and m.SupplierID=z.SupplierId
	and m.CostZoneID=z.costzoneid
	where z.costzoneid is  null
	and m.RequestStatus  not in (5,999)
	and m.dtstorecontexttypeid=3
	--and datetimecreated>GETDATE()-160
	and m.PDIParticipant=0
	and m.costzoneid is not null
	UNION
	select   'Promotions' source,
	filename,m.chainid,c.chainname,m.SupplierID,s.suppliername
		from MaintenanceRequests m
	inner join [DataTrue_EDI].[dbo].[Promotions] p
	on datatrue_edi_Promotions_recordid=recordid
	inner join chains c
	on c.ChainID=m.chainid
	inner join suppliers s
	on s.SupplierID=m.supplierid
    LEFT OUTER JOIN  CostZones z
	on m.ChainID=OwnerEntityID
	and m.SupplierID=z.SupplierId
	and m.CostZoneID=z.costzoneid
	where z.costzoneid is  null
	and m.RequestStatus  not in (5,999)
	and m.dtstorecontexttypeid=3
	--and datetimecreated>GETDATE()-160
	and m.PDIParticipant=0
	and m.costzoneid is not null)a
		order by  source,chainid,supplierid
	
   set @errMessage2+=CHAR(13)+CHAR(10)+ 'Source   '+ 'filename   '+'     Chain id,Name                       '+'             Supplier id,Name '+CHAR(13)+CHAR(10)
   open @rec2

  fetch next from @rec2 into @source,@filename,@chainid,@chainname,@SupplierID,@suppliername

    while @@FETCH_STATUS = 0
	begin
	set @errMessage2+=CHAR(13)+CHAR(10)+ @source+'    '+@filename+'        '+@chainid+','+@chainname+'   '+@SupplierID+','+@suppliername+CHAR(13)+CHAR(10)
 			
	fetch next from @rec2 into  @source,@filename,@chainid,@chainname,@SupplierID,@suppliername
	end
	
close @rec2
deallocate @rec2
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com'--;tatiana.alperovitch@icucsolutions.com;'
			,				
				@subject=@Subject2,@body=@errMessage2	
	
       end   
       
       
       
       
       
       
       
       
       
       
       
       
--       /***********************'Cost Records with missing ownermarketid***********************/       
 
 select @RecordCount3=count(*)
from MaintenanceRequests c
where RequestStatus  not in (5,999)
and dtstorecontexttypeid=3
and DATEADD(day, -30, getdate()) < datetimecreated
and PDIParticipant=1
and ownermarketid is null

if @RecordCount3 >0


set @errMessage3+='Please check files below. Found missing ownermarketid' +CHAR(13)+CHAR(10)

if @errMessage3 <>''
begin;
		
set @Subject3 ='Cost Records with missing ownermarketid' 
       
set @rec3 = CURSOR local fast_forward FOR
select  distinct source,	filename,chainid,chainname,SupplierID,suppliername
	from (
	select   'Costs' source,
	filename,m.chainid,c.chainname,m.SupplierID,suppliername
	from MaintenanceRequests m
	inner join [DataTrue_EDI].[dbo].[Costs] p
	on datatrue_edi_costs_recordid=recordid
	inner join chains c
	on c.ChainID=dtchainid
	inner join suppliers s
	on s.SupplierID=dtsupplierid
    where m.RequestStatus  not in (5,999)
	and m.dtstorecontexttypeid=3
	and DATEADD(day, -30, getdate()) < m.datetimecreated
	and m.PDIParticipant=1
	and m.OwnerMarketID is null
	
	UNION
	select   'Promotions' source,
	filename,m.chainid,c.chainname,m.SupplierID,s.suppliername
	from MaintenanceRequests m
	inner join [DataTrue_EDI].[dbo].[promotions] p
	on datatrue_edi_promotions_recordid=recordid
	inner join chains c
	on c.ChainID=m.chainid
	inner join suppliers s
	on s.SupplierID=m.SupplierID
    where m.RequestStatus  not in (5,999)
	and m.dtstorecontexttypeid=3
	and DATEADD(day, -30, getdate()) < m.datetimecreated
	and m.PDIParticipant=1
	and m.OwnerMarketID is null)a
	order by  source,chainid,supplierid
	
   set @errMessage3+=CHAR(13)+CHAR(10)+ 'Source   '+ 'filename   '+'     Chain id,Name                       '+'             Supplier id,Name '+CHAR(13)+CHAR(10)
   open @rec3 

  fetch next from @rec3 into @source,@filename,@chainid,@chainname,@SupplierID,@suppliername

    while @@FETCH_STATUS = 0
	begin
	set @errMessage3+=CHAR(13)+CHAR(10)+ @source+'    '+@filename+'        '+@chainid+','+@chainname+'   '+@SupplierID+','+@suppliername+CHAR(13)+CHAR(10)
 			
	fetch next from @rec1 into  @source,@filename,@chainid,@chainname,@SupplierID,@suppliername
	end
	
close @rec3
deallocate @rec3
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com'--;tatiana.alperovitch@icucsolutions.com;'
			,				
				@subject=@Subject3,@body=@errMessage3	
	
       end   

       
  
--   /***********************'Cost Records with incorrect ownermarcetid ***********************/       
 
select @RecordCount4=count(*)
 -- select distinct m.SupplierID,m.chainid,m.ownermarketid,c.*
 from MaintenanceRequests m
LEFT OUTER JOIN  CostZones c
on ChainID=OwnerEntityID
and m.SupplierID=c.SupplierId
and m.CostZoneID=c.costzoneid
and m.OwnerMarketID =c.OwnerMarketID
where c.OwnerMarketID is  null
and RequestStatus  not in (5,999)
and dtstorecontexttypeid=3
--and datetimecreated>GETDATE()-160
and PDIParticipant=1
and m.OwnerMarketID is not null



select* from CostZones where SupplierID=40557 and OwnerEntityID=40393
if @RecordCount4 >0


set @errMessage4+=cast(@RecordCount4 as varchar)+'Cost Records with incorrect OwnerMarketID' +CHAR(13)+CHAR(10)

if @errMessage4 <>''
begin;
		
set @Subject4 ='Cost Records with incorrect OwnerMarketID' 
       
set @rec4 = CURSOR local fast_forward FOR
select  distinct source,	filename,chainid,chainname,SupplierID,suppliername
	from (
	select   'Costs' source,
	filename,m.chainid,c.chainname,m.SupplierID,suppliername
	from MaintenanceRequests m
	inner join [DataTrue_EDI].[dbo].[Costs] p
	on datatrue_edi_costs_recordid=recordid
	inner join chains c
	on c.ChainID=dtchainid
	inner join suppliers s
	on s.SupplierID=dtsupplierid
    LEFT OUTER JOIN  CostZones z
	on m.ChainID=OwnerEntityID
	and m.SupplierID=z.SupplierId
	and m.OwnerMarketID=z.OwnerMarketID
	where z.OwnerMarketID is  null
	and m.RequestStatus  not in (5,999)
	and m.dtstorecontexttypeid=3
	--and datetimecreated>GETDATE()-160
	and m.PDIParticipant=1
	and m.OwnerMarketID is not null
	UNION
	select   'Promotions' source,
	filename,m.chainid,c.chainname,m.SupplierID,s.suppliername
		from MaintenanceRequests m
	inner join [DataTrue_EDI].[dbo].[Promotions] p
	on datatrue_edi_Promotions_recordid=recordid
	inner join chains c
	on c.ChainID=m.chainid
	inner join suppliers s
	on s.SupplierID=m.supplierid
    LEFT OUTER JOIN  CostZones z
	on m.ChainID=OwnerEntityID
	and m.SupplierID=z.SupplierId
	and m.OwnerMarketID=z.OwnerMarketID
	where z.OwnerMarketID is  null
	and m.RequestStatus  not in (5,999)
	and m.dtstorecontexttypeid=3
	--and datetimecreated>GETDATE()-160
	and m.PDIParticipant=1
	and m.OwnerMarketID is not null)a
		order by  source,chainid,supplierid
	
   set @errMessage4+=CHAR(13)+CHAR(10)+ 'Source   '+ 'filename   '+'     Chain id,Name                       '+'             Supplier id,Name '+CHAR(13)+CHAR(10)
   open @rec4

  fetch next from @rec4 into @source,@filename,@chainid,@chainname,@SupplierID,@suppliername

    while @@FETCH_STATUS = 0
	begin
	set @errMessage4+=CHAR(13)+CHAR(10)+ @source+'    '+@filename+'        '+@chainid+','+@chainname+'   '+@SupplierID+','+@suppliername+CHAR(13)+CHAR(10)
 			
	fetch next from @rec4 into  @source,@filename,@chainid,@chainname,@SupplierID,@suppliername
	end
	
close @rec4
deallocate @rec4
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com'--;tatiana.alperovitch@icucsolutions.com;'
			,				
				@subject=@Subject4,@body=@errMessage4	
	
       end  



return
end
GO
