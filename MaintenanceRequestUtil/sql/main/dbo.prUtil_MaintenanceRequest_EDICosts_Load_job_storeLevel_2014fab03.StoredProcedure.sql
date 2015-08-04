USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_MaintenanceRequest_EDICosts_Load_job_storeLevel_2014fab03]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE 
 PROCEDURE [dbo].[prUtil_MaintenanceRequest_EDICosts_Load_job_storeLevel_2014fab03]
AS
declare @rec cursor
declare @costtablerecordid int
declare @storeid int
declare @mridreturned int

DECLARE @Subject VARCHAR(MAX)
DECLARE @errMessage varchar(max)=''
DECLARE @badrecords table (recordid int)

DECLARE @badrecids varchar(max)=''
BEGIN

update datatrue_edi.dbo.Costs set recordsource = 
case when PartnerIdentifier IS null and 
dtsupplierid IS Not null 
then 'TMP' else 'EDI' end 
where RecordStatus = 0

insert @badrecords	select recordsource from [DataTrue_EDI].[dbo].[costs] p
where RecordStatus = 0 and recordsource is null
	
if @@ROWCOUNT >0
		set @errMessage+='One or more RecordSources are missing ' +CHAR(13)+CHAR(10)	
		
update p  set p.dtchainid = s.chainid
from [DataTrue_EDI].[dbo].[costs] p
inner join [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp] s
on LTRIM(rtrim(p.StoreIdentifier)) = LTRIM(rtrim(s.CorporateIdentifier))
where p.dtchainid is null

insert @badrecords
	select RecordID from [DataTrue_EDI].[dbo].[costs] p
inner join [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp] s
on LTRIM(rtrim(p.StoreIdentifier)) = LTRIM(rtrim(s.CorporateIdentifier))
and p.dtchainid is null

	
	if @@ROWCOUNT >0
		set @errMessage+='One or more chainid are missing when StoreIdentifier exists' +CHAR(13)+CHAR(10)		



update c set 
 dtsupplierid = SupplierID  
 from datatrue_edi.dbo.Costs c
 inner join Suppliers s 
 on LTRIM(rtrim(UniqueEDIName))=LTRIM(rtrim(PartnerIdentifier))
 and  dtsupplierid is null
and recordstatus = 0

insert @badrecords
	select RecordID from datatrue_edi.dbo.Costs c inner join Suppliers s 
    on UniqueEDIName=PartnerIdentifier and dtsupplierid is null and recordstatus = 0
	 
	if @@ROWCOUNT >0
		set @errMessage+='One or more supplierid are missing' +CHAR(13)+CHAR(10)


update c
    set PartnerIdentifier = UniqueEDIName
    from datatrue_edi.dbo.Costs c
    join Suppliers s on SupplierID=ltrim(rtrim(dtsupplierid))
    and PartnerIdentifier is null and recordstatus = 0

insert @badrecords
	select c.RecordID from datatrue_edi.dbo.Costs c
    join Suppliers s on SupplierID=ltrim(rtrim(dtsupplierid))
    and PartnerIdentifier is null and recordstatus = 0
	
	if @@ROWCOUNT >0
		set @errMessage+='One or more PartnerIdentifier are missing' +CHAR(13)+CHAR(10)



update c set c.dtbanner= e.custom1
from datatrue_edi.dbo.costs c 
join  [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp]e
on LTRIM(rtrim(c.StoreIdentifier))=LTRIM(rtrim(e.CorporateIdentifier))
and e.EdiName=c.partneridentifier
and c.dtbanner is null
and c.StoreIdentifier is not null
and c.StoreIdentifier<>''
and c.RecordStatus=0

insert @badrecords
	select RecordID from  datatrue_edi.dbo.costs c 
join  [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp]e
on LTRIM(rtrim(c.StoreIdentifier))=LTRIM(rtrim(e.CorporateIdentifier))
and e.EdiName=c.partneridentifier
and c.dtbanner is null
and c.StoreIdentifier is not null
and c.StoreIdentifier<>''
and c.RecordStatus=0
	
	if @@ROWCOUNT >0
		set @errMessage+='One or more dtbanner are missing when StoreIdentifier exists ' +CHAR(13)+CHAR(10)



update c set c.dtbanner= e.custom1

from datatrue_edi.dbo.costs c 
join  [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp]e
on LTRIM(rtrim(c.StoreName))=LTRIM(rtrim(e.CorporateName))
and e.EdiName=c.partneridentifier
and c.dtbanner is null
and c.StoreName is not null
and c.StoreName<>''
and (c.StoreIdentifier is not null or c.StoreIdentifier<>'')
and c.RecordStatus=0

