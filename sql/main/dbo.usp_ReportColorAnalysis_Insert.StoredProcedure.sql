USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ReportColorAnalysis_Insert]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
EXEC [usp_ReportColorAnalysis_Insert] '<ColorAnalysis>
  <ReportColorAnalysis>
    <ChainID>60620</ChainID>
    <SupplierID>40557</SupplierID>
    <ReportName>ZeroPOSReport</ReportName>
    <ReportTitle>ZERO POS - TOP 10 PRODUCTS (Banner and Product Combination)</ReportTitle>
    <Month>November, 2014</Month>
    <BannerIdSec>Food City</BannerIdSec>
    <BannerStore />
    <StoreID />
    <ProductName>Bimbolete  - Chocolate Creme Filled Snack</ProductName>
    <UPC>074323099713</UPC>
    <Delivery>272</Delivery>
    <Pickup>-180</Pickup>
    <Net>92</Net>
    <Color>#FFBAC5</Color>
  </ReportColorAnalysis>
  <ReportColorAnalysis>
    <ChainID>60620</ChainID>
    <SupplierID>40557</SupplierID>
    <ReportName>ZeroPOSReport</ReportName>
    <ReportTitle>ZERO POS - TOP 10 PRODUCTS (Banner and Product Combination)</ReportTitle>
    <Month>November, 2014</Month>
    <BannerIdSec>Food City</BannerIdSec>
    <BannerStore />
    <StoreID />
    <ProductName>BIMBO ROLES GLASEADOS2CT</ProductName>
    <UPC>074323091779</UPC>
    <Delivery>212</Delivery>
    <Pickup>-139</Pickup>
    <Net>73</Net>
    <Color>#FFBAC5</Color>
  </ReportColorAnalysis>
  <ReportColorAnalysis>
    <ChainID>60620</ChainID>
    <SupplierID>40557</SupplierID>
    <ReportName>ZeroPOSReport</ReportName>
    <ReportTitle>ZERO POS - TOP 10 PRODUCTS (Banner and Product Combination)</ReportTitle>
    <Month>November, 2014</Month>
    <BannerIdSec>Food City</BannerIdSec>
    <BannerStore />
    <StoreID />
    <ProductName>Pan de Muerto</ProductName>
    <UPC>074323054880</UPC>
    <Delivery>72</Delivery>
    <Pickup>0</Pickup>
    <Net>72</Net>
    <Color>#FFBAC5</Color>
  </ReportColorAnalysis>
  <ReportColorAnalysis>
    <ChainID>60620</ChainID>
    <SupplierID>40557</SupplierID>
    <ReportName>ZeroPOSReport</ReportName>
    <ReportTitle>ZERO POS - TOP 10 PRODUCTS (Banner and Product Combination)</ReportTitle>
    <Month>November, 2014</Month>
    <BannerIdSec>Bashas</BannerIdSec>
    <BannerStore />
    <StoreID />
    <ProductName>1x14 OZ BOBOLI 12" CRUST ORIGINAL</ProductName>
    <UPC>073130012373</UPC>
    <Delivery>50</Delivery>
    <Pickup>0</Pickup>
    <Net>50</Net>
    <Color />
  </ReportColorAnalysis>
  <ReportColorAnalysis>
    <ChainID>60620</ChainID>
    <SupplierID>40557</SupplierID>
    <ReportName>ZeroPOSReport</ReportName>
    <ReportTitle>ZERO POS - TOP 10 PRODUCTS (Banner and Product Combination)</ReportTitle>
    <Month>November, 2014</Month>
    <BannerIdSec>Bashas</BannerIdSec>
    <BannerStore />
    <StoreID />
    <ProductName>ORO OATNUT BREAD</ProductName>
    <UPC>073130028558</UPC>
    <Delivery>50</Delivery>
    <Pickup>-13</Pickup>
    <Net>37</Net>
    <Color />
  </ReportColorAnalysis>
  <ReportColorAnalysis>
    <ChainID>60620</ChainID>
    <SupplierID>40557</SupplierID>
    <ReportName>ZeroPOSReport</ReportName>
    <ReportTitle>ZERO POS - TOP 10 PRODUCTS (Banner and Product Combination)</ReportTitle>
    <Month>November, 2014</Month>
    <BannerIdSec>Food City</BannerIdSec>
    <BannerStore />
    <StoreID />
    <ProductName>Bimbo Rebanadas Multipack</ProductName>
    <UPC>074323094619</UPC>
    <Delivery>32</Delivery>
    <Pickup>0</Pickup>
    <Net>32</Net>
    <Color />
  </ReportColorAnalysis>
  <ReportColorAnalysis>
    <ChainID>60620</ChainID>
    <SupplierID>40557</SupplierID>
    <ReportName>ZeroPOSReport</ReportName>
    <ReportTitle>ZERO POS - TOP 10 PRODUCTS (Banner and Product Combination)</ReportTitle>
    <Month>November, 2014</Month>
    <BannerIdSec>Food City</BannerIdSec>
    <BannerStore />
    <StoreID />
    <ProductName>Marinela Suavicremas Vanilla</ProductName>
    <UPC>074323037951</UPC>
    <Delivery>28</Delivery>
    <Pickup>0</Pickup>
    <Net>28</Net>
    <Color>#C4D79B</Color>
  </ReportColorAnalysis>
  <ReportColorAnalysis>
    <ChainID>60620</ChainID>
    <SupplierID>40557</SupplierID>
    <ReportName>ZeroPOSReport</ReportName>
    <ReportTitle>ZERO POS - TOP 10 PRODUCTS (Banner and Product Combination)</ReportTitle>
    <Month>November, 2014</Month>
    <BannerIdSec>A.J.s</BannerIdSec>
    <BannerStore />
    <StoreID />
    <ProductName>1X14OZ ARNOLD STUFFING HERBSEASONED</ProductName>
    <UPC>073410310250</UPC>
    <Delivery>18</Delivery>
    <Pickup>0</Pickup>
    <Net>18</Net>
    <Color>#C4D79B</Color>
  </ReportColorAnalysis>
  <ReportColorAnalysis>
    <ChainID>60620</ChainID>
    <SupplierID>40557</SupplierID>
    <ReportName>ZeroPOSReport</ReportName>
    <ReportTitle>ZERO POS - TOP 10 PRODUCTS (Banner and Product Combination)</ReportTitle>
    <Month>November, 2014</Month>
    <BannerIdSec>Bashas</BannerIdSec>
    <BannerStore />
    <StoreID />
    <ProductName>1X14OZ ARNOLD STUFFING HERBSEASONED</ProductName>
    <UPC>073410310250</UPC>
    <Delivery>11</Delivery>
    <Pickup>0</Pickup>
    <Net>11</Net>
    <Color />
  </ReportColorAnalysis>
  <ReportColorAnalysis>
    <ChainID>60620</ChainID>
    <SupplierID>40557</SupplierID>
    <ReportName>ZeroPOSReport</ReportName>
    <ReportTitle>ZERO POS - TOP 10 PRODUCTS (Banner and Product Combination)</ReportTitle>
    <Month>November, 2014</Month>
    <BannerIdSec>Bashas</BannerIdSec>
    <BannerStore />
    <StoreID />
    <ProductName>Thomas EM's Limited Edition Rotation</ProductName>
    <UPC>048121221003</UPC>
    <Delivery>11</Delivery>
    <Pickup>0</Pickup>
    <Net>11</Net>
    <Color />
  </ReportColorAnalysis>
  <ReportColorAnalysis>
    <ChainID>60620</ChainID>
    <SupplierID>40557</SupplierID>
    <ReportName>ZeroPOSReport</ReportName>
    <ReportTitle>ZERO POS - TOP 15 PRODUCTS at all Banners, by Store (Banner + Store + Product Combination)</ReportTitle>
    <Month>November, 2014</Month>
    <BannerIdSec>Food City</BannerIdSec>
    <BannerStore>Food City-37</BannerStore>
    <StoreID>37</StoreID>
    <ProductName>Bimbolete  - Chocolate Creme Filled Snack</ProductName>
    <UPC>074323099713</UPC>
    <Delivery>156</Delivery>
    <Pickup>-72</Pickup>
    <Net>84</Net>
    <Color>#B8CCE4</Color>
  </ReportColorAnalysis>
  <ReportColorAnalysis>
    <ChainID>60620</ChainID>
    <SupplierID>40557</SupplierID>
    <ReportName>ZeroPOSReport</ReportName>
    <ReportTitle>ZERO POS - TOP 15 PRODUCTS at all Banners, by Store (Banner + Store + Product Combination)</ReportTitle>
    <Month>November, 2014</Month>
    <BannerIdSec>Food City</BannerIdSec>
    <BannerStore>Food City-37</BannerStore>
    <StoreID>37</StoreID>
    <ProductName>Pan de Muerto</ProductName>
    <UPC>074323054880</UPC>
    <Delivery>72</Delivery>
    <Pickup>0</Pickup>
    <Net>72</Net>
    <Color>#B8CCE4</Color>
  </ReportColorAnalysis>
  <ReportColorAnalysis>
    <ChainID>60620</ChainID>
    <SupplierID>40557</SupplierID>
    <ReportName>ZeroPOSReport</ReportName>
    <ReportTitle>ZERO POS - TOP 15 PRODUCTS at all Banners, by Store (Banner + Store + Product Combination)</ReportTitle>
    <Month>November, 2014</Month>
    <BannerIdSec>Bashas</BannerIdSec>
    <BannerStore>Bashas-172</BannerStore>
    <StoreID>172</StoreID>
    <ProductName>1x14 OZ BOBOLI 12" CRUST ORIGINAL</ProductName>
    <UPC>073130012373</UPC>
    <Delivery>47</Delivery>
    <Pickup>0</Pickup>
    <Net>47</Net>
    <Color>#B8CCE4</Color>
  </ReportColorAnalysis>
  <ReportColorAnalysis>
    <ChainID>60620</ChainID>
    <SupplierID>40557</SupplierID>
    <ReportName>ZeroPOSReport</ReportName>
    <ReportTitle>ZERO POS - TOP 15 PRODUCTS at all Banners, by Store (Banner + Store + Product Combination)</ReportTitle>
    <Month>November, 2014</Month>
    <BannerIdSec>Bashas</BannerIdSec>
    <BannerStore>Bashas-92</BannerStore>
    <StoreID>92</StoreID>
    <ProductName>ORO OATNUT BREAD</ProductName>
    <UPC>073130028558</UPC>
    <Delivery>50</Delivery>
    <Pickup>-13</Pickup>
    <Net>37</Net>
    <Color />
  </ReportColorAnalysis>
  <ReportColorAnalysis>
    <ChainID>60620</ChainID>
    <SupplierID>40557</SupplierID>
    <ReportName>ZeroPOSReport</ReportName>
    <ReportTitle>ZERO POS - TOP 15 PRODUCTS at all Banners, by Store (Banner + Store + Product Combination)</ReportTitle>
    <Month>November, 2014</Month>
    <BannerIdSec>Food City</BannerIdSec>
    <BannerStore>Food City-149</BannerStore>
    <StoreID>149</StoreID>
    <ProductName>Bimbolete  - Chocolate Creme Filled Snack</ProductName>
    <UPC>074323099713</UPC>
    <Delivery>48</Delivery>
    <Pickup>-12</Pickup>
    <Net>36</Net>
    <Color />
  </ReportColorAnalysis>
  <ReportColorAnalysis>
    <ChainID>60620</ChainID>
    <SupplierID>40557</SupplierID>
    <ReportName>ZeroPOSReport</ReportName>
    <ReportTitle>ZERO POS - TOP 15 PRODUCTS at all Banners, by Store (Banner + Store + Product Combination)</ReportTitle>
    <Month>November, 2014</Month>
    <BannerIdSec>Food City</BannerIdSec>
    <BannerStore>Food City-142</BannerStore>
    <StoreID>142</StoreID>
    <ProductName>BIMBO ROLES GLASEADOS2CT</ProductName>
    <UPC>074323091779</UPC>
    <Delivery>40</Delivery>
    <Pickup>-5</Pickup>
    <Net>35</Net>
    <Color>#FAACAC</Color>
  </ReportColorAnalysis>
  <ReportColorAnalysis>
    <ChainID>60620</ChainID>
    <SupplierID>40557</SupplierID>
    <ReportName>ZeroPOSReport</ReportName>
    <ReportTitle>ZERO POS - TOP 15 PRODUCTS at all Banners, by Store (Banner + Store + Product Combination)</ReportTitle>
    <Month>November, 2014</Month>
    <BannerIdSec>Food City</BannerIdSec>
    <BannerStore>Food City-112</BannerStore>
    <StoreID>112</StoreID>
    <ProductName>Bimbo Rebanadas Multipack</ProductName>
    <UPC>074323094619</UPC>
    <Delivery>32</Delivery>
    <Pickup>0</Pickup>
    <Net>32</Net>
    <Color>#FAACAC</Color>
  </ReportColorAnalysis>
  <ReportColorAnalysis>
    <ChainID>60620</ChainID>
    <SupplierID>40557</SupplierID>
    <ReportName>ZeroPOSReport</ReportName>
    <ReportTitle>ZERO POS - TOP 15 PRODUCTS at all Banners, by Store (Banner + Store + Product Combination)</ReportTitle>
    <Month>November, 2014</Month>
    <BannerIdSec>Food City</BannerIdSec>
    <BannerStore>Food City-4</BannerStore>
    <StoreID>4</StoreID>
    <ProductName>Marinela Suavicremas Vanilla</ProductName>
    <UPC>074323037951</UPC>
    <Delivery>28</Delivery>
    <Pickup>0</Pickup>
    <Net>28</Net>
    <Color>#FAACAC</Color>
  </ReportColorAnalysis>
  <ReportColorAnalysis>
    <ChainID>60620</ChainID>
    <SupplierID>40557</SupplierID>
    <ReportName>ZeroPOSReport</ReportName>
    <ReportTitle>ZERO POS - TOP 15 PRODUCTS at all Banners, by Store (Banner + Store + Product Combination)</ReportTitle>
    <Month>November, 2014</Month>
    <BannerIdSec>Food City</BannerIdSec>
    <BannerStore>Food City-107</BannerStore>
    <StoreID>107</StoreID>
    <ProductName>Bimbolete  - Chocolate Creme Filled Snack</ProductName>
    <UPC>074323099713</UPC>
    <Delivery>20</Delivery>
    <Pickup>0</Pickup>
    <Net>20</Net>
    <Color />
  </ReportColorAnalysis>
  <ReportColorAnalysis>
    <ChainID>60620</ChainID>
    <SupplierID>40557</SupplierID>
    <ReportName>ZeroPOSReport</ReportName>
    <ReportTitle>ZERO POS - TOP 15 PRODUCTS at all Banners, by Store (Banner + Store + Product Combination)</ReportTitle>
    <Month>November, 2014</Month>
    <BannerIdSec>A.J.s</BannerIdSec>
    <BannerStore>A.J.s-63</BannerStore>
    <StoreID>63</StoreID>
    <ProductName>1X14OZ ARNOLD STUFFING HERBSEASONED</ProductName>
    <UPC>073410310250</UPC>
    <Delivery>18</Delivery>
    <Pickup>0</Pickup>
    <Net>18</Net>
    <Color />
  </ReportColorAnalysis>
  <ReportColorAnalysis>
    <ChainID>60620</ChainID>
    <SupplierID>40557</SupplierID>
    <ReportName>ZeroPOSReport</ReportName>
    <ReportTitle>ZERO POS - TOP 15 PRODUCTS at all Banners, by Store (Banner + Store + Product Combination)</ReportTitle>
    <Month>November, 2014</Month>
    <BannerIdSec>Food City</BannerIdSec>
    <BannerStore>Food City-162</BannerStore>
    <StoreID>162</StoreID>
    <ProductName>BIMBO ROLES GLASEADOS2CT</ProductName>
    <UPC>074323091779</UPC>
    <Delivery>24</Delivery>
    <Pickup>-8</Pickup>
    <Net>16</Net>
    <Color />
  </ReportColorAnalysis>
  <ReportColorAnalysis>
    <ChainID>60620</ChainID>
    <SupplierID>40557</SupplierID>
    <ReportName>ZeroPOSReport</ReportName>
    <ReportTitle>ZERO POS - TOP 15 PRODUCTS at all Banners, by Store (Banner + Store + Product Combination)</ReportTitle>
    <Month>November, 2014</Month>
    <BannerIdSec>Food City</BannerIdSec>
    <BannerStore>Food City-37</BannerStore>
    <StoreID>37</StoreID>
    <ProductName>BIMBO ROLES GLASEADOS2CT</ProductName>
    <UPC>074323091779</UPC>
    <Delivery>53</Delivery>
    <Pickup>-41</Pickup>
    <Net>12</Net>
    <Color />
  </ReportColorAnalysis>
  <ReportColorAnalysis>
    <ChainID>60620</ChainID>
    <SupplierID>40557</SupplierID>
    <ReportName>ZeroPOSReport</ReportName>
    <ReportTitle>ZERO POS - TOP 15 PRODUCTS at all Banners, by Store (Banner + Store + Product Combination)</ReportTitle>
    <Month>November, 2014</Month>
    <BannerIdSec>Food City</BannerIdSec>
    <BannerStore>Food City-10</BannerStore>
    <StoreID>10</StoreID>
    <ProductName>Bimbolete  - Chocolate Creme Filled Snack</ProductName>
    <UPC>074323099713</UPC>
    <Delivery>12</Delivery>
    <Pickup>0</Pickup>
    <Net>12</Net>
    <Color />
  </ReportColorAnalysis>
  <ReportColorAnalysis>
    <ChainID>60620</ChainID>
    <SupplierID>40557</SupplierID>
    <ReportName>ZeroPOSReport</ReportName>
    <ReportTitle>ZERO POS - TOP 15 PRODUCTS at all Banners, by Store (Banner + Store + Product Combination)</ReportTitle>
    <Month>November, 2014</Month>
    <BannerIdSec>Bashas</BannerIdSec>
    <BannerStore>Bashas-28</BannerStore>
    <StoreID>28</StoreID>
    <ProductName>1X14OZ ARNOLD STUFFING HERBSEASONED</ProductName>
    <UPC>073410310250</UPC>
    <Delivery>11</Delivery>
    <Pickup>0</Pickup>
    <Net>11</Net>
    <Color />
  </ReportColorAnalysis>
  <ReportColorAnalysis>
    <ChainID>60620</ChainID>
    <SupplierID>40557</SupplierID>
    <ReportName>ZeroPOSReport</ReportName>
    <ReportTitle>ZERO POS - TOP 15 PRODUCTS at all Banners, by Store (Banner + Store + Product Combination)</ReportTitle>
    <Month>November, 2014</Month>
    <BannerIdSec>Bashas</BannerIdSec>
    <BannerStore>Bashas-56</BannerStore>
    <StoreID>56</StoreID>
    <ProductName>ORO COUNTRY WHITE</ProductName>
    <UPC>073130004323</UPC>
    <Delivery>10</Delivery>
    <Pickup>0</Pickup>
    <Net>10</Net>
    <Color />
  </ReportColorAnalysis>
