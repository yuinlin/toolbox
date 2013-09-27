accept wdate prompt "work date (t=today, t-1=yesterday, etc): "
accept prochrs prompt "hours spent on stored proc: "
accept testhrs prompt "hours spent on stress test: "

col translatedDate new_value translatedDate

select case when '&wdate' is null then trunc(sysdate)
                          when lower('&wdate') = 't' then trunc(sysdate)
                          else (trunc(sysdate) + replace(lower('&wdate'),'t')) end
        as translatedDate
  from dual;

insert into worklog (wdate
                     ,storedprochrs
                     ,stresstesthrs)
             values ('&translatedDate'
                     ,nvl('&prochrs',0)
                     ,nvl('&testhrs',0));


-- show log for the week
select * 
  from worklog 
 where wdate between next_day('&translatedDate','MONDAY')-7 and 
                     next_day('&translatedDate','MONDAY')-1       
 order by wdate;

accept dosave prompt "commit? (y/n): "

begin
   if nvl(upper('&dosave'),'N') = 'Y' then
      commit;
   else
      rollback;
   end if;
end;
/