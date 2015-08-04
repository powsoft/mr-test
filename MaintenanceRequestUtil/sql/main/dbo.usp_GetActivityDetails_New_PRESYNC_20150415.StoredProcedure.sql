USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetActivityDetails_New_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec usp_GetActivityDetails_New '-1'
CREATE procedure [dbo].[usp_GetActivityDetails_New_PRESYNC_20150415]
 @ChainId varchar(10)
as
Begin

IF OBJECT_ID('#tmpStoresTotal', 'U') IS NOT NULL
	Drop TABLE #tmpStoresTotal
	
IF OBJECT_ID('#tmpNewspaperStoreAndVendor', 'U') IS NOT NULL
	Drop TABLE #tmpNewspaperStoreAndVendor
	
IF OBJECT_ID('#tmpSBTStoreAndVendor', 'U') IS NOT NULL
	Drop TABLE #tmpSBTStoreAndVendor
	
IF OBJECT_ID('#tmpRegulatedStoreAndVendor', 'U') IS NOT NULL
	Drop TABLE #tmpRegulatedStoreAndVendor
	
IF OBJECT_ID('#tmpDXStoreAndVendor', 'U') IS NOT NULL
	Drop TABLE #tmpDXStoreAndVendor
	
IF OBJECT_ID('#tmpregulatedTotal', 'U') IS NOT NULL
	Drop TABLE #tmpregulatedTotal
	
IF OBJECT_ID('#tmpDXTotal', 'U') IS NOT NULL
	Drop TABLE #tmpDXTotal
	
IF OBJECT_ID('#tmpActiveStoresTotal', 'U') IS NOT NULL
	Drop TABLE #tmpActiveStoresTotal


Declare @sqlQuery varchar(max)

/* Store and Vendor activity per chain for Newspapers within the last 60 days */
				select c.ChainID,c.ChainIdentifier,ChainName, COUNT(distinct i.StoreID)StoreCnt,COUNT(distinct i.supplierid)SupplierCnt
				into #tmpNewspaperStoreAndVendor
					from InvoiceDetails i  with (index(6))
					join Chains c on i.ChainID = c.ChainID
					join Suppliers s on i.SupplierID = s.SupplierID
					join stores st on i.StoreID=st.StoreID
					where i.DateTimeCreated>GETDATE()-60 and RecordType=2
					and s.SupplierName != 'DEFAULT' and st.StoreName != 'DEFAULT' and st.ActiveStatus='Active' 
					and c.ChainIdentifier not in('MILE','MTN','ROCK','CTM')
					group by c.ChainID,c.ChainIdentifier,ChainName order by ChainIdentifier
					option (hash join,hash group,maxdop 0)
			
/* Store and Vendor activity per chain for SBT within the last 60 days */
				select c.ChainID,c.ChainIdentifier,ChainName, COUNT(distinct i.StoreID)StoreCnt,COUNT(distinct i.supplierid)SupplierCnt
				into #tmpSBTStoreAndVendor
					from InvoiceDetails i  with (index(6))
					join Chains c on i.ChainID = c.ChainID
					join Suppliers s on i.SupplierID = s.SupplierID
					join stores st on i.StoreID=st.StoreID
					join ProductIdentifiers p on i.ProductID=p.ProductID
					where i.DateTimeCreated>=GETDATE()-60 and isnulL(RecordType,0) =0 and s.IsRegulated=0 and p.ProductIdentifierTypeID=2
					and s.SupplierName != 'DEFAULT' and st.StoreName != 'DEFAULT' and c.ChainIdentifier != 'BUCEES' and st.ActiveStatus='Active'
					and c.ChainIdentifier not in('MILE','MTN','ROCK','CTM')
					group by c.ChainID,c.ChainIdentifier,ChainName order by ChainIdentifier
					option (hash join,hash group,maxdop 0)
					
/* Store and Vendor activity per chain for Regulated within the last 60 days */						 
			select c.ChainID,c.ChainIdentifier,ChainName, COUNT(distinct i.StoreID)StoreCnt,COUNT(distinct i.supplierid)SupplierCnt
			into #tmpRegulatedStoreAndVendor
				from InvoiceDetails i with (index(6))
				join Chains c on i.ChainID = c.ChainID
				join Suppliers s on i.SupplierID = s.SupplierID
				join stores st on st.StoreID=i.StoreID
				where i.DateTimeCreated > GETDATE()-60
				and s.IsRegulated = 1 and i.TotalCost not in (0.01,-0.01)
				and st.ActiveStatus='ACtive' and st.StoreName!='DEFAULT'
				and c.ChainIdentifier not in('MILE','MTN','ROCK','CTM')
				group by c.ChainID,chainname, c.ChainIdentifier order by ChainIdentifier
				option (hash join,hash group,maxdop 0)

