USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_checkdetailsWHLSByCheckNew_backup]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter date: <alter Date,,>
-- Description:	<Description,,>
-- =============================================

--exec [dbo].[amb_checkdetailsWHLSByCheckNew] 'WR320','271248'
--exec [dbo].[amb_checkdetailsWHLSByCheckNew] 'WR320','273490'
--exec [dbo].[amb_checkdetailsWHLSByCheckNew] 'Wolfe','370808'
--exec [dbo].[amb_checkdetailsWHLSByCheckNew] 'WR2198','104865'

-- exec [dbo].[amb_checkdetailsWHLSByCheckNew] 'STC','42503','499066','499950'
CREATE PROCEDURE [dbo].[amb_checkdetailsWHLSByCheckNew_backup]

	@WholesalerIdentifier VARCHAR(20),
	@WholesalerID VARCHAR(20),
	@checknumber VARCHAR(30),
	@checknumber2 VARCHAR(30)
	
AS

Declare @sql varchar (max)
Declare @dateissued varchar(20)
Declare @CheckNum as Cursor
Declare @ChecknumTO VARCHAR(30)
Declare @SqlOld VARCHAR(8000)
Declare @SqlNew VARCHAR(8000)
Declare @SqlFinal VARCHAR(8000)


  
--Declare @tempchecknumber as VARCHAR(30)

--if cast(@checknumber2 as int) < cast(@checknumber as int) 

--begin

--set @tempchecknumber=@checknumber
--set @checknumber=@checknumber2
--set @checknumber2=@tempchecknumber

--end
--

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
Create TABLE #temp_payment_results (
	[WholesalerID] [nvarchar](10) NOT NULL,
	[CheckNumber] [char](30) NULL,
	[ChainID] [nvarchar](10) NOT NULL,
	[Store Number] [nvarchar](20) NOT NULL,
	[NewspaperName] [nvarchar](100) NOT NULL,
	[SumOfQnt] [int] NULL,
	[CostToStore] [float] NOT NULL,
	[TotalCost] [float] NULL,
	[DateIssued] [varchar](20) NULL,
	[EndWeek] [varchar](20) NOT NULL,
	[InvType] [nvarchar](50) NOT NULL,
	[TitleID] [nvarchar](100) NULL
)
	
SET @Checknum= CURSOR LOCAL FAST_FORWARD FOR
      SELECT Distinct checknumber From [IC-HQSQL2].iControl.dbo.PaymentIssued 
      Where  CheckNumber >=@checknumber and CheckNumber <=@checknumber2
	  and WholesalerID =@WholesalerIdentifier
	     
	 OPEN @checknum
   
	FETCH NEXT FROM @Checknum Into @CheckNumTO
		WHILE @@FETCH_STATUS =	0
			begin	
	

SELECT @dateissued =CONVERT(varchar,PI.DateIssued,101) 
FROM [IC-HQSQL2].iControl.dbo.PaymentIssued PI 
GROUP BY PI.WholesalerID, PI.CheckNumber, PI.DateIssued
HAVING PI.WholesalerID=@WholesalerIdentifier AND PI.CheckNumber=@Checknumber;

	    -- Insert statements for procedure here

