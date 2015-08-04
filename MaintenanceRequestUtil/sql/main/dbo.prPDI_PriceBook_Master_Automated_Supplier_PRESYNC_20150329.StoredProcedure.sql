USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prPDI_PriceBook_Master_Automated_Supplier_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prPDI_PriceBook_Master_Automated_Supplier_PRESYNC_20150329]

as


declare @recsup cursor
declare @RecordID int
declare @VendorIDinPDIFile nvarchar(50)
declare @VendorDescription nvarchar(500)
declare @VendorName nvarchar(50)
declare @VendorIdentifier nvarchar(50)
declare @myid int=0
declare @entitytypeid smallint=5
declare @supplieralreadyexists int
declare @tempname nvarchar(50)
declare @supplierid int
declare @chainidentifier nvarchar(50)
declare @chainid int
declare @startdate date=getdate()
declare @enddate date='12/31/2025'
declare @errormessage nvarchar(1000)

set @recsup = CURSOR local fast_forward FOR
SELECT [RecordID]
      ,ltrim(rtrim([VendorIDinPDIFile]))
      ,ltrim(rtrim([VendorDescription]))
      ,ltrim(rtrim([VendorDescription]))
      ,ltrim(rtrim(chainidentifier))
      --select *
  FROM [DataTrue_EDI].[dbo].[Temp_PDI_Vendors] v
Where 1 = 1 
and recordstatus = 0
--and DataTrueSupplierID is null


open @recsup

fetch next from @recsup into @recordid, @vendoridentifier, @vendordescription, @vendorname, @chainidentifier