/* Store and Vendor activity per chain for DX within the last 60 days */ 
			select x.ChainID,x.ChainIdentifier,x.ChainName, COUNT(distinct StoreID)StoreCnt,COUNT(distinct supplierid)SupplierCnt
			into #tmpDXStoreAndVendor
			from (select distinct c.ChainID,c.ChainIdentifier,ChainName,i.StoreID,i.SupplierID
					from InvoiceDetails i with (index(6))
					join Chains c on i.ChainID = c.ChainID
					join Suppliers s on i.SupplierID = s.SupplierID
					join stores st on st.StoreID=i.StoreID
					join Memberships as m on m.OrganizationEntityID = i.ChainID and m.MemberEntityID = i.SupplierID
					where i.DateTimeCreated > GETDATE()-60 and s.IsRegulated = 0
					and s.SupplierName != 'DEFAULT' and st.StoreName !='DEFAULT' and st.ActiveStatus='Active'
					and m.MembershipTypeID = 14 and c.PDITradingPartner=1
					and c.ChainIdentifier not in('MILE','MTN','ROCK','CTM')
				union all
			     select distinct c.ChainID,c.ChainIdentifier,ChainName,mrs.StoreID,mr.SupplierID
					From MaintenanceRequests mr
					join MaintenanceRequestStores mrs on mr.MaintenanceRequestID=mrs.MaintenanceRequestID
					join Chains c on mr.ChainID = c.ChainID
					join Suppliers s on mr.SupplierID = s.SupplierID
					join stores st on st.StoreID=mrs.StoreID
					join Memberships as m on m.OrganizationEntityID = mr.ChainID and m.MemberEntityID = mr.SupplierID
					where mr.DateTimeCreated > GETDATE()-60 and s.IsRegulated = 0
					and s.SupplierName != 'DEFAULT' and m.MembershipTypeID = 14 and c.PDITradingPartner=1
					and st.StoreName !='DEFAULT' and st.ActiveStatus='Active'
					and c.ChainIdentifier not in('MILE','MTN','ROCK','CTM')
				)x
			group by x.ChainID,x.ChainIdentifier,x.ChainName order by ChainIdentifier
			option (hash join,hash group,maxdop 0)
			
/* Total Number of regulated connections per chain */
			select distinct c.ChainID,c.ChainIdentifier,c.ChainName,SUM(COUNT(distinct st.supplierid))over (partition by c.ChainIdentifier,c.ChainName)totalconnections
			into #tmpregulatedTotal
				from storesetup st
				join Suppliers s on st.SupplierID=s.SupplierID
				join chains c on c.ChainID=st.ChainID
				join stores on stores.StoreID=st.StoreID
				where s.IsRegulated=1 and GETDATE() between st.ActiveStartDate and st.ActiveLastDate
				and s.SupplierName !='DEFAULT' and stores.StoreName != 'DEFAULT' and stores.ActiveStatus='Active'
				and c.ChainIdentifier not in('MILE','MTN','ROCK','CTM')
				group by c.ChainID,c.ChainIdentifier,c.ChainName,st.StoreID order by ChainIdentifier	 
	 
/* Total number of DX members per chain */
		
			select c.ChainID,c.ChainIdentifier,c.ChainName,COUNT(distinct MemberEntityID)TotalDXMemberCnt
			into #tmpDXTotal
				from DataTrue_Main..Memberships as m
				join DataTrue_Main..storesetup as ss on m.OrganizationEntityID = ss.ChainID and m.MemberEntityID = ss.SupplierID and m.MembershipTypeID = 14
					and MemberEntityID in (select supplierid from DataTrue_Main..suppliers where IsRegulated = 0 and SupplierName<>'DEFAULT')
					and GETDATE() between ss.ActiveStartDate and ss.ActiveLastDate
				join chains c on c.ChainID=m.OrganizationEntityID
				join stores st on st.StoreID=ss.StoreID
				where st.StoreName!='DEFAULT' and st.ActiveStatus='Active' and c.ChainIdentifier not in('MILE','MTN','ROCK','CTM')
				group by c.ChainID,c.ChainIdentifier,c.ChainName order by ChainIdentifier
				option (hash join,hash group,maxdop 0)	 
	 
