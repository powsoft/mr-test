USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ListReportRequests]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_ListReportRequests] 
 
 @PersonId varchar(50)
 
as

Begin
 Declare @sqlQuery varchar(4000)
 set @sqlQuery = 'SELECT     isnull(dbo.Chains.ChainName,''All'') as ChainName, isnull(dbo.Suppliers.SupplierName,''All'') as SupplierName, isnull( dbo.Stores.StoreIdentifier,''All'') as StoreIdentifier, 
       isnull(dbo.AutomatedReportsRequests.Banner,''All'') as Banner, dbo.AutomatedReportsList.ReportName, 
                      dbo.AutomatedReportsRequests.LastXDays, dbo.AutomatedReportsRequests.DateRequested, 
                      isnull(dbo.ProductIdentifiers.IdentifierValue,''All'') as IdentifierValue, dbo.AutomatedReportsRequests.GetEveryXDays, 
                      case when Days  like ''%2%'' then 1 else 0 end as Mon,
                      case when Days  like ''%3%'' then 1 else 0 end as Tue,
                      case when Days  like ''%4%'' then 1 else 0 end as Wed,
                      case when Days  like ''%5%'' then 1 else 0 end as Thu,
                      case when Days  like ''%6%'' then 1 else 0 end as Fri,
                      case when Days  like ''%7%'' then 1 else 0 end as Sat,
                      case when Days  like ''%1%'' then 1 else 0 end as Sun, 
                      dbo.AutomatedReportsRequests.SubscriptionStartDate, 
                      dbo.AutomatedReportsRequests.By12pmEST, dbo.AutomatedReportsRequests.By5pmEST, dbo.AutomatedReportsRequests.FileType, 
                      dbo.AutomatedReportsRequests.LastDateSent, dbo.AutomatedReportsRequests.LastProcessDate,dbo.AutomatedReportsRequests.RecordCount,dbo.AutomatedReportsRequests.PersonID, dbo.AutomatedReportsRequests.AutoReportRequestID
                      
FROM         dbo.AutomatedReportsRequests INNER JOIN
                      dbo.AutomatedReportsList ON dbo.AutomatedReportsRequests.ReportID = dbo.AutomatedReportsList.ReportID left JOIN
                      dbo.Stores ON dbo.AutomatedReportsRequests.StoreID = dbo.Stores.StoreID Left JOIN
                      dbo.Chains ON dbo.AutomatedReportsRequests.ChainID = dbo.Chains.ChainID Left JOIN
                      dbo.Suppliers ON dbo.AutomatedReportsRequests.SupplierID = dbo.Suppliers.SupplierID Left JOIN
                      dbo.ProductIdentifiers ON dbo.AutomatedReportsRequests.ProductUPC = dbo.ProductIdentifiers.ProductID 
WHERE      dbo.AutomatedReportsRequests.PersonID = ' + @PersonId


exec(@sqlQuery); 

End
GO
