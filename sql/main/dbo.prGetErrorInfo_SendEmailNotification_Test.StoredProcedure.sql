USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetErrorInfo_SendEmailNotification_Test]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetErrorInfo_SendEmailNotification_Test] 
@chainid int,
@supplierid int

as
declare @chainidentifier nvarchar(50)
declare @chainname nvarchar(255)
declare @suppliername nvarchar(255)
declare @supplierIdentifier nvarchar(50)


if error_number() is null
    return

declare @errormessage nvarchar(4000)
declare @errorline int
declare @errorprocedure nvarchar(200)
declare @error_msg nvarchar(4000)

select 
    @errorline = ERROR_LINE(),
    @errorprocedure = ISNULL(ERROR_PROCEDURE(), '-'),
    @errormessage =  ERROR_MESSAGE()

set @error_msg = 'Error in procedure '+@errorprocedure+';  Line: '+cast(@errorline as nvarchar(10))+'; 
Message: '+@errormessage


select @chainidentifier = chainidentifier,   
	@chainname = ChainName
from chains 
where ChainID = @chainid

select 	@suppliername = SupplierName
from Suppliers
where supplierid = @supplierid


select @supplierIdentifier = LTRIM(rtrim(TranslationValueOutside)) 
from [DataTrue_EDI].[dbo].[TranslationMaster] 
where isnumeric(TranslationCriteria1) > 0 
and TranslationTypeID = 26 
and CAST(TranslationCriteria1 as int) = @supplierid
and TranslationChainID = @chainid

set @error_msg = 'Error  for chain name  ' + @chainname + '('+@chainidentifier+') and supplier name ' 
	+ @suppliername+'('+@supplierIdentifier+')'+char(13)+char(10)+ @error_msg


--print @errormessage
--print @error_msg
exec dbo.prSendEmailNotification_PassEmailAddresses 'PDI PriceBook Import Occurs Error'
	,@error_msg
	,'DataTrue System', 0, 'EZaslonkin@sphereconsultinginc.com'		
	--,'DataTrue System', 0, 'datatrueit@icucsolutions.com;Gilad.Keren@icucsolutions.com'		

return
GO
