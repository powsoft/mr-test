USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[DQOutboundFiles]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--SET DATEFIRST 1
Create PROCEDURE [dbo].[DQOutboundFiles]
	--@ParnerID as varchar(10)
	@WeekEndingDate as varchar(10)
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--Select * from InvoiceDetails
Delete from DQTEMPDQ
SET DATEFIRST 1
insert DQTEMPDQ

SELECT 'DOUBLEQ   ' AS CHaidID, 
Cast(I.StoreIdentifier AS VARCHAR(20)) + Cast(Replicate(' ',20-Len(I.StoreIdentifier)) AS VARCHAR(20)) AS StoreID, 
 ''
AS UPC
,
CONVERT(VARCHAR(8), i.SaleDate, 112) AS SaleDate, 
 Cast(Replicate('0',4-Len(Convert(INT,I.TotalQty))) AS VARCHAR(4)) + Cast(Convert(INT,(I.TotalQty)) AS VARCHAR(4)) As QTY, 
 Cast(Replicate('0',5-Len(I.UnitCost)) AS VARCHAR(5)) + Cast(I.UnitCost AS VARCHAR(5)) As Cost, I.ProductID, ' '
FROM         Suppliers S INNER JOIN
                      InvoiceDetails I ON S.SupplierID = I.SupplierID --INNER JOIN
                      --ProductIdentifiers  P ON I.ProductID = P.ProductID 
                      INNER JOIN Chains C ON I.ChainID = C.ChainID              
                      Where S.SupplierID= '63383'  and I.ChainID = 62362 and ---P.ProductName LIke 'USA%'
                     ---'63383'
                        DATEADD(DAY, 7 - DATEPART(WEEKDAY, SaleDate), CAST(SaleDate AS DATE))=@WeekEndingDate
                        --Select * from ProductIdentifiers
      --                  update 
                      
      --Select ProductID, Bipad, IdentifierValue from ProductIdentifiers where ProductIdentifierTypeID=8    and Bipad ='USA'         
      
      --Update DQTEMPDQ set  UPC = Select ProductID, Bipad, IdentifierValue from ProductIdentifiers where ProductIdentifierTypeID=8) P
      -- DQTEMPDQ Q inner join (
      --oN Q.PRoductID= P.ProductID where p.Bipad = 'USA'
      
      
      UPDATE   DQTEMPDQ
SET     Bipad= DataTrue_Main..ProductIdentifiers.Bipad, UPC = DataTrue_Main..ProductIdentifiers.IdentifierValue + '  '     
FROM         DQTEMPDQ INNER JOIN
                      ProductIdentifiers ON DQTEMPDQ.PRoductID = ProductIdentifiers.ProductID

--Select * from DQTEMPDQ where Bipad 

Update  DQTEMPDQ set UPC = 
Case datename(dw,SalesDate) 
When 'Monday' THen '089505010059'
When 'Tuesday' THen '089505020058'
When 'Wednesday' THen '089505030057'
When 'Thursday' THen '089505040056'
When 'Friday' THen '089505050055'
When 'Saturday' THen '089505050055'
When 'Sunday' THen '089505050055'

End + '  '
where BIpad = 'USA'
--Select * from DQTEMPDQ
END
GO
