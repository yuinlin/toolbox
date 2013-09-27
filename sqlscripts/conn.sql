-- usage: 
-- @conn gc  = conn gigagame@carmen
-- @conn gp  = conn gigagame@play
-- @conn g1  = conn gigagame@sdk1db
-- @conn d1  = conn dba_giga@sdk1db
-- @conn g2  = conn gigagame@sdk2db
-- @conn d2  = conn dba_giga@sdk2db
-- @conn g5  = conn gigagame@sdk5db
-- @conn d5  = conn dba_giga@sdk5db
-- @conn gf  = conn gigagame@ftestdb
-- @conn df  = conn dba_giga@ftestdb


col connect_string new_value connect_string

select case when '&1' = 'gc' then 'gigagame/gigagame@carmen'
            when '&1' = 'gp' then 'gigagame/gigagame@play'
            when '&1' = 'g1' then 'gigagame/gigagame@sdk1db'
            when '&1' = 'g2' then 'gigagame/gigagame@sdk2db'
            when '&1' = 'g5' then 'gigagame/gigagame@sdk5db'            
            when '&1' = 'g7' then 'gigagame/gigagame@sdk7db'            
            when '&1' = 'gf' then 'gigagame/gigagame@ftestdb'            
            when '&1' = 'd1' then 'dba_giga/!Giga@sdk1db'
            when '&1' = 'd2' then 'dba_giga/!Giga@sdk2db'
            when '&1' = 'd5' then 'dba_giga/!Giga@sdk5db'
            when '&1' = 'd7' then 'dba_giga/!Giga@sdk7db'
            when '&1' = 'df' then 'dba_giga/!Giga@ftestdb'
        end as connect_string
  from dual;        
       
conn &connect_string 