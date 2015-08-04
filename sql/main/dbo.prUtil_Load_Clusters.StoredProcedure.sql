USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Load_Clusters]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--CREATE procedure [dbo].[prUtil_Load_Clusters]
CREATE procedure [dbo].[prUtil_Load_Clusters]
as
/*
select * FROM  Clusters WHERE (ChainID > 3)
select * from DataTrue_EDI..Load_StoreClusters
*/
declare @MyID int
set @MyID = 7605

declare @rec cursor
declare @chainidentifier nvarchar(50)
declare @clusteridentifier nvarchar(50)
declare @clusterdescription nvarchar(500)
declare @clusterparentidentifier nvarchar(50)
declare @clusterparentid int
declare @parentclusterneeded tinyint
declare @clusterentitytypeid int
declare @clustermembershiptypeid int
declare @newclusterid int
declare @loadstatus smallint
declare @updatememberships bit
declare @recordid int
declare @chainid int
declare	@externalidentifier nvarchar(50)
declare @externaldescription nvarchar(50)

select @clusterentitytypeid = EntityTypeID
--select * 
from [dbo].[EntityTypes]
where EntityTypeName = 'Cluster'

print 'One|' + str(@clusterentitytypeid)

select @clustermembershiptypeid = MembershipTypeID
--select * 
from [dbo].[MembershipTypes]
where MembershipTypeName = 'ClusterMembership'

print 'Two|' + str(@clustermembershiptypeid)

set @updatememberships = 0

set @rec = CURSOR local fast_forward FOR
SELECT [ChainIdentifier]
      ,[ClusterIdentifier]
      ,[ClusterDescription]
      ,isnull([ClusterParentIdentifier], '')
      ,[RecordID]
      ,[ExternalIdentifier]
      ,[ExternalDescription]
  FROM [DataTrue_EDI].[dbo].[Load_StoreClusters]
  where LoadStatus = 0
  order by RecordID

print 'Three|' + str(@@rowcount)

open @rec

fetch next from @rec into 
@chainidentifier
,@clusteridentifier
,@clusterdescription
,@clusterparentidentifier
,@recordid
,@externalidentifier
,@externaldescription

print 'Three2|' + @chainidentifier + '|' + @clusteridentifier


while @@FETCH_STATUS = 0
	begin

begin transaction

begin try

		set @loadstatus = 1

		select @chainid = ChainID from Chains where ChainIdentifier = @chainidentifier
		
		if @@ROWCOUNT < 1
			set @loadstatus = -2

print 'Four|' + str(@chainid)
	
		select ClusterID from .Clusters
		where ClusterName = @clusteridentifier
		and ChainID = @chainid
		
		if @@ROWCOUNT < 1 and @loadstatus <> -2
			begin
			
print 'Five|' + str(@@ROWCOUNT)
			
				set @parentclusterneeded = 0
				if LEN(@clusterparentidentifier) > 0
					begin
						set @parentclusterneeded = 1
						select @clusterparentid =  ClusterID
						from Clusters
						where ltrim(rtrim(ClusterName)) = ltrim(rtrim(@clusterparentidentifier))
						if @@ROWCOUNT > 0 
							set @parentclusterneeded = 0
					end
				else
					begin
						set @clusterparentid = 0
					end
				if @parentclusterneeded = 0
					begin
					
						
						INSERT INTO [dbo].[SystemEntities]
								   ([EntityTypeID]
								   ,[LastUpdateUserID]
								   ,[DateTimeLastUpdate])
							 VALUES
								   (@clusterentitytypeid
								   ,@MyID
								   ,GETDATE())				
						
						select @newclusterid = SCOPE_IDENTITY()
						
						
						INSERT INTO [dbo].[Clusters]
								   ([ChainID]
								   ,[ClusterID]
								   ,[ClusterName]
								   ,[ClusterDescription]
								   ,[LastUpdateUserID]
								   ,[DateTimeLastUpdate]
								   ,[ExternalIdentifier]
									,[ExternalDescription])
							 VALUES
								   (@chainid
								   ,@newclusterid
								   ,@clusteridentifier
								   ,@clusterdescription
								   ,@MyID
								   ,GETDATE()
								   ,@externalidentifier
								   ,@externaldescription)

						--Add to Memberships table
						
						if LEN(@clusterparentidentifier) < 1
							begin
								set @clusterparentid = 0
							end
							
								INSERT INTO [dbo].[Memberships]
										   ([MembershipTypeID]
										   ,[ChainID]
										   ,[OrganizationEntityID]
										   ,[MemberEntityID]
										   ,[LastUpdateUserID]
										   ,[DateTimeLastUpdate])
									 VALUES
										   (@clustermembershiptypeid
										   ,@chainid
										   ,@clusterparentid
										   ,@newclusterid
										   ,@MyID
										   ,GETDATE())	
								set @updatememberships = 1							
							--end
						
						/*		   
						update [DataTrue_EDI].[dbo].[Load_StoreClusters] 
						set LoadStatus = @loadstatus 
						where RecordID = @recordid --ClusterIdentifier = @clusteridentifier
						*/
					end
				else
					begin
						set @loadstatus = -1
					/*
						update [DataTrue_EDI].[dbo].[Load_StoreClusters] 
						set LoadStatus = -1 
						where RecordID = @recordid --ClusterIdentifier = @clusteridentifier
					*/
					end

			
			end

		commit transaction
	
end try
	
begin catch
		rollback transaction
		
		set @loadstatus = -3
		
		declare @errormessage varchar(4500)
		declare @errorlocation varchar(255)

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		
		exec dbo.prSendEmailNotification
		@errorlocation,
		@errormessage,
		@errorlocation,
		@MyID
end catch


		update [DataTrue_EDI].[dbo].[Load_StoreClusters] 
		set LoadStatus = @loadstatus 
		where RecordID = @recordid

		fetch next from @rec into 
		@chainidentifier
		,@clusteridentifier
		,@clusterdescription
		,@clusterparentidentifier
		,@recordid
		,@externalidentifier
		,@externaldescription
	end
	
close @rec
deallocate @rec

if @updatememberships = 1
	begin
		exec prMemberships_HierarchyID_Update
	end

	
return
GO
