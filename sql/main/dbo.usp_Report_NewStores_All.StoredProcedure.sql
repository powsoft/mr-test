USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_NewStores_All]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
--[usp_Report_NewStores_All] '64074',0,'All','','','','','1900-01-01','1900-01-01'
CREATE  procedure [dbo].[usp_Report_NewStores_All] 
	-- Add the parameters for the stored procedure here
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

	set @query = 'SELECT  StoreNumber as [Store Number], SBTNumber as [SBT Number], Address, City, ZipCode, State, Banner,  
				  convert(varchar(10),cast(OpeningDate as date),101)as [Opening Date],
				  StoreMgr, District, Area, UserID, 
				  convert(varchar(10),cast(DateEntered as date),101) as [Date Entered]
				  FROM CreateStores with(nolock) where 1=1 '

	if(@Banner<>'All') 
		set @Query  = @Query + ' and banner =''' + @Banner + ''''

	if (@chainID <> '-1')
	set @Query = @Query + ' and ChainID in (' + @chainID+ ')'
	
	if (@LastxDays > 0)
		set @Query = @Query + ' and (OpeningDate between dateadd(d,-' +  cast(@LastxDays as varchar) + ', { fn NOW() }) and { fn NOW() })'  
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and OpeningDate >= ''' + @StartDate  + '''';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and OpeningDate <= ''' + @EndDate  + '''';
		
	exec (@Query )
END
GO