/* Total number of Active Stores within 60 days per chain */
			select x.ChainID,x.ChainIdentifier,x.ChainName,COUNT(distinct storeid)TotalActiveStores
			into #tmpActiveStoresTotal
			from(select distinct  c.ChainID,c.ChainIdentifier,c.ChainName,i.storeid
					from InvoiceDetailS i with (index=6)
					join chains c on c.ChainID=i.ChainID
					join stores s on i.StoreID=s.StoreID
					where i.DateTimeCreated>GETDATE()-60
					and s.StoreName!='DEFAULT' and s.ActiveStatus='Active'
					and i.TotalCost not in (0.01,-0.01) and s.ActiveStatus='active'
					and c.ChainIdentifier not in('MILE','MTN','ROCK','CTM')
				  union all
				select distinct c.ChainID,c.ChainIdentifier,ChainName,mrs.StoreID
					From MaintenanceRequests mr
					join MaintenanceRequestStores mrs on mr.MaintenanceRequestID=mrs.MaintenanceRequestID
					join Chains c on mr.ChainID = c.ChainID
					join Suppliers s on mr.SupplierID = s.SupplierID
					join stores st on mrs.StoreID=st.StoreID
					join Memberships as m on m.OrganizationEntityID = mr.ChainID and m.MemberEntityID = mr.SupplierID
					where mr.DateTimeCreated > GETDATE()-60 and s.IsRegulated = 0
					and s.SupplierName != 'DEFAULT' and m.MembershipTypeID = 14
					and c.PDITradingPartner=1 and st.ActiveStatus='Active'
					and st.StoreName!='DEFAULT' and c.ChainIdentifier not in('MILE','MTN','ROCK','CTM')
				)x
			group by x.ChainID,x.ChainIdentifier,x.ChainName order by ChainIdentifier
			option (hash join,maxdop 0)	
			
/* Total number of Stores per chains */	
			select c.ChainID,c.ChainIdentifier,c.ChainName,COUNT(*)TotalStores
			into #tmpStoresTotal 
			from stores s
			join chains c on s.ChainID=c.ChainID
			where s.ActiveStatus='Active' and s.ChainID in 
			(select ChainID from InvoiceDetails where DateTimeCreated>GETDATE()-60
                  union All
            select ChainID from MaintenanceRequests where datetimecreated>GETDATE()-60) 
            and ChainName !='DEFAULT' and nullif(Custom1,'') is  not null and Custom1 !='SHAWS'
			and c.ChainIdentifier not in('MILE','MTN','ROCK','CTM')
			group by c.ChainID,c.ChainIdentifier,c.ChainName order by ChainIdentifier
			option (hash join,maxdop 0)		 

/* Final query */

        select C.ChainIdentifier as ChainID,
			   C.ChainName as ChainName,
			   '' as [Trade Class],
			   Isnull(ST1.TotalStores,0) as [Total Stores],
			   Isnull(ST.TotalActiveStores,0) as [Total Active Stores],
			   (isnull(sum(NW.SupplierCnt),0) + isnull(sum(SBT.SupplierCnt),0)+isnull(sum(Reg.SupplierCnt),0)+isnull(sum(DX.SupplierCnt),0)) as [Total Active Vendors],
			   --Vendor
			   Isnull(SBT.SupplierCnt,0) as [SBT Paying Vendor],
			   Isnull(NW.SupplierCnt,0) as [SBT Nonpaying Vendor],
			   Isnull(Reg.SupplierCnt,0) as [Regulated Vendor],
			   Isnull(Reg1.totalconnections,0) as [Total Regulated Connections],
			   Isnull(DX.SupplierCnt,0) as [DX Vendor],
			   Isnull(DX1.TotalDXMemberCnt,0) as [Total DX Members],
			   '' as [BI&A Vendor],
			   --Store
			   Isnull(SBT.StoreCnt,0) as [SBT Paying Store],
			   Isnull(NW.StoreCnt,0) as [SBT Nonpaying Store],
			   Isnull(Reg.StoreCnt,0) as [Regulated Store],
			   Isnull(DX.StoreCnt,0) as [DX Store],
			   '' as [BI&A Store]
        from Chains C
        inner JOIN #tmpStoresTotal ST1 ON ST1.ChainID=C.ChainID
        left JOIN #tmpActiveStoresTotal ST ON ST.ChainID=C.ChainID
        left JOIN #tmpNewspaperStoreAndVendor NW ON NW.ChainID=C.ChainID
        left JOIN #tmpSBTStoreAndVendor SBT ON SBT.ChainID=C.ChainID
        left JOIN #tmpRegulatedStoreAndVendor Reg ON Reg.ChainID=C.ChainID
        left JOIN #tmpDXStoreAndVendor DX ON DX.ChainID=C.ChainID
        left JOIN #tmpregulatedTotal Reg1 ON Reg1.ChainID=C.ChainID
        left JOIN #tmpDXTotal DX1 ON DX1.ChainID=C.ChainID
        --left JOIN #tmpActiveStoresTotal ST ON ST.ChainID=C.ChainID
        --left JOIN #tmpStoresTotal ST1 ON ST1.ChainID=C.ChainID
        Where
			1=1 
			AND C.ChainId like CASE WHEN @ChainId<>'-1' THEN @ChainId ELSE '%' End
		group BY C.ChainIdentifier,C.ChainName,ST1.TotalStores,ST.TotalActiveStores,
			   --Vendor
			   SBT.SupplierCnt,NW.SupplierCnt,Reg.SupplierCnt,Reg1.totalconnections,DX.SupplierCnt,DX1.TotalDXMemberCnt,
			   --Store
			   SBT.StoreCnt,NW.StoreCnt,Reg.StoreCnt,DX.StoreCnt	
		Order BY
			C.ChainIdentifier
End
GO
