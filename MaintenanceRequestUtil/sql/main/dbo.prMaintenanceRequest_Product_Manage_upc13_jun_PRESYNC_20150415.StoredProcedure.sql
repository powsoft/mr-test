USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_Product_Manage_upc13_jun_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Batch submitted through debugger: SQLQuery12.sql|7|0|C:\Users\irina.trush\AppData\Local\Temp\15\~vsD393.sql
CREATE 
procedure [dbo].[prMaintenanceRequest_Product_Manage_upc13_jun_PRESYNC_20150415]
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



update c set  c.PDIParticipant = p.PDIParticipant
--select *
from MaintenanceRequests c
inner join PDI_CHAIN_SUPPLIER_RELATIONS p
on c.supplierid = p.supplierid
and c.chainid=p.chainid
where RequestStatus  not in (5,999)
and c.PDIParticipant<> p.PDIParticipant
and (Bipad is  null or Bipad<>'')

update m set upc12= datatrue_edi.dbo.fnParseUPC(LTRIM(rtrim(upc)))	
--select*
	from dbo.MaintenanceRequests  m	
    where  RequestStatus not in (5, 15, 6, 16, 999)
    and m.upc12 is null	
	and PDIParticipant =0
	and  (m.Bipad is  null or m.Bipad ='')
	and isnull(Approved, -1) <> 0	
	and LEN(LTRIM(rtrim(upc)))>12
	and (datatrue_edi.dbo.fnParseUPC(LTRIM(rtrim(upc))) in (select distinct identifiervalue from ProductIdentifiers)	
	or isnull(Approved, -1) <> 0	)
	
update m set upc12= datatrue_edi.dbo.fnParseUPC(LTRIM(rtrim(rawproductidentifier)))
 --select*
	from dbo.MaintenanceRequests  m
	where  RequestStatus not in (5, 15, 6, 16, 999)
    and m.upc12 is null	
    and  (m.Bipad is  null or m.Bipad ='')
	and PDIParticipant =0
	and isnull(Approved, -1) <> 0	
	and LEN(LTRIM(rtrim(rawproductidentifier)))>12	
	and LEN(LTRIM(rtrim(upc)))<1
	and (datatrue_edi.dbo.fnParseUPC(LTRIM(rtrim(rawproductidentifier))) in (select distinct identifiervalue from ProductIdentifiers)	
	or isnull(Approved, -1) <> 0	)
	
	
update m set upc12= datatrue_edi.dbo.fnParseUPC(upc)
	--select*
	from dbo.MaintenanceRequests  m	
	 where  RequestStatus not in (5, 15, 6, 16, 999)
    and m.upc12 is null	
	and PDIParticipant =0 
	and  (m.Bipad is  null or m.Bipad ='')
	and LEN(LTRIM(rtrim(upc)))<13
	and LEN(LTRIM(rtrim(upc)))>1
	and (datatrue_edi.dbo.fnParseUPC(LTRIM(rtrim(upc))) in (select distinct identifiervalue from ProductIdentifiers)	
	or isnull(Approved, -1) <> 0	)
	
--update m set m.upc12= datatrue_edi.dbo.fnParseUPC(LTRIM(rtrim(m.rawproductidentifier)))	
select datatrue_edi.dbo.fnParseUPC(LTRIM(rtrim(rawproductidentifier)))	
	from dbo.MaintenanceRequests  m
	  where  RequestStatus not in (5, 15, 6, 16, 999)
    and m.upc12 is null	
	and PDIParticipant =0
	and  (m.Bipad is  null or m.Bipad ='')
	and LEN(LTRIM(rtrim(rawproductidentifier)))<13
	and LEN(LTRIM(rtrim(rawproductidentifier)))>1
	and LEN(LTRIM(rtrim(upc)))<1
	and (datatrue_edi.dbo.fnParseUPC(LTRIM(rtrim(rawproductidentifier))) in (select distinct identifiervalue from ProductIdentifiers)	
	or isnull(Approved, -1) <> 0	)
	
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
	and PDIParticipant =0
	and ProductIdentifierTypeID = 2
    and  (m.Bipad is  null or m.Bipad ='')
	
	
	update m set 	
	dtproductdescription =description	
	from dbo.MaintenanceRequests  m 	        
    inner join Products r
    on m.ProductId=r.productid
    where   dtproductdescription is  null	
	and PDIParticipant =0
	and  (m.Bipad is  null or m.Bipad ='')
	
	
	
	


set @recten = CURSOR local fast_forward FOR
	select maintenancerequestid, LTRIM(rtrim(upc12)), LTRIM(rtrim(ItemDescription)) , Chainid--,bipad,supplierid,productid,datetimecreated,cost,requeststatus--,productid--,datatrue_edi_costs_recordid,rawproductidentifier--, PDIParticipant,requestsource,SupplierID
	from dbo.MaintenanceRequests
	where RequestStatus  not in (5, 15, 6, 16, 999)
	and ProductId is null	
	and LEN(LTRIM(rtrim(upc12)))> = 12
	and PDIParticipant =0
	and (Bipad is null or Bipad ='')
	and Approved=1
	and RequestTypeID in (1,2)
	and datetimecreated >'11-01-2013'
	
	--and upc12 like '%744473490233%'
	
	

open @recten

fetch next from @recten into @maintenancerequestid, @mrupc, @itemdescription, @chainid

while @@FETCH_STATUS = 0
	begin
	if LEN(LTRIM(rtrim(@itemdescription)))<1
			set @itemdescription=@mrupc
			
	    select @productid = productid from ProductIdentifiers 	    
			where ltrim(rtrim(IdentifierValue)) = @mrupc
			and ProductIdentifierTypeID=2
			
			
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
				   ,2 --UPC is type 2
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
						   
					
				update MaintenanceRequests set Productid = @productid,  dtproductdescription = @productdescription ,upc=@mrupc
				where MaintenanceRequestID = @maintenancerequestid
			end

		
			
		fetch next from @recten into @maintenancerequestid, @mrupc, @itemdescription, @chainid
	end
	
close @recten
deallocate @recten

--deallocate @rec2



declare @mrid int
declare @banner nvarchar(50)

declare @cost money

set @rec5 = CURSOR local fast_forward FOR
	select MaintenanceRequestid, ltrim(rtrim(Banner)), UPC12, ProductID, supplierid
	--select *
	from MaintenanceRequests
	where ProductId is not null
	and requesttypeid =2
	and ISNULL(cost, 0) = 0
	and (approved is null or approved = 1)
	and requeststatus not in (5, 6, 15, 16, 18, 999, -89, 9, -5)
	and (Bipad is null or Bipad ='')
	and PDIParticipant=0
	
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

update m set upc= upc12	
--select requeststatus,upc,upc12
	from dbo.MaintenanceRequests  m
    where   upc12 is not null	
	and LEN(LTRIM(rtrim(upc12)))>1
	and LEN(LTRIM(rtrim(upc)))<1
	and (Bipad is null or Bipad ='')
	and PDIParticipant=0



update c set  PDIParticipant = PDITradingPartner
from MaintenanceRequests c
inner join chains  b
on c.chainid = b.chainid
and PDIParticipant <> PDITradingPartner
and Bipad is not null
return
GO
