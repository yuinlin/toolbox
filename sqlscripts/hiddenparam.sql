--must conn as sysdba
accept PARAM_NAME prompt "parameter name: "

col Parameter form a30
col "Session Value" form a30
col "Instance Value" form a30

SELECT a.ksppinm "Parameter",
b.ksppstvl "Session Value",
c.ksppstvl "Instance Value"
FROM x$ksppi a, x$ksppcv b, x$ksppsv c
WHERE a.indx = b.indx AND
a.indx = c.indx AND
a.ksppinm LIKE '%&PARAM_NAME%';
