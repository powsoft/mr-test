USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ListReportRequests_New]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_ListReportRequests_New] 
 
 @PersonId varchar(50)
 
as

Begin
 Declare @sqlQuery varchar(4000)
 set @sqlQuery = 'SELECT     isnull(dbo.Chains.ChainName,''All'') as ChainName, isnull(dbo.Suppliers.SupplierName,''All'') as SupplierName, isnull( dbo.Stores.StoreIdentifier,''All'') as StoreIdentifier, 
       isnull(A.Banner,''All'') as Banner, dbo.AutomatedReportsList.ReportName, 
                      A.LastXDays, A.DateRequested, 
                      isnull(dbo.ProductIdentifiers.IdentifierValue,''All'') as IdentifierValue, A.GetEveryXDays, 
                      case when Days  like ''%2%'' then 1 else 0 end as Mon,
                      case when Days  like ''%3%'' then 1 else 0 end as Tue,
                      case when Days  like ''%4%'' then 1 else 0 end as Wed,
                      case when Days  like ''%5%'' then 1 else 0 end as Thu,
                      case when Days  like ''%6%'' then 1 else 0 end as Fri,
                      case when Days  like ''%7%'' then 1 else 0 end as Sat,
                      case when Days  like ''%1%'' then 1 else 0 end as Sun, 
                      A.SubscriptionStartDate, 
                      A.By12pmEST, A.By5pmEST, A.FileType, 
                      A.LastDateSent, A.LastProcessDate,A.RecordCount,A.PersonID, A.AutoReportRequestID
                      
FROM         dbo.AutomatedReportsRequests  A INNER JOIN
                      dbo.AutomatedReportsList ON A.ReportID = dbo.AutomatedReportsList.ReportID left JOIN
                      dbo.Stores ON A.StoreID = dbo.Stores.StoreID Left JOIN
                      dbo.Chains ON A.ChainID = dbo.Chains.ChainID Left JOIN
                      dbo.Suppliers ON A.SupplierID = dbo.Suppliers.SupplierID Left JOIN
                      dbo.ProductIdentifiers ON A.ProductUPC = dbo.ProductIdentifiers.ProductID 
WHERE      A.PersonID = ' + @PersonId


exec(@sqlQuery); 

End
GO
