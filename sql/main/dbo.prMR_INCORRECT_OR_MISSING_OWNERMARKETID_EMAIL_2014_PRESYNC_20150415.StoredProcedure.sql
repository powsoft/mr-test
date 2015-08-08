USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMR_INCORRECT_OR_MISSING_OWNERMARKETID_EMAIL_2014_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMR_INCORRECT_OR_MISSING_OWNERMARKETID_EMAIL_2014_PRESYNC_20150415]
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
DECLARE @SubmitDate DATETIME
DECLARE @StartDateTime DATETIME
DECLARE @chainid varchar(8)=''
DECLARE @chainname varchar(60)=''
DECLARE @SupplierID varchar(8)=''
DECLARE @suppliername varchar(60)=''
DECLARE @Storenumber varchar(8)=''
DECLARE @ownermarketid varchar(8)=''
DECLARE @statusName varchar(max)=''
DECLARE @FileName varchar(max)=''
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

                             
declare @rec2 cursor
DECLARE @Subject2 VARCHAR(MAX)=''
DECLARE @errMessage2 varchar(max)=''                     
                             

begin 

DECLARE @badrecidsCStEDI varchar(max)=''
DECLARE @SubjectCStEDI VARCHAR(MAX)=''
DECLARE @errMessageCStEDI varchar(max)=''
DECLARE @badrecordsCStEDI table (recordid int)



          
       
/***********************'Find EDI records with Invalid Store(s) in Cost Table***********************/       
 
select @RecordCount1=count(*)
from [DataTrue_EDI].[dbo].[costs] p
where recordstatus =0
and PDIParticipant =1
and (OwnerMarketID is null)
and (Bipad is null or Bipad='')
and dtstorecontexttypeid=3
and (StoreNumber is null or StoreNumber='')
and isnull(filetype,'ND')<>'888'
and Recordsource like '%EDI%'

if @RecordCount1 >0


set @errMessage1+=cast(@RecordCount1 as varchar)+' PDI Records with missing OwnerMarketID  ' +CHAR(13)+CHAR(10)

if @errMessage1 <>''
begin;
		
set @Subject1 ='EDI PDI Records with missing OwnerMarketID can not be process by Harmony System ' 
       
set @rec1 = CURSOR local fast_forward FOR

	select  distinct 
	CAST(p.datetimecreated as date) as submitdate,isnull(OwnerMarketID,'NON') as OwnerMarketID,isnull(storenumber,'NON') as storenumber,dtchainid,c.chainname,dtSupplierID,suppliername,filename
	from [DataTrue_EDI].[dbo].[Costs] p
	inner join chains c
	on c.ChainID=dtchainid
	inner join suppliers s
	on SupplierID=dtsupplierid
    where recordstatus =0
    and PDIParticipant =1
	and (OwnerMarketID is null)
	and (Bipad is null or Bipad='')
	and dtstorecontexttypeid=3
	and (StoreNumber is null or StoreNumber='')
	and isnull(filetype,'ND')<>'888'
	and Recordsource like '%EDI%'
	and p.datetimecreated>GETDATE()-35
	order by dtchainid,c.chainname,dtSupplierID,suppliername,OwnerMarketID,submitdate
	
set @errMessage1+=CHAR(13)+CHAR(10)+ 'Submit Date    '+ 'Store    '+ 'OwnerMarketID    '+'     Chain id,Name                       '+'             Supplier id,Name '+'             File Name '+CHAR(13)+CHAR(10)
open @rec1 

fetch next from @rec1 into @submitdate,@OwnerMarketID,@Storenumber,@chainid,@chainname,@SupplierID,@suppliername,@filename

while @@FETCH_STATUS = 0
begin
set @errMessage1+=CHAR(13)+CHAR(10)+cast(@submitdate as varchar(11))+'        '+@OwnerMarketID+'        '+@Storenumber+'        '+@chainid+','+@chainname+'   '+@SupplierID+','+@suppliername+'   '+@filename+CHAR(13)+CHAR(10)
--set @errMessage1+=CHAR(13)+CHAR(10)+cast(@submitdate as varchar(11))+'        '+@OwnerMarketID+'        '+@chainid+','+@chainname+'   '+@SupplierID+','+@suppliername+CHAR(13)+CHAR(10)

fetch next from @rec1 into @submitdate,@OwnerMarketID,@Storenumber,@chainid,@chainname,@SupplierID,@suppliername,@filename
end

close @rec1
deallocate @rec1
	exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com;tatiana.alperovitch@icucsolutions.com;ben.shi@icucsolutions.com'
	,				
		@subject=@Subject1,@body=@errMessage1	

end 

  
select @RecordCount2=count(*)
from [DataTrue_EDI].[dbo].[costs] p
where recordstatus =0
and PDIParticipant =1
and (OwnerMarketID is null)
and (Bipad is null or Bipad='')
and dtstorecontexttypeid=3
and (StoreNumber is null or StoreNumber='')
and isnull(filetype,'ND')<>'888'
and Recordsource like '%tmp%'



