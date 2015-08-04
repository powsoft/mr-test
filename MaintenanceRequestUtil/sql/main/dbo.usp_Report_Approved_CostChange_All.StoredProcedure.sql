USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Approved_CostChange_All]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec usp_Report_Approved_CostChange_All 79370,80673,'Buc-ees','-1','80666','-1',0,'1/1/1900','1/1/2099'
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  procedure  [dbo].[usp_Report_Approved_CostChange_All] 
	-- exec [usp_Report_Approved_CostChange_All] '40393','41713','All','','26643,28034,27891,63986,27712,41468,28731,26809,24716,64418,26673,29132,60184,26936,25749,25284,24155,60021,65720,27731,25465,26290,27398,40557,27030,60120,25369,73522,26857,25574,27197,60544,33501,79301,34980,60290,34873,26882,40578,24947,26714,35193,25216,27664,35232,24443,74225,25006,41348,24472,27143,25003,33797,28807,40569,79182,60555,60188,27729,24166,26813,34940,27874,60221,26789,40572,28815,34904,34796,34494,29257,26749,40571,35160,34456,29284,28967,65590,25399,77805,60166,60198,27228,60216,24724,24170,35202,41342,28819,28303,60213,24172,60210,28154,41343,41746,28207,26953,60228,28245,60178,60453,60060,28161,28781,28881,27315,29710,26966,25516,27717,40567,60187,27275,27801,60222,60209,60249,28628,25832,40558,34758,25666,60196,25193,28795,26246,25295,76819,26122,30227,28942,25277,30246,26709,29136,60081,28010,24194,26292,26261,25627,44109,60246,27799,24195,27593,60171,26263,34752,27552,25250,30434,24489,26827,28878,28518,24509,28011,26015,25174,28218,26565,60217,26871,27124,60080,25291,28504,24537,41464,25391,60119,24209,28158,60115,60527,26575,75148,24214,27492,28446,34224,32737,60410,60208,24910,63992,28248,60088,28444,40563,27790,27108,26316,60248,31027,24547,27895,26424,26578,28029,60193,60534,60212,60157,24645,35137,25380,41461,40559,28822,31295,25951,60234,25223,24256,24401,26188,25230,34458,26541,27645,28689,63972,28821,26848,26414,79591,28538,60101,26289,27426,28835,60183,60283,25372,28644,27680,40562,29163,27986,34757,26456,60204,25345,26800,60201,60192,34844,27274,40568,25194,27293,28285,24215,32104,60165,24222,24217,26086,60155,26042,25494,34170,24594,60225,60185,40560,60176,27900,26473,31514,26579,26573,24540,27567,25296,41465,65662,40561,26758,25548,28914,26020,63956,60223,32414,25642,73542,25682,27765,28863,75146,26831,26330,40570,41440,28956,28152,26797,60174,28910,26591,60189,34304,27192,27372,34913,26896,29102,32711,60479,24875,34840,60179,28676,25365,35060,35069,27657,60089,60232,60211,24465,31541,25530,28107,25198,25176,25177,60575,34680,25588,28877,24304,60215,60463,25976,40573,60197,28244,26381,74813,60162,34558,26691,34477,27869,60267,42148,33075,26832,27917,60170,40566,27053,25780,26341,60194,26208,40564,29114,28237,25707,33194,28944,25926,60207,60168,60566,26851,24269,33429,60266,25371,27517,44188,34851,73515,60206','','530','1900-01-01','1900-01-01'
	@chainID varchar(max),
	@PersonID int,
	@Banner varchar(50),
	@ProductUPC varchar(20),
	@SupplierId varchar(max),
	@StoreId varchar(10),
	@LastxDays int,
	@StartDate varchar(20),
	@EndDate varchar(20)
