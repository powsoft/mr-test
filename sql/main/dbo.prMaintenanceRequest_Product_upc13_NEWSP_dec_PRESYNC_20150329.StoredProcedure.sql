USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_Product_upc13_NEWSP_dec_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Batch submitted through debugger: SQLQuery12.sql|7|0|C:\Users\irina.trush\AppData\Local\Temp\15\~vsD393.sql
CREATE
procedure [dbo].[prMaintenanceRequest_Product_upc13_NEWSP_dec_PRESYNC_20150329]
as

declare @rec cursor
declare @rec2 cursor
declare @rec3 cursor
declare @rec4 cursor
declare @rec5 cursor
declare @upc nvarchar(50)
declare @productid int
declare @productdescription nvarchar(100)
declare @brandid int
declare @mrupc nvarchar(50)
declare @checkdigit char(1)
declare @lenofupc tinyint
declare @maintenancerequestid int
--declare @addnewproduct smallint=1
declare @itemdescription nvarchar(255)
declare @upc12 nvarchar(50)
declare @upc11 nvarchar(50)
declare @chainid int
declare @addnewproduct bit=1
declare @productfound bit
declare @approved bit
declare @recten cursor
declare @brandname nvarchar(50)
declare @supplierid int
declare @requesttypeid int

declare @rawprod nvarchar(50)
declare @noupc bit=1

declare @requestsource nvarchar(50)
declare @ProdIdTypeID int

DECLARE @badrecidsP varchar(max)=''
DECLARE @SubjectP VARCHAR(MAX)=''
DECLARE @errMessageP varchar(max)=''



	


update m set m.approved = 1, m.approvaldatetime = getdate()
--select m.bipad,*
from maintenancerequeststores s
inner join maintenancerequests m
on s.MaintenanceRequestID = m.MaintenanceRequestID
inner join datatrue_edi.dbo.costs c
on m.datatrue_edi_costs_recordid = c.recordid
and m.RequestStatus not in (5, 15, 6, 16, 999)
and LEN(LTRIM(rtrim(m.Bipad)))>1
and m.Bipad is not null
and m.dtstorecontexttypeid=1
and m.Approved is null

update m set  m.PDIParticipant = p.PDIParticipant
--select requeststatus,MaintenanceRequestID,datatrue_edi_costs_recordid into zztemp_fix_COST_PDI_MR
from MaintenanceRequests m 
inner join PDI_CHAIN_SUPPLIER_RELATIONS p
on m.supplierid = p.supplierid
and m.chainid=p.chainid
and p.PDIParticipant <> m.PDIParticipant
and (Bipad is  null or Bipad='')
and SubmitDateTime>'2014-08-01 00:00:00.000'

update c set  PDIParticipant = PDITradingPartner
from MaintenanceRequests c
inner join chains  b
on c.chainid = b.chainid
and PDIParticipant <> PDITradingPartner
and Bipad is not null
and dtstorecontexttypeid=1


update m set m.upc= LTRIM(rtrim(isnull(m.rawproductidentifier,'')))	
--select datatrue_edi.dbo.fnParseUPC(LTRIM(rtrim(rawproductidentifier))),upc,submitdatetime	
	from dbo.MaintenanceRequests  m
	where  RequestStatus not in (5, 15, 6, 16)
    and LEN(LTRIM(rtrim(rawproductidentifier)))>1 
    and rawproductidentifier is not null
	and LEN(LTRIM(rtrim(upc)))<1
	
	update m set m.rawproductidentifier= datatrue_edi.dbo.fnParseUPC(LTRIM(rtrim(m.upc)))	
--select datatrue_edi.dbo.fnParseUPC(LTRIM(rtrim(rawproductidentifier)))	
	from dbo.MaintenanceRequests  m
	where  RequestStatus not in (5, 15, 6, 16)
    and(LEN(LTRIM(rtrim(rawproductidentifier)))<1 or rawproductidentifier is null)
	and LEN(LTRIM(rtrim(upc)))>1
	and SubmitDateTime>GETDATE()-15
	
	update m set RequestStatus=-31,DenialReason='Record can not be processed.UPC is not provided.',Approved=0
	--select distinct banner,supplierid,upc,	RawProductIdentifier,requeststatus,DenialReason,approved,Bipad
	from dbo.MaintenanceRequests  m
	where   LEN(LTRIM(rtrim(upc)))<2
	and  (RawProductIdentifier is null or RawProductIdentifier ='')
	and RequestStatus<>-30	
	and (Bipad is NOT null or  PDIParticipant=0)
	
	
	
  update m set upc12= datatrue_edi.dbo.fnParseUPC(LTRIM(rtrim(upc)))	
