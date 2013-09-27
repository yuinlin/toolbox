accept SCHEMA prompt "schema (default all, can do fuzzy match): "

select case when object_type = 'PACKAGE BODY' 
            then 'alter PACKAGE '||owner||'.'||object_name||' compile BODY;' 
            else 'alter '|| object_type ||' '||owner||'.'||object_name||' compile;' 
        end as "invalid objects"
  from all_objects 
 where object_type in ('PROCEDURE','FUNCTION','TRIGGER','PACKAGE', 'PACKAGE BODY','VIEW','MATERIALIZED VIEW')
   and ( ('&SCHEMA' is null)
          or
         (owner like upper('%&SCHEMA%'))
       )   
   and status <> 'VALID';