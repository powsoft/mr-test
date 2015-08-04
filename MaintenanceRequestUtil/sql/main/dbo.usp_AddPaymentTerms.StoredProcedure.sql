USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_AddPaymentTerms]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_AddPaymentTerms]  
     @PaymentTermID int  Output , 
     @SupplierId varchar(20),
     @ChainId varchar(20),
     @StateName varchar(50),
     @PaymentDays int,
     @ActiveDate datetime,
     @EndDate datetime,
     @Status varchar(50),
     @LastModifiedBy int,
     @DeActivatedBy int,
     @Upc varchar(20),
			@ProductType varchar(50)
     as 
     
if (@PaymentTermID = 0) 
begin 
      Insert into [PaymentTerms] (
        [SupplierID]  ,  
        [ChainId],
        [StateName],
        [PaymentDueInBusinessDays],
        [ActiveDate],
        [EndDate],
        [Status],
        [LastModifiedBy],
        [DeActivatedBy],
        [UPC],
        [ProductType]
        
        )
      Values(
        @SupplierId,
        @ChainId,
        @StateName,
        @PaymentDays,
        @ActiveDate  , 
        @EndDate,
        @Status,
        @LastModifiedBy,
        @DeActivatedBy,
        @Upc,
        @ProductType
         ) 
end 

if (@PaymentTermID > 0)
Begin 

     Update [PaymentTerms] Set 
     [SupplierID] =  @SupplierId , 
     [ChainId]=@ChainId,
     [StateName] =  @StateName , 
     [PaymentDueInBusinessDays] =  @PaymentDays ,
     [ActiveDate]=@ActiveDate,
     [EndDate]=@EndDate,
     [Status]=@Status,
     [LastModifiedBy]=@LastModifiedBy,
     [DeActivatedBy]=@DeActivatedBy,
     [Upc]=@Upc,
     [ProductType]=@ProductType
      Where [PaymentTermID]=@PaymentTermID

End 
Declare @iErrorCode as int
-- Get the Error Code for the statement just executed.
SELECT @iErrorCode=@@ERROR
GO
