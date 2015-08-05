SELECT v.name, v.open_mode, v.restricted, d.status
FROM v$pdbs v, dba_pdbs d
WHERE v.guid = d.guid
ORDER BY v.create_scn;