if @RecordCount1 >0

begin;
set @errMessage1+=cast(@RecordCount1 as varchar)+' PDI Records with missing OwnerMarketID  ' +CHAR(13)+CHAR(10)

if @errMessage1 <>''
begin;
		
set @Subject1 ='EDI PDI Records with missing OwnerMarketID can not be process by Harmony System ' 
       
set @rec1 = CURSOR local fast_forward FOR

	select  distinct 
	CAST(p.datetimecreated as date) as submitdate,isnull(OwnerMarketID,'NON') as OwnerMarketID,isnull(storenumber,'NON') as storenumber,dtchainid,c.chainname,dtSupplierID,suppliername,filename
	from [DataTrue_EDI].[dbo].[Costs] p
	inner join chains c
	on c.ChainID=dtchainid
	inner join suppliers s
	on SupplierID=dtsupplierid
    where recordstatus =0
    and PDIParticipant =1
	and (OwnerMarketID is null)
	and (Bipad is null or Bipad='')
	and dtstorecontexttypeid=3
	and (StoreNumber is null or StoreNumber='')
	and isnull(filetype,'ND')<>'888'
	and Recordsource like '%tmp%'
	and p.datetimecreated>getdate()-35
	order by dtchainid,c.chainname,dtSupplierID,suppliername,OwnerMarketID,submitdate
	
set @errMessage1+=CHAR(13)+CHAR(10)+ 'Submit Date    '+ 'Store    '+ 'OwnerMarketID    '+'     Chain id,Name                       '+'             Supplier id,Name '+'             File Name '+CHAR(13)+CHAR(10)
open @rec1 

fetch next from @rec1 into @submitdate,@OwnerMarketID,@Storenumber,@chainid,@chainname,@SupplierID,@suppliername,@filename

while @@FETCH_STATUS = 0
begin
set @errMessage1+=CHAR(13)+CHAR(10)+cast(@submitdate as varchar(11))+'        '+@OwnerMarketID+'        '+@Storenumber+'        '+@chainid+','+@chainname+'   '+@SupplierID+','+@suppliername+'   '+@filename+CHAR(13)+CHAR(10)
--set @errMessage1+=CHAR(13)+CHAR(10)+cast(@submitdate as varchar(11))+'        '+@OwnerMarketID+'        '+@chainid+','+@chainname+'   '+@SupplierID+','+@suppliername+CHAR(13)+CHAR(10)

fetch next from @rec1 into @submitdate,@OwnerMarketID,@Storenumber,@chainid,@chainname,@SupplierID,@suppliername,@filename
end

close @rec1
deallocate @rec1
	exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com;tatiana.alperovitch@icucsolutions.com;'
	,				
		@subject=@Subject1,@body=@errMessage1	
end
end   
   /***********************'Find PDI TMP records with Invalid Store(s) in Cost Table***********************/     
--      select @RecordCount1=count(*)
--from DataTrue_edi.dbo.costs c
--where recordstatus =0
--and dtstorecontexttypeid=-1
----and DATEADD(day, -30, getdate()) < datetimecreated
--AND PDIParticipant=1
--and (Bipad is null or bipad='')

--and StoreNumber is not null
--and StoreNumber<>'' 

--if @RecordCount1 >0


--set @errMessage11+=cast(@RecordCount1 as varchar)+' records with Invalid Store(s) in Cost Table' +CHAR(13)+CHAR(10)

--if @errMessage11 <>''
--begin;
		
--set @Subject11 ='PDI records with Invalid Store(s) in Cost Table' 
       
 
--       set @rec11 = CURSOR local fast_forward FOR

--	select  distinct 
--	storenumber,dtchainid,c.chainname,dtSupplierID,suppliername
--	from [DataTrue_EDI].[dbo].[Costs] p
--	inner join chains c
--	on c.ChainID=dtchainid
--	inner join suppliers s
--	on SupplierID=dtsupplierid
--    where recordstatus =0
--    and dtstorecontexttypeid=-1
--    and StoreNumber is not null
--    and StoreNumber<>''
--    and (PDIParticipant=1 and  Bipad is  null)
--	order by dtchainid,storenumber,dtsupplierid
	
--   set @errMessage11+=CHAR(13)+CHAR(10)+ 'Store    '+'     Chain id,Name                       '+'             Supplier id,Name '+CHAR(13)+CHAR(10)
--   open @rec11 

--  fetch next from @rec11 into @Storenumber,@chainid,@chainname,@SupplierID,@suppliername

--    while @@FETCH_STATUS = 0
--	begin
--	set @errMessage11+=CHAR(13)+CHAR(10)+@Storenumber+'        '+@chainid+','+@chainname+'   '+@SupplierID+','+@suppliername+CHAR(13)+CHAR(10)
 			
--	fetch next from @rec11 into @Storenumber,@chainid,@chainname,@SupplierID,@suppliername
--	end
	
