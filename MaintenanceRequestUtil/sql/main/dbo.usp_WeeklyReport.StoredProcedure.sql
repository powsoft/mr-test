USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_WeeklyReport]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_WeeklyReport]
 
 @SupplierId varchar(5),
 @FromStartDate varchar(50),
 @ToEndDate varchar(50)
 
as

Begin
 Declare @sqlQuery varchar(6000)
 Declare @DayCount int
 Declare @CheckDate varchar(50)
 Declare @ColNames varchar(500)
 
 
 IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[tmpWeeklyEnvelope]') AND type in (N'U'))
    DROP TABLE tmpWeeklyEnvelope
   
 set @sqlQuery = 'select  distinct I.SupplierId, C.ChainId, ChainName as Retailer, P.IdentifierValue as PubId, I.StoreID,
        (I.StoreIdentifier + '' - '' +  StoreName) as Store, StoreIdentifier as [Store number] into [tmpWeeklyEnvelope]
        from InvoiceDetails I
        Inner join Chains C on C.ChainId=I.ChainId
        inner join  ProductIdentifiers P on P.ProductId=I.ProductId
        where SupplierID=' + @SupplierId  + '
        and TotalCost is not null
        and I.InvoiceDetailTypeId in (1,7)
        and P.ProductIdentifierTypeId = 7
        and SaleDate >= ''' + @FromStartDate  + '''
        and SaleDate <= ''' + @ToEndDate  + ''' '
       print(@sqlQuery)
exec(@sqlQuery)


 IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[tmpweekly]') AND type in (N'U'))
    DROP TABLE [tmpweekly]
        
 set @sqlQuery = '
        select  Retailer, PubId, Store,  [Store number],'
       
        set @DayCount=Datediff(day,convert(date, @FromStartDate),convert(date, @ToEndDate))+1
        set @CheckDate=@FromStartDate
        set @ColNames=''
       
        while(@DayCount>0)
        begin
            set @sqlQuery = @sqlQuery + '
            (Select (sum(isnull(ID.PromoAllowance,0)*ID.TotalQty)) from InvoiceDetails  ID
            inner join  ProductIdentifiers PI on PI.ProductId=ID.ProductId
            where SaleDate = ''' +  @CheckDate + '''
            and SupplierID=I.SupplierID and  ChainID=I.ChainID
            and PI.IdentifierValue=I.PubId
            and PI.ProductIdentifierTypeId=7
            and StoreID=I.StoreID and TotalCost is not null)
            as ''' + @CheckDate + ''','
           
            set @ColNames=@ColNames + ' cast(sum([' + @CheckDate + ']) as varchar),'
           
            set @DayCount=@DayCount-1
            set @CheckDate = convert(varchar(10),DateAdd(day, 1, @CheckDate),110)
        end
       
        set @ColNames=@ColNames + ' cast(sum([Total]) as varchar) '
       
        set @sqlQuery = @sqlQuery + '
        (Select (sum(isnull(ID.PromoAllowance,0)*ID.TotalQty)) from InvoiceDetails ID
        inner join  ProductIdentifiers PI on PI.ProductId=ID.ProductId
        where SaleDate >= ''' +  @FromStartDate + ''' and SaleDate<= ''' +  @ToEndDate + '''
        and SupplierID=I.SupplierID and  ChainID=I.ChainID
        and PI.IdentifierValue=I.PubId
            and PI.ProductIdentifierTypeId=7
        and StoreID=I.StoreID and TotalCost is not null)
        as Total

        into [tmpweekly]

        from tmpWeeklyEnvelope I
        order by Retailer,Store, PubId'
              
 exec(@sqlQuery)
 exec(@sqlQuery);
  
 declare @col1 varchar(5000)
    select @col1=(case when @col1 is null then '' else @col1 + ',' end) + ''''+column_name+'''' from 
    INFORMATION_SCHEMA.COLUMNS where TABLE_NAME='tmpweekly'

declare @col2 varchar(5000)
    select @col2=(case when @col2 is null then '' else @col2 + ',' end) + 'isnull(cast(['+column_name+'] as varchar),''0.00'')' from 
    INFORMATION_SCHEMA.COLUMNS where TABLE_NAME='tmpweekly'
        
 set @sqlQuery ='select top 1 ' + @col1 + '  from tmpweekly union all select ' + @col2 + ' from tmpweekly '
 set @sqlQuery =@sqlQuery + ' union all select Retailer, PubId,''Total'','''', ' + @ColNames + ' from  tmpweekly group by Retailer, PubId'
 set @sqlQuery =@sqlQuery + ' union all select Retailer, ''Total'','''','''', ' + @ColNames + ' from  tmpweekly group by Retailer'
 exec(@sqlQuery)
 exec(@sqlQuery)
   
End
GO
