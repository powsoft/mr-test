USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMR_INCORRECT_STORS_RECORDS_EMAIL_2014]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMR_INCORRECT_STORS_RECORDS_EMAIL_2014]
as




declare @costtablerecordid int
declare @RecordID int
declare @mridreturned int
declare @RecordCount1 int
declare @RecordCount11 int
declare @RecordCount2 int
declare @RecordCount22 int
declare @RecordCount3 int
declare @RecordCount31 int
declare @RecordCount30 int
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
                             
declare @rec11 cursor
DECLARE @badrecids11 varchar(max)=''
DECLARE @requeststatus11  varchar(4)=''
DECLARE @statusName11 varchar(max)=''
DECLARE @Subject11 VARCHAR(MAX)=''
DECLARE @errMessage11 varchar(max)=''
DECLARE @badrecords11 table(SubmitDateTime date,StartDateTime date,
                             requeststatus smallint,supplierID int,chainid int,chainname varchar,suppliername varchar,RequestTypeID int
                             ) 
                             
declare @rec10 cursor
DECLARE @badrecids10 varchar(max)=''
DECLARE @requeststatus10 varchar(4)=''
DECLARE @statusName10 varchar(max)=''
DECLARE @Subject10 VARCHAR(MAX)=''
DECLARE @errMessage10 varchar(max)=''
DECLARE @badrecords10 table(SubmitDateTime date,StartDateTime date,
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
                             
                              
declare @rec22 cursor
DECLARE @badrecids22 varchar(max)=''
DECLARE @requeststatus22  varchar(4)=''
DECLARE @statusName22 varchar(max)=''
DECLARE @Subject22 VARCHAR(MAX)=''
DECLARE @errMessage22 varchar(max)=''
DECLARE @badrecords22 table(SubmitDateTime date,
                             requeststatus smallint,supplierID int,chainid int,chainname varchar,suppliername varchar,RequestTypeID int
                             )   
                             
                             
                             
declare @rec30 cursor
DECLARE @badrecids30 varchar(max)=''
DECLARE @requeststatus30  varchar(4)=''
DECLARE @statusName30 varchar(max)=''
DECLARE @Subject30 VARCHAR(MAX)=''
DECLARE @errMessage30 varchar(max)=''
DECLARE @badrecords30 table(SubmitDateTime date,
                             requeststatus smallint,supplierID int,chainid int,chainname varchar,suppliername varchar,RequestTypeID int
                             )    
                             
declare @rec31 cursor
DECLARE @badrecids31 varchar(max)=''
DECLARE @requeststatus31  varchar(4)=''
DECLARE @statusName31 varchar(max)=''
DECLARE @Subject31 VARCHAR(MAX)=''
DECLARE @errMessage31 varchar(max)=''
DECLARE @badrecords31 table(SubmitDateTime date,
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

begin 

DECLARE @badrecidsCStEDI varchar(max)=''
DECLARE @SubjectCStEDI VARCHAR(MAX)=''
DECLARE @errMessageCStEDI varchar(max)=''
DECLARE @badrecordsCStEDI table (recordid int)

DECLARE @badrecidsCSt varchar(max)=''
DECLARE @SubjectCSt VARCHAR(MAX)=''
DECLARE @errMessageCSt varchar(max)=''
DECLARE @badrecordsCSt table (recordid int)

DECLARE @badrecidsPSt varchar(max)=''
DECLARE @SubjectPSt VARCHAR(MAX)=''
DECLARE @errMessagePSt varchar(max)=''
DECLARE @badrecordsPSt table (recordid int)

          
       
/***********************'Find EDI records with Invalid Store(s) in Cost Table***********************/       
 
 select @RecordCount1=count(*)
from DataTrue_edi.dbo.costs c
where recordstatus =0
and dtstorecontexttypeid=-1
and DATEADD(day, -30, getdate()) < datetimecreated
AND Recordsource like '%EDI%'
and (PDIParticipant=0 or Bipad is NOT null)   
and StoreNumber is not null
and StoreNumber<>''

if @RecordCount1 >0


set @errMessage1+=cast(@RecordCount1 as varchar)+' EDI Records with Invalid Store(s) in Cost Table' +CHAR(13)+CHAR(10)

if @errMessage1 <>''
begin;
		
set @Subject1 ='EDI Records with Invalid Store(s) in Cost Table' 
       
set @rec1 = CURSOR local fast_forward FOR

	select  distinct 
	PDIParticipant,storenumber,dtchainid,c.chainname,dtSupplierID,suppliername
	from [DataTrue_EDI].[dbo].[Costs] p
	inner join chains c
	on c.ChainID=dtchainid
	inner join suppliers s
	on SupplierID=dtsupplierid
    where recordstatus =0
    and dtstorecontexttypeid=-1
    --and DATEADD(day, -30, getdate()) < p.datetimecreated
    AND Recordsource like '%EDI%'
    and (PDIParticipant=0 or Bipad is NOT null)   
    and StoreNumber is not null
    and StoreNumber<>''
	order by PDIParticipant,dtchainid,storenumber,dtsupplierid
	
   set @errMessage1+=CHAR(13)+CHAR(10)+ 'Store    '+'     Chain id,Name                       '+'             Supplier id,Name '+CHAR(13)+CHAR(10)
   open @rec1 

  fetch next from @rec1 into @Storenumber,@chainid,@chainname,@SupplierID,@suppliername

    while @@FETCH_STATUS = 0
	begin
	set @errMessage1+=CHAR(13)+CHAR(10)+@Storenumber+'        '+@chainid+','+@chainname+'   '+@SupplierID+','+@suppliername+CHAR(13)+CHAR(10)
 			
	fetch next from @rec1 into @Storenumber,@chainid,@chainname,@SupplierID,@suppliername
	end
	
close @rec1
deallocate @rec1
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com;tatiana.alperovitch@icucsolutions.com;'
			,				
				@subject=@Subject1,@body=@errMessage1	
	
       end   
   /***********************'Find PDI TMP records with Invalid Store(s) in Cost Table***********************/     
      select @RecordCount1=count(*)
from DataTrue_edi.dbo.costs c
where recordstatus =0
and dtstorecontexttypeid=-1
--and DATEADD(day, -30, getdate()) < datetimecreated
AND PDIParticipant=1
and (Bipad is null or bipad='')

and StoreNumber is not null
and StoreNumber<>'' 

if @RecordCount1 >0


set @errMessage11+=cast(@RecordCount1 as varchar)+' records with Invalid Store(s) in Cost Table' +CHAR(13)+CHAR(10)

if @errMessage11 <>''
begin;
		
set @Subject11 ='PDI records with Invalid Store(s) in Cost Table' 
       
 
       set @rec11 = CURSOR local fast_forward FOR

	select  distinct 
	storenumber,dtchainid,c.chainname,dtSupplierID,suppliername
	from [DataTrue_EDI].[dbo].[Costs] p
	inner join chains c
	on c.ChainID=dtchainid
	inner join suppliers s
	on SupplierID=dtsupplierid
    where recordstatus =0
    and dtstorecontexttypeid=-1
    and StoreNumber is not null
    and StoreNumber<>''
    and (PDIParticipant=1 and  Bipad is  null)
	order by dtchainid,storenumber,dtsupplierid
	
   set @errMessage11+=CHAR(13)+CHAR(10)+ 'Store    '+'     Chain id,Name                       '+'             Supplier id,Name '+CHAR(13)+CHAR(10)
   open @rec11 

  fetch next from @rec11 into @Storenumber,@chainid,@chainname,@SupplierID,@suppliername

    while @@FETCH_STATUS = 0
	begin
	set @errMessage11+=CHAR(13)+CHAR(10)+@Storenumber+'        '+@chainid+','+@chainname+'   '+@SupplierID+','+@suppliername+CHAR(13)+CHAR(10)
 			
	fetch next from @rec11 into @Storenumber,@chainid,@chainname,@SupplierID,@suppliername
	end
	
close @rec11
deallocate @rec11
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com;gilad.keren@icucsolutions.com;charlie.clark@icucsolutions.com;dataexchange@profdata.com'
			,				
				@subject=@Subject11,@body=@errMessage11	
	
       end        
            
            
            
 /***********************'Find not  TMP records with Invalid Store(s) in Cost Table***********************/     
      select @RecordCount1=count(*)
from DataTrue_edi.dbo.costs c
where recordstatus =0
and dtstorecontexttypeid=-1
and DATEADD(day, -30, getdate()) < datetimecreated
AND Recordsource like '%TMP%'
    and StoreNumber is not null
    and StoreNumber<>''
    and (PDIParticipant=0 or Bipad is NOT null)

if @RecordCount1 >0


set @errMessage10+=cast(@RecordCount1 as varchar)+'  records with Invalid Store(s) in Cost Table' +CHAR(13)+CHAR(10)

if @errMessage10 <>''
begin;
		
set @Subject10 ='Not PDI records with Invalid Store(s) in Cost Table' 
       
 
       set @rec10 = CURSOR local fast_forward FOR

	select  distinct 
	storenumber,dtchainid,c.chainname,dtSupplierID,suppliername
	from [DataTrue_EDI].[dbo].[Costs] p
	inner join chains c
	on c.ChainID=dtchainid
	inner join suppliers s
	on SupplierID=dtsupplierid
    where recordstatus =0
    and dtstorecontexttypeid=-1
    and DATEADD(day, -30, getdate()) < p.datetimecreated
    AND Recordsource like '%TMP%'
    and StoreNumber is not null
    and StoreNumber<>''
    and (PDIParticipant=0 or Bipad is NOT null)
	order by dtchainid,storenumber,dtsupplierid
	
   set @errMessage10+=CHAR(13)+CHAR(10)+'Store    '+'     Chain id,Name                       '+'             Supplier id,Name '+CHAR(13)+CHAR(10)
   open @rec10

  fetch next from @rec10 into @Storenumber,@chainid,@chainname,@SupplierID,@suppliername

    while @@FETCH_STATUS = 0
	begin
	set @errMessage10+=CHAR(13)+CHAR(10)+@Storenumber+'        '+@chainid+','+@chainname+'   '+@SupplierID+','+@suppliername+CHAR(13)+CHAR(10)
 			
	fetch next from @rec10 into @Storenumber,@chainid,@chainname,@SupplierID,@suppliername
	end
	
close @rec10
deallocate @rec10
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com;gilad.keren@icucsolutions.com;charlie.clark@icucsolutions.com;bill.harris@icucsolutions.com;amol.sayal@icucsolutions.com'
			,				
				@subject=@Subject10,@body=@errMessage10	
	
       end        
            
       
       
 select @RecordCount2=count(*)
from [DataTrue_EDI].[dbo].[promotions] p
where loadstatus =0
and dtstorecontexttypeid=-1
and DATEADD(day, -30, getdate()) < datetimecreated

if @RecordCount2 >0
set @errMessage2+=cast(@RecordCount2 as varchar)+' Promotion Records can not be moved to MR.Invalid Store(s) in Promotion Table.' +CHAR(13)+CHAR(10)

if @errMessage2 <>''
begin;
		
set @Subject2 ='Promotion Records can not be moved to MR.Invalid Store(s) in Promotion Table.' 
       
set @rec2 = CURSOR local fast_forward FOR

	select  distinct 
	storenumber,p.chainid,c.chainname,p.SupplierID,s.suppliername
	from [DataTrue_EDI].[dbo].[Promotions] p
	inner join chains c
	on c.ChainID=p.chainid
	inner join suppliers s
	on s.SupplierID=p.supplierid
    where loadstatus =0
    and dtstorecontexttypeid=-1
    and DATEADD(day, -30, getdate()) < p.datetimecreated
	order by p.chainid,storenumber,p.supplierid
	
	
   set @errMessage2+=CHAR(13)+CHAR(10)+ 'Store    '+'     Chain id,Name                       '+'             Supplier id,Name '+CHAR(13)+CHAR(10)
   open @rec2 

  fetch next from @rec2 into @Storenumber,@chainid,@chainname,@SupplierID,@suppliername

    while @@FETCH_STATUS = 0
	begin
	set @errMessage2+=CHAR(13)+CHAR(10)+@Storenumber+'        '+@chainid+','+@chainname+'   '+@SupplierID+','+@suppliername+CHAR(13)+CHAR(10)
 			
	fetch next from @rec2 into @Storenumber,@chainid,@chainname,@SupplierID,@suppliername
	end
	
close @rec2
deallocate @rec2
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com;tatiana.alperovitch@icucsolutions.com;charlie.clark@icucsolutions.com'
			,				
				@subject=@Subject2,@body=@errMessage2	
	
       end        
       
       
       
       
       
       
 select @RecordCount3=count(*)
from [DataTrue_EDI].[dbo].[promotions] p
where loadstatus =0
and p.storeid is null
and ISNUMERIC(LTRIM(rtrim(p.storenumber)))<>1
and p.StoreNumber is not null 
and p.StoreNumber <>''
and DATEADD(day, -30, getdate()) < datetimecreated

if @RecordCount3 >0
set @errMessage3+=cast(@RecordCount31 as varchar)+' Promotion Records can not be moved to MR.Invalid Store(s) in Promotion Table.' +CHAR(13)+CHAR(10)

if @errMessage3 <>''
begin;
		
set @Subject3 ='Promotion Records can not be moved to MR.Invalid Store(s) in Promotion Table.' 
       
set @rec31 = CURSOR local fast_forward FOR

	select  distinct 
	storenumber,p.chainid,c.chainname,p.SupplierID,s.suppliername
	from [DataTrue_EDI].[dbo].[Promotions] p
	inner join chains c
	on c.ChainID=p.chainid
	inner join suppliers s
	on s.SupplierID=p.supplierid
    where loadstatus =0
and p.storeid is null
and ISNUMERIC(LTRIM(rtrim(p.storenumber)))<>1
and p.StoreNumber is not null 
and p.StoreNumber <>''
and DATEADD(day, -30, getdate()) < p.datetimecreated
	order by p.chainid,storenumber,p.supplierid
	
	
   set @errMessage3+=CHAR(13)+CHAR(10)+ 'Store    '+'     Chain id,Name                       '+'             Supplier id,Name '+CHAR(13)+CHAR(10)
   open @rec3 

  fetch next from @rec3 into @Storenumber,@chainid,@chainname,@SupplierID,@suppliername

    while @@FETCH_STATUS = 0
	begin
	set @errMessage3+=CHAR(13)+CHAR(10)+@Storenumber+'        '+@chainid+','+@chainname+'   '+@SupplierID+','+@suppliername+CHAR(13)+CHAR(10)
 			
	fetch next from @rec31 into @Storenumber,@chainid,@chainname,@SupplierID,@suppliername
	end
	
close @rec3
deallocate @rec3
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com;tatiana.alperovitch@icucsolutions.com;charlie.clark@icucsolutions.com'
			,				
				@subject=@Subject31,@body=@errMessage3	
	
       end        
       
       
       
 select @RecordCount31=count(*)
from [DataTrue_EDI].[dbo].[promotions] p
where loadstatus =0
and p.storeid is null
and ISNUMERIC(LTRIM(rtrim(p.StoreIdentifier)))<>1
and p.StoreIdentifier is not null 
and p.StoreIdentifier <>''
and PDIParticipant=1
and DATEADD(day, -30, getdate()) < datetimecreated

if @RecordCount31 >0
set @errMessage31+=cast(@RecordCount31 as varchar)+' Promotion Records can not be moved to MR.Invalid Store(s) in Promotion Table.' +CHAR(13)+CHAR(10)

if @errMessage31 <>''
begin;
		
set @Subject31 ='Promotion Records can not be moved to MR.Invalid Store(s) in Promotion Table.' 
       
set @rec31 = CURSOR local fast_forward FOR

	select  distinct 
	storenumber,p.chainid,c.chainname,p.SupplierID,s.suppliername
	from [DataTrue_EDI].[dbo].[Promotions] p
	inner join chains c
	on c.ChainID=p.chainid
	inner join suppliers s
	on s.SupplierID=p.supplierid
    where loadstatus =0
and p.storeid is null
and ISNUMERIC(LTRIM(rtrim(p.storeidentifier)))<>1
and p.storeidentifier is not null 
and p.storeidentifier <>''
and DATEADD(day, -30, getdate()) < p.datetimecreated
and PDIParticipant=1
	order by p.chainid,storenumber,p.supplierid
	
	
   set @errMessage31+=CHAR(13)+CHAR(10)+ 'Store    '+'     Chain id,Name                       '+'             Supplier id,Name '+CHAR(13)+CHAR(10)
   open @rec31 

  fetch next from @rec31 into @Storenumber,@chainid,@chainname,@SupplierID,@suppliername

    while @@FETCH_STATUS = 0
	begin
	set @errMessage31+=CHAR(13)+CHAR(10)+@Storenumber+'        '+@chainid+','+@chainname+'   '+@SupplierID+','+@suppliername+CHAR(13)+CHAR(10)
 			
	fetch next from @rec31 into @Storenumber,@chainid,@chainname,@SupplierID,@suppliername
	end
	
close @rec31
deallocate @rec31
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com;dataexchange@profdata.com;gilad.keren@icucsolutions.com;charlie.clark@icucsolutions.com'
			,				
				@subject=@Subject31,@body=@errMessage31	
	
       end        
       
       
       
       
select @RecordCount30=count(*)
from [DataTrue_EDI].[dbo].[promotions] p
where loadstatus =0
and p.storeid is null
and ISNUMERIC(LTRIM(rtrim(p.StoreIdentifier)))<>1
and p.StoreIdentifier is not null 
and p.StoreIdentifier <>''
and PDIParticipant=0
and DATEADD(day, -30, getdate()) < datetimecreated

if @RecordCount30 >0
set @errMessage30+=cast(@RecordCount30 as varchar)+' Promotion Records can not be moved to MR.Invalid Store(s) in Promotion Table.' +CHAR(13)+CHAR(10)

if @errMessage30 <>''
begin;
		
set @Subject30 ='Promotion Records can not be moved to MR.Invalid Store(s) in Promotion Table.' 
       
set @rec30 = CURSOR local fast_forward FOR

	select  distinct 
	storenumber,p.chainid,c.chainname,p.SupplierID,s.suppliername
	from [DataTrue_EDI].[dbo].[Promotions] p
	inner join chains c
	on c.ChainID=p.chainid
	inner join suppliers s
	on s.SupplierID=p.supplierid
    where loadstatus =0
and p.storeid is null
and ISNUMERIC(LTRIM(rtrim(p.storeidentifier)))<>1
and p.storeidentifier is not null 
and p.storeidentifier <>''
and DATEADD(day, -30, getdate()) < p.datetimecreated
and PDIParticipant=0
	order by p.chainid,storenumber,p.supplierid
	
	
   set @errMessage30+=CHAR(13)+CHAR(10)+ 'Store    '+'     Chain id,Name                       '+'             Supplier id,Name '+CHAR(13)+CHAR(10)
   open @rec30 

  fetch next from @rec30 into @Storenumber,@chainid,@chainname,@SupplierID,@suppliername

    while @@FETCH_STATUS = 0
	begin
	set @errMessage30+=CHAR(13)+CHAR(10)+@Storenumber+'        '+@chainid+','+@chainname+'   '+@SupplierID+','+@suppliername+CHAR(13)+CHAR(10)
 			
	fetch next from @rec30 into @Storenumber,@chainid,@chainname,@SupplierID,@suppliername
	end
	
close @rec30
deallocate @rec30
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com;amol.sayal@icucsolutions.com;gilad.keren@icucsolutions.com;charlie.clark@icucsolutions.com'
			,				
				@subject=@Subject30,@body=@errMessage30	
	
       end        











return
end
GO