--select*
	from dbo.MaintenanceRequests  m
	where  RequestStatus not in (5, 15, 6, 16, 999)
    and m.upc12 is null	
	and LEN(LTRIM(rtrim(m.Bipad)))>1
	and LEN(LTRIM(rtrim(upc)))>12
	and m.dtstorecontexttypeid=1
	and (datatrue_edi.dbo.fnParseUPC(LTRIM(rtrim(upc))) in (select distinct identifiervalue from ProductIdentifiers)	
	or isnull(Approved, -1) <> 0	)

	
	
	
update m set upc12=datatrue_edi.dbo.fnParseUPC(LTRIM(rtrim(rawproductidentifier)))	
 --select*
	from dbo.MaintenanceRequests  m
	where  RequestStatus not in (5, 15, 6, 16, 999)
    and upc12 is null	
	and m.dtstorecontexttypeid=1
	and LEN(LTRIM(rtrim(m.Bipad)))>1
	and LEN(LTRIM(rtrim(rawproductidentifier)))>12	
	and LEN(LTRIM(rtrim(upc)))<1
	and (datatrue_edi.dbo.fnParseUPC(LTRIM(rtrim(rawproductidentifier)))
	 in (select distinct identifiervalue from ProductIdentifiers where  ProductIdentifierTypeID = 8)	
	or isnull(Approved, -1) <> 0	)
	and m.Bipad is not null
	and m.Bipad<>''	
	
  update m set upc12= datatrue_edi.dbo.fnParseUPC(upc)
	from dbo.MaintenanceRequests  m	
    where  RequestStatus not in (5, 15, 6, 16, 999)
    and upc12 is null
	and LEN(LTRIM(rtrim(m.Bipad)))>1
	and (datatrue_edi.dbo.fnParseUPC(upc) in (select distinct identifiervalue from ProductIdentifiers where  ProductIdentifierTypeID = 8)
	or isnull(Approved, -1) <> 0)
	and LEN(LTRIM(rtrim(upc)))<13
	and LEN(LTRIM(rtrim(upc)))>1
	and m.dtstorecontexttypeid=1
	and m.Bipad is not null
	and m.Bipad<>''
	
update m set upc12= datatrue_edi.dbo.fnParseUPC(LTRIM(rtrim(rawproductidentifier)))	
	from dbo.MaintenanceRequests  m
    where  RequestStatus not in (5, 15, 6, 16, 999)
    and m.upc12 is null	
	and LEN(LTRIM(rtrim(m.Bipad)))>1
	and (datatrue_edi.dbo.fnParseUPC(rawproductidentifier) in 
	(select distinct identifiervalue from ProductIdentifiers where  ProductIdentifierTypeID = 8) 
	or isnull(Approved, -1) <> 0)
	and LEN(LTRIM(rtrim(rawproductidentifier)))<13
	and LEN(LTRIM(rtrim(rawproductidentifier)))>1
	and LEN(LTRIM(rtrim(upc)))<1
	and m.dtstorecontexttypeid=1
	and m.Bipad is not null
	and m.Bipad<>''

	
	
update m set 
	m.productid=p.productid,
	dtproductdescription =description	
	--select datatrue_edi.dbo.fnParseUPC(LTRIM(rtrim(upc))),m.productid,p.productid,	dtproductdescription ,description
	from dbo.MaintenanceRequests  m
    inner join productidentifiers p
    on LTRIM(rtrim(identifiervalue))=LTRIM(rtrim(upc12))      
    inner join Products r
    on p.ProductId=r.productid
    where  RequestStatus not in (5, 15, 6, 16, 999)
    and m.ProductId is null	
	and LEN(LTRIM(rtrim(m.Bipad)))>1
	and m.Bipad is not null
	--and m.Bipad=p.bipad
	and p.ProductIdentifierTypeID = 8
	and m.dtstorecontexttypeid=1
	
		
update m set 	
	dtproductdescription =description	
	from dbo.MaintenanceRequests  m
    inner join Products p
    on p.ProductId=m.productid
    where  RequestStatus not in (5, 15, 6, 16, 999)
    and m.ProductId is not null	
	and LEN(LTRIM(rtrim(m.Bipad)))>1	
	and dtproductdescription is null
		
	

