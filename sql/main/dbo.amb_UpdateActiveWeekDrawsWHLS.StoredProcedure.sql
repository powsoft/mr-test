USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_UpdateActiveWeekDrawsWHLS]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--  exec usp_UpdateActiveWeekDrawsWHLS '2','2','2','3','2','2','3','2012-10-29','NYT','KNG3900','24178','1'
CREATE proc [dbo].[amb_UpdateActiveWeekDrawsWHLS] 
(
@mon varchar(20),
@Tue varchar(20),
@wed varchar(20),
@Thur varchar(20),
@Fri varchar(20),
@Sat varchar(20),
@sun varchar(20),
@WeekEnding varchar(20),
@Bipad varchar(40),
@StoreId varchar(20),
@SupplierId varchar(20),
@dbType varchar(20)
)
as
begin
if(@dbType='0')
	begin
		UPDATE   [IC-HQSQL2].iControl.dbo.OnR   SET 
		OnR.Mon = @mon, 
		OnR.Tue = @Tue, 
		OnR.Wed = @wed, 
		OnR.Thur = @Thur, 
		OnR.Fri = @Fri, 
		OnR.Sat = @Sat, 
		OnR.Sun = @sun 
		WHERE CAST(OnR.WeekEnding AS DATE)=CAST(@WeekEnding AS DATE)
		AND OnR.StoreID=@StoreId 
		AND OnR.Bipad=@Bipad
	end
	
else
	begin
		update ST 
		set qty=@mon
			from dbo.Storetransactions_forward st
			inner join dbo.stores s on st.storeid=s.storeid
			inner join dbo.Productidentifiers pi on pi.productid=st.productid and pi.productidentifiertypeid=8
		where datename(W,SaleDateTime)='Monday' and s.legacysystemstoreidentifier=@StoreId 
		and TransactionTypeID in (29) and st.supplierid= @SupplierId and pi.bipad=@Bipad and saledatetime=@WeekEnding

		update ST
		set
			qty= @Tue
			from dbo.Storetransactions_forward st
			inner join dbo.stores s on st.storeid=s.storeid
			inner join dbo.Productidentifiers pi on pi.productid=st.productid and pi.productidentifiertypeid=8
		where datename(W,SaleDateTime)='Tuesday' and s.legacysystemstoreidentifier=@StoreId
		and TransactionTypeID in (29) and st.supplierid= @SupplierId and pi.bipad=@Bipad and saledatetime=@WeekEnding

		update ST
		set
			qty= @wed
			from dbo.Storetransactions_forward st
			inner join dbo.stores s on st.storeid=s.storeid
			inner join dbo.Productidentifiers pi on pi.productid=st.productid and pi.productidentifiertypeid=8
		where datename(W,SaleDateTime)='Wednesday' and s.legacysystemstoreidentifier=@StoreId
		and TransactionTypeID in (29) and st.supplierid= @SupplierId and pi.bipad=@Bipad and saledatetime=@WeekEnding

		update ST
		set
			qty= @Thur
			from dbo.Storetransactions_forward st
			inner join dbo.stores s on st.storeid=s.storeid
			inner join dbo.Productidentifiers pi on pi.productid=st.productid and pi.productidentifiertypeid=8
		where datename(W,SaleDateTime)='Thursday' and s.legacysystemstoreidentifier=@StoreId
		and TransactionTypeID in (29) and st.supplierid= @SupplierId and pi.bipad=@Bipad and saledatetime=@WeekEnding
		 
		update ST 
		set
			qty= @Fri
			from dbo.Storetransactions_forward st
			inner join dbo.stores s on st.storeid=s.storeid
			inner join dbo.Productidentifiers pi on pi.productid=st.productid and pi.productidentifiertypeid=8
		where datename(W,SaleDateTime)='Friday' and s.legacysystemstoreidentifier=@StoreId
		and TransactionTypeID in (29) and st.supplierid= @SupplierId and pi.bipad=@Bipad and saledatetime=@WeekEnding

		update ST
		set
			qty= @Sat
			from dbo.Storetransactions_forward st
			inner join dbo.stores s on st.storeid=s.storeid
			inner join dbo.Productidentifiers pi on pi.productid=st.productid and pi.productidentifiertypeid=8
		where datename(W,SaleDateTime)='Saturday' and s.legacysystemstoreidentifier=@StoreId
		and TransactionTypeID in (29) and st.supplierid= @SupplierId and pi.bipad=@Bipad and saledatetime=@WeekEnding

		update ST
		set
			qty= @sun
			from dbo.Storetransactions_forward st
			inner join dbo.stores s on st.storeid=s.storeid
			inner join dbo.Productidentifiers pi on pi.productid=st.productid and pi.productidentifiertypeid=8
		where datename(W,SaleDateTime)='Sunday' and s.legacysystemstoreidentifier=@StoreId
		and TransactionTypeID in (29) and st.supplierid= @SupplierId and pi.bipad=@Bipad and saledatetime=@WeekEnding
	end
	
End
GO
