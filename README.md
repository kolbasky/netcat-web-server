Example script for replying to web-requests via netcat.<br>
Replies to requests like http://hostname:port/<queryid>, where queryid is id of postgresql query.<br>
Script looks up this id in pg_stat_statements and replies with nice json, containig query text and stats.
