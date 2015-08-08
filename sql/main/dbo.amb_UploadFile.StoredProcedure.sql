USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_UploadFile]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create Procedure [dbo].[amb_UploadFile]
@PersonId int ,
@ChainID int,
@SupplierID int,
@FileName varchar(250) ,
@FileType varchar(50),
@FileLocation varchar(250),
@FileSize varchar(50),
@UploadSource varchar(20)  as

Insert into [UploadedFiles] (
[PersonId]  ,
[ChainID],
[SupplierID],
[FileName]  ,
[FileType]  ,
[FileLocation],
[FileSize],[uploadSource]  )
Values(
@PersonId  ,
@ChainID,
@SupplierID ,
@FileName  ,
@FileType  ,
@fileLocation,
@FileSize,@UploadSource   )

Declare @iErrorCode as int

SELECT @iErrorCode=@@ERROR
GO