insert @badrecords
select RecordID from  datatrue_edi.dbo.costs c 
join  [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp]e
on LTRIM((c.StoreName))=LTRIM(rtrim(e.CorporateName))
and e.EdiName=c.partneridentifier
and c.dtbanner is null
and c.StoreName is not null
and c.StoreName<>''
and (c.StoreIdentifier is not null or c.StoreIdentifier<>'')
and c.RecordStatus=0
	
	if @@ROWCOUNT >0
		set @errMessage+='One or more dtbanner are missing when StoreName exists ' +CHAR(13)+CHAR(10)

update p set p.dtstoreid = s.storeid,
 p.dtstorecontexttypeid = 1
from datatrue_edi.dbo.costs p
inner join stores s
on CAST(storenumber as int) = CAST(s.custom2 as int)
and LTRIM(rtrim(p.dtbanner)) = LTRIM(rtrim(custom1))
where recordstatus = 0
and len(p.StoreNumber) > 0  

insert @badrecords
select RecordID from datatrue_edi.dbo.costs p
inner join stores s
on CAST(storenumber as int) = CAST(s.custom2 as int)
and LTRIM(rtrim(p.dtbanner)) = LTRIM(rtrim(custom1))
and recordstatus = 0
and len(p.StoreNumber) > 0  
and p.dtstorecontexttypeid!=1
and p.dtstoreid is null

	
	if @@ROWCOUNT >0
		set @errMessage+='One or more dtstoreid are missing when StoreNamber exists ' +CHAR(13)+CHAR(10)

		
if @errMessage <>''
		begin;
			with c as (select ROW_NUMBER() over (partition by recordid order by recordid)dupe from @badrecords)
				delete c where dupe>1
			set @Subject ='Validation Error for proc.set_cost_storeLevel_job_New_Rule' 
			select @badrecids += cast(recordid as varchar(13))+ CHAR(13)+CHAR(10) from @badrecords
			set @errMessage+=CHAR(13)+CHAR(10)+'Record ID:'+CHAR(13)+CHAR(10)+@badrecids
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com',
				@subject=@Subject,@body=@errMessage				
	
       end                                                                                                                                      

begin try
begin transaction

set @rec = CURSOR local fast_forward FOR
select recordid, dtstoreid
FROM [DataTrue_EDI].[dbo].[Costs]
where 1=1--recordstatus = 0
and dtstorecontexttypeid is not null
and dtchainid is not null
and dtbanner is not null
and dtsupplierid is not null
and dtstoreid is not null
and PriceChangeCode in ('A','B','W')
and Recordsource is not null
and PDIParticipant = 0

open @rec
fetch next from @rec into @costtablerecordid, @storeid
while @@FETCH_STATUS = 0
	begin
		INSERT INTO [DataTrue_Main].[dbo].[MaintenanceRequests]
				   ([datatrue_edi_costs_recordid]
				   ,[SubmitDateTime]
				   ,[RequestTypeID]
				   ,[ChainID]
				   ,[SupplierID]
				   ,[Banner]
				   ,[AllStores]
				   ,[UPC]
				   ,[ItemDescription]
				   ,[Cost]
				   ,[SuggestedRetail]
				   ,[StartDateTime]
				   ,[EndDateTime]
				   ,[SupplierLoginID]
				   ,[dtstorecontexttypeid]
				   ,[CostZoneID]
				   ,[RequestSource])
		SELECT c.[RecordID]
			  ,cast([DateCreated] as date)
			  ,case when [PriceChangeCode] in ('A','W') then 1 else 2 end
			  ,c.dtchainid
			  ,c.dtsupplierid
			  ,LTRIM(rtrim(dtbanner))
			  ,0  --[AllStores] 
			  ,[ProductIdentifier]
			  ,isnull([ProductName], '')
			  ,isnull([Cost], 0.0)
			  ,isnull([SuggRetail], 0.0)
			  ,cast(isnull([EffectiveDate], '12/1/2011') as date)
			  ,cast(isnull([EndDate], '12/31/2099') as Date)
			  ,-1 
			  ,1
			  ,[dtcostzoneid]
			  ,Recordsource
		  FROM [DataTrue_EDI].[dbo].[Costs] c
		  where c.RecordID = @costtablerecordid		  
		  and PriceChangeCode in ('A','B','W')
		  and dtstorecontexttypeid is not null		  
  
			set @mridreturned = SCOPE_IDENTITY()
			
			insert into maintenancerequeststores
			(MaintenanceRequestID, StoreID, Included)
			values(@mridreturned, @storeid, 1)
		
			 update c set c.recordstatus = 1
			from [DataTrue_EDI].[dbo].[Costs] c
			where c.RecordID = @costtablerecordid
  
			fetch next from @rec into @costtablerecordid, @storeid			
		end
commit transaction
end try
begin catch
rollback transaction
end catch
return
END
GO
