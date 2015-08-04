USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UpdatePDIVendors_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC usp_UpdatePDIVendors '44285','62314','Exclude','41713'

CREATE procedure [dbo].[usp_UpdatePDIVendors_PRESYNC_20150329]
@ChainID varchar(20),
@SupplierID varchar(20),
@Action varchar(10),
@UserID varchar(20)
As
Begin

Declare @Flag bit
Declare @IsExist int

IF(@Action = 'Include')
	SET @Flag = 0
ELSE	
	SET @Flag = 1


			SET @IsExist = 0
			Select @IsExist = count(*) from PDIVendors where ChainID=@ChainID and SupplierID=@SupplierID
			
			IF(@IsExist=0)
				Begin
					
					INSERT INTO PDIVendors
					(
						ChainID,
						SupplierID,
						IsExcluded
					)
					VALUES
					(
						@ChainID,
						@SupplierID,
						@Flag
					)
					
				End
			ELSE
				Begin
				
					UPDATE PDIVendors
					SET
							IsExcluded = @Flag,
							LastUpdatedBy= @UserID,
							LastUpdatedDate = getdate()
					WHERE
							ChainID = @ChainID
							AND SupplierID = @SupplierID						
					
				End
	
End
GO
