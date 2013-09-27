col node form 99
col name form a38
col type form a11
col value form a60

accept pname prompt 'parameter name like: '

select inst_id node
       ,name
       ,case type when 1 then 'boolean'
                  when 2 then 'string'
                  when 3 then 'integer'
                  when 4 then 'pfile'
                  when 5 then 'reserved'
                  when 6 then 'big integer'
                  else to_char(type) end type
       ,value
  from gv$parameter
 where lower(name) like lower('%&pname%')
 order by name, inst_id;