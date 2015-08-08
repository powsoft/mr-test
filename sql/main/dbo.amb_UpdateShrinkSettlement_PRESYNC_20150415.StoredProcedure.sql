USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_UpdateShrinkSettlement_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec [amb_UpdateShrinkSettlement1] 0, 1, '1229','60626','24245','CVS1021','store','test gagan','','10/13/2013','10/06/2013','2','','Week End'
-- exec [amb_UpdateShrinkSettlement1] 0, 3, '291','64010','27108','LG379','item','','','','12/22/2013','2','PMERC','Week End'


-- exec [amb_UpdateShrinkSettlement1] 0, 1, '291','64010','28791','LG3125','item','','02/10/2014','03/27/2014','','2','PTNS','Sale Date'
-- exec [amb_UpdateShrinkSettlement1] 0, 1, '291','64010','28791','LG3125','item','','','','02/16/2014','2','PTNS','Week End'
-- exec [amb_UpdateShrinkSettlement1] 0, 1, '291','64010','27108','LG379','item','','','','11/24/2013','2','X4007','Week End'


-- exec [amb_UpdateShrinkSettlement1] 0, 1, '291','64010','27131','LG975','store','','11/28/2013','03/27/2014','','2','','Sale Date'
-- exec [amb_UpdateShrinkSettlement1] 0, 1, '291','64010','27131','LG964','store','','','','12/29/2013','2','','Week End'

-- exec [amb_UpdateShrinkSettlement1] 0, 1, '291','64010','24209','','chain','','03/19/2014','03/27/2014','','2','','Sale Date'
-- exec [amb_UpdateShrinkSettlement1] 0, 1, '291','64010','27108','','chain','','','','01/05/2014','2','','Week End'

CREATE PROCEDURE [dbo].[amb_UpdateShrinkSettlement_PRESYNC_20150415]
    @shrinkfactid INT ,
    @status INT ,
    @userid VARCHAR(20) ,
    @chainid VARCHAR(20) ,
    @supplierid VARCHAR(20) ,
    @storeid VARCHAR(20) ,
    @viewlevel VARCHAR(10),
    @rejectReason VARCHAR(50),
    @SaleDate VARCHAR(50),
    @DateTimeCreated VARCHAR(50),
    @WeekEnd varchar(20),
    @OldStatus INT,
    @Bipad varchar(40),
    @GroupBy varchar(20)
  
