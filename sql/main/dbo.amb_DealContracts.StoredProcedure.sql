USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_DealContracts]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create Procedure [dbo].[amb_DealContracts]
@PersonId int ,
@SupplierID int,
@FileName varchar(250) ,
@FileType varchar(50),
@FileSize varchar(50),
@DealNumber varchar(50) as

Insert into [DealContracts] (
[PersonId]  ,
[SupplierID],
[FileName]  ,
[FileType]  ,
[FileSize]  ,
[DealNumber]
)

Values(
@PersonId  ,
@SupplierID ,
@FileName  ,
@FileType  ,
@FileSize  ,
@DealNumber )

Declare @iErrorCode as int

SELECT @iErrorCode=@@ERROR
GO
