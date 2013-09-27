accept s_name prompt 'enter segment name: '
accept s_owner prompt 'enter segment owner if not pbds: '
accept s_type prompt 'enter segment type if not table: '

var v_TOTAL_BLOCKS               NUMBER
var v_TOTAL_BYTES                NUMBER
var v_UNUSED_BLOCKS              NUMBER
var v_UNUSED_BYTES               NUMBER
var v_LUSED_EXTENT_FILE_ID       NUMBER
var v_LUSED_EXTENT_BLOCK_ID      NUMBER
var v_LUSED_BLOCK                NUMBER

exec dbms_space.unused_space (nvl(upper('&s_owner'),'PBDS'),-
upper('&s_name'),nvl(upper('&s_type'),'TABLE'), -
:v_TOTAL_BLOCKS,:v_TOTAL_BYTES,:v_UNUSED_BLOCKS,:v_UNUSED_BYTES, -
:v_LUSED_EXTENT_FILE_ID,:v_LUSED_EXTENT_BLOCK_ID,:v_LUSED_BLOCK)


select (:v_total_bytes - :v_UNUSED_BYTES)/1024 as "HWM in KB" from dual;
