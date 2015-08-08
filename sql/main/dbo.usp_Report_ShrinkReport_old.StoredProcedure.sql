USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_ShrinkReport_old]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE procedure [dbo].[usp_Report_ShrinkReport_old]
	-- Add the parameters for the stored procedure here
	@chainID varchar(20),
	@PersonID int,
	@Banner varchar(50),
	@ProductUPC varchar(20),
	@SupplierId varchar(10),
	@StoreId varchar(10),
	@LastxDays int
AS
BEGIN
Declare @Query varchar(5000)
declare @attvalue int

select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
 --print 'Att : ' 
 
 set @query = 'Select top 1 ''Supplier Name'',''Chain Name'',''Store Number'',''Banner'',''Last Count'',''Last Settlement'',''UPC'', ''BI Units'',''BI Cost'',''TTLPOS'',''TTLPOS$'',''TTLDelivered'',''TTLDelivered$'',
 ''Expected EI'',''Expected EI$'',''Last Count Units'',''Last Count$'',''Shrink (Units)'',''Shrink($) FIFO'' from Chains union all 
		
		Select   SupplierName, ChainName, CAST(StoreNumber AS VARCHAR), Banner,  CAST([Last Count Date] AS VARCHAR), 
		cast([BI Date] as varchar), cast(UPC as varchar), cast([BI Count] as varchar), cast([BI $] as varchar),  cast([Total POS] as varchar), 
		cast([Total POS$] as varchar),  cast([Total Deliveries] as varchar),  cast([Total Deliveries$] as varchar),  
		cast([Expected EI] as varchar), cast([Expected EI$] as varchar),  cast([Last Count] as varchar),
		cast([Last Count$] as varchar), cast([Shrink Units] as varchar), cast([Shrink $] as varchar) 

		From [InventoryCount_MainReport_FactTable] as MR where 1=1 '
        
	if @attvalue =17
	    set @Query  = @Query  + ' and MR.ChainID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
	
	else if @attvalue = 9
	    set @Query  = @Query  + ' and MR.SupplierId  in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'
		
	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and MR.SupplierId=' + @SupplierId  
		
	if(@chainID  <>'-1') 
		set @Query   = @Query  +  ' and MR.ChainID=' + @chainID 
	
	
	if(@Banner<>'All') 
		set @Query  = @Query + ' and MR.Banner like ''%' + @Banner + '%''' 
  
	if(@StoreId <>'-1') 
		set @Query = @Query  +  ' and MR.StoreNumber like ''%' + @StoreId + '%'''
 
	if(@ProductUPC  <>'-1') 
		set @Query   = @Query  +  ' and MR.UPC like ''%' + @ProductUPC + '%'''
 
	if (@LastxDays >= 0)
		set @Query = @Query + ' and (convert(varchar(10),MR.[BI Date],101) between dateadd(d,-' +  cast(@LastxDays as varchar) + ', { fn NOW() }) and { fn NOW() })'  

	exec (@query)
 --print (@Query )
END
GO