AS 
   BEGIN
    declare @strQuery varchar(4000)
    
    
    IF(@GroupBy='Sale Date')
		BEGIN
			IF ( @viewlevel = 'item' ) 
				BEGIN
					UPDATE sh
					SET
						sh.[Status] = @status
					  , sh.[LastUpdateUserID] = @userid
					  , sh.[RejectReason]=@rejectReason
					  , sh.[ApprovalDateTime] = getdate()
				--Select distinct sh.* 
					FROM
							 dbo.InventoryReport_Newspaper_Shrink_Facts sh
							 INNER JOIN dbo.chains c
							  ON c.ChainID = sh.ChainID
							 INNER JOIN dbo.Suppliers sup
							  ON sup.SupplierID = sh.SupplierID
							 INNER JOIN dbo.stores s
							  ON s.storeid = sh.storeid
							 INNER JOIN dbo.Products p
							  ON p.productid = sh.productid
							 INNER JOIN dbo.ProductIdentifiers pi
							  ON p.productid = pi.productid
					WHERE
						sh.ChainID = @chainid AND
						sh.Supplierid = @supplierid AND
						sh.SaleDateTime = @SaleDate AND
						sh.[Status] = @OldStatus AND
						LegacySystemStoreIdentifier = @storeid and
						Bipad = @Bipad AND
						convert(VARCHAR(12), sh.SaleDateTime, 101) = convert(VARCHAR(12), @SaleDate , 101) and
						--convert(VARCHAR, sh.DateTimeCreated, 120) = cast(convert(VARCHAR,  @DateTimeCreated , 120) AS DATETIME)      
						convert(VARCHAR(12), sh.DateTimeCreated, 101) = convert(VARCHAR(12),  @DateTimeCreated , 101)       
				END 
			ELSE 
				IF ( @viewlevel = 'store' ) 
					BEGIN
						UPDATE F
						SET
							F.[Status] = @status,
							F.[RejectReason]=@rejectReason,
							F.[LastUpdateUserID] = @userid,
							F.[ApprovalDateTime] = getdate()
						--Select distinct F.* 
						FROM
							[DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts] F
							INNER JOIN Stores S
								ON S.StoreID = F.StoreID
						WHERE
							F.ChainID = @chainid AND
							F.Supplierid = @supplierid AND
							S.LegacySystemStoreIdentifier = @storeid AND
							F.[Status] = @OldStatus AND
							F.SaleDateTime = @SaleDate AND
							--convert(VARCHAR, F.DateTimeCreated, 120) = cast(convert(VARCHAR,  @DateTimeCreated , 120) AS DATETIME)					     
							convert(VARCHAR(12), F.DateTimeCreated, 101) = convert(VARCHAR(12),  @DateTimeCreated , 101)       
					END
				ELSE 
					IF ( @viewlevel = 'chain' ) 
						BEGIN
							UPDATE [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts]
							SET
								[Status] = @status, 
								[LastUpdateUserID] = @userid,
								[RejectReason]=@rejectReason,
								[ApprovalDateTime] = getdate()
							--Select distinct * from InventoryReport_Newspaper_Shrink_Facts
							WHERE
								ChainID = @chainid AND
								Supplierid = @supplierid AND
								SaleDateTime = @SaleDate AND
								[Status] = @OldStatus AND
								--convert(VARCHAR, DateTimeCreated, 120) = cast(convert(VARCHAR,  @DateTimeCreated , 120) AS DATETIME) 
								convert(VARCHAR(12), DateTimeCreated, 101) = convert(VARCHAR(12),  @DateTimeCreated , 101)       
					  END
				END
	else if(@GroupBy='Week End')
		BEGIN
			IF ( @viewlevel = 'item' ) 
				BEGIN
					UPDATE sh
						SET
							sh.[Status] = @status,
							sh.[RejectReason]=@rejectReason,
							sh.[LastUpdateUserID] = @userid,
							sh.[ApprovalDateTime] = getdate()
					--Select distinct sh.* 
						FROM
							 dbo.InventoryReport_Newspaper_Shrink_Facts sh
							 INNER JOIN dbo.chains c
							  ON c.ChainID = sh.ChainID
							 INNER JOIN dbo.Suppliers sup
							  ON sup.SupplierID = sh.SupplierID
							 INNER JOIN dbo.stores s
							  ON s.storeid = sh.storeid
							 INNER JOIN dbo.Products p
							  ON p.productid = sh.productid
							 INNER JOIN dbo.ProductIdentifiers pi
							  ON p.productid = pi.productid
						WHERE
							sh.ChainID = @chainid AND
							sh.Supplierid = @supplierid AND
							LegacySystemStoreIdentifier = @storeid AND
							sh.status = @OldStatus AND
							Bipad = @Bipad AND
							convert(VARCHAR(12), dbo.getweekendCVS(sh.SaleDateTime, sh.Chainid, sh.Supplierid), 101) = convert(VARCHAR(12), @WeekEnd , 101)      
							
				END 
			ELSE 
				IF ( @viewlevel = 'store' ) 
					BEGIN
						UPDATE sh
						SET
							sh.[Status] = @status,
							sh.[RejectReason]=@rejectReason,
							sh.[LastUpdateUserID] = @userid,
							sh.[ApprovalDateTime] = getdate()
						--select distinct sh.*
						FROM
							 dbo.InventoryReport_Newspaper_Shrink_Facts sh
							 INNER JOIN dbo.chains c
							  ON c.ChainID = sh.ChainID
							 INNER JOIN dbo.Suppliers sup
							  ON sup.SupplierID = sh.SupplierID
							 INNER JOIN dbo.stores s
							  ON s.storeid = sh.storeid
						WHERE
							sh.ChainID = @chainid AND
							sh.Supplierid = @supplierid AND
							LegacySystemStoreIdentifier = @storeid AND
							sh.status = @OldStatus AND
							convert(VARCHAR(12), dbo.getweekendCVS(sh.SaleDateTime, sh.Chainid, sh.Supplierid), 101) = convert(VARCHAR(12), @WeekEnd , 101) 					     
							
					END
				ELSE 
					IF ( @viewlevel = 'chain' ) 
						BEGIN
							UPDATE sh
						SET
							sh.[Status] = @status,
							sh.[RejectReason]=@rejectReason,
							sh.[LastUpdateUserID] = @userid,
							sh.[ApprovalDateTime] = getdate()
						--select *
						FROM
							  dbo.InventoryReport_Newspaper_Shrink_Facts sh
								 INNER JOIN dbo.chains c
								  ON c.ChainID = sh.ChainID
								 INNER JOIN dbo.Suppliers sup
								  ON sup.SupplierID = sh.SupplierID
						WHERE
							sh.ChainID = @chainid AND
							sh.Supplierid = @supplierid AND
							sh.status = @OldStatus AND
							convert(VARCHAR(12), dbo.getweekendCVS(sh.SaleDateTime, sh.Chainid, sh.Supplierid), 101) = convert(VARCHAR(12), @WeekEnd , 101) 					      
							
					  END
				END
    END
GO