SET	 @sql='SELECT PI.WholesalerID, PI.CheckNumber, [EDI 810-Translator DetailsChains].ChainID, 
				[EDI 810-Translator DetailsChains].[Store Number], [TitleName] AS NewspaperName,
				Sum([EDI 810-Translator DetailsChains].Qnt) AS SumOfQnt, [EDI 810-Translator DetailsChains].CostToStore, 
				Sum([Qnt]*[CostToStore]) AS TotalCost,Convert(varchar,PI.DateIssued,101) as DateIssued,
				Convert(varchar,[EDI 810-Translator DetailsChains].EndWeek,101) as EndWeek, [EDI 810-Translator DetailsChains].InvType, 
				 PWB.WholesaerBipad AS TitleID 
				
				FROM ((([IC-HQSQL2].iControl.dbo.[EDI 810-Translator DetailsChains] [EDI 810-Translator DetailsChains]
				INNER JOIN [IC-HQSQL2].iControl.dbo.PaymentIssued  PI ON [EDI 810-Translator DetailsChains].InvoiceNo = PI.InvNo)
				INNER JOIN [IC-HQSQL2].iControl.dbo.[UPCs List] [UPCs List] ON [EDI 810-Translator DetailsChains].upc = [UPCs List].UPC) 
				INNER JOIN [IC-HQSQL2].iControl.dbo.Products P ON ([UPCs List].Bipad = P.Bipad) AND ([UPCs List].Bipad = P.Bipad)) 
				LEFT JOIN  [IC-HQSQL2].iControl.dbo.ProductsWhlsUniqueBipads PWB ON (P.Bipad =  PWB.iControlBipad) 
				AND (PI.WholesalerID =  PWB.WholesalerID) 

				GROUP BY PI.WholesalerID, PI.CheckNumber, [EDI 810-Translator DetailsChains].ChainID, 
				[EDI 810-Translator DetailsChains].[Store Number], [TitleName], [EDI 810-Translator DetailsChains].CostToStore, 
				PI.DateIssued, [EDI 810-Translator DetailsChains].EndWeek, [EDI 810-Translator DetailsChains].InvType, 
				 PWB.WholesaerBipad 

				HAVING (((PI.WholesalerID)='''+rtrim(@WholesalerIdentifier)+''') AND ((PI.CheckNumber)='''+rtrim(@ChecknumTO)+''')) 
				
		
                union all

        	--PI.DateIssued

			SELECT '''+rtrim(@WholesalerIdentifier)+'''AS WholesalerID,'''+rtrim(@ChecknumTO)+''' as CheckNumber ,[EDI 810-Translator DetailsChains].ChainID, 
			[EDI 810-Translator DetailsChains].[Store Number], P.TitleName, Sum([EDI 810-Translator DetailsChains].Qnt) AS SumOfQnt,
			[EDI 810-Translator DetailsChains].CostToStore,Sum([Qnt]*[CostToStore]) AS TotalCost,'''+cast(@DateIssued as VARCHAR(20))+''' AS DateIssued,
			Convert(varchar,[EDI 810-Translator DetailsChains].EndWeek,101) as EndWeek, [EDI 810-Translator DetailsChains].InvType,'''' as TitleID

			FROM (([IC-HQSQL2].iControl.dbo.[EDI 810-Translator DetailsChains] [EDI 810-Translator DetailsChains]
			INNER JOIN [IC-HQSQL2].iControl.dbo.[UPCs List] [UPCs List] ON [EDI 810-Translator DetailsChains].upc = [UPCs List].UPC) 
			INNER JOIN [IC-HQSQL2].iControl.dbo.Products P ON ([UPCs List].Bipad = P.Bipad) AND ([UPCs List].Bipad = P.Bipad)) 
			WHERE [EDI 810-Translator DetailsChains].InvoiceNo IN 
				(
					SELECT CAST([AggregatorNumber] as float) AS InvNoNum
					FROM ([IC-HQSQL2].iControl.dbo.[EDI 810-Translator DetailsChains]  [EDI 810-Translator DetailsChains]
					INNER JOIN [IC-HQSQL2].iControl.dbo.PaymentIssued  PI ON [EDI 810-Translator DetailsChains].InvoiceNo = PI.InvNo) 
					INNER JOIN [IC-HQSQL2].iControl.dbo.InvoiceAggregation InvoiceAggregation ON PI.InvNo = InvoiceAggregation.InvoiceNumber
					WHERE CAST([AggregatorNumber] as float) NOT IN (SELECT InvoiceNo FROM [IC-HQSQL2].iControl.dbo.Invoices) 
					AND (AggregatorNumber not like ''%FEE%'' and AggregatorNumber not like ''D%'' 
					and AggregatorNumber not like ''H%'' and AggregatorNumber not like ''%S%'')
					GROUP BY PI.WholesalerID, PI.CheckNumber, [AggregatorNumber], [EDI 810-Translator DetailsChains].ChainID
					HAVING (((PI.WholesalerID)='''+rtrim(@WholesalerIdentifier)+''') AND ((PI.CheckNumber)='''+rtrim(@ChecknumTO)+''')) 
				)
			GROUP BY [EDI 810-Translator DetailsChains].ChainID, 
			[EDI 810-Translator DetailsChains].[Store Number], P.TitleName, [EDI 810-Translator DetailsChains].CostToStore, 
			[EDI 810-Translator DetailsChains].EndWeek, [EDI 810-Translator DetailsChains].InvType
			--HAVING (((WholesalerID)='''+rtrim(@WholesalerIdentifier)+'''))


			union all
				
				
			SELECT '''+rtrim(@WholesalerIdentifier)+''' AS WHLSID,'''+rtrim(@ChecknumTO)+''' as CheckNo,PI.ChainID, SL.StoreNumber, 
			''DeliveryFee'' AS txtFee, 1 AS qnt, Sum(I.DeliveryFee) AS CostToStore, Sum(I.DeliveryFee) AS TotalCost,Convert(varchar,
			PI.DateIssued,101) as DateIssued,Convert(varchar,PI.WeekEnding,101) as EndWeek,
			''DeliveryFee'' AS InvType,'''' AS TitleID

			FROM ([IC-HQSQL2].iControl.dbo.PaymentIssued  PI 
			INNER JOIN  [IC-HQSQL2].iControl.dbo.Invoices I  ON PI.InvNo = I.InvoiceNo) 
			INNER JOIN [IC-HQSQL2].iControl.dbo.StoresList  SL ON (PI.ChainID = SL.ChainID) AND (I.StoreID = SL.StoreID)
			WHERE I.WholesalerID='''+rtrim(@WholesalerIdentifier)+'''
			GROUP BY PI.CheckNumber, PI.ChainID, SL.StoreNumber, PI.WeekEnding, PI.DateIssued
			HAVING PI.CheckNumber='''+rtrim(@ChecknumTO)+''' AND Sum(I.DeliveryFee)<>0


			union all


			SELECT '''+rtrim(@WholesalerIdentifier)+''' AS WHLSID,'''+rtrim(@ChecknumTO)+''' as CheckNo,PI.ChainID, SL.StoreNumber, 
			''DataStorageFee'' AS txtFee, 1 AS qnt,Sum(I.NetInvoice) AS CostToStore, Sum(I.NetInvoice) AS TotalCost,
			Convert(varchar,PI.DateIssued,101) as DateIssued,Convert(varchar,
			PI.WeekEnding,101) as EndWeek,''DSF'' AS InvType,'''' AS TitleID

			FROM ([IC-HQSQL2].iControl.dbo.PaymentIssued  PI 
			INNER JOIN  [IC-HQSQL2].iControl.dbo.Invoices I  ON PI.InvNo = I.InvoiceNo) 
			INNER JOIN [IC-HQSQL2].iControl.dbo.StoresList  SL ON (PI.ChainID = SL.ChainID) AND (I.StoreID = SL.StoreID)

			WHERE I.WholesalerID='''+rtrim(@WholesalerIdentifier)+''' and I.InvType=''DSF''
			GROUP BY PI.CheckNumber, PI.ChainID, SL.StoreNumber, PI.WeekEnding, PI.DateIssued
			HAVING PI.CheckNumber='''+rtrim(@ChecknumTO)+''' AND Sum(I.NetInvoice)<>0 '

	

--print(@SQL)
	insert into #temp_payment_results exec(@sql)
	
	FETCH NEXT FROM @Checknum Into @CheckNumTo
	end
	CLOSE @CheckNum
    DEALLOCATE @CheckNum
    
    
	SET @SqlOld = 'Select * from #temp_payment_results '
    
	
	SET @SqlNew= 'SELECT DISTINCT ID.SupplierIdentifier AS WholesalerID,Pd.CheckNo AS CheckNumber,C.ChainIdentifier as ChainID,
					ID.StoreIdentifier AS [Store Number],P.ProductName AS [NewspaperName],Sum(Id.TotalQty) AS SumOfQnt,
					Id.Unitcost AS CostToStore,Sum(ID.TotalQty * Id.Unitcost) AS TotalCost,Convert(varchar,PD.DisbursementDate,101) AS DateIssued,
					Convert(varchar,ID.SaleDate,101) as EndWeek,IDT.InvoiceDetailTypeName AS InvType,PID.Bipad AS TitleID

					FROM dbo.InvoiceDetails ID
					INNER JOIN dbo.PaymentHistory PH ON ID.PaymentID=PH.PaymentID and PH.PaymentStatus=10
					INNER JOIN dbo.PaymentDisbursements PD ON PD.DisbursementID=PH.DisbursementID 
					INNER JOIN dbo.InvoiceDetailTypes IDT ON ID.InvoiceDetailTypeID = IDT.InvoiceDetailTypeID  
					INNER JOIN dbo.Chains C ON ID.ChainID = C.ChainID	
					INNER JOIN dbo.Products P ON ID.ProductID=P.ProductID
					INNER JOIN dbo.ProductIdentifiers PID ON PID.OwnerEntityID=ID.SupplierID AND PID.Productidentifiertypeid=8

					GROUP BY ID.SaleDate,ID.SupplierIdentifier,C.ChainIdentifier,PD.DisbursementDate,Pd.CheckNo,P.ProductName,
					IDT.InvoiceDetailTypeName,ID.SupplierID,ID.StoreIdentifier,Id.Unitcost,ID.TotalQty,PID.Bipad

					HAVING 1=1 AND ID.SupplierID='+@WholesalerID
										
    IF (@checknumber<>'')
		SET @SqlNew += ' AND Pd.CheckNo >=''' + @checknumber + ''''
	
    IF (@checknumber2<>'')
		SET @SqlNew += ' AND Pd.CheckNo <= ''' + @checknumber2 + ''''
	
	
	PRINT(@SqlOld + ' UNION ' + @SqlNew)
	/* -----EXEC Final Query------ */		
	 EXEC(@SqlOld + ' UNION ' + @SqlNew)

END
GO
