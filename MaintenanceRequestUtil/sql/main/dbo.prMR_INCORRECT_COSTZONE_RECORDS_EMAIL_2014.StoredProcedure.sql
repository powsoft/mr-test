USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMR_INCORRECT_COSTZONE_RECORDS_EMAIL_2014]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMR_INCORRECT_COSTZONE_RECORDS_EMAIL_2014]
as




declare @costtablerecordid int
declare @RecordID int
declare @mridreturned int
declare @RecordCount1 int
declare @RecordCount2 int
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
and costzoneid is null

if @RecordCount1 >0


set @errMessage1+=cast(@RecordCount1 as varchar)+' Records with missing costzones' +CHAR(13)+CHAR(10)

if @errMessage1 <>''
begin;
		
set @Subject1 ='Cost Records with missing costzones' 
       
set @rec1 = CURSOR local fast_forward FOR
select  distinct TableName,	filename,dtchainid,chainname,dtSupplierID,suppliername
	from (
	select   'Costs' TableName,
	filename,dtchainid,c.chainname,dtSupplierID,suppliername
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
	select   'Promotions' TableName,
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
	order by  tablename,dtchainid,dtsupplierid
	
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
       
       
       /***********************'Cost Records with missing ownermarketid***********************/       
 
 select @RecordCount1=count(*)
from MaintenanceRequests c
where RequestStatus  not in (5,999)
and dtstorecontexttypeid=3
and DATEADD(day, -30, getdate()) < datetimecreated
and PDIParticipant=1
and ownermarketid is null

if @RecordCount1 >0


set @errMessage1+=cast(@RecordCount1 as varchar)+' Records with missing ownermarketid' +CHAR(13)+CHAR(10)

if @errMessage1 <>''
begin;
		
set @Subject1 ='Cost Records with missing ownermarketid' 
       
set @rec1 = CURSOR local fast_forward FOR

	select  distinct 
	filename,dtchainid,c.chainname,dtSupplierID,suppliername
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
	and m.ownermarketid is null
	order by  dtchainid,dtsupplierid
	
   set @errMessage1+=CHAR(13)+CHAR(10)+ 'filename   '+'     Chain id,Name                       '+'             Supplier id,Name '+CHAR(13)+CHAR(10)
   open @rec1 

  fetch next from @rec1 into @filename,@chainid,@chainname,@SupplierID,@suppliername

    while @@FETCH_STATUS = 0
	begin
	set @errMessage1+=CHAR(13)+CHAR(10)+@filename+'        '+@chainid+','+@chainname+'   '+@SupplierID+','+@suppliername+CHAR(13)+CHAR(10)
 			
	fetch next from @rec1 into @filename,@chainid,@chainname,@SupplierID,@suppliername
	end
	
close @rec1
deallocate @rec1
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com;tatiana.alperovitch@icucsolutions.com;'
			,				
				@subject=@Subject1,@body=@errMessage1	
	
       end   
       
  /***********************'Cost Records with incorrect cost zones***********************/       
 
select @RecordCount1=count(*)
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



select* from CostZones where SupplierID=40557 and OwnerEntityID=40393
if @RecordCount1 >0


set @errMessage1+=cast(@RecordCount1 as varchar)+'Cost Records with incorrect cost zones' +CHAR(13)+CHAR(10)

if @errMessage1 <>''
begin;
		
set @Subject1 ='Cost Records with incorrect cost zones' 
       
set @rec2 = CURSOR local fast_forward FOR

	select  distinct 
	filename,dtchainid,c.chainname,dtSupplierID,suppliername
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
		order by  dtchainid,dtsupplierid
	
   set @errMessage1+=CHAR(13)+CHAR(10)+ 'filename   '+'     Chain id,Name                       '+'             Supplier id,Name '+CHAR(13)+CHAR(10)
   open @rec2

  fetch next from @rec2 into @filename,@chainid,@chainname,@SupplierID,@suppliername

    while @@FETCH_STATUS = 0
	begin
	set @errMessage1+=CHAR(13)+CHAR(10)+@filename+'        '+@chainid+','+@chainname+'   '+@SupplierID+','+@suppliername+CHAR(13)+CHAR(10)
 			
	fetch next from @rec2 into @filename,@chainid,@chainname,@SupplierID,@suppliername
	end
	
close @rec2
deallocate @rec2
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com'--;tatiana.alperovitch@icucsolutions.com;'
			,				
				@subject=@Subject1,@body=@errMessage1	
	
       end        
       
   /***********************'Find PDI TMP records with Invalid Store(s) in Cost Table***********************/  
   /***********************'Cost Records with incorrect ownermarcetid zones***********************/       
 
select @RecordCount1=count(*)
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
if @RecordCount1 >0


set @errMessage1+=cast(@RecordCount1 as varchar)+'Cost Records with incorrect cost zones' +CHAR(13)+CHAR(10)

if @errMessage1 <>''
begin;
		
set @Subject1 ='Cost Records with incorrect cost zones' 
       
set @rec2 = CURSOR local fast_forward FOR

	select  distinct 
	filename,dtchainid,c.chainname,dtSupplierID,suppliername
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
and m.OwnerMarketID =z.OwnerMarketID
where z.OwnerMarketID is  null
and m.RequestStatus  not in (5,999)
and m.dtstorecontexttypeid=3
--and datetimecreated>GETDATE()-160
and m.PDIParticipant=1
and m.OwnerMarketID is not null
		order by  dtchainid,dtsupplierid
	
   set @errMessage1+=CHAR(13)+CHAR(10)+ 'filename   '+'     Chain id,Name                       '+'             Supplier id,Name '+CHAR(13)+CHAR(10)
   open @rec2

  fetch next from @rec2 into @filename,@chainid,@chainname,@SupplierID,@suppliername

    while @@FETCH_STATUS = 0
	begin
	set @errMessage1+=CHAR(13)+CHAR(10)+@filename+'        '+@chainid+','+@chainname+'   '+@SupplierID+','+@suppliername+CHAR(13)+CHAR(10)
 			
	fetch next from @rec2 into @filename,@chainid,@chainname,@SupplierID,@suppliername
	end
	
close @rec2
deallocate @rec2
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com'--;tatiana.alperovitch@icucsolutions.com;'
			,				
				@subject=@Subject1,@body=@errMessage1	
	
       end        
       
   



return
end
GO
