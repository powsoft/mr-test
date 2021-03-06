USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMR_process_Populate_PDI_CHAIN_SUPPLIER_RELATIONS]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Irina,rush>
-- Create date: <17 Sep 2014>
-- Description:	<Populateing PDI_CHAIN_SUPPLIER_RELATIONS table from DataTrue_EDI..Temp_PDI_VendorIDs>
-- =============================================
CREATE  PROCEDURE [dbo].[prMR_process_Populate_PDI_CHAIN_SUPPLIER_RELATIONS]
AS
BEGIN

/**************** Case 1
from DataTrue_EDI..Temp_PDI_VendorIDs 
*************/

   select distinct DataTruechainid,DataTruesupplierid from DataTrue_EDI..Temp_PDI_VendorIDs 
   except
   select distinct chainid,supplierid  from   PDI_CHAIN_SUPPLIER_RELATIONS 
   
   if  @@ROWCOUNT > 0
   insert into PDI_CHAIN_SUPPLIER_RELATIONS(chainid, supplierid, chainname, suppliername, PDIPARTicipant)  
   select chainid, supplierid, chainname, suppliername,1 --pdi  into  drop table ZZtemp_PDISUPP
    from
  (select distinct DataTruechainid,DataTruesupplierid from DataTrue_EDI..Temp_PDI_VendorIDs 
   except
   select distinct chainid,supplierid  from   PDI_CHAIN_SUPPLIER_RELATIONS  )a
   inner join suppliers s
   on s.SupplierID=DataTruesupplierid
   inner join Chains c
   on c.ChainID=DataTrueChainID
   
   
   select distinct OrganizationEntityID,MemberEntityID from Memberships
   where MembershipTypeID in (15,14,33)
   except
   select distinct chainid,supplierid  from   PDI_CHAIN_SUPPLIER_RELATIONS 
   
   
   
   /**************** Case 1
from DataTrue_EDI..Memberships 
*************/
   
    if  @@ROWCOUNT > 0
   insert into PDI_CHAIN_SUPPLIER_RELATIONS(chainid, supplierid, chainname, suppliername, PDIPARTicipant)  
   select chainid, supplierid, chainname, suppliername,1 --pdi  into  drop table ZZtemp_PDISUPP
    from
  (select distinct  OrganizationEntityID,MemberEntityID from Memberships
   where MembershipTypeID in (15,14)
   except
   select distinct chainid,supplierid  from   PDI_CHAIN_SUPPLIER_RELATIONS  )a
   inner join suppliers s
   on s.SupplierID=MemberEntityID
   inner join Chains c
   on c.ChainID=OrganizationEntityID
   
      /**************** Case 2
from DataTrue_EDI..COSTS where Recordsource like 'tmppdi' and supplier is regulated
*************/
   
   select distinct dtchainid,dtSupplierID from DataTrue_EDI..costs   
   inner join suppliers s
   on s.supplierid=dtsupplierid
   and s.isregulated=1
   where RecordStatus=0 and Recordsource like 'tmppdi'
    except
   select distinct chainid,supplierid  from   PDI_CHAIN_SUPPLIER_RELATIONS 
   
   
   if  @@ROWCOUNT > 0
   insert into PDI_CHAIN_SUPPLIER_RELATIONS(chainid, supplierid, chainname, suppliername, PDIPARTicipant)  
   select chainid, supplierid, chainname, suppliername,1 --pdi  into  drop table ZZtemp_PDISUPP
    from
    (
    select distinct dtchainid,dtSupplierID from DataTrue_EDI..costs   
   inner join suppliers s
   on s.supplierid=dtsupplierid
   --and s.isregulated=1
   where RecordStatus=0 and Recordsource like 'tmppdi'
    except
   select distinct chainid,supplierid  from   PDI_CHAIN_SUPPLIER_RELATIONS 
    )a
    
    inner join suppliers s
   on s.SupplierID=dtsupplierid
   inner join Chains c
   on c.ChainID=dtChainID
   
     
END
GO
