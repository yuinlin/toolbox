accept sql prompt "sql (double up quotes!): "

exec print_table(rtrim('&sql',';'))
