USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UploadFile]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_UploadFile]
@PersonId int ,
@ChainID int,
@SupplierID int,
@FileName varchar(250) ,
@FileType varchar(50),
@FileLocation varchar(250),
@FileSize varchar(50),
@UploadSource varchar(20),
@SendToRetailer bit,
@SendToSupplier bit  

as

Insert into [UploadedFiles] (
[PersonId]  ,
[ChainID],
[SupplierID],
[FileName]  ,
[FileType]  ,
[FileLocation],
[FileSize],
[uploadSource],
[SendToRetailer],
[SendToSupplier] )
Values(
@PersonId  ,
@ChainID,
@SupplierID ,
@FileName  ,
@FileType  ,
@fileLocation,
@FileSize,
@UploadSource,
@SendToRetailer,
@SendToSupplier )

if(@FileType='RegulatedInvoices')
begin
	--Adding teh record to the Ach_SuppliersFilesReceived in case the file type is Regulated Invoices
	Declare @SupplierName varchar(50), @ChainName varchar(50)

	select @SupplierName=SupplierIdentifier from Suppliers where SupplierId=@SupplierId
	select @ChainName=C.ChainIdentifier, @ChainId=C.ChainId from Chains C
	inner join SupplierBanners B on C.ChainId=B.ChainId
	where B.SupplierId=@SupplierId

	insert into Datatrue_edi.dbo.Ach_SuppliersFilesReceived(chainid,supplierid,datereceived,receivedflag,chainname,suppliername,filename)
									values(@ChainID,@SupplierID,GETDATE(),1,@ChainName,@SupplierName,@FileName)
end    

Declare @iErrorCode as int

SELECT @iErrorCode=@@ERROR
GO
