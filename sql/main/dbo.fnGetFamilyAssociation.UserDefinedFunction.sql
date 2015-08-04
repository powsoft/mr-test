USE [DataTrue_Main]
GO
/****** Object:  UserDefinedFunction [dbo].[fnGetFamilyAssociation]    Script Date: 06/25/2015 18:26:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*  
select   dbo.fnGetFamilyAssociation(OrganizationEntityID,0)ImmediateParentID,  
dbo.fnGetFamilyAssociation(OrganizationEntityID,1)FamilyAssociation  
,*   
from   
Memberships  WHERE OrganizationEntityID=60738  
  
*/  
CREATE FUNCTION [dbo].[fnGetFamilyAssociation] (@CURRENT INT,@RetrivalType INT)  
RETURNS VARCHAR(MAX)  
AS  
BEGIN  
        DECLARE @LEVEL INT  
        DECLARE @STACK TABLE (ITEM INT, LEVEL INT)  
        DECLARE @FINAL TABLE (MEMBERID INT)   
        DECLARE @FINAL1 TABLE (MEMBERID INT)   
        DECLARE @FamilyAssociation VARCHAR(MAX)  
  SET @FamilyAssociation=','  
       
        INSERT INTO @STACK VALUES (@CURRENT, 1)  
        SELECT @LEVEL = 1  
        IF @RetrivalType=1  
        BEGIN  
    
        WHILE @LEVEL > 0  
            BEGIN  
               IF EXISTS (SELECT * FROM @STACK WHERE LEVEL = @LEVEL)  
                    BEGIN  
                      SELECT @CURRENT = ITEM  
                         FROM @STACK  
                     WHERE LEVEL = @LEVEL  
                     IF @LEVEL>1  
                     BEGIN  
       INSERT INTO @FINAL  
       SELECT @CURRENT  
                     END  
                           
                         DELETE FROM @STACK   
                         WHERE LEVEL = @LEVEL  
                         AND ITEM = @CURRENT  
           
                         INSERT INTO @STACK  
                         SELECT OrganizationEntityID, @LEVEL + 1  
                         FROM dbo.Memberships (NOLOCK)  
                         WHERE MemberEntityID = @CURRENT AND OrganizationEntityID <> @CURRENT  
                           
                              
       
                         IF @@ROWCOUNT > 0  
                            SELECT @LEVEL = @LEVEL + 1  
                         ELSE  
							DELETE FROM @FINAL WHERE MEMBERID=-1  
                    END  
               ELSE  
                  SELECT @LEVEL = @LEVEL - 1  
                 -- DELETE FROM @FINAL WHERE MEMBERID=@CURRENT  
            END -- WHILE  
            END  
         IF @RetrivalType=0    
         BEGIN  
          INSERT INTO @FINAL  
            SELECT  OrganizationEntityID FROM dbo.Memberships  
            WHERE MemberEntityID=@CURRENT  
         END   
    INSERT INTO @FINAL1  
       SELECT DISTINCT MEMBERID  FROM @FINAL ORDER BY 1  
       
        SELECT @FamilyAssociation=@FamilyAssociation+ CAST(MEMBERID AS VARCHAR(1000))+',' FROM @FINAL1  
          
        RETURN @FamilyAssociation  
          
END
GO