--close @rec11
--deallocate @rec11
--			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com;gilad.keren@icucsolutions.com;charlie.clark@icucsolutions.com;dataexchange@profdata.com'
--			,				
--				@subject=@Subject11,@body=@errMessage11	
	
--       end        
            
            
            
-- /***********************'Find not  TMP records with Invalid Store(s) in Cost Table***********************/     
--      select @RecordCount1=count(*)
--from DataTrue_edi.dbo.costs c
--where recordstatus =0
--and dtstorecontexttypeid=-1
--and DATEADD(day, -30, getdate()) < datetimecreated
--AND Recordsource like '%TMP%'
--    and StoreNumber is not null
--    and StoreNumber<>''
--    and (PDIParticipant=0 or Bipad is NOT null)

--if @RecordCount1 >0


--set @errMessage10+=cast(@RecordCount1 as varchar)+'  records with Invalid Store(s) in Cost Table' +CHAR(13)+CHAR(10)

--if @errMessage10 <>''
--begin;
		
--set @Subject10 ='Not PDI records with Invalid Store(s) in Cost Table' 
       
 
--       set @rec10 = CURSOR local fast_forward FOR

--	select  distinct 
--	storenumber,dtchainid,c.chainname,dtSupplierID,suppliername
--	from [DataTrue_EDI].[dbo].[Costs] p
--	inner join chains c
--	on c.ChainID=dtchainid
--	inner join suppliers s
--	on SupplierID=dtsupplierid
--    where recordstatus =0
--    and dtstorecontexttypeid=-1
--    and DATEADD(day, -30, getdate()) < p.datetimecreated
--    AND Recordsource like '%TMP%'
--    and StoreNumber is not null
--    and StoreNumber<>''
--    and (PDIParticipant=0 or Bipad is NOT null)
--	order by dtchainid,storenumber,dtsupplierid
	
--   set @errMessage10+=CHAR(13)+CHAR(10)+'Store    '+'     Chain id,Name                       '+'             Supplier id,Name '+CHAR(13)+CHAR(10)
--   open @rec10

--  fetch next from @rec10 into @Storenumber,@chainid,@chainname,@SupplierID,@suppliername

--    while @@FETCH_STATUS = 0
--	begin
--	set @errMessage10+=CHAR(13)+CHAR(10)+@Storenumber+'        '+@chainid+','+@chainname+'   '+@SupplierID+','+@suppliername+CHAR(13)+CHAR(10)
 			
--	fetch next from @rec10 into @Storenumber,@chainid,@chainname,@SupplierID,@suppliername
--	end
	
--close @rec10
--deallocate @rec10
--			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com;gilad.keren@icucsolutions.com;charlie.clark@icucsolutions.com;bill.harris@icucsolutions.com;amol.sayal@icucsolutions.com'
--			,				
--				@subject=@Subject10,@body=@errMessage10	
	
--       end        
            
       
       
-- select @RecordCount2=count(*)
--from [DataTrue_EDI].[dbo].[promotions] p
--where loadstatus =0
--and dtstorecontexttypeid=-1
--and DATEADD(day, -30, getdate()) < datetimecreated

--if @RecordCount2 >0
--set @errMessage2+=cast(@RecordCount2 as varchar)+' Promotion Records can not be moved to MR.Invalid Store(s) in Promotion Table.' +CHAR(13)+CHAR(10)

--if @errMessage2 <>''
--begin;
		
--set @Subject2 ='Promotion Records can not be moved to MR.Invalid Store(s) in Promotion Table.' 
       
--set @rec2 = CURSOR local fast_forward FOR

--	select  distinct 
--	storenumber,p.chainid,c.chainname,p.SupplierID,s.suppliername
--	from [DataTrue_EDI].[dbo].[Promotions] p
--	inner join chains c
--	on c.ChainID=p.chainid
--	inner join suppliers s
--	on s.SupplierID=p.supplierid
--    where loadstatus =0
--    and dtstorecontexttypeid=-1
--    and DATEADD(day, -30, getdate()) < p.datetimecreated
--	order by p.chainid,storenumber,p.supplierid
	
	
--   set @errMessage2+=CHAR(13)+CHAR(10)+ 'Store    '+'     Chain id,Name                       '+'             Supplier id,Name '+CHAR(13)+CHAR(10)
--   open @rec2 

--  fetch next from @rec2 into @Storenumber,@chainid,@chainname,@SupplierID,@suppliername

--    while @@FETCH_STATUS = 0
--	begin
--	set @errMessage2+=CHAR(13)+CHAR(10)+@Storenumber+'        '+@chainid+','+@chainname+'   '+@SupplierID+','+@suppliername+CHAR(13)+CHAR(10)
 			
--	fetch next from @rec2 into @Storenumber,@chainid,@chainname,@SupplierID,@suppliername
--	end
	
--close @rec2
--deallocate @rec2
--			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com'--;tatiana.alperovitch@icucsolutions.com;gilad.keren@icucsolutions.com;charlie.clark@icucsolutions.com'
--			,				
--				@subject=@Subject2,@body=@errMessage2	
	
--       end        





return
end
GO