AS
BEGIN
Declare @Query varchar(max)
declare @AttValue int
Declare @CostFormat varchar(10)

	if(@supplierID<>'-1')
			Begin
		DECLARE @sqlCommand nvarchar(max)
		declare @counts int
		SET @sqlCommand = 'SELECT @cnt=Max(Costformat) FROM SupplierFormat where SupplierID in ('+ @supplierID+' )'
		EXECUTE sp_executesql @sqlCommand, N'@cnt int OUTPUT',   @cnt=@CostFormat OUTPUT
	End
	 else
		set @CostFormat=4
	set @CostFormat = ISNULL(@CostFormat , 4)
	select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
	
	set @query = 'SELECT  CAST(mreq.MaintenanceRequestID AS varchar) AS [Maintenance Request ID], 
					CASE WHEN RequestTypeID = 2 THEN ''Cost Change'' ELSE '''' END AS [Request Type], sup.SupplierName AS [Supplier Name], 
					mreq.Banner AS Banner,
					(SELECT CostZoneName FROM   CostZones WHERE (CostZoneId = mreq.CostZoneID)) AS [Cost Zone Name], 
					mreq.UPC,case when mreq.RequestTypeId>1 then case when  isnull(mreq.ItemDescription,'''')=''''  then prod.ProductName else mreq.ItemDescription end else mreq.ItemDescription end  as [Item Description], 
					convert(varchar(10),CAST(mreq.SubmitDateTime AS date),101) AS [Submit Date Time], 
					convert(varchar(10),CAST(mreq.StartDateTime AS date),101) AS [Start Date Time], 
					convert(varchar(10),CAST(mreq.EndDateTime AS date),101) AS [End Date Time],
					(SELECT dbo.Persons.FirstName + dbo.Persons.LastName AS Expr1 FROM dbo.Logins 
						INNER JOIN dbo.Persons ON dbo.Logins.OwnerEntityId = dbo.Persons.PersonID
						WHERE (dbo.Logins.OwnerEntityId = mreq.SupplierLoginID)) AS [Supplier User Name],
					case when sup.PDITradingPartner=1 then 
							''$''+ Convert(varchar(50), cast(p.UnitPrice as numeric(10,' + @CostFormat + ')))  
						else 
							''$''+ Convert(varchar(50), cast(mreq.CurrentSetupCost as numeric(10,' + @CostFormat + ')))  
						end as [Current Setup Cost],
					
					''$''+ Convert(varchar(50), cast(mreq.Cost as numeric(10,' + @CostFormat + ')))  AS Cost, 
					''$''+ Convert(varchar(50), cast(mreq.SuggestedRetail as numeric(10,2))) AS [Suggested Retail], 
					CASE WHEN PromoTypeID = 1 THEN ''OI'' WHEN PromoTypeID = 2 THEN ''BB'' WHEN PromoTypeID = 3 THEN ''CC'' ELSE '''' END AS [Promo Type], 
					''$''+ CAST(mreq.PromoAllowance AS varchar) AS [Promo Allowance], 
					mreq.EmailGeneratedToSupplier as [Email Generated To Supplier], 
					convert(varchar(10),CAST(mreq.EmailGeneratedToSupplierDateTime AS date),101) AS [Email Date Time], 
					CASE WHEN Approved = 1 THEN ''Yes'' WHEN Approved = 0 THEN ''No'' ELSE ''Pending'' END AS Approved, 
					convert(varchar(10),CAST(mreq.ApprovalDateTime AS date),101) AS [Approved Date Time],
					(SELECT Persons_1.FirstName + '' '' + Persons_1.LastName AS Expr1 FROM   dbo.Logins AS Logins_1 
						INNER JOIN dbo.Persons AS Persons_1 ON Logins_1.OwnerEntityId = Persons_1.PersonID
						WHERE (Logins_1.OwnerEntityId = mreq.ChainLoginID)) AS [Retailer User Name],
		 case when mreq.RequestTypeId>1 then  case when isnull(mreq.VinDescription,'''')='''' then prod.VinDesc else mreq.VinDescription end else mreq.VinDescription end as [VIN Description]   
					FROM    MaintenanceRequests AS mreq with (nolock) 
					INNER JOIN   Suppliers AS sup with (nolock)  ON mreq.SupplierID = sup.SupplierID 
					INNER JOIN  Chains AS ch with (nolock) ON mreq.ChainID = ch.ChainID 
					INNER JOIN   SupplierBanners SB with (nolock) on SB.SupplierId = sup.SupplierId and SB.Status=''Active'' and SB.Banner=mreq.banner 
					left join (Select distinct IdentifierValue, ProductName, T.VIN, T.OwnerPackageDescription as VinDesc, T.SupplierID 
													from Products P WITH(NOLOCK)
													inner join ProductIdentifiers PD WITH(NOLOCK) on PD.ProductId=P.ProductId and PD.ProductIdentifierTypeId=2
													left join SupplierPackages T WITH(NOLOCK) on T.ProductID=P.ProductID
												) Prod on Prod.IdentifierValue = mreq.UPC and Prod.SupplierID = mreq.SupplierID and Prod.VIN=mreq.VIN 
					
					left JOIN (
													Select DISTINCT P.SupplierId, ChainId, PD.IdentifierValue as UPC, UnitPrice, T.VIN
													from ProductPrices P WITH (NOLOCK)
													INNER JOIN ProductIdentifiers PD WITH (NOLOCK) on PD.ProductID=P.ProductID AND PD.ProductIdentifierTypeID=2 and p. ProductPriceTypeID=11 
													left join SupplierPackages T WITH(NOLOCK) on T.ProductID=P.ProductID and T.SupplierID=P.SupplierID 
													and T.SupplierPackageTypeID=1 --and T.SupplierPackageID=P.SupplierPackageID
					and P.ProductPriceTypeID IN (3,11)
									AND getdate() BETWEEN P.ActiveStartDate AND P.ActiveLastDate
								  ) P on P.SupplierID=mreq.SupplierID and P.ChainID=mreq.ChainID AND P.UPC=mreq.UPC and P.VIN=mreq.VIN	
					WHERE (approved=1) and RequestTypeId=2 and requeststatus<>999 '


	--if @AttValue =17
	--	set @query = @query + ' and ch.ChainID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
	--else
	--	set @query = @query + ' and sup.SupplierID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'

	if(@chainID  <>'-1') 
		set @Query   = @Query  +  ' and mreq.ChainID in (' + @chainID +')'

	if(@Banner<>'All') 
		set @Query  = @Query + ' and mreq.banner like ''%' + @Banner + '%'''

	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and mreq.SupplierId in (' + @SupplierId  +')'
	
	if(@ProductUPC  <>'-1') 
		set @Query   = @Query  +  ' and  mreq.UPC like ''%' + @ProductUPC + '%'''

	if (@LastxDays > 0)
		set @Query = @Query + ' and (mreq.StartDateTime between dateadd(d,-' +  cast(@LastxDays as varchar) + ', { fn NOW() }) and { fn NOW() }  )'  
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and dbo.FDatetime(mreq.ApprovalDateTime) >= ''' + @StartDate  + '''';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and dbo.FDatetime(mreq.ApprovalDateTime) <= ''' + @EndDate  + '''';
	
	print(@Query)
	exec (@Query )

END
GO
