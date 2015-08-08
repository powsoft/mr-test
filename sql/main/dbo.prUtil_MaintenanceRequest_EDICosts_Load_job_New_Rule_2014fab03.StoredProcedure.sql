USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_MaintenanceRequest_EDICosts_Load_job_New_Rule_2014fab03]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Modifier:		<Irina ,Trush>
-- Create date: <02-2014>

-- =============================================
CREATE PROCEDURE [dbo].[prUtil_MaintenanceRequest_EDICosts_Load_job_New_Rule_2014fab03]
	
AS
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


update p  set p.dtchainid = s.chainid
from [DataTrue_EDI].[dbo].[costs] p
inner join [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp] s
on LTRIM(rtrim(p.Banner)) = LTRIM(rtrim(s.banner))
where p.dtchainid is null

insert @badrecords
	select RecordID from [DataTrue_EDI].[dbo].[costs] p
inner join [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp] s
on LTRIM(rtrim(p.Banner)) = LTRIM(rtrim(s.banner))
and p.dtchainid is null
	
	if @@ROWCOUNT >0
		set @errMessage+='One or more chainid are missing when banner exists' +CHAR(13)+CHAR(10)

update p  set p.dtchainid = s.chainid
--select count(*)
from [DataTrue_EDI].[dbo].[costs] p
inner join [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp] s
on LTRIM(rtrim(p.StoreIdentifier)) = LTRIM(rtrim(s.CorporateIdentifier))
and p.dtchainid is null

insert @badrecords
	select RecordID from [DataTrue_EDI].[dbo].[costs] p
inner join [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp] s
on LTRIM(rtrim(p.StoreIdentifier)) = LTRIM(rtrim(s.CorporateIdentifier))
and p.dtchainid is null
and recordstatus = 0
	
	if @@ROWCOUNT >0
		set @errMessage+='One or more chainid are missing when StoreIdentifier exists' +CHAR(13)+CHAR(10)		
		

update c set 
 dtsupplierid = SupplierID  
 from datatrue_edi.dbo.Costs c
 inner join Suppliers s 
 on UniqueEDIName=PartnerIdentifier
 and  dtsupplierid is null
and recordstatus = 0

insert @badrecords
	select RecordID from datatrue_edi.dbo.Costs c inner join Suppliers s 
    on UniqueEDIName=PartnerIdentifier and dtsupplierid is null and recordstatus = 0
	 
	if @@ROWCOUNT >0
		set @errMessage+='One or more supplierid are missing' +CHAR(13)+CHAR(10)
 update c set c.recordstatus = 20 
from datatrue_edi.dbo.Costs c
join Exclusions e on c.dtsupplierid=e.SupplierId
and (dtbanner=e.custom1 or c.dtcostzoneid=e.costzoneid or storeid= dtstoreid) 
join ExclusionTypes t on t.ExclusionTypeID=e.ExclusionTypeID
and dtstoreid IS NOT NULL
and recordstatus = 0
and isActive=1
and t.ExclusionName = 'EDITableCostRecordExclusion'

insert @badrecords
	select RecordID from datatrue_edi.dbo.Costs c
join Exclusions e on c.dtsupplierid=e.SupplierId and (dtbanner=e.custom1 or c.dtcostzoneid=e.costzoneid or storeid= dtstoreid) 
join ExclusionTypes t on t.ExclusionTypeID=e.ExclusionTypeID
Where dtstoreid IS NOT NULL
and recordstatus = 0
and isActive=1
and t.ExclusionName = 'EDITableCostRecordExclusion'
	
	if @@ROWCOUNT >0
		set @errMessage+='One or more records were not excluded from MaintenanceReques ' +CHAR(13)+CHAR(10)
	 

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


update c set dtstorecontexttypeid = 
( Case StoreProductContextMethod when 'BANNER' then 2	when 'COSTZONE' then 3	else null end)
from datatrue_edi.dbo.costs c inner join SupplierStoreProductContextMethod m
on UniqueEDIName=PartnerIdentifier
and c.dtChainId=m.chainid
and dtstorecontexttypeid is null and RecordStatus = 0

insert @badrecords
	select c.RecordID from datatrue_edi.dbo.costs c inner join SupplierStoreProductContextMethod m
    on UniqueEDIName=PartnerIdentifier
    and c.dtChainId=m.chainid
    and dtstorecontexttypeid is null and RecordStatus = 0
	
	if @@ROWCOUNT >0
		set @errMessage+='One or more dtstorecontexttypeid are missing' +CHAR(13)+CHAR(10)


update c set c.dtbanner= e.custom1
from datatrue_edi.dbo.costs c 
join  [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp]e
on LTRIM(rtrim(c.StoreIdentifier))=LTRIM(rtrim(e.CorporateIdentifier))
and e.EdiName=c.partneridentifier
and c.dtbanner is null
and c.StoreIdentifier is not null
and c.StoreIdentifier<>''
and RecordStatus = 0

insert @badrecords
	select RecordID from  datatrue_edi.dbo.costs c 
join  [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp]e
on LTRIM(rtrim(c.StoreIdentifier))=LTRIM(rtrim(e.CorporateIdentifier))
and e.EdiName=c.partneridentifier
and c.dtbanner is null
and c.StoreIdentifier is not null
and c.StoreIdentifier<>''
and RecordStatus = 0
	
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
and (c.StoreIdentifier is  null or c.StoreIdentifier='')
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

update datatrue_edi.dbo.costs set PriceChangeCode = 
case 
	when LTRIM(rtrim(RequestTypeID)) = 1 then 'A'
	when LTRIM(rtrim(RequestTypeID)) = 2 then 'B'
else null
end
where recordstatus = 0
and RequestTypeID is not null
insert @badrecords
	select RecordID from [DataTrue_EDI].[dbo].[costs] where PriceChangeCode not in('A','B') and recordstatus = 0
and RequestTypeID is not null	
	
	
	if @@ROWCOUNT >0
		set @errMessage+='One or more PriceChangeCode are not updated' +CHAR(13)+CHAR(10)
		
if @errMessage <>''
		begin;
			with c as (select ROW_NUMBER() over (partition by recordid order by recordid)dupe from @badrecords)
				delete c where dupe>1
			set @Subject ='Validation Error for banner in proc.set_new_dtbanner_cost_job_New_Rul' 
			select @badrecids += cast(recordid as varchar(13))+ CHAR(13)+CHAR(10) from @badrecords
			set @errMessage+=CHAR(13)+CHAR(10)+'Record ID:'+CHAR(13)+CHAR(10)+@badrecids
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com',
				@subject=@Subject,@body=@errMessage				
	
       end
--else 
begin 
exec set_new_MaintenanceRequests_cost_job_New_Rule_2014fab03
end

    
END
GO