set @recten = CURSOR local fast_forward FOR
	select maintenancerequestid, LTRIM(rtrim(upc12)), LTRIM(rtrim(ItemDescription)) , Chainid--,productid--,datatrue_edi_costs_recordid,rawproductidentifier--, PDIParticipant,requestsource,SupplierID
	from dbo.MaintenanceRequests
	where RequestStatus  not in (5, 15, 6, 16, 999)
	and ProductId is null	
	and LEN(LTRIM(rtrim(upc12)))> = 12
	and LEN(LTRIM(rtrim(Bipad)))>1
	and RequestTypeID in (1,2)
	and dtstorecontexttypeid=1
	and Bipad is not null
	and Bipad<>''
	

open @recten

fetch next from @recten into @maintenancerequestid, @mrupc, @itemdescription, @chainid

while @@FETCH_STATUS = 0
	begin
	if LEN(LTRIM(rtrim(@itemdescription)))<1
			set @itemdescription=@mrupc
			
	    select @productid = productid from ProductIdentifiers 	    
			where ltrim(rtrim(IdentifierValue)) = @mrupc
			and ProductIdentifierTypeID = 8
			
			
			
			if @@ROWCOUNT <1
									
					begin
				INSERT INTO [dbo].[Products]
				   ([ProductName]
				   ,[Description]
				   ,[ActiveStartDate]
				   ,[ActiveLastDate]
				   ,[LastUpdateUserID])
				VALUES
				   (@itemdescription
				   ,@itemdescription
				   ,GETDATE()
				   ,'12/31/2025'
				   ,2)

				set @productid = Scope_Identity()
		
				INSERT INTO [DataTrue_Main].[dbo].[ChainProductFactors]
				   ([ChainID]
				   ,[ProductID]
				   ,[BrandID]
				   ,[BaseUnitsCalculationPerNoOfweeks]
				   ,[CostFromRetailPercent]
				   ,[BillingRuleID]
				   ,[ActiveStartDate]
				   ,[ActiveEndDate]
				   ,[LastUpdateUserID])
				SELECT @chainid
					  ,@productid
					  ,0 --@brandid
					  ,[BaseUnitsCalculationPerNoOfweeks]
					  ,[CostFromRetailPercent]
					  ,[BillingRuleID]
					  ,[ActiveStartDate]
					  ,[ActiveEndDate]
					  ,2
				  FROM [DataTrue_Main].[dbo].[ChainProductFactors]
				  where 1 = 1
				  and ChainID = @chainid
				  and productid = 0
				  
				INSERT INTO [dbo].[ProductIdentifiers]
				   ([ProductID]
				   ,[ProductIdentifierTypeID]
				   ,[OwnerEntityId]
				   ,[IdentifierValue]
				   ,[LastUpdateUserID])
				VALUES
				   (@productid
				   ,8 --UPC is type 2
				   ,0 -- 0 is default entity
				   ,@mrupc
				   ,2)
		           
				 INSERT INTO [dbo].[ProductBrandAssignments]
						   ([BrandID]
						   ,[ProductID]
						   ,[CustomOwnerEntityID]
						   ,[LastUpdateUserID])
					 VALUES
						   (0 --@brandid
						   ,@productid
						   ,0
						   ,2)
						   
					
				update MaintenanceRequests set Productid = @productid,  dtproductdescription = @productdescription
				where MaintenanceRequestID = @maintenancerequestid
			end

		
			
		fetch next from @recten into @maintenancerequestid, @mrupc, @itemdescription, @chainid
	end
	
close @recten
deallocate @recten

declare @bipad varchar(50)

set @rec2 = CURSOR local fast_forward FOR
	select maintenancerequestid, LTRIM(rtrim(upc12)), LTRIM(rtrim(ItemDescription)) , Chainid, approved--, productid
	,RequestTypeID, ltrim(rtrim(BrandIdentifier)), SupplierID, requestsource, ltrim(rtrim(Bipad))
	from dbo.MaintenanceRequests
	where  ProductId is null
	and RequestStatus not in (5, 15, 6, 16, 999)
	and isnull(Approved, -1) <> 0
	and RequestSource is not null	
	and LEN(LTRIM(rtrim(upc12))) = 12
	and LEN(ltrim(rtrim(Bipad)))>1
	
	
	order by requesttypeid
	
open @rec2