</ColorAnalysis>'
*/
CREATE PROC [dbo].[usp_ReportColorAnalysis_Insert]
@ReportColorAnalysisXml XML

AS 
BEGIN
	DECLARE @Month AS VARCHAR(20)
	SELECT @Month = DATENAME(MONTH, DateAdd(month, -1, Convert(date, GETDATE()))) + ', ' + DATENAME(YEAR,DateAdd(month, -1, Convert(date, GETDATE()))) 

	DELETE RCA
	FROM [dbo].[ReportColorAnalysis] AS RCA
	INNER JOIN (
				SELECT Distinct T.ReportColorAnalysis.value('ChainID[1]', 'varchar(20)') AS [ChainID],
					T.ReportColorAnalysis.value('SupplierID[1]', 'varchar(20)') AS [SupplierID],
					T.ReportColorAnalysis.value('ReportName[1]', 'nvarchar(100)') AS [ReportName],
					T.ReportColorAnalysis.value('ReportTitle[1]', 'nvarchar(250)') AS [ReportTitle],
					T.ReportColorAnalysis.value('Month[1]', 'nvarchar(20)') AS [Month]

				FROM  @ReportColorAnalysisXml.nodes('/ColorAnalysis/ReportColorAnalysis') AS T(ReportColorAnalysis)
			   ) AS TRCA ON RCA.[ChainID]=TRCA.[ChainID]
				   AND RCA.[SupplierID]=TRCA.[SupplierID] 
				   AND RCA.[ReportName]=TRCA.[ReportName] 
				   AND RCA.[ReportTitle]=TRCA.[ReportTitle] 
				   AND RCA.[Month]=@Month
	
	INSERT INTO [dbo].[ReportColorAnalysis]
			   ([ChainID]
			   ,[SupplierID]
			   ,[Supplier Name]
			   ,[ReportName]
			   ,[ReportTitle]
			   ,[Month]
			   ,[BannerIdSec]
			   ,[Banner Store]
			   ,[Store ID]
			   ,[Product Name]
			   ,[UPC]
			   ,[Delivery]
			   ,[Pickup]
			   ,[Net]
			   ,[Color])
     
            SELECT T.ReportColorAnalysis.value('ChainID[1]', 'varchar(20)') AS [ChainID],
				 T.ReportColorAnalysis.value('SupplierID[1]', 'varchar(20)') AS [SupplierID],
				 T.ReportColorAnalysis.value('SupplierName[1]', 'varchar(200)') AS [SupplierName],
				 T.ReportColorAnalysis.value('ReportName[1]', 'nvarchar(100)') AS [ReportName],
				 T.ReportColorAnalysis.value('ReportTitle[1]', 'nvarchar(250)') AS [ReportTitle],
				 --T.ReportColorAnalysis.value('Month[1]', 'nvarchar(20)') AS [Month],
				 @Month AS [Month],
				 T.ReportColorAnalysis.value('BannerIdSec[1]', 'nvarchar(250)') AS [BannerIdSec],
				 T.ReportColorAnalysis.value('BannerStore[1]', 'nvarchar(250)') AS [Banner Store],
				 T.ReportColorAnalysis.value('StoreID[1]', 'varchar(50)') AS [Store ID] ,
				 T.ReportColorAnalysis.value('ProductName[1]', 'nvarchar(500)') AS [Product Name],
				 T.ReportColorAnalysis.value('UPC[1]', 'nvarchar(20)') AS [UPC],
				 T.ReportColorAnalysis.value('Delivery[1]', 'varchar(20)') AS [Delivery],
				 T.ReportColorAnalysis.value('Pickup[1]', 'varchar(20)') AS [Pickup],
				 T.ReportColorAnalysis.value('Net[1]', 'varchar(20)') AS [Net],
				 T.ReportColorAnalysis.value('Color[1]', 'nvarchar(20)') AS [Color]

			FROM 
			   @ReportColorAnalysisXml.nodes('/ColorAnalysis/ReportColorAnalysis') AS T(ReportColorAnalysis)
			
END
GO
