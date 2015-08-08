USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetPaymentTerms]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec usp_GetPaymentTerms '-1','50964','-1','Active','',''
CREATE procedure [dbo].[usp_GetPaymentTerms]
@SupplierId varchar(20),
@ChainId varchar(20),
@StateName varchar(50),
@Status varchar(50),
@Upc varchar(20),
@ProductType varchar(50)
as
 
Begin
Declare @sqlQuery varchar(4000)
    set @sqlQuery = 'SELECT p.PaymentTermID, s.SupplierName, p.ChainId,  p.StateName,
					 p.PaymentDueInBusinessDays as PaymentDays, 
					 convert(varchar(10),p.ActiveDate,101) as ActiveDate,
					  convert(varchar(10),p.EndDate,101) as EndDate, Status,p.UPC,P.ProductType as [Product Type]
					FROM dbo.PaymentTerms p
					INNER JOIN dbo.Suppliers s ON s.SupplierId = p.SupplierID 					
					where 1=1 '
           
        if(@SupplierId <>'-1' )   
            set @sqlQuery = @sqlQuery + ' and p.SupplierID = ' + @SupplierId
        
        if(@ChainId <>'-1' )   
            set @sqlQuery = @sqlQuery + ' and p.ChainId = ' + @ChainId
           
        if(@StateName <> '-1' )
            set @sqlQuery = @sqlQuery + ' and p.StateName = ''' + @StateName + ''''
         
        if(@Status <> '-1' )
            set @sqlQuery = @sqlQuery + ' and p.Status = ''' + @Status + ''''
            
        if(@UPC<>'')
				set @sqlQuery = @sqlQuery + ' and P.UPC=''' + @UPC + ''''
				
		 if(@ProductType<>'-1')
				set @sqlQuery = @sqlQuery + ' and P.ProductType=''' + @ProductType + ''''

        
        PRINT @sqlQuery    
        execute(@sqlQuery);
 
End
GO