While @@FETCH_STATUS = 0
	begin
				
				select @chainid = chainid 
				from chains
				where ltrim(rtrim(ChainIdentifier)) = @chainidentifier

				select datatruechainid, LTRIM(rtrim(PDIVendorID)), COUNT(distinct DatatrueSupplierID)
				--select *
				from datatrue_edi.dbo.Temp_PDI_VendorIDs 
				where datatruechainid = @chainid
				and LTRIM(rtrim(PDIVendorID)) = @vendoridentifier
				group by datatruechainid, LTRIM(rtrim(PDIVendorID))
				having COUNT(distinct DatatrueSupplierID) > 1
				
				if @@ROWCOUNT > 0
					begin

						set @errormessage = @chainidentifier + '/' + @vendorname + 'in pricebook load was matched to multiple supplierds and it was not loaded.'


						if @@ROWCOUNT > 0
							begin
							
								exec dbo.prSendEmailNotification_PassEmailAddresses 'PDI PriceBook Import Issue Detected - Multiple DataTrueSupplierIDs For Same Vendor'
									,@errormessage
									,'DataTrue System', 0, 'datatrueit@icucsolutions.com;vishal.gupta@icucsolutions.com;gagan.deep@icucsolutions.com'		
							end
					
					end
				else
					begin
				
						set @supplieralreadyexists = 0
						
						set @supplierid = null
						
						select @supplierid = DatatrueSupplierid 
						from datatrue_edi.dbo.Temp_PDI_VendorIDs
						where LTRIM(rtrim(PDIVendorID)) = @vendoridentifier
						and DataTrueChainID = @chainid
						
		--select * from datatrue_edi.dbo.Temp_PDI_VendorIDs

						if @@ROWCOUNT > 0
							begin
								set @supplieralreadyexists = @supplieralreadyexists + 1		
							end
						else
							begin
								Select @supplierid = SupplierID, @tempname = SupplierName 
								FROM [DataTrue_Main].[dbo].[Suppliers] 
								where ltrim(rtrim(SupplierName)) = ltrim(rtrim(@VendorName))
								
								if @@ROWCOUNT > 0
									begin
										set @supplieralreadyexists = @supplieralreadyexists + 1		
									end									
							end
							
						--print @tempname
						
						if @supplieralreadyexists > 0
							begin
						
								update [DataTrue_EDI].[dbo].[Temp_PDI_Vendors] set recordstatus = -1, DataTrueSupplierID = @supplierid, DataTrueChainID = @chainid
								where recordid = @RecordID
							
							end
						else
							begin
							
							
								set @errormessage = @chainidentifier + '/' + @vendorname + 'in pricebook load was not matched to existing supplier and it was not loaded.'


								if @@ROWCOUNT > 0
									begin
									
										exec dbo.prSendEmailNotification_PassEmailAddresses 'PDI PriceBook Import Issue Detected - Vendors Record Not Matched'
											,@errormessage
											,'DataTrue System', 0, 'datatrueit@icucsolutions.com;vishal.gupta@icucsolutions.com;gagan.deep@icucsolutions.com'		
									
							end					
							
							
		----20140920------						INSERT INTO [DataTrue_Main].[dbo].[SystemEntities]
		----------						   ([EntityTypeID]
		----------						   ,[LastUpdateUserID])
		----------						VALUES
		----------						   (@entitytypeid
		----------						   ,@MyID)
						           

		----------						set @supplierid = Scope_Identity()
									
		----------						INSERT INTO [DataTrue_Main].[dbo].[Suppliers]
		----------								   ([SupplierID]
		----------								   ,[SupplierName]
		----------								   ,[SupplierIdentifier]
		----------								   ,[SupplierDescription]
		----------								   ,[ActiveStartDate]
		----------								   ,[ActiveLastDate]
		----------								   ,[LastUpdateUserID])
		----------							 VALUES
		----------								   (@supplierid
		----------								   ,@VendorName
		----------								   ,@vendoridentifier --@VendorIDinPDIFile
		----------								   ,@VendorDescription
		----------								   ,@startdate
		----------								   ,@enddate
		----------								   ,@MyID)					

		------------Needed change - after supplier is inserted we need to also insert a record in datatrue_edi.dbo.Temp_PDI_VendorIDs table at this point.
					
		----------						update [DataTrue_EDI].[dbo].[Temp_PDI_Vendors] set recordstatus = 1, DataTrueSupplierID = @supplierid, DataTrueChainID = @chainid  
		----------						where recordid = @RecordID
							end 
			
						If @supplierid is not null
							begin
								select *
								from [DataTrue_EDI].[dbo].[TranslationMaster] t
								where [TranslationTypeID] = 26
								--and [TranslationTradingPartnerIdentifier] = @chainidentifier
								and [TranslationChainID] = @chainid	
								and [TranslationCriteria1] = CAST(@supplierid as nvarchar(50))					
										
								if @@ROWCOUNT < 1
									begin
										INSERT INTO [DataTrue_EDI].[dbo].[TranslationMaster]
											   ([TranslationTypeID]
											   ,[TranslationTradingPartnerIdentifier]
											   ,[TranslationChainID]
											   ,[TranslationSupplierID]
											   ,[TranslationClusterID]
											   ,[TranslationStoreID]
											   ,[TranslationProductID]
											   ,[TranslationTargetColumn]
											   ,[TranslationValueOutside]
											   ,[TranslationColumn1]
											   ,[TranslationCriteria1]
											   ,[ActiveStartDate]
											   ,[ActiveLastDate])
										 VALUES
											   (26 --<TranslationTypeID, int,>
											   ,@chainidentifier --<TranslationTradingPartnerIdentifier, nvarchar(50),>
											   ,@chainid --<TranslationChainID, int,>
											   ,@supplierid --0 --<TranslationSupplierID, int,>
											   ,0 --<TranslationClusterID, int,>
											   ,0 --<TranslationStoreID, int,>
											   ,0 --<TranslationProductID, int,>
											   ,'ALL' --<TranslationTargetColumn, nvarchar(500),>
											   ,@vendoridentifier --<TranslationValueOutside, nvarchar(500),>
											   ,'ALL' --<TranslationColumn1, nvarchar(50),>
											   ,CAST(@supplierid as nvarchar) --<TranslationCriteria1, nvarchar(50),>
											   ,'1/1/2010' --<ActiveStartDate, datetime,>
											   ,'12/31/2099') --<ActiveLastDate, datetime,>)
									end
							end
					end
							
			fetch next from @recsup into @recordid, @vendoridentifier, @vendordescription, @vendorname, @chainidentifier						
end

close @recsup
deallocate @recsup


return
GO
