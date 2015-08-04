USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Deleted_Approved_Promotions]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[usp_Report_Deleted_Approved_Promotions] 
	-- exec usp_Report_Deleted_Approved_Promotions '40393','2','All','','-1','','90','1900-01-01','1900-01-01'
	@chainID varchar(20),
	@PersonID int,
	@Banner varchar(50),
	@ProductUPC varchar(20),
	@SupplierId varchar(10),
	@StoreId varchar(10),
	@LastxDays int,
	@StartDate varchar(20),
	@EndDate varchar(20), @MaxRowsCount varchar(20) = ' Top 2500000 '
AS
BEGIN
Declare @Query varchar(5000)
declare @AttValue int
Declare @CostFormat varchar(10)

	if(@supplierID<>'-1')
		Select @CostFormat = Costformat from SupplierFormat where SupplierID = @supplierID
	 else
		set @CostFormat=4
		set @CostFormat = ISNULL(@CostFormat , 4)
	select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
 
	set @query = 'Select ' + @MaxRowsCount + ' S.SupplierName as [Supplier Name], C.ChainName as [Retailer Name], 
				    M.Banner, UPC, ItemDescription as [Item Description], 
					''$''+ Convert(varchar(50), cast(Cost as numeric(10,' + @CostFormat + '))) as [Base Cost], 
					''$''+ Convert(varchar(50), cast(PromoAllowance as numeric(10,' + @CostFormat + '))) as [Allowance], 
					convert(varchar(10),cast(StartDateTime as date),101) as [Start Date], 
					convert(varchar(10),cast(EndDateTime as date),101) as [End Date],
					convert(varchar(10),cast(SubmitDateTime as date),101) as [Submit Date], 
					(P.FirstName + '' '' +  P.LastName) as [Submitted by UserName], 
					convert(varchar(10),cast(ApprovalDateTime as date),101) as [Approve Date], 
					(P1.FirstName + '' '' +  P1.LastName) as [Approved by UserName],
					convert(varchar(10),cast(DeleteDateTime as date),101) as [Deletion Date], 
					(P2.FirstName + '' '' +  P2.LastName) as [Deleted by UserName], 
					DeleteReason as [Deletion Reason]
				from MaintenanceRequests M  with (nolock)  
					inner join Suppliers S  with (nolock)   on S.SupplierID=M.SupplierID
					inner join Chains  C with (nolock)   on C.ChainID=M.ChainID
					INNER JOIN SupplierBanners SB with (nolock)   on SB.SupplierId = S.SupplierId and SB.Status=''Active'' and SB.Banner=M.Banner
					left join Persons   as P on P.PersonID=M.SupplierLoginID
					left join Persons   as P1 on P1.PersonID=M.ChainLoginID
					left join Persons   as P2 on P2.PersonID=M.DeleteLoginId
					where RequestTypeID=3
					and MarkDeleted=1 and Approved=1 '
				
		if @AttValue =17
			set @query = @query + ' and c.ChainID in (select attributepart from dbo.fnGetRetailersTable(' +  cast(@PersonID as varchar) + '))'
		else
			set @query = @query + ' and s.SupplierID in (select attributepart from dbo.fnGetSupplierTable(' +  cast(@PersonID as varchar) + '))'

		if(@chainID  <>'-1') 
			set @Query   = @Query  +  ' and C.ChainID=' + @chainID 

		if(@Banner<>'All') 
			set @Query  = @Query + ' and M.Banner like ''%' + @Banner + '%'''
	
		if(@SupplierId<>'-1') 
			set @Query  = @Query  + ' and S.SupplierId=' + @SupplierId  

		if(@ProductUPC  <>'-1') 
			set @Query   = @Query  +  ' and  M.UPC like ''%' + @ProductUPC + '%'''

		if (@LastxDays > 0)
			set @Query = @Query + ' and (M.StartDateTime between dateadd(d,-' +  cast(@LastxDays as varchar) + ', { fn NOW() }) and { fn NOW() })'  
		
		if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
			set @Query = @Query + ' and M.StartDateTime >= ''' + @StartDate  + '''';

		if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
			set @Query = @Query + ' and M.StartDateTime <= ''' + @EndDate  + '''';
		
		exec (@Query )

END
GO
