col DESTINATION form a26
col DEST_NAME form a30

select DEST_ID
       ,DEST_NAME 
       ,DESTINATION
       ,TARGET
       ,VALID_TYPE
       ,VALID_ROLE
       ,VALID_NOW
       ,STATUS
  from v$archive_dest;
