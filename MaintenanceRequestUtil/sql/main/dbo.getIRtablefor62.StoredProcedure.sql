USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[getIRtablefor62]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getIRtablefor62]
as
begin


--- re-create that table ---
select c.ChainIdentifier as ChainID,
--select c.ChainID,
		isnull(saledate,CAST('1900-01-01' as DateTime)) as [weekending], 
	datepart(dw,isnull(saledate,CAST('1900-01-01' as DateTime))) as week_day,
	 sp.SupplierIdentifier as [WholesalerID],
	  bipad.bipad as bipad,
	 LegacySystemStoreIdentifier as StoreId,
	 pr.ProductName as TitleName,
	isnull(sum(ret_qty_cy),0)  as [Total POS Units],
	isnull(cast(sum(ret_cost_cy)as real),0) as [Total POS $],
	isnull(cast(sum(ret_ret_cy)as real),0) as [Total POS Retail $],
	isnull(SUM(draw),0) as [Gross Units],
	isnull(cast(sum(draw_cost)as real),0) as [Gross billing $],
	isnull(sum(shrink_qty_cy),0) as [Total_dcr_units],
	isnull(cast(sum(shrink_cost_cy)as real),0) as [total_dcr_amount],
	0 as [Total_dcr_units_suspended],
	0.0 as [total_dcr_amount_suspended],
	isnull(mn.ManufacturerIdentifier,'Unknown') as [PublisherID],
	MAX(dcr_payment) as DCR_PAYMENT,
	 c.ChainIdentifier + '-' +  sp.SupplierIdentifier as [Chain_wholesalerid],
	 isnull(cast(sum(shrink_ret_cy)as real),0) as [total_dcr_amount_retail]
			
	
	from 
	(
		select	/*pca.ProductCategoryID as CategoryID,*/
			st.SupplierID,st.StoreID,st.BrandID,st.ProductID,/*st.UPC ,*/s.ChainID,s.StoreIdentifier,s.LegacySystemStoreIdentifier,
			case when tt.buckettype=1 then tt.qtysign*qty*ruleRetail else 0 end as ret_ret_cy,
			case when tt.buckettype=1 then tt.qtysign*qty else 0 end as ret_qty_cy ,
			case when tt.buckettype=1 then tt.qtysign*qty*RuleCost else 0 end as ret_cost_cy ,
			case when tt.buckettype=1 then tt.qtysign*qty*isnull(st.PromoAllowance,0) else 0 end as ret_pa_cy ,
			case when tt.buckettype=2 and tt.QtySign=1   then tt.qtysign*qty else 0 end as supp_del_cy ,
			case when tt.buckettype=2 and tt.QtySign=-1 then tt.qtysign*qty else 0 end as supp_cred_cy ,
			case when tt.buckettype in (2) then tt.qtysign*qty*rulecost else 0 end as supp_cost_cy , 
			case when tt.buckettype in (2) then tt.qtysign*qty*isnull(st.PromoAllowance,0) else 0 end as supp_pa_cy , 
			case when tt.buckettype in (2) then tt.qtysign*qty*ruleRetail else 0 end as supp_ret_cy ,
			case when tt.buckettype=3 then tt.qtysign*qty else 0 end as shrink_qty_cy ,
			case when tt.buckettype=3 then tt.qtysign*qty*ruleCost else 0 end as shrink_cost_cy ,
			case when tt.buckettype=3 then tt.qtysign*qty*isnull(st.PromoAllowance,0) else 0 end as shrink_pa_cy ,
			case when tt.buckettype=3 then tt.qtysign*qty*ruleRetail else 0 end as shrink_ret_cy ,
			case when tt.buckettype in (2) and tt.QtySign=1  then tt.qtysign*qty*rulecost else 0 end as del_cost_cy ,
			case when tt.buckettype in (2) and tt.QtySign=1  then tt.qtysign*qty*ruleRetail else 0 end as del_ret_cy,
			0 as draw,
			0.0 as draw_cost,
			saleDateTime as saledate,
			case when BucketType=3 then 
				case when not pd.DisbursementID  IS null then pd.CheckNo + ' ' + pd.DisbursementAmount
				else '0'
				end
			else '0' 
			end as dcr_payment
	from [DataTrue_Main].[dbo].StoreTransactions  as st with(nolock)
	inner join [DataTrue_Main].[dbo].chains_migration as cm with (nolock) 
	on st.ChainID = (select ChainID from DataTrue_Main.dbo.chains where ChainIdentifier = cm.ChainID) 
	and st.SaleDateTime >= cm.datemigrated
    --COMMENTED OUT ON 1/14/2015 PER FB 20319
    --and st.ProductPriceTypeID is not null 
	inner join [DataTrue_Main].[dbo].Stores as S on st.storeid=s.storeid
	/*left join [DataTrue_Main].[dbo].productcategoryassignments as pca with(nolock)
		 --on st.ProductID=pca.productid /* and pca.StoreBanner=s.Custom1*/
		 on st.ProductID=pca.productid and st.chainid = pca.customownerentityid */
	inner join [DataTrue_Main].[dbo].transactiontypes as tt with(nolock) 
		 on st.TransactionTypeID=tt.transactiontypeid
	--left join [DataTrue_Main].[dbo].InvoiceDetails as idt with(nolock) on
	--	st.ChainID= idt.ChainID and st.ProductID=idt.ProductID and st.StoreID = idt.StoreID and st.SaleDateTime = idt.SaleDate
	--	and cast(st.InvoiceBatchID as nvarchar(255)) = idt.BatchID and st.SupplierID = idt.SupplierID
	left join
	    (
		select distinct ChainID, SupplierID, ProductID, StoreID, SaleDate, BatchID, PaymentID from [DataTrue_Main].[dbo].InvoiceDetails as idt with(nolock)
		) as idt on
		st.ChainID = idt.ChainID and st.SupplierID = idt.SupplierID and st.ProductID=idt.ProductID and st.StoreID = idt.StoreID and st.SaleDateTime = idt.SaleDate
		and cast(st.InvoiceBatchID as nvarchar(255)) = idt.BatchID 
	left join [DataTrue_Main].[dbo].PaymentHistory as ph with(nolock) on
		--idt.PaymentID = ph.PaymentId
		idt.PaymentID = ph.PaymentId and ph.PaymentStatus = 10
	left join [DataTrue_Main].[dbo].PaymentDisbursements as pd with(nolock) on
		ph.DisbursementID = pd.DisbursementID
		
	where tt.BucketType in ( 1,2,3) 

	UNION ALL

	select 
		/* pca.ProductCategoryID as CategoryID, */
		st.SupplierID,st.StoreID,st.BrandID,st.ProductID,/*st.UPC ,*/s.ChainID,s.StoreIdentifier,s.LegacySystemStoreIdentifier,
	0.0 as ret_ret_cy,
	0 as ret_qty_cy ,
	0.0 as ret_cost_cy ,
	0.0 as ret_pa_cy ,
	0.0  supp_del_cy ,
	0.0 supp_cred_cy ,
	0.0 supp_cost_cy , 
	0.0 as supp_pa_cy , 
	0.0  supp_ret_cy ,
	0.0 shrink_qty_cy ,
	0.0  shrink_cost_cy ,
	0.0 as shrink_pa_cy ,
	0.0 as shrink_ret_cy ,
	0.0  as del_cost_cy ,
	0.0  as del_ret_cy,
	qty as draw,
	qty*rulecost as draw_cost,
	saleDateTime as saledate,
	'0' as DCR_PAYMENT
	from [DataTrue_Main].[dbo].StoreTransactions_Forward as st with(nolock)
	inner join [DataTrue_Main].[dbo].chains_migration as cm with (nolock) on st.ChainID = (select ChainID from DataTrue_Main.dbo.chains where ChainIdentifier = cm.ChainID) and st.SaleDateTime >= cm.datemigrated
	inner join [DataTrue_Main].[dbo].Stores as S with(nolock) on st.storeid=s.storeid
	/*left join [DataTrue_Main].[dbo].productcategoryassignments as pca with(nolock)
		 on st.ProductID=pca.productid  */
--	where  st.ChainID=42501
	) as trans
inner join [DataTrue_Main].[dbo].chains  as c with(nolock) on trans.chainid=c.chainid 
inner join [DataTrue_Main].[dbo].products as pr with(nolock) on trans.productid = pr.productID
left join [DataTrue_Main].[dbo].Brands as br with(nolock) on trans.BrandID = br.BrandID
left join [DataTrue_Main].[dbo].Manufacturers as mn with(nolock) on br.ManufacturerID = mn.ManufacturerID
left join [DataTrue_Main].[dbo].Suppliers as sp with(nolock) on trans.SupplierID = sp.SupplierID
left join ( select distinct bipad, productid from [DataTrue_Main].[dbo].[ProductIdentifiers] with(nolock) where ProductIdentifierTypeID = 8 ) as bipad
	on trans.ProductID = bipad.ProductID
group by  /*CategoryID,*/sp.SupplierIdentifier,StoreIdentifier,LegacySystemStoreIdentifier,
	/*trans.BrandID,*/bipad,/*UPC,*/saledate,c.ChainID,pr.ProductName,mn.ManufacturerIdentifier, c.ChainIdentifier 


end
GO
