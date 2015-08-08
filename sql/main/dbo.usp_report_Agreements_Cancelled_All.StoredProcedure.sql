USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_report_Agreements_Cancelled_All]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create procedure [dbo].[usp_report_Agreements_Cancelled_All]
(
-- exec [usp_report_Agreements_Pending] '-1','-1','All','','-1','','0','1900-01-01','1900-01-01'

@chainID varchar(max), --@Retailer_ID	
@PersonID int,
@Banner varchar(50),
@ProductUPC varchar(20),
@SupplierId varchar(max), --@Manufacturer_ID
@StoreId varchar(10),
@LastxDays int,
@StartDate varchar(20),
@EndDate varchar(20)
)
as
Begin
-- usp_report_Agreements '-1','65726','','Pending'
-- usp_report_Agreements '-1','65726','','Approved'
-- usp_report_Agreements '-1','65726','','Cancelled'
--sp_columns Agreements 
-- Select * from agreements
Declare @Sql varchar(max);

Set @Sql=' Select Agreement_System_No as [Agreement System No],
	   M.ManufacturerName as [Manufacturer Name],	 
	   C.ChainName as [Retailer Name],	 
	   Agreement_Number as [Agreement Number],
	   Agreement_Description as [Agreement Description],
	   CONVERT(varchar(10),Date_ContractEntered,105) [Record Entry Date],
	   CONVERT(varchar(10),Agreement_Date,105) [Agreement Date],	   
	 CONVERT(varchar(10), Date_StartDate,105) [Start Date],
	   CONVERT(varchar(10),Date_LastDate,105) [Last Date],
	   CONVERT(varchar(10),Date_CancelDate,105) [Cancel Date], 
		   Case when Cancel_UserID<>0 then (Select CAST(FirstName AS VARCHAR) +'' ''+ CAST(LastName AS VARCHAR)  from Persons  where PersonID=Cancel_UserID) else '''' end as [Cancelled By], 
	    case when A.Retailer_ApprovingParty_DateApproved is null then ''Pending'' else ''Approved'' end as [Retailer Approval],
	   Case when Retailer_ApprovingParty_UserID<>0 then (Select CAST(FirstName AS VARCHAR) +'' ''+ CAST(LastName AS VARCHAR)  from Persons  where PersonID=Retailer_ApprovingParty_UserID) else '''' end as [Retailer ApprovingParty Name],
       case when A.Mfg_ApprovingParty_DateApproved is null then ''Pending'' else ''Approved'' end as [Mfg  Approval],
       Case when Mfg_ApprovingParty_UserID<>0 then (Select FirstName + '' ''+ LastName from Persons  where PersonID=Mfg_ApprovingParty_UserID) else '''' end  as [Mfg ApprovingParty Name],
	 --''Pending'' as [Mfg  Approval], -- logic to implement later
	   case when A.Date_CancelDate is null then ''Active'' else ''Inactive'' end AS [Status]
    from Agreements A 
	   inner join dbo.Manufacturers M
		  On A.Manufacturer_ID=M.ManufacturerID
	   Inner join Chains C 
		  on A.Retailer_ID=C.ChainID where 1=1 AND A.Date_CancelDate IS NOT NULL AND A.IsCancelled=1 '
   
   
-- Select { fn NOW() }

    if(@SupplierId<>'-1')
	   Set @Sql=@Sql + ' AND M.ManufacturerID in ('+@SupplierId+')'
    
    if(@chainID <> '-1')
	   Set @Sql=@Sql+' AND C.ChainID in (' + @chainID + ')'
	   
  if (@LastxDays > 0)
			set @Sql = @Sql + ' and (A.Agreement_Date between { fn NOW() } and dateadd(d,' +  cast(@LastxDays as varchar) + ', { fn NOW() }) )'  
		
		if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
			set @Sql = @Sql + ' and A.Agreement_Date >= ''' + @StartDate  + '''';

		if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
			set @Sql = @Sql + ' and A.Agreement_Date <= ''' + @EndDate  + '''';
	   
	Print(@Sql)
	Exec(@Sql);
End
GO