fetch next from @rec2 into @maintenancerequestid, @upc12, @itemdescription, @chainid, 
@approved, @requesttypeid, @brandname, @supplierid, @requestsource, @bipad

while @@FETCH_STATUS = 0
	begin
			if LEN(LTRIM(rtrim(@itemdescription)))<1
			set @itemdescription=@mrupc
				
			select @productid = productid from ProductIdentifiers 
			where ltrim(rtrim(Bipad)) = @bipad		
			and ProductIdentifierTypeID =8
			
			
			if @@ROWCOUNT <1
									
					begin				
							
								INSERT INTO [dbo].[Products]
								   ([ProductName]
								   ,[Description]
								   ,[ActiveStartDate]
								   ,[ActiveLastDate]
								   ,[LastUpdateUserID])
								VALUES
								   (@itemdescription
								   ,@itemdescription
								   ,GETDATE()
								   ,'12/31/2025'
								   ,2)

								set @productid = Scope_Identity()
						
								INSERT INTO [DataTrue_Main].[dbo].[ChainProductFactors]
								   ([ChainID]
								   ,[ProductID]
								   ,[BrandID]
								   ,[BaseUnitsCalculationPerNoOfweeks]
								   ,[CostFromRetailPercent]
								   ,[BillingRuleID]
								   ,[ActiveStartDate]
								   ,[ActiveEndDate]
								   ,[LastUpdateUserID])
								SELECT @chainid
									  ,@productid
									  ,0 --@brandid
									  ,[BaseUnitsCalculationPerNoOfweeks]
									  ,[CostFromRetailPercent]
									  ,[BillingRuleID]
									  ,[ActiveStartDate]
									  ,[ActiveEndDate]
									  ,2
								  FROM [DataTrue_Main].[dbo].[ChainProductFactors]
								  where 1 = 1
								  and ChainID = @chainid
								  and productid = 0
								  
								INSERT INTO [dbo].[ProductIdentifiers]
								   ([ProductID]
								   ,[ProductIdentifierTypeID]
								   ,[OwnerEntityId]
								   ,[IdentifierValue]
								   ,[LastUpdateUserID]
								   ,[Bipad])
								VALUES
								   (@productid
								   ,8 --UPC is type 2
								   ,0 -- 0 is default entity
								   ,@UPC12
								   ,2
								   ,@bipad)
						           
						         If @brandname is not null
									begin
									
										set @brandid = null
										
										select @brandid = brandid
										from Brands
										where LTRIM(rtrim(BrandName)) = @BrandName
										
									end  
						           
						           
								 INSERT INTO [dbo].[ProductBrandAssignments]
										   ([BrandID]
										   ,[ProductID]
										   ,[CustomOwnerEntityID]
										   ,[LastUpdateUserID])
									 VALUES
										   (isnull(@brandid, 0)
										   ,@productid
										   ,0
										   ,2)
										   
								update MaintenanceRequests set Productid = @productid, upc = @upc12, upc12 = @upc12, dtproductdescription = @itemdescription
								where MaintenanceRequestID = @maintenancerequestid	
																	   
				end			
			
						
		fetch next from @rec2 into @maintenancerequestid, @upc12, @itemdescription, @chainid, 
		@approved, @requesttypeid, @brandname, @supplierid, @requestsource, @bipad
	end
	
close @rec2
deallocate @rec2



declare @mrid int
declare @banner nvarchar(50)

declare @cost money

set @rec5 = CURSOR local fast_forward FOR
	select MaintenanceRequestid, ltrim(rtrim(Banner)), UPC12, ProductID, supplierid
	--select *
	from MaintenanceRequests
	where ProductId is not null
	and requesttypeid = 2
	and ISNULL(cost, 0) = 0
	and (approved is null or approved = 1)
	and requeststatus not in (5, 6, 15, 16, 18, 999, -89, 9, -5)
	and Bipad is not null
	
open @rec5

fetch next from @rec5 into @mrid, @banner, @upc12, @productid, @supplierid

