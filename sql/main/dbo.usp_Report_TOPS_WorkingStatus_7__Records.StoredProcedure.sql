USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_TOPS_WorkingStatus_7__Records]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  procedure [dbo].[usp_Report_TOPS_WorkingStatus_7__Records] 
	-- exec [usp_Report_TOPS_WorkingStatus_7__Records] '-1','2','All','','-1','-1','','1900-01-01','1900-01-01'
	
	@chainID varchar(20),
	@PersonID int,
	@Banner varchar(50),
	@ProductUPC varchar(20),
	@SupplierId varchar(max),
	@StoreId varchar(10),
	@LastxDays int,
	@StartDate varchar(20),
	@EndDate varchar(20), @MaxRowsCount varchar(20) = ' Top 2500000 '
AS
BEGIN
Declare @Query varchar(max)
declare @AttValue int
declare @RoleName Varchar(50)
Declare @CostFormat varchar(10)

	if(@supplierID<>'-1')
		Select @CostFormat = Costformat from SupplierFormat where SupplierID = @supplierID
	 else
		set @CostFormat=4
		
		set @CostFormat = ISNULL(@CostFormat , 4)
 	
	select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
	SELECT @RoleName= RoleName from AssignUserRoles_New A inner join UserRoles_New R on R.RoleID=A.RoleID where UserID=@PersonID

	set @query = '
	declare @temptable table (
[StoreTransactionID] [bigint] NOT NULL,
	[DateTimeSent] [datetime] NOT NULL,
	[Retailer Name] [nvarchar](50) NOT NULL,
	[Supplier Name] [nvarchar](255) NOT NULL,
	[Banner] [nvarchar](50) NULL,
	[Store Name] [nvarchar](50) NOT NULL,
	[Store Number] [nvarchar](50) NOT NULL,
	[Product Name] [nvarchar](255) NOT NULL,
	[UPC] [nvarchar](250) NOT NULL,
	[Qty] [int] NOT NULL,
	[Setup Cost] [varchar](50) NULL,
	[Setup Retail] [varchar](50) NULL,
	[Rule Cost] [varchar](50) NULL,
	[Rule Retail] [varchar](50) NULL,
	[File Name] [nvarchar](250) NULL,
	[Working Source] [varchar](16) NOT NULL,
	[Transaction Date] [date] NULL,
	[Date Time Created] [date] NULL,
	[WorkingStatus] [smallint] NOT NULL)
	 
	insert into @temptable 
	SELECT st.StoreTransactionID,GetDate(), ch.ChainName AS [Retailer Name]
					 , sup.SupplierName AS [Supplier Name]
					 , ST.Banner
					 , S.StoreName AS [Store Name]
					 , S.StoreIdentifier  AS [Store Number]
					 , P.ProductName AS [Product Name]
					 , ST.UPC
					 , Qty AS [Qty]
					 , ''$'' + convert(VARCHAR(50), cast(ST.SetupCost AS NUMERIC(10, '+ @CostFormat +'))) AS [Setup Cost]
					 , ''$'' + convert(VARCHAR(50), cast(ST.SetupRetail AS NUMERIC(10, '+ @CostFormat +'))) AS [Setup Retail]
					 , ''$'' + convert(VARCHAR(50), cast(ST.RuleCost AS NUMERIC(10, '+ @CostFormat +'))) AS [Rule Cost]
					 , ''$'' + convert(VARCHAR(50), cast(ST.RuleRetail AS NUMERIC(10, '+ @CostFormat +'))) AS [Rule Retail]
					 ,SourceIdentifier  AS [File Name]
					 , CASE
						   WHEN WorkingSource = ''INV'' THEN
							   ''Inventory Count''
						   WHEN WorkingSource = ''SUP-S'' THEN
							   ''Delivery Pickups''
						   WHEN WorkingSource = ''SUP-U'' THEN
							   ''Delivery Pickups''
						   ELSE
							   ''''
					   END AS [Working Source]
					 , convert(varchar(10),cast(ST.SaleDateTime as date),101) AS [Transaction Date]
					 , convert(varchar(10),cast(ST.DateTimeCreated as date),101) AS [Date Time Created], st.WorkingStatus
					
							
				FROM
					DataTrue_Main.dbo.StoreTransactions_Working AS ST WITH (NOLOCK)
					INNER JOIN dbo.Suppliers AS sup WITH (NOLOCK)
						ON ST.SupplierID = sup.SupplierID
					INNER JOIN dbo.Chains AS ch WITH (NOLOCK)
						ON ST.ChainID = ch.ChainID
					INNER JOIN Stores S
						ON S.StoreID = ST.StoreID
					INNER JOIN dbo.SupplierBanners SB WITH (NOLOCK)
						ON SB.SupplierId = sup.SupplierID AND SB.Status = ''Active'' AND SB.Banner = ST.Banner
					INNER JOIN Products P
						ON P.ProductID = ST.ProductID 
				WHERE
					1 = 1
					AND ST.WorkingStatus =-7 and st.StoreTransactionID not in (select storeTransactionId from StoreTransaction_Working_TOPS_SubsHistory) '

		if @AttValue =17
			set @Query = @Query + ' and ch.ChainID in (select attributepart from dbo.fnGetRetailersTable(' +  cast(@PersonID as varchar) + '))'
		else
			set @Query = @Query + ' and sup.SupplierID in (select attributepart from dbo.fnGetSupplierTable(' +  cast(@PersonID as varchar) + '))'
	if(@chainID  <>'-1') 
		set @Query   = @Query  +  ' and ST.ChainID in (' + @chainID + ')' 

	if(@Banner<>'All') 
		set @Query  = @Query + ' and ST.banner like ''%' + @Banner + '%'''
	if(@StoreId <>'-1') 
			set @Query  = @Query + ' and S.storeidentifier like ''%' + @StoreId  + '%'''
	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and ST.SupplierId in (' + @SupplierId   + ')'

	if(@ProductUPC  <>'-1') 
		set @Query   = @Query  +  ' and  ST.UPC like ''%' + @ProductUPC + '%'''

	if (@LastxDays > 0)
		set @Query = @Query + ' and (ST.SaleDateTime between { fn NOW() } and dateadd(d,' +  cast(@LastxDays as varchar) + ', { fn NOW() }) )'   
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and ST.SaleDateTime >= ''' + @StartDate  + '''';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and ST.SaleDateTime <= ''' + @EndDate  + '''';

	exec (@Query + ';    select [Retailer Name]
      ,[Supplier Name]
      ,[Banner]
      ,[Store Name]
      ,[Store Number]
      ,[Product Name]
      ,[UPC]
      ,[Qty]
      ,[Setup Cost]
      ,[Setup Retail]
      ,[Rule Cost]
      ,[Rule Retail]
      ,[File Name]
      ,[Working Source]
      ,[Transaction Date]
      ,[Date Time Created] from @temptable;insert into StoreTransaction_Working_TOPS_SubsHistory select * from @temptable ')
	
END
GO
