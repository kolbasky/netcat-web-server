#!/usr/bin/env bash
# port to listen to
port=9187
# script to reply to requests
# escape all $vars with \ between EOFs 
# unless you want them to get expanded at paste time
script=$(mktemp)
trap "rm -f $script" EXIT INT TERM QUIT ERR
cat << EOF > $script
#!/usr/bin/env bash
while read line; do 
  if [[ \$line =~ GET./.*HTTP ]]; then
    # treat value after first / as parameter
    webparam=\${line##GET /};
    webparam=\${webparam%% HTTP*};
    break;
  fi
done;
# log to console. plain echo will not work!
echo "\$(date "+%Y-%m-%dT%T") - \$webparam" > /dev/tty
# check param before inserting into sql
if [[ \$webparam =~ ^-?[0-9]+$ ]];then
  query="
    select COALESCE(
      jsonb_pretty(json_agg(pss)::jsonb), 
      'queryid not found'
    )
    from pg_stat_statements pss 
    where queryid = \$webparam;"
  echo -e "HTTP/1.1 200 OK\n\n";
  # actual response
  timeout 2 psql -U postgres -qtAX -c "\$query" || true
else
    echo -e "HTTP/1.1 403 Forbidden\n\n";
    echo -e "URL should look like http://$(hostname):$port/<queryid>";
fi
EOF
chmod +x $script
nc -k -l -p $port -c "$script"  