while @@FETCH_STATUS = 0
	begin
	
		set @cost = null
		
		select @cost = cost from MaintenanceRequests
		where productid = @productid 
		and LTRIM(rtrim(Banner)) = @banner
		and requesttypeid =2
		and cost > 0
		and requeststatus in (0, 1, 2)
		and supplierid = @supplierid
		
		if isnull(@cost, 0) > 0
			begin
				update MaintenanceRequests set Cost = @cost where Maintenancerequestid = @mrid			
			end
		else
			begin
				update MaintenanceRequests set requeststatus = -30 where Maintenancerequestid = @mrid
				
			--	exec dbo.prSendEmailNotification_PassEmailAddresses 'MaintenanceRequest Records Found With Zero Costs Set to -31'
			--	,'MaintenanceRequest Records Found With Zero Costs Set to -30'
			--	,'DataTrue System', 0, 'irina.trush@icucsolutions.com'
			--	--,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;irina.trush@icontroldsd.com;nik.baskin@icontroldsd.com;gilad.keren@icontroldsd.com;mandeep@amebasoftwares.com'	
			end
			
		
		fetch next from @rec5 into @mrid, @banner, @upc12, @productid, @supplierid	
	end
	
close @rec5
deallocate @rec5

declare @rec6 cursor
declare @validupc nvarchar(50)

set @rec6 = CURSOR local fast_forward FOR
	select MaintenanceRequestid, ltrim(rtrim(Banner)), ltrim(rtrim(UPC12)), ProductID, supplierid
	--select *
	from MaintenanceRequests
	where ProductId is not null
	and LEN(ltrim(rtrim(UPC12))) = 12
	and (approved is null or approved = 1)
	and requeststatus not in (5, 6, 15, 16, 17, 18, 999, -89, 9, -5)
	and CAST(submitdatetime as date) > '3/1/2013'
	and Bipad ='@@@@'--is not null
	
open @rec6

fetch next from @rec6 into @mrid, @banner, @upc12, @productid, @supplierid

while @@FETCH_STATUS = 0
	begin
	
		set @validupc = null
		
		select @validupc = LTRIM(rtrim(identifiervalue))
		from ProductIdentifiers
		where productid = @productid 
		and ProductIdentifierTypeID = 8
		
	
		if @upc12 <> @validupc
			begin
				update MaintenanceRequests set upc = @validupc, upc12 = @validupc where Maintenancerequestid = @mrid			
			end
			
		
		fetch next from @rec6 into @mrid, @banner, @upc12, @productid, @supplierid	
	end
	
close @rec6
deallocate @rec6

	
	update m set 	
	dtproductdescription =description
	--select*	
	from dbo.MaintenanceRequests  m 	        
    inner join Products r
    on m.ProductId=r.productid
    where   dtproductdescription is  null	
	
	
	update m set upc= upc12	
--select requeststatus,upc,upc12
	from dbo.MaintenanceRequests  m
    where   upc12 is not null	
	and LEN(LTRIM(rtrim(upc12)))>1
	and LEN(LTRIM(rtrim(upc)))<1
	and Bipad is not null
	
update m set m.RequestStatus=2
--select m.bipad,m.requeststatus,*
from maintenancerequeststores s
inner join maintenancerequests m
on s.MaintenanceRequestID = m.MaintenanceRequestID
inner join datatrue_edi.dbo.costs c
on m.datatrue_edi_costs_recordid = c.recordid
and m.RequestStatus not in (2,5, 15, 6, 16, 999,17,18)
and LEN(LTRIM(rtrim(m.Bipad)))>1
and m.productid is not null

update m set RequestStatus=-27
            --select datetimecreated,OwnerMarketID,*	
		    FROM [DataTrue_Main].[dbo].[MaintenanceRequests] m		   
			where   RequestStatus in (2)	
			and MaintenanceRequestID not in 
			(select distinct MaintenanceRequestID From MaintenanceRequestStores 
			where datetimecreated>GETDATE()-60)	and datetimecreated>GETDATE()-60
			and Approved = 1
			and LEN(LTRIM(rtrim(m.Bipad)))>1
			
			
	update m set m.productid=p.productid	
	-- select distinct m.productid,p.productid,m.supplierid,m.ChainID,m.Bipad,p.Bipad,m.dtstorecontexttypeid,m.requeststatus,m.approved,upc12
	from dbo.MaintenanceRequests  m 
	inner join productidentifiers p
    on LTRIM(rtrim(identifiervalue))=LTRIM(rtrim(upc12))      
    and m.submitdatetime> getdate()-60
    and ProductIdentifierTypeID = 2
    and RequestStatus not in (5, 15, 6, 16, 999)    
	--and m.PDIParticipant =0
	and m.productid<>p.productid
    and  (m.Bipad is  null or m.Bipad ='')
    
    
			

return
GO
